import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_transaction.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass/liquid_glass_container.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<SaleTransaction> transactions;
  final bool isReadOnly;
  final VoidCallback? onUndo;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.isReadOnly = false,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm:ss a');
    final activeTransactions = transactions.reversed.toList();

    if (activeTransactions.isEmpty) {
      return LiquidGlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: LiquidGlassColors.textMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              const Text(
                'No sales recorded today yet',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: LiquidGlassColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE TRANSACTION LOG (${activeTransactions.length})',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: LiquidGlassColors.textSecondary,
                ),
              ),
              if (!isReadOnly && onUndo != null && activeTransactions.any((t) => !t.isCancelled))
                InkWell(
                  onTap: onUndo,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.undo, size: 14, color: LiquidGlassColors.accentRose),
                        const SizedBox(width: 4),
                        const Text(
                          'Undo Last',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: LiquidGlassColors.accentRose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        LiquidGlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeTransactions.length > 8 ? 8 : activeTransactions.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.8,
              color: LiquidGlassColors.glassBorderLight,
            ),
            itemBuilder: (context, index) {
              final tx = activeTransactions[index];
              final isSet = tx.ticketCount == 12;
              final isMultiSet = tx.ticketCount > 12 && tx.ticketCount % 12 == 0;
              final isBulk = tx.ticketCount > 12 && tx.ticketCount % 12 != 0;

              Color badgeColor;
              String typeBadge;
              if (isSet) {
                badgeColor = LiquidGlassColors.accentEmerald;
                typeBadge = '1 SET (12)';
              } else if (isMultiSet) {
                badgeColor = LiquidGlassColors.accentEmerald;
                typeBadge = '${tx.ticketCount ~/ 12} SETS';
              } else if (isBulk) {
                badgeColor = LiquidGlassColors.accentTeal;
                typeBadge = 'BULK (${tx.ticketCount})';
              } else {
                badgeColor = LiquidGlassColors.accentViolet;
                typeBadge = '${tx.ticketCount} TICKET${tx.ticketCount > 1 ? 'S' : ''}';
              }

              if (tx.isCancelled) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.cancel_outlined, color: LiquidGlassColors.accentRose, size: 20),
                  title: Text(
                    'CANCELLED: +${tx.ticketCount} tickets (₹${tx.totalAmount.toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      decoration: TextDecoration.lineThrough,
                      color: LiquidGlassColors.textMuted,
                    ),
                  ),
                  trailing: Text(
                    timeFormat.format(tx.timestamp),
                    style: const TextStyle(fontSize: 11, color: LiquidGlassColors.textMuted),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        typeBadge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '+${tx.ticketCount} tickets',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(@ ₹${tx.unitPrice.toStringAsFixed(2)}/tkt)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: LiquidGlassColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            timeFormat.format(tx.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: LiquidGlassColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${tx.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: LiquidGlassColors.accentEmerald,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
