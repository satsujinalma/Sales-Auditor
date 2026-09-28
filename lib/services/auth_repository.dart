import '../models/app_user.dart';
import '../models/shop_model.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> getCurrentUser();
  Future<AppUser> loginAsShopkeeper({
    required String name,
    String? phoneNumber,
    String? shopName,
  });
  Future<AppUser> loginWithAdminCredentials({
    required String username,
    required String password,
  });
  Future<void> updateAdminCredentials({
    required String username,
    required String password,
  });
  Future<Map<String, String>> getAdminCredentials();
  Future<void> completeOnboarding({
    required AppUser user,
    Shop? initialShop,
  });
  Future<void> signOut();
}
