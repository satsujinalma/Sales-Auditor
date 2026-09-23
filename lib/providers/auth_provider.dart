import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/shop_model.dart';
import '../services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isOtpSent = false;
  String _phoneNumber = '';
  String? _errorMessage;

  StreamSubscription<AppUser?>? _authSubscription;

  AuthProvider(this._authRepository) {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  bool get isLoading => _isLoading;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isOtpSent => _isOtpSent;
  String get phoneNumber => _phoneNumber;
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

  Future<bool> sendOtp(String phone) async {
    _isSendingOtp = true;
    _errorMessage = null;
    _phoneNumber = phone.trim();
    notifyListeners();

    try {
      await _authRepository.sendOtp(_phoneNumber);
      _isOtpSent = true;
      _isSendingOtp = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send OTP: $e';
      _isSendingOtp = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _isVerifyingOtp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.verifyOtp(
        phoneNumber: _phoneNumber,
        otp: otp.trim(),
      );
      _currentUser = user;
      _isVerifyingOtp = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isVerifyingOtp = false;
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

  void resetOtpState() {
    _isOtpSent = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _currentUser = null;
    _isOtpSent = false;
    _phoneNumber = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
