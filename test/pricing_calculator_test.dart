import 'package:flutter_test/flutter_test.dart';
import 'package:sales_auditor/models/pricing_config.dart';
import 'package:sales_auditor/services/pricing_calculator.dart';

void main() {
  group('PricingCalculator Tests', () {
    const nayarambalamPricing = PricingConfig(
      singleTicketPrice: 50.0,
      setPrice12: 570.0, // Nayarambalam rate
      bulkFormula: BulkPricingFormula.proRata,
      targetBenchmarkMin: 48.30,
      targetBenchmarkMax: 48.50,
      claimedAvgPrice: 47.20,
    );

    const standardPricing = PricingConfig(
      singleTicketPrice: 50.0,
      setPrice12: 580.0, // Standard branch rate
      bulkFormula: BulkPricingFormula.proRata,
      targetBenchmarkMin: 48.30,
      targetBenchmarkMax: 48.50,
      claimedAvgPrice: 47.20,
    );

    test('Single ticket calculation (1 to 11 tickets)', () {
      final res1 = PricingCalculator.calculate(
        ticketCount: 1,
        config: nayarambalamPricing,
      );
      expect(res1.totalAmount, 50.0);
      expect(res1.unitPrice, 50.0);
      expect(res1.isSetOrBulk, false);
      expect(res1.discountAmount, 0.0);

      final res5 = PricingCalculator.calculate(
        ticketCount: 5,
        config: nayarambalamPricing,
      );
      expect(res5.totalAmount, 250.0);
      expect(res5.unitPrice, 50.0);
    });

    test('1 Full Set (12 tickets) with Nayarambalam discount (₹570)', () {
      final res12 = PricingCalculator.calculate(
        ticketCount: 12,
        config: nayarambalamPricing,
      );
      expect(res12.totalAmount, 570.0);
      expect(res12.unitPrice, 47.50); // 570 / 12 = 47.50
      expect(res12.isSetOrBulk, true);
      expect(res12.discountAmount, 30.0); // 600 - 570
    });

    test('1 Full Set (12 tickets) with Standard branch discount (₹580)', () {
      final res12 = PricingCalculator.calculate(
        ticketCount: 12,
        config: standardPricing,
      );
      expect(res12.totalAmount, 580.0);
      expect(res12.unitPrice, closeTo(48.33, 0.01));
      expect(res12.isSetOrBulk, true);
      expect(res12.discountAmount, 20.0); // 600 - 580
    });

    test('> 12 tickets with Pro-Rata Average Rate formula (Nayarambalam)', () {
      // 15 tickets @ 47.50/tkt = 712.50
      final res15 = PricingCalculator.calculate(
        ticketCount: 15,
        config: nayarambalamPricing,
      );
      expect(res15.totalAmount, 712.50);
      expect(res15.unitPrice, 47.50);
      expect(res15.isSetOrBulk, true);

      // 24 tickets (2 full sets) @ 47.50 = 1140.0
      final res24 = PricingCalculator.calculate(
        ticketCount: 24,
        config: nayarambalamPricing,
      );
      expect(res24.totalAmount, 1140.0);
      expect(res24.unitPrice, 47.50);
    });

    test('> 12 tickets with Sets + Remainder formula', () {
      const remainderPricing = PricingConfig(
        singleTicketPrice: 50.0,
        setPrice12: 570.0,
        bulkFormula: BulkPricingFormula.setPlusRemainder,
      );

      // 15 tickets = 1 set (570) + 3 singles (3 * 50 = 150) = 720
      final res15 = PricingCalculator.calculate(
        ticketCount: 15,
        config: remainderPricing,
      );
      expect(res15.totalAmount, 720.0);
      expect(res15.unitPrice, 48.0);
      expect(res15.isSetOrBulk, true);
    });

    test('Invalid ticket count returns zero', () {
      final res0 = PricingCalculator.calculate(
        ticketCount: 0,
        config: nayarambalamPricing,
      );
      expect(res0.totalAmount, 0.0);
      expect(res0.unitPrice, 0.0);
    });
  });
}
