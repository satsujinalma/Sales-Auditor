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
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                child: Icon(statusIcon, size: 16, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUDIT ANALYSIS & BENCHMARK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            statusInsight,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // Price Comparison Meter
          Row(
            children: [
              _buildPriceBadge(
                label: 'Shop Claim',
                value: '₹${claimedPrice.toStringAsFixed(2)}',
                color: const Color(0xFFD97706),
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
                    : const Color(0xFF2563EB),
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

          const SizedBox(height: 12),

          // Sales Composition Progress Bar (Bulk vs Single)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulk (Sets ≥ 12): $bulkTickets (${bulkPercent.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
              Text(
                'Retail (<12): $singleTickets (${singlePercent.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4338CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (bulkPercent * 10).toInt().clamp(0, 1000),
                    child: Container(color: const Color(0xFF0F766E)),
                  ),
                  Expanded(
                    flex: (singlePercent * 10).toInt().clamp(0, 1000),
                    child: Container(color: const Color(0xFF818CF8)),
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
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlight
                ? color.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isHighlight ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
