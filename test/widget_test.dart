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

  testWidgets('Full Lottery Sales Auditor UI & Interaction Smoke Test', (
    WidgetTester tester,
  ) async {
    final repository = MockLiveSalesRepository();
    await repository.init();
    await repository.saveShop(testShop);
    await repository.setSelectedShopId(testShop.id);
    await repository.resetDaySales('nayarambalam');

    final authRepository = HybridAuthRepository(repository);
    await authRepository.init();
    final freshUser = await authRepository.verifyOtp(
      phoneNumber: '+91 9876543210',
      otp: '123456',
    );
    await authRepository.completeOnboarding(
      user: freshUser.copyWith(
        name: 'Test Shopkeeper',
        role: UserRole.shopkeeper,
        shopId: 'nayarambalam',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => SalesProvider(repository)),
          ChangeNotifierProvider(create: (_) => AdminProvider(repository)),
        ],
        child: const KeralaLotteryAuditorApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify initial Shopkeeper UI components
    expect(find.text('BOX 1'), findsOneWidget);
    expect(find.text('BOX 2'), findsOneWidget);
    expect(find.text('BOX 3'), findsOneWidget);
    expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);

    // Initial state
    expect(find.text('No sales yet'), findsOneWidget);

    // Tap button '1' (1 ticket @ ₹50 staged)
    final btn1 = find.widgetWithText(InkWell, '1').first;
    await tester.tap(btn1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Confirm and enter sale for Customer 1
    final enterSaleBtn1 =
        find.widgetWithText(ElevatedButton, 'ENTER SALE • ₹50');
    expect(enterSaleBtn1, findsOneWidget);
    await tester.tap(enterSaleBtn1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Box 2 updated to 1 ticket
    expect(find.text('1'), findsWidgets);
    expect(find.text('₹50'), findsWidgets);

    // Tap button '12' (1 Full Set = 12 tickets @ ₹570 staged)
    final btn12 = find.widgetWithText(InkWell, '12').first;
    await tester.ensureVisible(btn12);
    await tester.tap(btn12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Confirm and enter sale for Customer 2
    final enterSaleBtn12 =
        find.widgetWithText(ElevatedButton, 'ENTER SALE • ₹570');
    expect(enterSaleBtn12, findsOneWidget);
    await tester.ensureVisible(enterSaleBtn12);
    await tester.tap(enterSaleBtn12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Total tickets should now be 1 + 12 = 13 tickets
    expect(find.text('13'), findsWidgets);
    expect(find.text('₹620'), findsWidgets);
    expect(find.text('₹47.69'), findsWidgets);

    // Test Undo functionality
    final undoBtn = find.widgetWithText(ElevatedButton, 'Undo');
    if (undoBtn.evaluate().isNotEmpty) {
      await tester.tap(undoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After undoing last 12 tickets, total should revert to 1 ticket @ ₹50
      expect(find.text('1'), findsWidgets);
      expect(find.text('₹50'), findsWidgets);
    }

    // Switch to Admin / Head App Mode (prompts for Master Admin credentials)
    final adminIconBtn = find.byIcon(Icons.admin_panel_settings_outlined);
    expect(adminIconBtn, findsOneWidget);
    await tester.tap(adminIconBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Head App Security dialog is presented
    expect(find.text('Head App Security'), findsOneWidget);
    expect(find.text('VERIFY & ENTER'), findsOneWidget);

    // Enter Admin username and password
    await tester.enterText(
      find.widgetWithText(TextField, 'Admin Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Admin Password'),
      'vazhapazhamadmin@321',
    );
    await tester.pump();

    // Tap Verify & Enter
    await tester.tap(find.text('VERIFY & ENTER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Admin Screen elements
    expect(find.text('HEAD APP • AUDIT MONITOR'), findsOneWidget);
    expect(find.text('LIVE MIRRORED UI'), findsOneWidget);
  });
}
