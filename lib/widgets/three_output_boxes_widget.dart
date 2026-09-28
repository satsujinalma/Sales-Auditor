import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_sales_summary.dart';

class ThreeOutputBoxesWidget extends StatelessWidget {
  final DailySalesSummary summary;
  final bool isReadOnlyMirror;

  const ThreeOutputBoxesWidget({
    super.key,
    required this.summary,
    this.isReadOnlyMirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final avgFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final timeFormat = DateFormat('hh:mm:ss a');

    final lastSale = summary.lastSale;
    final totalTickets = summary.totalTicketsSold;
    final totalRev = summary.totalRevenue;
    final avgPrice = summary.averagePricePerTicket;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isReadOnlyMirror)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 6),
                Text(
                  'LIVE AUDIT MIRROR (VIEW ONLY)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),

        // Row 1: Box 1 (Timestamp) & Box 2 (Total Tickets)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOX 1: EXACT TIMESTAMP OF THE SALE
            Expanded(
              child: _buildBox(
                context: context,
                boxNumber: 'BOX 1',
                title: 'LATEST SALE TIME',
                icon: Icons.access_time_filled,
                primaryColor: Colors.blue.shade700,
                backgroundColor: const Color(0xFFEBF3FC),
                content: lastSale != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeFormat.format(lastSale.timestamp),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${lastSale.ticketCount} tickets (₹${lastSale.totalAmount.toStringAsFixed(0)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'No sales yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // BOX 2: CUMULATIVE TOTAL TICKETS SOLD TODAY
            Expanded(
              child: _buildBox(
                context: context,
                boxNumber: 'BOX 2',
                title: 'TOTAL TICKETS SOLD',
                icon: Icons.confirmation_number,
                primaryColor: const Color(0xFF0F766E),
                backgroundColor: const Color(0xFFE6F7F5),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$totalTickets',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'tickets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sets: ${(totalTickets / 12).toStringAsFixed(1)} (12s)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade900.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // BOX 3: CUMULATIVE TOTAL REVENUE & LIVE AVERAGE TICKET PRICE
        _buildBox(
          context: context,
          boxNumber: 'BOX 3',
          title: 'CUMULATIVE REVENUE & LIVE AVERAGE PRICE',
          icon: Icons.currency_rupee,
          primaryColor: const Color(0xFF15803D),
          backgroundColor: const Color(0xFFDCFCE7),
          content: Row(
            children: [
              // Total Revenue
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL REVENUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(totalRev),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                width: 1.5,
                color: Colors.green.shade300,
              ),
              const SizedBox(width: 12),
              // Live Average Price per ticket
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE AVERAGE PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          totalTickets > 0
                              ? avgFormat.format(avgPrice)
                              : '₹0.00',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: avgPrice >= 48.0
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ ticket',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBox({
    required BuildContext context,
    required String boxNumber,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        boxNumber,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: primaryColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
