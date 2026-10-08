import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/shop_model.dart';
import '../services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  bool _isLoading = true;
  bool _isLoggingIn = false;
  bool _isLoggingInAsAdmin = false;
  String? _errorMessage;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<List<AppUser>>? _usersSubscription;

  AuthProvider(this._authRepository) {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isApproved =>
      _currentUser?.role == UserRole.admin || (_currentUser?.isApproved ?? false);
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  bool get isLoading => _isLoading;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoggingInAsAdmin => _isLoggingInAsAdmin;
  String? get errorMessage => _errorMessage;

  List<AppUser> get allUsers => _allUsers;
  List<AppUser> get pendingUsers => _allUsers
      .where((u) => u.role == UserRole.shopkeeper && !u.isApproved && u.approvalStatus == ApprovalStatus.pending)
      .toList();
  List<AppUser> get approvedStaff => _allUsers
      .where((u) => u.role == UserRole.shopkeeper && u.isApproved)
      .toList();

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getCurrentUser();
      _allUsers = await _authRepository.getAllUsers();

      _authSubscription = _authRepository.authStateChanges().listen((user) {
        _currentUser = user;
        notifyListeners();
      });

      _usersSubscription = _authRepository.watchAllUsers().listen((users) {
        _allUsers = users;
        // If current user is in users list, sync status
        if (_currentUser != null && _currentUser!.role != UserRole.admin) {
          final matched = users.where((u) => u.id == _currentUser!.id);
          if (matched.isNotEmpty && matched.first.isApproved != _currentUser!.isApproved) {
            _currentUser = matched.first;
          }
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      final refreshed = await _authRepository.refreshCurrentUser();
      if (refreshed != null) {
        _currentUser = refreshed;
      }
      _allUsers = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshUsers() async {
    try {
      _allUsers = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> loginAsShopkeeper({
    required String name,
    String? phoneNumber,
    String? shopName,
  }) async {
    _isLoggingIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginAsShopkeeper(
        name: name.trim(),
        phoneNumber: phoneNumber?.trim(),
        shopName: shopName?.trim(),
      );
      _currentUser = user;
      _allUsers = await _authRepository.getAllUsers();
      _isLoggingIn = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithAdminCredentials(
    String username,
    String password,
  ) async {
    _isLoggingInAsAdmin = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginWithAdminCredentials(
        username: username.trim(),
        password: password.trim(),
      );
      _currentUser = user;
      _allUsers = await _authRepository.getAllUsers();
      _isLoggingInAsAdmin = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoggingInAsAdmin = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, String>> getAdminCredentials() async {
    return await _authRepository.getAdminCredentials();
  }

  Future<bool> updateAdminCredentials({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.updateAdminCredentials(
        username: username.trim(),
        password: password.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update credentials: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String name,
    required UserRole role,
    Shop? initialShop,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name.trim(),
        role: role,
        shopId: initialShop?.id,
        shopName: initialShop?.name,
      );

      await _authRepository.completeOnboarding(
        user: updatedUser,
        initialShop: initialShop,
      );

      _currentUser = updatedUser.copyWith(isProfileComplete: true);
      _allUsers = await _authRepository.getAllUsers();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Admin Approval Actions ---

  Future<void> approveUser(String userId, {String? shopId}) async {
    try {
      await _authRepository.approveUser(userId, shopId: shopId);
      _allUsers = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to approve user: $e';
      notifyListeners();
    }
  }

  Future<void> rejectUser(String userId) async {
    try {
      await _authRepository.rejectUser(userId);
      _allUsers = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reject user: $e';
      notifyListeners();
    }
  }

  Future<void> revokeUser(String userId) async {
    try {
      await _authRepository.revokeUser(userId);
      _allUsers = await _authRepository.getAllUsers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to revoke user: $e';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }
}
