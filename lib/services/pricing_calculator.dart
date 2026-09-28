import '../models/pricing_config.dart';

class PriceCalculationResult {
  final int ticketCount;
  final double totalAmount;
  final double unitPrice;
  final bool isSetOrBulk;
  final double discountAmount;
  final String formulaDescription;

  const PriceCalculationResult({
    required this.ticketCount,
    required this.totalAmount,
    required this.unitPrice,
    required this.isSetOrBulk,
    required this.discountAmount,
    required this.formulaDescription,
  });

  double get effectiveRatePerTicket => unitPrice;
}

class PricingCalculator {
  /// Calculate transaction price for a given quantity of tickets and shop pricing configuration.
  static PriceCalculationResult calculate({
    required int ticketCount,
    required PricingConfig config,
  }) {
    if (ticketCount <= 0) {
      return const PriceCalculationResult(
        ticketCount: 0,
        totalAmount: 0.0,
        unitPrice: 0.0,
        isSetOrBulk: false,
        discountAmount: 0.0,
        formulaDescription: 'Invalid count',
      );
    }

    final fullMortalCost = ticketCount * config.singleTicketPrice;
    final isSetOrBulk = ticketCount >= 12;

    double totalAmount;
    String description;

    if (ticketCount <= 12) {
      // Direct tiered pricing
      totalAmount = config.getTierPrice(ticketCount);
      if (ticketCount == 12) {
        description = '1 Full Set (12 tickets) @ ₹${config.setPrice12.toStringAsFixed(0)}';
      } else {
        description = '$ticketCount Ticket${ticketCount > 1 ? 's' : ''} @ ₹${config.singleTicketPrice.toStringAsFixed(0)}';
      }
    } else {
      // Exceeding 12 tickets (> 12)
      if (config.bulkFormula == BulkPricingFormula.proRata) {
        // Option A: Automatic calculation based on shop's established set average rate
        final avgRatePerTicket = config.setPrice12 / 12.0;
        totalAmount = ticketCount * avgRatePerTicket;
        description = '$ticketCount Bulk Tickets @ Avg Set Rate ₹${avgRatePerTicket.toStringAsFixed(2)}/ticket';
      } else {
        // Option B: Bundled sets + remainder tier
        final sets = ticketCount ~/ 12;
        final remainder = ticketCount % 12;
        final setsCost = sets * config.setPrice12;
        final remainderCost = config.getTierPrice(remainder);
        totalAmount = setsCost + remainderCost;
        description = '$sets Set${sets > 1 ? 's' : ''} (₹${setsCost.toStringAsFixed(0)}) + $remainder Retail (₹${remainderCost.toStringAsFixed(0)})';
      }
    }

    // Round total amount to 2 decimal places
    totalAmount = double.parse(totalAmount.toStringAsFixed(2));
    final unitPrice = totalAmount / ticketCount;
    final discount = fullMortalCost - totalAmount;

    return PriceCalculationResult(
      ticketCount: ticketCount,
      totalAmount: totalAmount,
      unitPrice: unitPrice,
      isSetOrBulk: isSetOrBulk,
      discountAmount: discount > 0 ? discount : 0.0,
      formulaDescription: description,
    );
  }
}
