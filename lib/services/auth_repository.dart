import '../models/app_user.dart';
import '../models/shop_model.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> getCurrentUser();
  Future<void> sendOtp(String phoneNumber);
  Future<AppUser> verifyOtp({required String phoneNumber, required String otp});
  Future<void> completeOnboarding({
    required AppUser user,
    Shop? initialShop,
  });
  Future<void> signOut();
}
