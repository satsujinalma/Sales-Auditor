import '../models/app_user.dart';
import '../models/shop_model.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> getCurrentUser();
  Future<AppUser?> refreshCurrentUser();

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

  // Admin User & Staff Approval Management
  Future<List<AppUser>> getAllUsers();
  Stream<List<AppUser>> watchAllUsers();
  Future<void> approveUser(String userId, {String? shopId});
  Future<void> rejectUser(String userId);
  Future<void> revokeUser(String userId);

  Future<void> signOut();
}
