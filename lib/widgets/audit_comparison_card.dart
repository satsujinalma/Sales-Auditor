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

    // Audit status assessment in simple, plain English
    Color statusColor;
    String statusTitle;
    String statusInsight;
    IconData statusIcon;

    if (totalTickets == 0) {
      statusColor = const Color(0xFF64748B);
      statusTitle = 'Waiting for Sales';
      statusInsight =
          'No tickets entered yet today. Live audit check will appear here as sales happen.';
      statusIcon = Icons.hourglass_bottom;
    } else if (avgPrice >= targetMin) {
      statusColor = const Color(0xFF15803D); // Green
      statusTitle = 'Full Profit Rate (₹${avgPrice.toStringAsFixed(2)} / tkt)';
      statusInsight =
          'Good profit! Most tickets were sold as singles (₹50). Total collection matches target (₹$targetMin – ₹$targetMax).';
      statusIcon = Icons.check_circle_outline;
    } else if (avgPrice > claimedPrice + 0.3) {
      statusColor = const Color(0xFFD97706); // Amber
      statusTitle = 'Normal Set Sales (₹${avgPrice.toStringAsFixed(2)} / tkt)';
      statusInsight =
          'Customers bought mostly 12-ticket sets. Average collected is ₹${avgPrice.toStringAsFixed(2)} per ticket (better than shop claim of ₹$claimedPrice).';
      statusIcon = Icons.info_outline;
    } else {
      statusColor = const Color(0xFFEA580C); // Orange
      statusTitle = 'High Discount Sets (₹${avgPrice.toStringAsFixed(2)} / tkt)';
      statusInsight =
          'Almost all sales (${bulkPercent.toStringAsFixed(0)}%) were 12-ticket sets at discount. Average collected is ₹${avgPrice.toStringAsFixed(2)} per ticket.';
      statusIcon = Icons.warning_amber_rounded;
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
                      'SALES & PROFIT AUDIT',
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

          const SizedBox(height: 8),
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
                label: "Today's Average",
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
                label: 'Target Range',
                value: '₹$targetMin-$targetMax',
                color: const Color(0xFF15803D),
                isHighlight: false,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sales Composition Progress Bar (Sets vs Singles)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sets of 12: $bulkTickets tkts (${bulkPercent.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
              Text(
                'Singles: $singleTickets tkts (${singlePercent.toStringAsFixed(0)}%)',
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
