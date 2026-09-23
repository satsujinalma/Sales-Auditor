class SaleTransaction {
  final String id;
  final String shopId;
  final DateTime timestamp;
  final int ticketCount;
  final double totalAmount;
  final double unitPrice;
  final bool isSetOrBulk;
  final bool isCancelled;

  const SaleTransaction({
    required this.id,
    required this.shopId,
    required this.timestamp,
    required this.ticketCount,
    required this.totalAmount,
    required this.unitPrice,
    required this.isSetOrBulk,
    this.isCancelled = false,
  });

  SaleTransaction copyWith({
    String? id,
    String? shopId,
    DateTime? timestamp,
    int? ticketCount,
    double? totalAmount,
    double? unitPrice,
    bool? isSetOrBulk,
    bool? isCancelled,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      timestamp: timestamp ?? this.timestamp,
      ticketCount: ticketCount ?? this.ticketCount,
      totalAmount: totalAmount ?? this.totalAmount,
      unitPrice: unitPrice ?? this.unitPrice,
      isSetOrBulk: isSetOrBulk ?? this.isSetOrBulk,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'timestamp': timestamp.toIso8601String(),
      'ticketCount': ticketCount,
      'totalAmount': totalAmount,
      'unitPrice': unitPrice,
      'isSetOrBulk': isSetOrBulk,
      'isCancelled': isCancelled,
    };
  }

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    return SaleTransaction(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ticketCount: (json['ticketCount'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      isSetOrBulk: json['isSetOrBulk'] as bool? ?? false,
      isCancelled: json['isCancelled'] as bool? ?? false,
    );
  }
}
