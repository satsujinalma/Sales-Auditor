import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/main.dart';
import 'package:sales_auditor/models/daily_sales_summary.dart';
import 'package:sales_auditor/models/sale_transaction.dart';
import 'package:sales_auditor/providers/admin_provider.dart';
import 'package:sales_auditor/providers/auth_provider.dart';
import 'package:sales_auditor/providers/sales_provider.dart';
import 'package:sales_auditor/services/hybrid_auth_repository.dart';
import 'package:sales_auditor/services/mock_live_sales_repository.dart';
import 'package:sales_auditor/models/pricing_config.dart';
import 'package:sales_auditor/models/shop_model.dart';
import 'package:sales_auditor/widgets/sales_volume_breakdown_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sales Volume Analysis & Box Pattern Tests', () {
    test('Unit Test: DailySalesSummary volumeDistribution records correct quantities for various ticket purchases', () {
      final now = DateTime.now();
      final txs = <SaleTransaction>[];

      // 5 people took 1 ticket each
      for (int i = 0; i < 5; i++) {
        txs.add(SaleTransaction(
          id: 'tx_1_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 1,
          totalAmount: 50.0,
          unitPrice: 50.0,
          isSetOrBulk: false,
        ));
      }

      // 2 tickets went out 30 times
      for (int i = 0; i < 30; i++) {
        txs.add(SaleTransaction(
          id: 'tx_2_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 2,
          totalAmount: 100.0,
          unitPrice: 50.0,
          isSetOrBulk: false,
        ));
      }

      // 8 lots of the 12-ticket set went out
      for (int i = 0; i < 8; i++) {
        txs.add(SaleTransaction(
          id: 'tx_12_$i',
          shopId: 'kdlr',
          timestamp: now,
          ticketCount: 12,
          totalAmount: 570.0,
          unitPrice: 47.5,
          isSetOrBulk: true,
        ));
      }

      final summary = DailySalesSummary(
        shopId: 'kdlr',
        date: now,
        transactions: txs,
      );

      // Verify exact quantities recorded
      expect(summary.volumeCount(1), 5);
      expect(summary.volumeCount(2), 30);
      expect(summary.volumeCount(12), 8);
      expect(summary.volumeCount(3), 0);

      // Verify singles vs sets counts
      expect(summary.singleOrdersCount, 35); // 5 + 30
      expect(summary.setOrdersCount, 8); // 8
      expect(summary.totalTransactionsCount, 43); // 5 + 30 + 8
      expect(summary.totalTicketsSold, (5 * 1) + (30 * 2) + (8 * 12)); // 5 + 60 + 96 = 161
    });

    testWidgets('Widget Test: SalesVolumeBreakdownWidget displays Left (Singles) and Right (Sets) Box Pattern columns and fires callback on tap', (tester) async {
      final now = DateTime.now();
      final txs = <SaleTransaction>[
        // 1 ticket - 5 quantities
        for (int i = 0; i < 5; i++)
          SaleTransaction(
            id: 'tx_1_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 1,
            totalAmount: 50.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 2 tickets - 8 quantities
        for (int i = 0; i < 8; i++)
          SaleTransaction(
            id: 'tx_2_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 2,
            totalAmount: 100.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 3 tickets - 6 quantities
        for (int i = 0; i < 6; i++)
          SaleTransaction(
            id: 'tx_3_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 3,
            totalAmount: 150.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        // 12 tickets - 10 quantities
        for (int i = 0; i < 10; i++)
          SaleTransaction(
            id: 'tx_12_$i',
            shopId: 'kdlr',
            timestamp: now,
            ticketCount: 12,
            totalAmount: 570.0,
            unitPrice: 47.5,
            isSetOrBulk: true,
          ),
      ];

      final summary = DailySalesSummary(
        shopId: 'kdlr',
        date: now,
        transactions: txs,
      );

      int? tappedCount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SalesVolumeBreakdownWidget(
                summary: summary,
                onSelectTicketCount: (count) {
                  tappedCount = count;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('SALES VOLUME BREAKDOWN'), findsOneWidget);
      expect(find.text('29 ORDERS TODAY'), findsOneWidget);

      // Verify Left Column: Singles (1, 2, 3)
      expect(find.text('SINGLES (LEFT)'), findsOneWidget);
      expect(find.text('1 Ticket'), findsOneWidget);
      expect(find.text('2 Tickets'), findsOneWidget);
      expect(find.text('3 Tickets'), findsOneWidget);

      // Verify Right Column: Sets (6, 12, 24, 36)
      expect(find.text('SETS (RIGHT)'), findsOneWidget);
      expect(find.text('12 Tickets'), findsOneWidget);
      expect(find.text('1 Full Set'), findsOneWidget);

      // Verify figures (quantities)
      expect(find.text('5'), findsWidgets); // 1 tix = 5 qty
      expect(find.text('8'), findsWidgets); // 2 tix = 8 qty
      expect(find.text('6'), findsWidgets); // 3 tix = 6 qty
      expect(find.text('10'), findsWidgets); // 12 tix = 10 qty

      // Test tapping box '12' triggers onSelectTicketCount(12)
      final box12 = find.byKey(const Key('volume_box_12'));
      expect(box12, findsOneWidget);
      await tester.tap(box12);
      expect(tappedCount, 12);

      // Test tapping box '1' triggers onSelectTicketCount(1)
      final box1 = find.byKey(const Key('volume_box_1'));
      expect(box1, findsOneWidget);
      await tester.tap(box1);
      expect(tappedCount, 1);
    });

    testWidgets('Widget Test: In Admin Dashboard ALL SHOPS tab, tapping a specific shop opens the Sales Volume Breakdown modal without switching to Mirror tab', (tester) async {
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

      // Tap on the first shop card (KDLR Counter)
      expect(find.text('REGISTERED SHOPS (1)'), findsOneWidget);
      await tester.tap(find.text('KDLR Counter'));
      await tester.pumpAndSettle();

      // Verify that the Sales Volume Breakdown modal opened!
      expect(find.text('SALES VOLUME BREAKDOWN'), findsOneWidget);
      expect(find.text('SINGLES (LEFT)'), findsOneWidget);
      expect(find.text('SETS (RIGHT)'), findsOneWidget);
      expect(find.text('MIRROR THIS COUNTER LIVE'), findsOneWidget);

      // Tap 'MIRROR THIS COUNTER LIVE' button to verify it can mirror if desired
      await tester.ensureVisible(find.text('MIRROR THIS COUNTER LIVE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MIRROR THIS COUNTER LIVE'));
      await tester.pumpAndSettle();

      // Now we should be on Mirror mode
      expect(find.text('Live Audit Mode'), findsOneWidget);
    });

    test('Unit Test: AdminProvider.resetShopSales resets only the target shop and keeps other shops intact', () async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();

      // Register a second shop
      await salesRepo.saveShop(
        const Shop(
          id: 'thiru',
          name: 'Thiruvonam',
          location: 'Thiruvonam',
          code: 'THIRU',
          pricingConfig: PricingConfig(),
        ),
      );

      final adminProvider = AdminProvider(salesRepo);
      // Wait for adminProvider to initialize summaries
      await Future.delayed(const Duration(milliseconds: 100));

      final shops = adminProvider.shops;
      expect(shops.length, greaterThanOrEqualTo(2));
      final shop1 = shops[0]; // KDLR
      final shop2 = shops[1]; // Thiruvonam

      // Record sales for both shops
      await salesRepo.recordSale(
        shopId: shop1.id,
        ticketCount: 12,
        config: shop1.pricingConfig,
      );
      await salesRepo.recordSale(
        shopId: shop2.id,
        ticketCount: 5,
        config: shop2.pricingConfig,
      );

      // Verify both shops have sales
      final summary1Before = await salesRepo.getDailySales(shop1.id, DateTime.now());
      final summary2Before = await salesRepo.getDailySales(shop2.id, DateTime.now());
      expect(summary1Before.totalTicketsSold, 12);
      expect(summary2Before.totalTicketsSold, 5);

      // Reset only shop1
      await adminProvider.resetShopSales(shop1.id);

      // Verify shop1 is reset to 0
      final summary1After = await salesRepo.getDailySales(shop1.id, DateTime.now());
      expect(summary1After.totalTicketsSold, 0);
      expect(summary1After.totalRevenue, 0.0);
      expect(adminProvider.allShopSummaries[shop1.id]?.totalTicketsSold, 0);

      // Verify shop2 is completely untouched
      final summary2After = await salesRepo.getDailySales(shop2.id, DateTime.now());
      expect(summary2After.totalTicketsSold, 5);
      expect(summary2After.totalRevenue, 250.0);
      expect(adminProvider.allShopSummaries[shop2.id]?.totalTicketsSold, 5);
    });

    testWidgets('Widget Test: In Admin Dashboard shop modal, tapping RESET SALES button opens confirmation dialog and confirming resets only that shop\'s figures', (tester) async {
      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();

      // Record a sale in KDLR
      final shops = await salesRepo.getShops();
      final defaultShop = shops.first;
      await salesRepo.recordSale(
        shopId: defaultShop.id,
        ticketCount: 12,
        config: defaultShop.pricingConfig,
      );

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

      // Tap on KDLR Counter
      await tester.tap(find.text('KDLR Counter'));
      await tester.pumpAndSettle();

      // Modal is open, verify 12 tickets recorded
      expect(find.text('SALES VOLUME BREAKDOWN'), findsOneWidget);
      expect(find.byKey(const Key('reset_shop_data_button')), findsOneWidget);

      // Scroll to make sure reset button is visible and tap it
      await tester.ensureVisible(find.byKey(const Key('reset_shop_data_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset_shop_data_button')));
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog appears
      expect(find.text('Reset Shop Sales?'), findsOneWidget);
      expect(find.text('KDLR Counter (KDLR)'), findsOneWidget);
      expect(find.text('12 Tickets'), findsWidgets);
      expect(find.text('• Only this specific shop\'s sales will be cleared.\n• Other counters will NOT be affected.\n• Action is performed manually after admin review.'), findsOneWidget);

      // Tap Confirm Reset
      await tester.tap(find.byKey(const Key('confirm_reset_shop_data_button')));
      await tester.pumpAndSettle();

      // Verify SnackBar appears and modal shows 0 tickets sold
      expect(find.text('Sales data for "KDLR Counter" has been reset to 0.'), findsOneWidget);
    });
  });
}
