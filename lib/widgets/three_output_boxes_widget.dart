import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_sales_summary.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass/liquid_glass_container.dart';

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
        // TOP METRICS ROW: Box 1 & Box 2
        Row(
          children: [
            // BOX 1: LATEST SALE
            Expanded(
              child: _buildGlassBox(
                badgeText: 'BOX 1',
                title: 'LATEST SALE',
                icon: Icons.history_rounded,
                badgeColor: const Color(0xFF3B82F6),
                child: lastSale != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeFormat.format(lastSale.timestamp),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: LiquidGlassColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '+${lastSale.ticketCount} tickets (₹${lastSale.totalAmount.toStringAsFixed(0)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'No sales yet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: LiquidGlassColors.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // BOX 2: TOTAL TICKETS
            Expanded(
              child: _buildGlassBox(
                badgeText: 'BOX 2',
                title: 'TOTAL TICKETS',
                icon: Icons.confirmation_number_outlined,
                badgeColor: LiquidGlassColors.accentEmerald,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$totalTickets',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: LiquidGlassColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'tickets',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LiquidGlassColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sets: ${(totalTickets / 12).toStringAsFixed(1)} (12s)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: LiquidGlassColors.accentEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // BOX 3: CUMULATIVE REVENUE & LIVE AVERAGE PRICE
        LiquidGlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LiquidGlassColors.accentTeal.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: LiquidGlassColors.accentTeal.withValues(alpha: 0.40),
                          ),
                        ),
                        child: const Text(
                          'BOX 3',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF22D3EE),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CUMULATIVE REVENUE & LIVE AVERAGE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: LiquidGlassColors.accentTeal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
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
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: LiquidGlassColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(totalRev),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: LiquidGlassColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: LiquidGlassColors.glassBorderSubtle,
                  ),
                  const SizedBox(width: 14),
                  // Live Average Price per ticket
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE AVERAGE PRICE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: LiquidGlassColors.textMuted,
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
                                    ? const Color(0xFF34D399)
                                    : (avgPrice > 0
                                        ? const Color(0xFFFBBF24)
                                        : LiquidGlassColors.textMuted),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '/ tkt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: LiquidGlassColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassBox({
    required String badgeText,
    required String title,
    required IconData icon,
    required Color badgeColor,
    required Widget child,
  }) {
    return LiquidGlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: LiquidGlassColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(icon, size: 14, color: badgeColor),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
