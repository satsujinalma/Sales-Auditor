import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/main.dart';
import 'package:sales_auditor/models/app_user.dart';
import 'package:sales_auditor/providers/admin_provider.dart';
import 'package:sales_auditor/providers/auth_provider.dart';
import 'package:sales_auditor/providers/sales_provider.dart';
import 'package:sales_auditor/services/hybrid_auth_repository.dart';
import 'package:sales_auditor/services/mock_live_sales_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Authentication & Onboarding Flow Tests', () {
    test('Unit Test: Fresh user verification & onboarding completion', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Send OTP
      await authRepo.sendOtp('+91 9876543210');

      // Verify OTP for fresh user
      final freshUser = await authRepo.verifyOtp(
        phoneNumber: '+91 9876543210',
        otp: '123456',
      );

      expect(freshUser.phoneNumber, '+919876543210');
      expect(freshUser.isProfileComplete, false);

      // Complete Onboarding as Shopkeeper
      await authRepo.completeOnboarding(
        user: freshUser.copyWith(
          name: 'Rajesh Nayarambalam',
          role: UserRole.shopkeeper,
        ),
      );

      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.name, 'Rajesh Nayarambalam');
      expect(currentUser.isProfileComplete, true);
      expect(currentUser.role, UserRole.shopkeeper);

      // Sign out
      await authRepo.signOut();
      expect(await authRepo.getCurrentUser(), isNull);
    });

    testWidgets('Widget Test: Full Phone Login -> OTP -> Onboarding Flow', (
      WidgetTester tester,
    ) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
            ChangeNotifierProvider(create: (_) => SalesProvider(salesRepo)),
            ChangeNotifierProvider(create: (_) => AdminProvider(salesRepo)),
          ],
          child: const KeralaLotteryAuditorApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 1: Verify on Phone Login Screen
      expect(find.text('SALES AUDITOR'), findsOneWidget);
      expect(find.text('Sign In with Mobile'), findsOneWidget);
      expect(find.text('GET OTP'), findsOneWidget);

      // Tap demo quick fill
      await tester.tap(find.text('Demo Quick Fill: +91 98765 43210'));
      await tester.pump();

      // Tap GET OTP
      await tester.tap(find.text('GET OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 2: Verify on OTP Verification Screen
      expect(find.text('Verify Phone Number'), findsOneWidget);
      expect(find.text('VERIFY & SIGN IN'), findsOneWidget);

      // Tap test OTP hint to auto-fill '123456'
      await tester.tap(find.text('Test OTP: 123456 (Tap to auto-fill)'));
      await tester.pump();

      // Tap Verify & Sign In
      await tester.tap(find.text('VERIFY & SIGN IN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 3: Fresh user should land on Profile Onboarding Screen
      expect(find.text('Complete Store & Role Setup'), findsOneWidget);
      expect(find.text('1. SELECT YOUR APP ROLE'), findsOneWidget);
      expect(find.text('COMPLETE & ENTER APP'), findsOneWidget);

      // Fill in onboarding details
      // 1. Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shopkeeper Name'),
        'Sandeep Nayarambalam',
      );
      // 2. Shop Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shop / Agency Name'),
        'Nayarambalam Central Lucky Center',
      );
      // 3. Location
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Location / Landmark'),
        'Nayarambalam Junction',
      );
      // 4. Shop Code
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shop Code'),
        'NYR-05',
      );

      await tester.pump();

      // Scroll button into view and tap
      final submitBtn = find.text('COMPLETE & ENTER APP');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();

      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 4: User should now be in the main app (Shopkeeper Sales Terminal)
      expect(find.text('BOX 1'), findsOneWidget);
      expect(find.text('BOX 2'), findsOneWidget);
      expect(find.text('BOX 3'), findsOneWidget);
      expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);
    });

    test('Unit Test: Admin login with default credentials and update credentials', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Verify default admin credentials
      final initialCreds = await authRepo.getAdminCredentials();
      expect(initialCreds['username'], 'admin');
      expect(initialCreds['password'], 'vazhapazhamadmin@321');

      // Login with default admin credentials
      final adminUser = await authRepo.loginWithAdminCredentials(
        username: 'admin',
        password: 'vazhapazhamadmin@321',
      );

      expect(adminUser.role, UserRole.admin);
      expect(adminUser.isProfileComplete, true);
      expect(adminUser.name, 'Central Admin & Auditor');

      // Update admin credentials
      await authRepo.updateAdminCredentials(
        username: 'superadmin',
        password: 'newsecurepassword@999',
      );

      final updatedCreds = await authRepo.getAdminCredentials();
      expect(updatedCreds['username'], 'superadmin');
      expect(updatedCreds['password'], 'newsecurepassword@999');

      // Old password should now fail
      expect(
        () => authRepo.loginWithAdminCredentials(
          username: 'admin',
          password: 'vazhapazhamadmin@321',
        ),
        throwsException,
      );

      // New password should succeed
      final updatedAdmin = await authRepo.loginWithAdminCredentials(
        username: 'superadmin',
        password: 'newsecurepassword@999',
      );
      expect(updatedAdmin.role, UserRole.admin);
    });

    testWidgets('Widget Test: Admin direct login with username & password to Admin Dashboard', (
      WidgetTester tester,
    ) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
            ChangeNotifierProvider(create: (_) => SalesProvider(salesRepo)),
            ChangeNotifierProvider(create: (_) => AdminProvider(salesRepo)),
          ],
          child: const KeralaLotteryAuditorApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify on PhoneLoginScreen
      expect(find.text('Shopkeeper (OTP)'), findsOneWidget);
      expect(find.text('Admin Login'), findsOneWidget);

      // 2. Switch to Admin Login tab
      await tester.tap(find.text('Admin Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 3. Verify Admin login form is shown
      expect(find.text('Admin Direct Login'), findsOneWidget);
      expect(find.text('SIGN IN AS ADMIN'), findsOneWidget);

      // 4. Fill in Admin credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admin Username'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admin Password'),
        'vazhapazhamadmin@321',
      );
      await tester.pump();

      // 5. Scroll to SIGN IN AS ADMIN button and tap
      final signInBtn = find.text('SIGN IN AS ADMIN');
      await tester.ensureVisible(signInBtn);
      await tester.pumpAndSettle();

      await tester.tap(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 6. Should land directly on Admin Dashboard
      expect(find.text('HEAD APP • AUDIT MONITOR'), findsOneWidget);
      expect(find.text('LIVE MIRRORED UI'), findsOneWidget);
      expect(find.text('ALL SHOPS SUMMARY'), findsOneWidget);
    });
  });
}
