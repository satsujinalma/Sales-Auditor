import 'package:flutter/material.dart';
import '../models/daily_sales_summary.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass/liquid_glass_container.dart';

/// Box Pattern widget showing customer purchase volume breakdown in side-by-side
/// columns (Singles on Left, Sets & Bundles on Right).
class SalesVolumeBreakdownWidget extends StatelessWidget {
  final DailySalesSummary summary;
  final ValueChanged<int>? onSelectTicketCount;

  const SalesVolumeBreakdownWidget({
    super.key,
    required this.summary,
    this.onSelectTicketCount,
  });

  @override
  Widget build(BuildContext context) {
    final dist = summary.volumeDistribution;

    // Single tickets: counts < 12 and != 6
    final singlesOrders = summary.singleOrdersCount;
    final singlesTickets = summary.activeTransactions
        .where((t) => t.ticketCount < 12 && t.ticketCount != 6)
        .fold(0, (sum, t) => sum + t.ticketCount);

    // Set / bulk tickets: counts >= 12 or == 6
    final setsOrders = summary.setOrdersCount;
    final setsTickets = summary.activeTransactions
        .where((t) => t.ticketCount >= 12 || t.ticketCount == 6)
        .fold(0, (sum, t) => sum + t.ticketCount);

    final totalOrders = singlesOrders + setsOrders;
    final singlesRatio = totalOrders > 0 ? (singlesOrders / totalOrders) : 0.5;
    final setsRatio = totalOrders > 0 ? (setsOrders / totalOrders) : 0.5;

    // Standard single buckets
    const standardSingles = [1, 2, 3, 4, 5];
    final extraSingles = dist.keys
        .where((k) => k < 12 && k != 6 && !standardSingles.contains(k))
        .toList()
      ..sort();

    // Standard set buckets
    const standardSets = [6, 12, 24, 36];
    final extraSets = dist.keys
        .where((k) => (k >= 12 || k == 6) && !standardSets.contains(k))
        .toList()
      ..sort();

    return LiquidGlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SECTION HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.view_column_rounded,
                    size: 18,
                    color: LiquidGlassColors.accentTeal,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SALES VOLUME BREAKDOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.glassFillMedium,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: LiquidGlassColors.glassBorderSubtle,
                  ),
                ),
                child: Text(
                  '$totalOrders ORDERS TODAY',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: LiquidGlassColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Live customer purchase pattern: Compare individual singles vs 6 & 12 sets.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: LiquidGlassColors.textSecondary,
            ),
          ),

          const SizedBox(height: 10),

          // 2. VISUAL DISTRIBUTION COMPARISON BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: (singlesRatio * 1000).toInt().clamp(1, 999),
                    child: Container(
                      color: LiquidGlassColors.accentEmerald,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (setsRatio * 1000).toInt().clamp(1, 999),
                    child: Container(
                      color: LiquidGlassColors.accentViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: LiquidGlassColors.accentEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Singles: ${(singlesRatio * 100).toStringAsFixed(0)}% ($singlesOrders qty)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LiquidGlassColors.accentEmerald,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: LiquidGlassColors.accentViolet,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Sets & Bundles: ${(setsRatio * 100).toStringAsFixed(0)}% ($setsOrders qty)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LiquidGlassColors.accentViolet,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. BOX PATTERN: LEFT COLUMN (Singles) & RIGHT COLUMN (Sets)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: SINGLE TICKETS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildColumnHeader(
                      title: 'SINGLES (LEFT)',
                      badge: '$singlesTickets tix',
                      color: LiquidGlassColors.accentEmerald,
                    ),
                    const SizedBox(height: 8),
                    ...standardSingles.map((count) {
                      final qty = dist[count] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildVolumeBox(
                          count: count,
                          label: count == 1 ? '1 Ticket' : '$count Tickets',
                          subLabel: null,
                          quantity: qty,
                          isSet: false,
                        ),
                      );
                    }),
                    if (extraSingles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ...extraSingles.map((count) {
                        final qty = dist[count] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildVolumeBox(
                            count: count,
                            label: '$count Tickets',
                            subLabel: 'Loose',
                            quantity: qty,
                            isSet: false,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // RIGHT COLUMN: SETS & BUNDLES (6, 12, 24...)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildColumnHeader(
                      title: 'SETS (RIGHT)',
                      badge: '$setsTickets tix',
                      color: LiquidGlassColors.accentViolet,
                    ),
                    const SizedBox(height: 8),
                    ...standardSets.map((count) {
                      final qty = dist[count] ?? 0;
                      String? sub;
                      if (count == 6) sub = 'Half Set';
                      if (count == 12) sub = '1 Full Set';
                      if (count == 24) sub = '2 Full Sets';
                      if (count == 36) sub = '3 Full Sets';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildVolumeBox(
                          count: count,
                          label: '$count Tickets',
                          subLabel: sub,
                          quantity: qty,
                          isSet: true,
                        ),
                      );
                    }),
                    if (extraSets.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ...extraSets.map((count) {
                        final qty = dist[count] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildVolumeBox(
                            count: count,
                            label: '$count Tickets',
                            subLabel: 'Bulk Pack',
                            quantity: qty,
                            isSet: true,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader({
    required String title,
    required String badge,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeBox({
    required int count,
    required String label,
    required String? subLabel,
    required int quantity,
    required bool isSet,
  }) {
    final activeColor =
        isSet ? LiquidGlassColors.accentViolet : LiquidGlassColors.accentEmerald;
    final isActive = quantity > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('volume_box_$count'),
        onTap: onSelectTicketCount != null
            ? () => onSelectTicketCount!(count)
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.13)
                : LiquidGlassColors.glassFillLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.50)
                  : LiquidGlassColors.glassBorderLight,
              width: isActive ? 1.3 : 0.8,
            ),
            boxShadow: isActive
                ? LiquidGlassTheme.neonGlow(
                    color: activeColor,
                    intensity: 0.12,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Ticket count tag and title
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor.withValues(alpha: 0.25)
                            : LiquidGlassColors.glassFillMedium,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isActive ? activeColor : LiquidGlassColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive
                                  ? LiquidGlassColors.textPrimary
                                  : LiquidGlassColors.textSecondary,
                            ),
                          ),
                          if (subLabel != null)
                            Text(
                              subLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? activeColor
                                    : LiquidGlassColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Right: Figures count (e.g. 5 quantities, 30 quantities)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isActive
                          ? (isSet
                              ? Colors.amberAccent
                              : LiquidGlassColors.accentEmerald)
                          : LiquidGlassColors.textMuted,
                    ),
                  ),
                  Text(
                    quantity == 1 ? 'qty' : 'quantities',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? LiquidGlassColors.textSecondary
                          : LiquidGlassColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
