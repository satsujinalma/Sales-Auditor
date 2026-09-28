import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/shop_model.dart';
import '../services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isLoggingIn = false;
  bool _isLoggingInAsAdmin = false;
  String? _errorMessage;

  StreamSubscription<AppUser?>? _authSubscription;

  AuthProvider(this._authRepository) {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  bool get isLoading => _isLoading;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoggingInAsAdmin => _isLoggingInAsAdmin;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getCurrentUser();
      _authSubscription = _authRepository.authStateChanges().listen((user) {
        _currentUser = user;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      );

      await _authRepository.completeOnboarding(
        user: updatedUser,
        initialShop: initialShop,
      );

      _currentUser = updatedUser.copyWith(isProfileComplete: true);
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

  Future<void> signOut() async {
    await _authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
