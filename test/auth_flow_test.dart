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

  group('Authentication & Flow Tests', () {
    test('Unit Test: Direct Shopkeeper Name & Shop login', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Direct Login as Shopkeeper
      final user = await authRepo.loginAsShopkeeper(
        name: 'Rajesh Nayarambalam',
        shopName: 'Nayarambalam Store',
      );

      expect(user.name, 'Rajesh Nayarambalam');
      expect(user.role, UserRole.shopkeeper);
      expect(user.isProfileComplete, true);
      expect(user.shopId, isNotNull);

      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.name, 'Rajesh Nayarambalam');

      // Sign out
      await authRepo.signOut();
      expect(await authRepo.getCurrentUser(), isNull);
    });

    testWidgets(
        'Widget Test: Full Shopkeeper Name Login -> Direct Sales Terminal Flow',
        (
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

      // Step 1: Verify on Login Screen
      expect(find.text('SALES AUDIT'), findsOneWidget);
      expect(find.text('Shopkeeper Sign In'), findsOneWidget);
      expect(find.text('ENTER SALES TERMINAL'), findsOneWidget);

      // Enter Shopkeeper Name & Shop Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shopkeeper Name'),
        'Sandeep Nayarambalam',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shop / Counter Name (Optional)'),
        'Nayarambalam Store',
      );
      await tester.pump();

      // Tap ENTER SALES TERMINAL
      final enterBtn = find.text('ENTER SALES TERMINAL');
      await tester.ensureVisible(enterBtn);
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 2: User should now be directly inside the Sales Terminal
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

      // 1. Verify on Login Screen
      expect(find.text('Shopkeeper Login'), findsOneWidget);
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

      // Log in a shopkeeper
      await authRepo.loginAsShopkeeper(
        name: 'Nayarambalam Operator',
        shopName: 'Nayarambalam Store',
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
