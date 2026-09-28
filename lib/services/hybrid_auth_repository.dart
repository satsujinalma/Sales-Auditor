import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/pricing_config.dart';
import '../models/shop_model.dart';
import 'auth_repository.dart';
import 'firestore_sales_repository.dart';
import 'sales_repository.dart';

class HybridAuthRepository implements AuthRepository {
  static const String _keyCurrentUser = 'sales_auditor_current_user_v1';
  static const String _keyUsersList = 'sales_auditor_registered_users_v1';
  static const String _keyAdminUsername = 'sales_auditor_admin_username_v1';
  static const String _keyAdminPassword = 'sales_auditor_admin_password_v1';

  final SalesRepository _salesRepository;
  final _authStateController = StreamController<AppUser?>.broadcast();
  final _uuid = const Uuid();

  AppUser? _currentUser;
  bool _initialized = false;

  HybridAuthRepository(this._salesRepository);

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure default admin credentials exist locally if not set
      if (!prefs.containsKey(_keyAdminUsername)) {
        await prefs.setString(_keyAdminUsername, 'admin');
      }
      if (!prefs.containsKey(_keyAdminPassword)) {
        await prefs.setString(_keyAdminPassword, 'vazhapazhamadmin@321');
      }

      final userJson = prefs.getString(_keyCurrentUser);
      if (userJson != null) {
        _currentUser =
            AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (_) {}

    _initialized = true;
    _authStateController.add(_currentUser);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _authStateController.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (!_initialized) await init();
    return _currentUser;
  }

  @override
  Future<AppUser> loginAsShopkeeper({
    required String name,
    String? phoneNumber,
    String? shopName,
  }) async {
    if (!_initialized) await init();

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Please enter shopkeeper name');
    }

    String? assignedShopId;
    final cleanShopName = shopName?.trim() ?? '';

    // Check or create store
    final existingShops = await _salesRepository.getShops();
    if (cleanShopName.isNotEmpty) {
      final match = existingShops.where(
        (s) => s.name.toLowerCase() == cleanShopName.toLowerCase(),
      );
      if (match.isNotEmpty) {
        assignedShopId = match.first.id;
        await _salesRepository.setSelectedShopId(assignedShopId);
      } else {
        final newId = cleanShopName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_');
        final shopId = newId.isNotEmpty ? newId : _uuid.v4().substring(0, 8);
        final code = cleanShopName.length >= 3
            ? cleanShopName.substring(0, 3).toUpperCase()
            : 'SHP';

        final newShop = Shop(
          id: shopId,
          name: cleanShopName,
          location: 'Kerala Retail Counter',
          code: code,
          pricingConfig: const PricingConfig(
            singleTicketPrice: 50.0,
            setPrice12: 570.0,
            bulkFormula: BulkPricingFormula.proRata,
            targetBenchmarkMin: 48.30,
            targetBenchmarkMax: 48.50,
            claimedAvgPrice: 47.20,
          ),
        );
        await _salesRepository.saveShop(newShop);
        await _salesRepository.setSelectedShopId(newShop.id);
        assignedShopId = newShop.id;
      }
    } else if (existingShops.isNotEmpty) {
      assignedShopId = existingShops.first.id;
      await _salesRepository.setSelectedShopId(assignedShopId);
    }

    final user = AppUser(
      id: _uuid.v4(),
      name: cleanName,
      phoneNumber: phoneNumber?.trim().isNotEmpty == true
          ? phoneNumber!.trim()
          : 'SHOPKEEPER',
      role: UserRole.shopkeeper,
      isProfileComplete: true,
      shopId: assignedShopId,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    _currentUser = user;
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    _authStateController.add(_currentUser);

    return user;
  }

  @override
  Future<AppUser> loginWithAdminCredentials({
    required String username,
    required String password,
  }) async {
    if (!_initialized) await init();

    final creds = await getAdminCredentials();
    final validUser = creds['username']?.trim();
    final validPass = creds['password']?.trim();

    if (username.trim() != validUser || password.trim() != validPass) {
      throw Exception('Invalid admin username or password');
    }

    final adminUser = AppUser(
      id: 'admin_master_account',
      phoneNumber: 'ADMIN_DESK',
      name: 'Central Admin & Auditor',
      role: UserRole.admin,
      isProfileComplete: true,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    _currentUser = adminUser;
    await prefs.setString(_keyCurrentUser, jsonEncode(adminUser.toJson()));
    _authStateController.add(_currentUser);

    return adminUser;
  }

  @override
  Future<Map<String, String>> getAdminCredentials() async {
    if (!_initialized) await init();

    // Check Cloud Firestore if available
    final salesRepo = _salesRepository;
    if (salesRepo is FirestoreSalesRepository) {
      try {
        final firestoreCreds = await salesRepo.getAdminCredentials();
        return firestoreCreds;
      } catch (_) {}
    }

    // Fallback to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyAdminUsername) ?? 'admin',
      'password': prefs.getString(_keyAdminPassword) ?? 'vazhapazhamadmin@321',
    };
  }

  @override
  Future<void> updateAdminCredentials({
    required String username,
    required String password,
  }) async {
    if (!_initialized) await init();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdminUsername, username.trim());
    await prefs.setString(_keyAdminPassword, password.trim());

    // Sync to Cloud Firestore if connected
    final salesRepo = _salesRepository;
    if (salesRepo is FirestoreSalesRepository) {
      try {
        await salesRepo.updateAdminCredentials(
          username: username.trim(),
          password: password.trim(),
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> completeOnboarding({
    required AppUser user,
    Shop? initialShop,
  }) async {
    if (!_initialized) await init();

    final completedUser = user.copyWith(isProfileComplete: true);
    final prefs = await SharedPreferences.getInstance();

    // Save initial shop if creating a new shop
    if (initialShop != null) {
      await _salesRepository.saveShop(initialShop);
      await _salesRepository.setSelectedShopId(initialShop.id);
    }

    // Save user in registered list
    final usersJson = prefs.getString(_keyUsersList);
    Map<String, dynamic> usersMap = {};
    if (usersJson != null) {
      try {
        usersMap = jsonDecode(usersJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    final normalizedPhone =
        completedUser.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    usersMap[normalizedPhone] = completedUser.toJson();
    await prefs.setString(_keyUsersList, jsonEncode(usersMap));

    // Update active session
    _currentUser = completedUser;
    await prefs.setString(_keyCurrentUser, jsonEncode(completedUser.toJson()));
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) await init();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    _currentUser = null;
    _authStateController.add(null);
  }
}
