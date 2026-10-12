import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/main.dart';
import 'package:sales_auditor/models/app_user.dart';
import 'package:sales_auditor/models/daily_sales_summary.dart';
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
    test('Unit Test: Direct Shopkeeper Name & Shop login (defaults to pending approval)', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      await salesRepo.saveShop(testShop);
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Direct Login as Shopkeeper using shopCode
      final user = await authRepo.loginAsShopkeeper(
        name: 'Rajesh Nayarambalam',
        shopCode: 'NYR-01',
      );

      expect(user.name, 'Rajesh Nayarambalam');
      expect(user.role, UserRole.shopkeeper);
      expect(user.isProfileComplete, true);
      expect(user.shopId, isNotNull);
      expect(user.isApproved, false);
      expect(user.approvalStatus, ApprovalStatus.pending);

      // Admin approves the user
      await authRepo.approveUser(user.id);
      final approvedUser = await authRepo.getCurrentUser();
      expect(approvedUser, isNotNull);
      expect(approvedUser!.isApproved, true);
      expect(approvedUser.approvalStatus, ApprovalStatus.approved);

      // Sign out
      await authRepo.signOut();
      expect(await authRepo.getCurrentUser(), isNull);
    });

    test('Unit Test: Multi-User Sync on Same Shop Counter (Amal & Koshi on KDLR)', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Amal registers for KDLR shop
      final amal = await authRepo.loginAsShopkeeper(
        name: 'Amal',
        shopName: 'KDLR',
      );
      // Koshi registers for KDLR shop
      final koshi = await authRepo.loginAsShopkeeper(
        name: 'Koshi',
        shopName: 'KDLR',
      );

      // Both must share the exact same shopId
      expect(amal.shopId, isNotNull);
      expect(koshi.shopId, isNotNull);
      expect(amal.shopId, koshi.shopId);

      final kdlrShopId = amal.shopId!;
      final shop = await salesRepo.getShop(kdlrShopId);
      final pricingConfig = shop?.pricingConfig ?? const PricingConfig(singleTicketPrice: 50.0, setPrice12: 570.0);

      // Admin approves both staff members
      await authRepo.approveUser(amal.id);
      await authRepo.approveUser(koshi.id);

      // Verify pending count is 0 and approved count is 2
      final allStaff = await authRepo.getAllUsers();
      final pending = allStaff.where((u) => u.approvalStatus == ApprovalStatus.pending).toList();
      expect(pending.length, 0);
      expect(allStaff.where((u) => u.isApproved).length, 2);

      // Initialize daily sales for KDLR
      final today = DateTime.now();
      DailySalesSummary? amalViewSummary;
      DailySalesSummary? koshiViewSummary;

      // Both users listen to the same shop's live stream
      final sub1 = salesRepo.watchDailySales(kdlrShopId, today).listen((s) {
        amalViewSummary = s;
      });
      final sub2 = salesRepo.watchDailySales(kdlrShopId, today).listen((s) {
        koshiViewSummary = s;
      });

      // Amal enters 10 tickets
      await salesRepo.recordSale(
        shopId: kdlrShopId,
        ticketCount: 10,
        config: pricingConfig,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(amalViewSummary?.totalTicketsSold, 10);
      expect(amalViewSummary?.totalRevenue, 500.0);
      expect(koshiViewSummary?.totalTicketsSold, 10);
      expect(koshiViewSummary?.totalRevenue, 500.0);

      // Koshi on another terminal records 12 tickets
      await salesRepo.recordSale(
        shopId: kdlrShopId,
        ticketCount: 12,
        config: pricingConfig,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Both counter staff are fully synchronized in real-time
      expect(amalViewSummary?.totalTicketsSold, 22);
      expect(amalViewSummary?.totalRevenue, 1070.0);
      expect(koshiViewSummary?.totalTicketsSold, 22);
      expect(koshiViewSummary?.totalRevenue, 1070.0);

      await sub1.cancel();
      await sub2.cancel();
    });

    testWidgets(
        'Widget Test: Shopkeeper Login -> Pending Approval Screen -> Admin Approves -> Direct Sales Terminal',
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

      // Step 1: Verify on Login Screen
      expect(find.text('SALES AUDIT'), findsOneWidget);
      expect(find.text('Staff Sign In'), findsOneWidget);
      expect(find.text('ENTER SALES'), findsOneWidget);

      // Enter Staff Username & Shop Code
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Staff Username'),
        'Sandeep Nayarambalam',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Shop Code'),
        'NYR-01',
      );
      await tester.pump();

      // Tap ENTER SALES
      final enterBtn = find.text('ENTER SALES');
      await tester.ensureVisible(enterBtn);
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 2: New user must see Pending Approval Screen
      expect(find.text('ACCESS PENDING APPROVAL'), findsOneWidget);
      expect(find.text('REQUEST DETAILS'), findsOneWidget);
      expect(find.text('Sandeep Nayarambalam'), findsOneWidget);
      expect(find.text('Nayarambalam Store'), findsOneWidget);
      expect(find.text('CHECK APPROVAL STATUS'), findsOneWidget);

      // Step 3: Admin approves the user
      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser, isNotNull);
      await authRepo.approveUser(currentUser!.id);

      // Step 4: Tap CHECK APPROVAL STATUS to trigger immediate verification
      final checkBtn = find.text('CHECK APPROVAL STATUS');
      await tester.tap(checkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 5: User is now directly inside the Sales Terminal
      expect(find.text('TOTAL TICKETS'), findsNothing);
      expect(find.text('TOTAL REVENUE'), findsNothing);
      expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);
      expect(find.text('BOX 1'), findsNothing);
      expect(find.text('AUDIT MONITOR'), findsNothing);
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
      expect(initialCreds['password'], anyOf('admin123', 'vazhapazhamadmin@321'));

      // Login with default admin credentials
      final adminUser = await authRepo.loginWithAdminCredentials(
        username: 'admin',
        password: initialCreds['password']!,
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
          password: initialCreds['password']!,
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

    test(
        'Unit Test: Mock User login with admin / admin123 directly accesses User Sales Terminal without approval',
        () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Login as mock user to user section
      final mockUser = await authRepo.loginWithAdminCredentials(
        username: 'admin',
        password: 'admin123',
        asStaffUser: true,
      );

      expect(mockUser.role, UserRole.shopkeeper);
      expect(mockUser.name, 'admin');
      expect(mockUser.isApproved, true);
      expect(mockUser.approvalStatus, ApprovalStatus.approved);
      expect(mockUser.isProfileComplete, true);
    });

    testWidgets(
        'Widget Test: Admin direct login with username & password to Admin Dashboard with STAFF tab',
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

      // 1. Verify on Login Screen (Default is Staff Login)
      expect(find.text('Staff Sign In'), findsOneWidget);
      expect(find.byKey(const Key('admin_shield_button')), findsOneWidget);

      // 2. Tap Admin Shield button on top right
      await tester.tap(find.byKey(const Key('admin_shield_button')));
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
      expect(find.text('MIRROR'), findsOneWidget);
      expect(find.text('ALL SHOPS'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
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

      // Log in a shopkeeper and pre-approve
      final user = await authRepo.loginAsShopkeeper(
        name: 'Nayarambalam Operator',
        shopName: 'Nayarambalam Store',
      );
      await authRepo.approveUser(user.id);

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

    testWidgets(
        'Widget Test: Mock User login with admin & admin123 directly opens User Sales Terminal without approval',
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

      // 1. On Login Screen, tap Admin Shield to open credentials form
      expect(find.byKey(const Key('admin_shield_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin_shield_button')));
      await tester.pumpAndSettle();

      // 2. Verify LOGIN TO USER SECTION button is present
      expect(find.text('LOGIN TO USER SECTION'), findsOneWidget);

      // 3. Enter mock user credentials: admin / admin123
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admin Username'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admin Password'),
        'admin123',
      );
      await tester.pump();

      // 4. Tap LOGIN TO USER SECTION
      final loginUserBtn = find.text('LOGIN TO USER SECTION');
      await tester.ensureVisible(loginUserBtn);
      await tester.tap(loginUserBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 5. Must open User Sales Terminal directly with NO approval needed!
      expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);
      expect(find.text('Pending Approval'), findsNothing);
    });

    test('Unit Test: Staff entering non-existent shop code throws error and does NOT create shop in repository', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      expect(
        () => authRepo.loginAsShopkeeper(
          name: 'Shivane',
          shopCode: 'Vahemahe',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Shop code "Vahemahe" not found'),
        )),
      );

      final shops = await salesRepo.getShops();
      expect(shops.any((s) => s.code.toUpperCase() == 'VAHEMAHE' || s.name == 'Vahemahe'), false);
    });

    testWidgets('Widget Test: Admin registers new shop in ALL SHOPS tab, code is visible, and staff joins', (tester) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      // Login as Admin
      await authRepo.loginWithAdminCredentials(username: 'admin', password: 'vazhapazhamadmin@321');

      final adminProvider = AdminProvider(salesRepo);
      final authProvider = AuthProvider(authRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => SalesProvider(salesRepo)),
            ChangeNotifierProvider.value(value: adminProvider),
          ],
          child: const KeralaLotteryAuditorApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Go to ALL SHOPS tab
      await tester.tap(find.text('ALL SHOPS'));
      await tester.pumpAndSettle();

      // Tap + REGISTER SHOP
      expect(find.byKey(const Key('register_new_shop_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('register_new_shop_button')));
      await tester.pumpAndSettle();

      // Verify register dialog
      expect(find.text('Register New Shop'), findsOneWidget);

      // Enter Shop Name "Thiruvonam"
      await tester.enterText(find.widgetWithText(TextFormField, 'Shop Name'), 'Thiruvonam');
      await tester.pump();

      // Shop code should auto-derive "THIRU"
      expect(find.text('THIRU'), findsOneWidget);

      // Tap REGISTER SHOP
      await tester.tap(find.text('REGISTER SHOP'));
      await tester.pumpAndSettle();

      // Dialog closed, shop code is visible on the shop card!
      expect(find.text('CODE: THIRU'), findsOneWidget);

      // Now verify staff can login with that code
      await authRepo.signOut();
      final staffUser = await authRepo.loginAsShopkeeper(
        name: 'Shivane',
        shopCode: 'THIRU',
      );
      expect(staffUser.shopName, 'Thiruvonam');
      expect(staffUser.approvalStatus, ApprovalStatus.pending);
    });
  });
}
