import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/shop_model.dart';
import 'auth_repository.dart';
import 'sales_repository.dart';

class HybridAuthRepository implements AuthRepository {
  static const String _keyCurrentUser = 'sales_auditor_current_user_v1';
  static const String _keyUsersList = 'sales_auditor_registered_users_v1';

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
      final userJson = prefs.getString(_keyCurrentUser);
      if (userJson != null) {
        _currentUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
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
  Future<void> sendOtp(String phoneNumber) async {
    if (!_initialized) await init();
  }

  @override
  Future<AppUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (!_initialized) await init();

    // Verify OTP (Allows standard test OTP 123456 or any 6-digit number)
    if (otp.trim().length != 6) {
      throw Exception('Invalid OTP. Please enter a 6-digit code.');
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_keyUsersList);
    Map<String, dynamic> usersMap = {};

    if (usersJson != null) {
      try {
        usersMap = jsonDecode(usersJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    AppUser user;
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    if (usersMap.containsKey(normalizedPhone)) {
      // Existing user
      user = AppUser.fromJson(usersMap[normalizedPhone] as Map<String, dynamic>);
    } else {
      // Fresh user
      user = AppUser(
        id: _uuid.v4(),
        phoneNumber: normalizedPhone,
        name: '',
        role: UserRole.shopkeeper,
        isProfileComplete: false,
        createdAt: DateTime.now(),
      );
      usersMap[normalizedPhone] = user.toJson();
      await prefs.setString(_keyUsersList, jsonEncode(usersMap));
    }

    _currentUser = user;
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    _authStateController.add(_currentUser);

    return user;
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

    final normalizedPhone = completedUser.phoneNumber.replaceAll(RegExp(r'\s+'), '');
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
