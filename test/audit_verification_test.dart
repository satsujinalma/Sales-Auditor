import 'package:flutter_test/flutter_test.dart';
import 'package:sales_auditor/models/pricing_config.dart';
import 'package:sales_auditor/services/mock_live_sales_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kerala Lottery Audit Scenario Verification Tests', () {
    test('Scenario 1: Shopkeeper claims ₹47.20 avg, but customer buys 10 single tickets and only one 12-ticket set', () async {
      final repository = MockLiveSalesRepository();
      await repository.init();
      await repository.resetDaySales('nayarambalam');

      final shop = await repository.getShop('nayarambalam');
      expect(shop, isNotNull);
      final config = shop!.pricingConfig;

      // 10 single tickets sold (10 transactions of 1 ticket @ ₹50)
      for (int i = 0; i < 10; i++) {
        await repository.recordSale(
          shopId: 'nayarambalam',
          ticketCount: 1,
          config: config,
        );
      }

      // 1 set (12 tickets) sold @ ₹570
      await repository.recordSale(
        shopId: 'nayarambalam',
        ticketCount: 12,
        config: config,
      );

      final summary = await repository.getDailySales('nayarambalam', DateTime.now());

      // Total tickets = 10 + 12 = 22
      expect(summary.totalTicketsSold, 22);
      // Total revenue = (10 * 50) + 570 = 500 + 570 = 1070
      expect(summary.totalRevenue, 1070.0);

      // Average price = 1070 / 22 = 48.636...
      expect(summary.averagePricePerTicket, closeTo(48.64, 0.01));

      // Proves actual average (₹48.64) is ABOVE target benchmark (₹48.30 - ₹48.50), disproving claimed ₹47.20!
      expect(summary.averagePricePerTicket > config.targetBenchmarkMin, true);
    });

    test('Scenario 2: Shopkeeper sells exclusively in 12-ticket sets (100% bulk)', () async {
      final repository = MockLiveSalesRepository();
      await repository.init();
      await repository.resetDaySales('nayarambalam');

      final shop = await repository.getShop('nayarambalam');
      final config = shop!.pricingConfig;

      // 5 sets of 12 tickets sold @ ₹570 each
      for (int i = 0; i < 5; i++) {
        await repository.recordSale(
          shopId: 'nayarambalam',
          ticketCount: 12,
          config: config,
        );
      }

      final summary = await repository.getDailySales('nayarambalam', DateTime.now());

      expect(summary.totalTicketsSold, 60);
      expect(summary.totalRevenue, 2850.0); // 5 * 570
      expect(summary.averagePricePerTicket, 47.50); // Exactly set unit rate
      expect(summary.bulkTicketsPercentage, 100.0);
    });

    test('Scenario 3: Dynamic pricing configuration update at runtime', () async {
      final repository = MockLiveSalesRepository();
      await repository.init();
      await repository.resetDaySales('nayarambalam');

      // Update Nayarambalam set price from ₹570 to ₹580
      const updatedConfig = PricingConfig(
        singleTicketPrice: 50.0,
        setPrice12: 580.0,
        bulkFormula: BulkPricingFormula.proRata,
      );

      await repository.updateShopPricing('nayarambalam', updatedConfig);

      final updatedShop = await repository.getShop('nayarambalam');
      expect(updatedShop!.pricingConfig.setPrice12, 580.0);

      // Record a sale with new pricing
      await repository.recordSale(
        shopId: 'nayarambalam',
        ticketCount: 12,
        config: updatedShop.pricingConfig,
      );

      final summary = await repository.getDailySales('nayarambalam', DateTime.now());
      expect(summary.totalRevenue, 580.0);
      expect(summary.averagePricePerTicket, closeTo(48.33, 0.01));
    });

    test('Scenario 4: PIN verification & update', () async {
      final repository = MockLiveSalesRepository();
      await repository.init();

      expect(await repository.verifyAdminPin('1234'), true);
      expect(await repository.verifyAdminPin('9999'), false);

      await repository.updateAdminPin('5678');
      expect(await repository.verifyAdminPin('5678'), true);
      expect(await repository.verifyAdminPin('1234'), false);
    });
  });
}
