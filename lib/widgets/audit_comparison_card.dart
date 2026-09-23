import 'package:flutter/material.dart';
import '../models/daily_sales_summary.dart';
import '../models/pricing_config.dart';

class AuditComparisonCard extends StatelessWidget {
  final DailySalesSummary summary;
  final PricingConfig pricingConfig;

  const AuditComparisonCard({
    super.key,
    required this.summary,
    required this.pricingConfig,
  });

  @override
  Widget build(BuildContext context) {
    final totalTickets = summary.totalTicketsSold;
    final avgPrice = summary.averagePricePerTicket;
    final bulkPercent = summary.bulkTicketsPercentage;
    final singlePercent = summary.singleTicketsPercentage;
    final bulkTickets = summary.bulkTicketsSold;
    final singleTickets = summary.singleTicketsSold;

    final claimedPrice = pricingConfig.claimedAvgPrice; // ~47.20
    final targetMin = pricingConfig.targetBenchmarkMin; // 48.30
    final targetMax = pricingConfig.targetBenchmarkMax; // 48.50

    // Audit status assessment
    Color statusColor;
    String statusTitle;
    String statusInsight;
    IconData statusIcon;

    if (totalTickets == 0) {
      statusColor = Colors.grey;
      statusTitle = 'Awaiting Sales Data';
      statusInsight = 'Record transactions to generate audit assessment.';
      statusIcon = Icons.hourglass_empty;
    } else if (avgPrice >= targetMin) {
      statusColor = const Color(0xFF15803D); // Green
      statusTitle = 'Target Average Maintained (₹${avgPrice.toStringAsFixed(2)})';
      statusInsight =
          'Actual avg is within benchmark (₹$targetMin - ₹$targetMax). Bulk claims do not lower margins.';
      statusIcon = Icons.check_circle;
    } else if (avgPrice > claimedPrice + 0.3) {
      statusColor = Colors.amber.shade800; // Orange
      statusTitle = 'Moderate Margin (₹${avgPrice.toStringAsFixed(2)})';
      statusInsight =
          'Actual avg is higher than shopkeeper claimed ₹$claimedPrice. Bulk sales account for ${bulkPercent.toStringAsFixed(1)}% of volume.';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.red.shade700; // Red
      statusTitle = 'Low Average Detected (₹${avgPrice.toStringAsFixed(2)})';
      statusInsight =
          'Matches claimed ₹$claimedPrice. Verified: Bulk/Set sales represent ${bulkPercent.toStringAsFixed(1)}% of total volume.';
      statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUDIT ANALYSIS & BENCHMARK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            statusInsight,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),

          const Divider(height: 20, thickness: 1),

          // Price Comparison Meter
          Row(
            children: [
              _buildPriceBadge(
                label: 'Shop Claim',
                value: '₹${claimedPrice.toStringAsFixed(2)}',
                color: Colors.orange.shade800,
                isHighlight: false,
              ),
              const SizedBox(width: 8),
              _buildPriceBadge(
                label: 'Actual Live Avg',
                value: totalTickets > 0
                    ? '₹${avgPrice.toStringAsFixed(2)}'
                    : '₹0.00',
                color: avgPrice >= targetMin
                    ? const Color(0xFF15803D)
                    : Colors.blue.shade800,
                isHighlight: true,
              ),
              const SizedBox(width: 8),
              _buildPriceBadge(
                label: 'Expected Target',
                value: '₹$targetMin-$targetMax',
                color: const Color(0xFF15803D),
                isHighlight: false,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sales Composition Progress Bar (Bulk vs Single)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulk (Sets ≥ 12): $bulkTickets (${bulkPercent.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
              Text(
                'Retail (<12): $singleTickets (${singlePercent.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (bulkPercent * 10).toInt().clamp(0, 1000),
                    child: Container(color: const Color(0xFF0F766E)),
                  ),
                  Expanded(
                    flex: (singlePercent * 10).toInt().clamp(0, 1000),
                    child: Container(color: Colors.indigo.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge({
    required String label,
    required String value,
    required Color color,
    required bool isHighlight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isHighlight
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? color : Colors.grey.shade300,
            width: isHighlight ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
