enum BulkPricingFormula {
  proRata, // Qty * (setPrice / 12)
  setPlusRemainder, // (Sets * setPrice) + tier(remainder)
}

class PricingConfig {
  final double singleTicketPrice;
  final double setPrice12;
  final Map<int, double> customTierPrices;
  final BulkPricingFormula bulkFormula;
  final double targetBenchmarkMin;
  final double targetBenchmarkMax;
  final double claimedAvgPrice;

  const PricingConfig({
    this.singleTicketPrice = 50.0,
    this.setPrice12 = 570.0,
    this.customTierPrices = const {},
    this.bulkFormula = BulkPricingFormula.proRata,
    this.targetBenchmarkMin = 48.30,
    this.targetBenchmarkMax = 48.50,
    this.claimedAvgPrice = 47.20,
  });

  /// Get price for 1 to 12 tickets
  double getTierPrice(int count) {
    if (count <= 0) return 0.0;
    if (count > 12) count = 12;

    if (customTierPrices.containsKey(count)) {
      return customTierPrices[count]!;
    }

    if (count == 12) {
      return setPrice12;
    }

    // Default 1..11 is linear based on single ticket price
    return count * singleTicketPrice;
  }

  PricingConfig copyWith({
    double? singleTicketPrice,
    double? setPrice12,
    Map<int, double>? customTierPrices,
    BulkPricingFormula? bulkFormula,
    double? targetBenchmarkMin,
    double? targetBenchmarkMax,
    double? claimedAvgPrice,
  }) {
    return PricingConfig(
      singleTicketPrice: singleTicketPrice ?? this.singleTicketPrice,
      setPrice12: setPrice12 ?? this.setPrice12,
      customTierPrices: customTierPrices ?? this.customTierPrices,
      bulkFormula: bulkFormula ?? this.bulkFormula,
      targetBenchmarkMin: targetBenchmarkMin ?? this.targetBenchmarkMin,
      targetBenchmarkMax: targetBenchmarkMax ?? this.targetBenchmarkMax,
      claimedAvgPrice: claimedAvgPrice ?? this.claimedAvgPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'singleTicketPrice': singleTicketPrice,
      'setPrice12': setPrice12,
      'customTierPrices': customTierPrices.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'bulkFormula': bulkFormula.name,
      'targetBenchmarkMin': targetBenchmarkMin,
      'targetBenchmarkMax': targetBenchmarkMax,
      'claimedAvgPrice': claimedAvgPrice,
    };
  }

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    final customTiers = <int, double>{};
    if (json['customTierPrices'] != null) {
      final map = json['customTierPrices'] as Map<String, dynamic>;
      map.forEach((k, v) {
        final parsedKey = int.tryParse(k);
        if (parsedKey != null) {
          customTiers[parsedKey] = (v as num).toDouble();
        }
      });
    }

    return PricingConfig(
      singleTicketPrice: (json['singleTicketPrice'] as num?)?.toDouble() ?? 50.0,
      setPrice12: (json['setPrice12'] as num?)?.toDouble() ?? 570.0,
      customTierPrices: customTiers,
      bulkFormula: json['bulkFormula'] == 'setPlusRemainder'
          ? BulkPricingFormula.setPlusRemainder
          : BulkPricingFormula.proRata,
      targetBenchmarkMin:
          (json['targetBenchmarkMin'] as num?)?.toDouble() ?? 48.30,
      targetBenchmarkMax:
          (json['targetBenchmarkMax'] as num?)?.toDouble() ?? 48.50,
      claimedAvgPrice: (json['claimedAvgPrice'] as num?)?.toDouble() ?? 47.20,
    );
  }
}
