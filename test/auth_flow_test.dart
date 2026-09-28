import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/main.dart';
import 'package:sales_auditor/models/app_user.dart';
import 'package:sales_auditor/models/pricing_config.dart';
import 'package:sales_auditor/models/shop_model.dart';
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

  const testShop = Shop(
    id: 'nayarambalam',
    name: 'Nayarambalam Store',
    location: 'Nayarambalam, Vypin',
    code: 'NYR-01',
    pricingConfig: PricingConfig(
      singleTicketPrice: 50.0,
      setPrice12: 570.0,
      bulkFormula: BulkPricingFormula.proRata,
      targetBenchmarkMin: 48.30,
      targetBenchmarkMax: 48.50,
      claimedAvgPrice: 47.20,
    ),
  );

  group('Authentication & Onboarding Flow Tests', () {
    test('Unit Test: Fresh user verification & onboarding completion',
        () async {
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

      // Enter mobile number
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile Number'),
        '9876543210',
      );
      await tester.pump();

      // Tap GET OTP
      await tester.tap(find.text('GET OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 2: Verify on OTP Verification Screen
      expect(find.text('Verify Phone Number'), findsOneWidget);
      expect(find.text('VERIFY & SIGN IN'), findsOneWidget);

      // Enter OTP
      await tester.enterText(
        find.byType(TextFormField),
        '123456',
      );
      await tester.pump();

      // Tap Verify & Sign In
      await tester.tap(find.text('VERIFY & SIGN IN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 3: Fresh user should land on Profile Onboarding Screen
      expect(find.text('Store & Profile Setup'), findsOneWidget);
      expect(find.text('1. SHOPKEEPER DETAILS'), findsOneWidget);
      expect(find.text('COMPLETE & ENTER SALES TERMINAL'), findsOneWidget);

      // Fill in onboarding details
      // 1. Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shopkeeper Name'),
        'Sandeep Nayarambalam',
      );
      // 2. Shop Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shop Name'),
        'Nayarambalam Store',
      );

      await tester.pump();

      // Scroll button into view and tap
      final submitBtn = find.text('COMPLETE & ENTER SALES TERMINAL');
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

    test(
        'Unit Test: Admin login with default credentials and update credentials',
        () async {
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

    testWidgets(
        'Widget Test: Admin direct login with username & password to Admin Dashboard',
        (
      WidgetTester tester,
    ) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      await salesRepo.saveShop(testShop);
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

    testWidgets(
        'Widget Test: Switching from Shopkeeper to Head App requires Master Admin password',
        (
      WidgetTester tester,
    ) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      await salesRepo.saveShop(testShop);
      await salesRepo.setSelectedShopId(testShop.id);

      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Onboard a shopkeeper
      final user = await authRepo.verifyOtp(
        phoneNumber: '+91 9999988888',
        otp: '123456',
      );
      await authRepo.completeOnboarding(
        user: user.copyWith(
          name: 'Nayarambalam Operator',
          role: UserRole.shopkeeper,
          shopId: 'nayarambalam',
        ),
      );

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

      // Verify on Shopkeeper Screen
      expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);

      // Tap Admin Head App icon
      final adminBtn = find.byIcon(Icons.admin_panel_settings_outlined);
      expect(adminBtn, findsOneWidget);
      await tester.tap(adminBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Security dialog should appear
      expect(find.text('Head App Security'), findsOneWidget);
      expect(find.text('VERIFY & ENTER'), findsOneWidget);

      // Enter username & wrong password
      await tester.enterText(
        find.widgetWithText(TextField, 'Admin Username'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Admin Password'),
        'wrongpassword@123',
      );
      await tester.tap(find.text('VERIFY & ENTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Still in dialog, error displayed
      expect(find.text('Head App Security'), findsOneWidget);

      // Enter correct master password
      await tester.enterText(
        find.widgetWithText(TextField, 'Admin Password'),
        'vazhapazhamadmin@321',
      );
      await tester.tap(find.text('VERIFY & ENTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully unlocked Head App
      expect(find.text('HEAD APP • AUDIT MONITOR'), findsOneWidget);
    });
  });
}
