import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/models/ai_benchmark_models.dart';
import 'package:sales_auditor/models/daily_sales_summary.dart';
import 'package:sales_auditor/models/pricing_config.dart';
import 'package:sales_auditor/models/sale_transaction.dart';
import 'package:sales_auditor/models/shop_model.dart';
import 'package:sales_auditor/providers/admin_provider.dart';
import 'package:sales_auditor/providers/ai_benchmark_provider.dart';
import 'package:sales_auditor/providers/auth_provider.dart';
import 'package:sales_auditor/providers/sales_provider.dart';
import 'package:sales_auditor/screens/admin/admin_dashboard_screen.dart';
import 'package:sales_auditor/services/hybrid_auth_repository.dart';
import 'package:sales_auditor/services/mock_live_sales_repository.dart';
import 'package:sales_auditor/services/nemotron_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pricingConfig = PricingConfig(
    singleTicketPrice: 50.0,
    setPrice12: 570.0, // ₹47.50 / ticket in 12-set
  );

  const shop1 = Shop(
    id: 'nayarambalam',
    name: 'Nayarambalam Store',
    location: 'Vypin',
    code: 'NAYAR',
    pricingConfig: pricingConfig,
    claimedAverageRate: 47.20,
  );

  const shop2 = Shop(
    id: 'central_3',
    name: 'Central Shop #3',
    location: 'Ernakulam',
    code: 'CENTRAL3',
    pricingConfig: pricingConfig,
    claimedAverageRate: 46.50,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NVIDIA Nemotron AI Service & Audit Logic Unit Tests', () {
    test('Scenario 1: High bundle volume (82%) with low claim (₹46.50) triggers MISMATCH (🔴)', () async {
      final service = NemotronAiService();
      final config = AiConfig(updatedAt: DateTime.now());

      // 10 sets of 12 tickets (120 tickets @ 570 = 5,700) + 5 singles (5 tickets @ 50 = 250)
      // Total tickets = 125, Total revenue = 5,950 -> Actual avg = 47.60
      // Let's create an even starker example with 82% bundle volume
      final transactions = <SaleTransaction>[];
      for (int i = 0; i < 20; i++) {
        transactions.add(
          SaleTransaction(
            id: 'tx_b_$i',
            shopId: shop2.id,
            timestamp: DateTime.now(),
            ticketCount: 12,
            totalAmount: 580.0,
            unitPrice: 580.0 / 12,
            isSetOrBulk: true,
          ),
        );
      }
      for (int i = 0; i < 4; i++) {
        transactions.add(
          SaleTransaction(
            id: 'tx_s_$i',
            shopId: shop2.id,
            timestamp: DateTime.now(),
            ticketCount: 2,
            totalAmount: 100.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        );
      }

      final summary = DailySalesSummary(
        shopId: shop2.id,
        date: DateTime.now(),
        transactions: transactions,
      );

      final report = await service.auditShopSales(
        shop: shop2,
        summary: summary,
        config: config,
        allowFallback: true,
      );

      expect(report.statusTag, AiStatusTag.mismatch);
      expect(report.statusTag.emoji, '🔴');
      expect(report.bundleRatioPercentage, greaterThan(80.0));
      expect(report.actualAveragePrice, greaterThan(report.claimedAveragePrice));
      expect(report.whatsappProofText, contains('MISMATCH'));
      expect(report.whatsappProofText, contains(shop2.name));
      expect(report.whatsappProofText, contains('Audited by:* NVDIA AI'));
      expect(report.whatsappProofText, contains('AUDIT DEPTH & SETTLEMENT INSIGHT:'));
    });

    test('Scenario 2: Math matches claimed average within ₹0.35 triggers MATCHES (🟢)', () async {
      final service = NemotronAiService();
      final config = AiConfig(updatedAt: DateTime.now());

      final transactions = <SaleTransaction>[
        SaleTransaction(
          id: 'tx_match',
          shopId: shop1.id,
          timestamp: DateTime.now(),
          ticketCount: 12,
          totalAmount: 570.0,
          unitPrice: 47.50,
          isSetOrBulk: true,
        ),
      ];

      final summary = DailySalesSummary(
        shopId: shop1.id,
        date: DateTime.now(),
        transactions: transactions,
      );

      final report = await service.auditShopSales(
        shop: shop1,
        summary: summary,
        config: config,
        allowFallback: true,
      );

      expect(report.statusTag, AiStatusTag.matches);
      expect(report.statusTag.emoji, '🟢');
      expect(report.auditSummary, contains('Sales are healthy'));
      expect(report.whatsappProofText, contains('MATCHES'));
    });

    test('Scenario 3: Higher singles volume explains variance -> CLOSE ENOUGH (🟡)', () async {
      final service = NemotronAiService();
      final config = AiConfig(updatedAt: DateTime.now());

      // Sells predominantly singles (ticketCount < 12)
      final transactions = <SaleTransaction>[];
      for (int i = 0; i < 15; i++) {
        transactions.add(
          SaleTransaction(
            id: 'tx_single_$i',
            shopId: shop1.id,
            timestamp: DateTime.now(),
            ticketCount: 1,
            totalAmount: 50.0,
            unitPrice: 50.0,
            isSetOrBulk: false,
          ),
        );
      }

      final summary = DailySalesSummary(
        shopId: shop1.id,
        date: DateTime.now(),
        transactions: transactions,
      );

      final report = await service.auditShopSales(
        shop: shop1,
        summary: summary,
        config: config,
        allowFallback: true,
      );

      expect(report.statusTag, AiStatusTag.closeEnough);
      expect(report.statusTag.emoji, '🟡');
      expect(report.auditSummary, contains('single-ticket volume'));
    });

    test('Scenario 4: Strictly throws Exception when API key is missing and allowFallback is false', () async {
      final service = NemotronAiService();
      final config = AiConfig(updatedAt: DateTime.now());
      final summary = DailySalesSummary(
        shopId: shop1.id,
        date: DateTime.now(),
      );

      expect(
        () => service.auditShopSales(
          shop: shop1,
          summary: summary,
          config: config,
          allowFallback: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Scenario 5: Successfully extracts fields from truncated or fenced responses', () {
      final service = NemotronAiService();
      const truncatedJson = '''
{
  "statusTag": "Matches",
  "auditSummary": "Claimed average ₹47.20 matches actual weighted average ₹47.50 within ₹0.35 tolerance, indicating accurate reporting.",
  "ticketMixAnalysis": "All 12 tickets sold were part of a 12-ticket bundle (100% bundle sales), with no single-ticket transactions.",
  "habitTrackingAnalysis": "Retailer consistently reports averages close to actuals, suggesting reliable recording habits.",
  "whatsappProofText": "🧾 *
''';
      final parsed = service.extractJsonForTesting(truncatedJson);
      expect(parsed, isNotNull);
      expect(parsed!['statusTag'], 'Matches');
      expect(parsed['auditSummary'], contains('within ₹0.35 tolerance'));
      expect(parsed['ticketMixAnalysis'], contains('100% bundle sales'));
      expect(parsed['habitTrackingAnalysis'], contains('reliable recording habits'));
    });
  });

  group('AI Benchmark Provider & Cloud Config Tests', () {
    test('Provider stops and records error when API key is missing without fallback', () async {
      final repo = MockLiveSalesRepository();
      await repo.init();
      await repo.saveShop(shop1);

      final provider = AiBenchmarkProvider(repository: repo, allowFallback: false);

      await provider.runFullNetworkAudit(
        shops: [shop1],
        summaries: {
          shop1.id: DailySalesSummary(shopId: shop1.id, date: DateTime.now()),
        },
      );

      expect(provider.reports, isEmpty);
      expect(provider.errorMessage, contains('NVIDIA API Key not found in Cloud Database'));
    });

    test('Provider runs full network audit and computes Trust Matrix (with allowFallback: true)', () async {
      final repo = MockLiveSalesRepository();
      await repo.init();
      await repo.saveShop(shop1);
      await repo.saveShop(shop2);

      final provider = AiBenchmarkProvider(repository: repo, allowFallback: true);

      final summaries = {
        shop1.id: DailySalesSummary(
          shopId: shop1.id,
          date: DateTime.now(),
          transactions: [
            SaleTransaction(
              id: 'tx1',
              shopId: shop1.id,
              timestamp: DateTime.now(),
              ticketCount: 12,
              totalAmount: 570.0,
              unitPrice: 47.50,
              isSetOrBulk: true,
            ),
          ],
        ),
        shop2.id: DailySalesSummary(
          shopId: shop2.id,
          date: DateTime.now(),
          transactions: [
            SaleTransaction(
              id: 'tx2',
              shopId: shop2.id,
              timestamp: DateTime.now(),
              ticketCount: 24,
              totalAmount: 1160.0,
              unitPrice: 1160.0 / 24,
              isSetOrBulk: true,
            ),
          ],
        ),
      };

      await provider.runFullNetworkAudit(
        shops: [shop1, shop2],
        summaries: summaries,
      );

      expect(provider.reports.length, 2);
      final matrix = provider.trustMatrix;
      expect(matrix.totalShops, 2);
      expect(matrix.trustIntegrityPercentage, greaterThan(0));
    });

    test('Provider saves AI Config with API key and retrieves it', () async {
      final repo = MockLiveSalesRepository();
      await repo.init();

      final provider = AiBenchmarkProvider(repository: repo);
      final success = await provider.saveAiConfig(
        apiKey: 'nvapi-test-secret-key-12345',
        modelName: 'nvidia/nemotron-3-super-120b-a12b',
      );

      expect(success, true);
      expect(provider.config.apiKey, 'nvapi-test-secret-key-12345');
      expect(provider.config.hasApiKey, true);

      // Verify saved in repository
      final savedConfig = await repo.getAiConfig();
      expect(savedConfig.apiKey, 'nvapi-test-secret-key-12345');
      expect(savedConfig.modelName, 'nvidia/nemotron-3-super-120b-a12b');
    });
  });

  group('Admin Dashboard AI BENCHMARK Tab Widget Tests', () {
    testWidgets('AI BENCHMARK tab is visible in TabBar, navigates to intelligence hub', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final salesRepo = MockLiveSalesRepository();
      await salesRepo.init();
      await salesRepo.saveShop(shop1);
      final authRepo = HybridAuthRepository(salesRepo);
      await authRepo.init();

      final aiProvider = AiBenchmarkProvider(repository: salesRepo, allowFallback: true);
      await aiProvider.runFullNetworkAudit(
        shops: [shop1],
        summaries: {
          shop1.id: DailySalesSummary(
            shopId: shop1.id,
            date: DateTime.now(),
            transactions: [
              SaleTransaction(
                id: 'tx_demo',
                shopId: shop1.id,
                timestamp: DateTime.now(),
                ticketCount: 12,
                totalAmount: 570.0,
                unitPrice: 47.50,
                isSetOrBulk: true,
              ),
            ],
          ),
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
            ChangeNotifierProvider(create: (_) => SalesProvider(salesRepo)),
            ChangeNotifierProvider(create: (_) => AdminProvider(salesRepo)),
            ChangeNotifierProvider.value(value: aiProvider),
          ],
          child: MaterialApp(
            home: AdminDashboardScreen(onSwitchToShopkeeper: () {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Tab 3: AI AUDIT is present
      expect(find.text('AI AUDIT'), findsOneWidget);

      // 2. Tap AI AUDIT tab
      await tester.tap(find.text('AI AUDIT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 3. Verify Intelligence Hub elements render
      expect(find.text('Run Audit'), findsWidgets);
      expect(find.text('NETWORK TRUST MATRIX'), findsOneWidget);
      expect(find.text('WEEKLY AI SHOP ANALYZER'), findsOneWidget);
      expect(find.text('SHOP AI AUDIT CARDS'), findsOneWidget);

      // 4. Verify Weekly Analyzer table columns
      expect(find.text('Shop Name'), findsOneWidget);
      expect(find.text('Weekly Volume'), findsOneWidget);
      expect(find.text('Claim vs. Actual'), findsOneWidget);
      expect(find.text('AI Status Tag'), findsOneWidget);
      expect(find.text('AI Audit Summary'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);

      // 5. Verify 1-Click WhatsApp Proof button is accessible
      final whatsappIconBtns = find.byIcon(Icons.send_rounded);
      expect(whatsappIconBtns, findsWidgets);

      await tester.tap(whatsappIconBtns.first);
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Proof Exporter'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.text('Send on WhatsApp'), findsOneWidget);
    });
  });
}
