import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_transaction.dart';

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
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No sales recorded today yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.black54,
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
                        Icon(Icons.undo, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Undo Last',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeTransactions.length > 8 ? 8 : activeTransactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.8),
          itemBuilder: (context, index) {
            final tx = activeTransactions[index];
            final isSet = tx.ticketCount == 12;
            final isMultiSet = tx.ticketCount > 12 && tx.ticketCount % 12 == 0;
            final isBulk = tx.ticketCount > 12 && tx.ticketCount % 12 != 0;

            Color badgeColor;
            String typeBadge;
            if (isSet) {
              badgeColor = const Color(0xFF0F766E);
              typeBadge = '1 SET (12)';
            } else if (isMultiSet) {
              badgeColor = const Color(0xFF0F766E);
              typeBadge = '${tx.ticketCount ~/ 12} SETS';
            } else if (isBulk) {
              badgeColor = Colors.teal.shade800;
              typeBadge = 'BULK (${tx.ticketCount})';
            } else {
              badgeColor = Colors.blueGrey;
              typeBadge = '${tx.ticketCount} TICKET${tx.ticketCount > 1 ? 'S' : ''}';
            }

            if (tx.isCancelled) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                title: Text(
                  'CANCELLED: +${tx.ticketCount} tickets (₹${tx.totalAmount.toStringAsFixed(0)})',
                  style: const TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.black45,
                  ),
                ),
                trailing: Text(
                  timeFormat.format(tx.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      typeBadge,
                      style: TextStyle(
                        fontSize: 10,
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(@ ₹${tx.unitPrice.toStringAsFixed(2)}/tkt)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeFormat.format(tx.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
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
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
