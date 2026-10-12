import 'sale_transaction.dart';

class DailySalesSummary {
  final String shopId;
  final DateTime date;
  final List<SaleTransaction> transactions;

  const DailySalesSummary({
    required this.shopId,
    required this.date,
    this.transactions = const [],
  });

  /// Active (non-cancelled) transactions
  List<SaleTransaction> get activeTransactions =>
      transactions.where((t) => !t.isCancelled).toList();

  /// Box 1: Latest sale transaction (most recent)
  SaleTransaction? get lastSale =>
      activeTransactions.isNotEmpty ? activeTransactions.last : null;

  /// Box 2: Cumulative total of tickets sold today
  int get totalTicketsSold =>
      activeTransactions.fold(0, (sum, t) => sum + t.ticketCount);

  /// Box 3 (Part 1): Cumulative total revenue collected today
  double get totalRevenue =>
      activeTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);

  /// Box 3 (Part 2): Live calculated overall average price per ticket (Total Revenue ÷ Total Tickets)
  double get averagePricePerTicket {
    if (totalTicketsSold == 0) return 0.0;
    return totalRevenue / totalTicketsSold;
  }

  /// Breakdown: Total bulk/set tickets sold (transactions with >= 12 tickets)
  int get bulkTicketsSold => activeTransactions
      .where((t) => t.isSetOrBulk)
      .fold(0, (sum, t) => sum + t.ticketCount);

  /// Breakdown: Total single/retail tickets sold (transactions with < 12 tickets)
  int get singleTicketsSold => activeTransactions
      .where((t) => !t.isSetOrBulk)
      .fold(0, (sum, t) => sum + t.ticketCount);

  /// Percentage of tickets sold in bulk/sets
  double get bulkTicketsPercentage {
    if (totalTicketsSold == 0) return 0.0;
    return (bulkTicketsSold / totalTicketsSold) * 100.0;
  }

  /// Percentage of tickets sold as singles
  double get singleTicketsPercentage {
    if (totalTicketsSold == 0) return 0.0;
    return (singleTicketsSold / totalTicketsSold) * 100.0;
  }

  int get totalTransactionsCount => activeTransactions.length;

  /// Map of ticket count -> number of times that volume was purchased (quantities/orders count)
  Map<int, int> get volumeDistribution {
    final dist = <int, int>{};
    for (final t in activeTransactions) {
      dist[t.ticketCount] = (dist[t.ticketCount] ?? 0) + 1;
    }
    return dist;
  }

  /// Get quantities/times sold for a specific ticket bundle count
  int volumeCount(int ticketCount) {
    return activeTransactions.where((t) => t.ticketCount == ticketCount).length;
  }

  /// Total count of single ticket orders (< 12 tickets and != 6)
  int get singleOrdersCount =>
      activeTransactions.where((t) => t.ticketCount < 12 && t.ticketCount != 6).length;

  /// Total count of set / bulk orders (>= 12 tickets or == 6)
  int get setOrdersCount =>
      activeTransactions.where((t) => t.ticketCount >= 12 || t.ticketCount == 6).length;

  DailySalesSummary copyWith({
    String? shopId,
    DateTime? date,
    List<SaleTransaction>? transactions,
  }) {
    return DailySalesSummary(
      shopId: shopId ?? this.shopId,
      date: date ?? this.date,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'date': date.toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory DailySalesSummary.fromJson(Map<String, dynamic> json) {
    final txList = <SaleTransaction>[];
    if (json['transactions'] != null) {
      final list = json['transactions'] as List<dynamic>;
      for (final item in list) {
        txList.add(SaleTransaction.fromJson(item as Map<String, dynamic>));
      }
    }

    return DailySalesSummary(
      shopId: json['shopId'] as String,
      date: DateTime.parse(json['date'] as String),
      transactions: txList,
    );
  }
}
