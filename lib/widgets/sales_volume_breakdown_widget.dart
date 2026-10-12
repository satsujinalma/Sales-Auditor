import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_sales_summary.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass/liquid_glass_container.dart';

/// Box Pattern widget showing customer purchase volume breakdown in side-by-side
/// columns (Singles on Left, Sets & Bundles on Right), with an instant Active Sales
/// filter for rapid admin analysis.
class SalesVolumeBreakdownWidget extends StatefulWidget {
  final DailySalesSummary summary;
  final ValueChanged<int>? onSelectTicketCount;

  const SalesVolumeBreakdownWidget({
    super.key,
    required this.summary,
    this.onSelectTicketCount,
  });

  @override
  State<SalesVolumeBreakdownWidget> createState() =>
      _SalesVolumeBreakdownWidgetState();
}

class _SalesVolumeBreakdownWidgetState
    extends State<SalesVolumeBreakdownWidget> {
  int _viewMode = 0; // 0: Dual Columns (Box Pattern), 1: Active Purchases Only

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
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

    // Active buckets (counts with quantity > 0, sorted by quantity descending)
    final activeBuckets = dist.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SECTION HEADER (Guaranteed NO horizontal overflow on any device)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.view_column_rounded,
                  size: 15,
                  color: LiquidGlassColors.accentTeal,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SALES VOLUME BREAKDOWN',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: LiquidGlassColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: LiquidGlassColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // 2. VISUAL DISTRIBUTION COMPARISON BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: LiquidGlassColors.accentEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Singles: ${(singlesRatio * 100).toStringAsFixed(0)}% ($singlesOrders qty)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: LiquidGlassColors.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: LiquidGlassColors.accentViolet,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Sets: ${(setsRatio * 100).toStringAsFixed(0)}% ($setsOrders qty)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: LiquidGlassColors.accentViolet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. VIEW MODE SWITCHER TABS (Box Pattern vs Active Purchases)
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: LiquidGlassColors.glassFillMedium,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LiquidGlassColors.glassBorderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _viewMode = 0),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _viewMode == 0
                            ? LiquidGlassColors.accentViolet.withValues(alpha: 0.85)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 11,
                            color: _viewMode == 0
                                ? Colors.white
                                : LiquidGlassColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Box Pattern (Columns)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _viewMode == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _viewMode == 0
                                  ? Colors.white
                                  : LiquidGlassColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _viewMode = 1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _viewMode == 1
                            ? LiquidGlassColors.accentEmerald.withValues(alpha: 0.85)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: _viewMode == 1
                                ? Colors.white
                                : LiquidGlassColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active Only (${activeBuckets.length})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _viewMode == 1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _viewMode == 1
                                  ? Colors.white
                                  : LiquidGlassColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. CONTENT AREA: Dual Columns OR Active Purchases View
          if (_viewMode == 0) ...[
            // DUAL COLUMNS (BOX PATTERN)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: SINGLES
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildColumnHeader(
                        title: 'SINGLES (LEFT)',
                        badge: '$singlesTickets tix',
                        color: LiquidGlassColors.accentEmerald,
                      ),
                      const SizedBox(height: 6),
                      ...standardSingles.map((count) {
                        final qty = dist[count] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
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
                        ...extraSingles.map((count) {
                          final qty = dist[count] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
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

                const SizedBox(width: 8),

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
                      const SizedBox(height: 6),
                      ...standardSets.map((count) {
                        final qty = dist[count] ?? 0;
                        String? sub;
                        if (count == 6) sub = 'Half Set';
                        if (count == 12) sub = '1 Full Set';
                        if (count == 24) sub = '2 Full Sets';
                        if (count == 36) sub = '3 Full Sets';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
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
                        ...extraSets.map((count) {
                          final qty = dist[count] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
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
          ] else ...[
            // ACTIVE PURCHASES ONLY VIEW (Direct executive analysis)
            _buildActivePurchasesView(summary, activeBuckets),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 8.5,
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
        onTap: widget.onSelectTicketCount != null
            ? () => widget.onSelectTicketCount!(count)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.14)
                : LiquidGlassColors.glassFillLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.55)
                  : LiquidGlassColors.glassBorderSubtle,
              width: isActive ? 1.1 : 0.7,
            ),
            boxShadow: isActive
                ? LiquidGlassTheme.neonGlow(
                    color: activeColor,
                    intensity: 0.10,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Ticket Count Pill
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.25)
                      : LiquidGlassColors.glassFillMedium,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isActive ? activeColor : LiquidGlassColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Title & Subtitle (never truncated!)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? activeColor
                              : LiquidGlassColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 3),

              // Quantity Badge / Figure
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'qty',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: activeColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Text(
                    '0',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: LiquidGlassColors.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact, executive breakdown of actively purchased ticket quantities
  Widget _buildActivePurchasesView(
    DailySalesSummary summary,
    List<MapEntry<int, int>> activeBuckets,
  ) {
    if (activeBuckets.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: LiquidGlassColors.glassFillMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No tickets recorded yet today.',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: LiquidGlassColors.textSecondary,
          ),
        ),
      );
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: activeBuckets.map((entry) {
        final count = entry.key;
        final qty = entry.value;
        final isSet = count >= 12 || count == 6;
        final activeColor =
            isSet ? LiquidGlassColors.accentViolet : LiquidGlassColors.accentEmerald;
        final totalTix = count * qty;

        final txs = summary.activeTransactions
            .where((t) => t.ticketCount == count)
            .toList();
        final totalRevenue = txs.fold(0.0, (sum, t) => sum + t.totalAmount);
        final avgRate =
            totalTix > 0 ? (totalRevenue / totalTix) : 0.0;

        String packageDesc;
        if (count == 6) {
          packageDesc = 'Half Set (6 Tickets)';
        } else if (count == 12) {
          packageDesc = 'Full Set (12 Tickets)';
        } else if (count == 24) {
          packageDesc = 'Double Set (24 Tickets)';
        } else if (count == 36) {
          packageDesc = 'Triple Set (36 Tickets)';
        } else if (count < 12) {
          packageDesc = count == 1 ? 'Single Ticket' : '$count Loose Tickets';
        } else {
          packageDesc = 'Bulk Set ($count Tickets)';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: widget.onSelectTicketCount != null
                ? () => widget.onSelectTicketCount!(count)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Prominent Ticket Count Pill
                  Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),

                  // Description & Orders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageDesc,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: LiquidGlassColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          '$qty orders ($totalTix tickets total)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Revenue & Rate
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(totalRevenue),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: LiquidGlassColors.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${avgRate.toStringAsFixed(2)}/tix',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
