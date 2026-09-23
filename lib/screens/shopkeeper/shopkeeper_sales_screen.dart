import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/pricing_calculator.dart';
import '../../widgets/audit_comparison_card.dart';
import '../../widgets/recent_transactions_list.dart';
import '../../widgets/three_output_boxes_widget.dart';

class ShopkeeperSalesScreen extends StatefulWidget {
  final VoidCallback onSwitchToAdmin;

  const ShopkeeperSalesScreen({
    super.key,
    required this.onSwitchToAdmin,
  });

  @override
  State<ShopkeeperSalesScreen> createState() => _ShopkeeperSalesScreenState();
}

class _ShopkeeperSalesScreenState extends State<ShopkeeperSalesScreen> {
  int _maxButtons = 36; // Default grid 1 to 36 or 40
  bool _showAuditAnalysis = true;

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final currentShop = salesProvider.currentShop;
    final summary = salesProvider.todaySummary;

    if (salesProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentShop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Terminal')),
        body: const Center(child: Text('No shop selected')),
      );
    }

    final pricing = currentShop.pricingConfig;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentShop.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${currentShop.code} • 1 Set (12) = ₹${pricing.setPrice12.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Shop Terminal',
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () => _showShopPicker(context, salesProvider),
          ),
          IconButton(
            tooltip: 'Admin / Head App',
            icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
            onPressed: widget.onSwitchToAdmin,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // THE 3 SPECIFIC OUTPUT BOXES (Box 1, Box 2, Box 3)
              ThreeOutputBoxesWidget(summary: summary),

              const SizedBox(height: 12),

              // ONE-TAP QUICK SALES ENTRY SECTION HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ONE-TAP SALES ENTRY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Grid size toggle (30, 36, 40)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [30, 36, 40].map((size) {
                            final isSelected = _maxButtons == size;
                            return InkWell(
                              onTap: () => setState(() => _maxButtons = size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '$size',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Undo
                      if (summary.activeTransactions.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          icon: const Icon(Icons.undo, size: 14),
                          label: const Text(
                            'Undo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _handleUndo(salesProvider),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // THE ONE-TAP BUTTONS GRID (1 to 30/36/40)
              _buildOneTapGrid(context, salesProvider, pricing),

              const SizedBox(height: 14),

              // AUDIT COMPARISON CARD (Claim vs Actual vs Target)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AUDIT BENCHMARK MONITOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.black54,
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        setState(() => _showAuditAnalysis = !_showAuditAnalysis),
                    child: Text(
                      _showAuditAnalysis ? 'Hide' : 'Show',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (_showAuditAnalysis) ...[
                const SizedBox(height: 6),
                AuditComparisonCard(
                  summary: summary,
                  pricingConfig: pricing,
                ),
              ],

              const SizedBox(height: 14),

              // LIVE RECENT TRANSACTIONS LOG
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: RecentTransactionsList(
                  transactions: summary.transactions,
                  onUndo: () => _handleUndo(salesProvider),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneTapGrid(
    BuildContext context,
    SalesProvider provider,
    pricing,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic button size for phone screen (4 columns)
        const crossAxisCount = 4;
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_maxButtons, (index) {
            final ticketCount = index + 1;
            final isFullSet = ticketCount == 12;
            final isMultiSet = ticketCount > 12 && ticketCount % 12 == 0;
            final isSingle = ticketCount < 12;

            final calc = PricingCalculator.calculate(
              ticketCount: ticketCount,
              config: pricing,
            );

            // Styling based on ticket type (Set vs Single vs Bulk)
            Color bgColor;
            Color borderColor;
            Color textColor;
            String? setBadgeText;

            if (isFullSet) {
              bgColor = const Color(0xFF0F766E);
              borderColor = const Color(0xFF042F2E);
              textColor = Colors.white;
              setBadgeText = '1 SET';
            } else if (isMultiSet) {
              bgColor = const Color(0xFF115E59);
              borderColor = const Color(0xFF042F2E);
              textColor = Colors.white;
              setBadgeText = '${ticketCount ~/ 12} SETS';
            } else if (!isSingle) {
              bgColor = const Color(0xFFF0FDF4);
              borderColor = const Color(0xFF86EFAC);
              textColor = const Color(0xFF14532D);
            } else {
              bgColor = Colors.white;
              borderColor = Colors.grey.shade300;
              textColor = Colors.black87;
            }

            return SizedBox(
              width: itemWidth,
              height: 60,
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                elevation: isFullSet || isMultiSet ? 2 : 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleTap(provider, ticketCount, calc),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: isFullSet || isMultiSet ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Stack(
                      children: [
                        if (setBadgeText != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade400,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                setBadgeText,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$ticketCount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${calc.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isFullSet || isMultiSet
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF15803D),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _handleTap(
    SalesProvider provider,
    int ticketCount,
    PriceCalculationResult calc,
  ) async {
    HapticFeedback.lightImpact();

    final tx = await provider.recordSale(ticketCount);
    if (!mounted || tx == null) return;

    // Quick visual snackbar confirmation
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Logged: +$ticketCount tickets = ₹${calc.totalAmount.toStringAsFixed(0)} (${calc.formulaDescription})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () => provider.undoLastSale(),
        ),
      ),
    );
  }

  void _handleUndo(SalesProvider provider) async {
    HapticFeedback.mediumImpact();
    final success = await provider.undoLastSale();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Last transaction cancelled and removed from totals.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showShopPicker(BuildContext context, SalesProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Retail Shop Terminal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Switching terminal will track sales under that shop profile',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Divider(height: 20),
                ...provider.shops.map((shop) {
                  final isCurrent = provider.currentShop?.id == shop.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? const Color(0xFF0F766E)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.storefront,
                        color: isCurrent ? Colors.white : Colors.black54,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      shop.name,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0F766E) : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${shop.code} • 1 Set (12) = ₹${shop.pricingConfig.setPrice12.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: Color(0xFF0F766E))
                        : null,
                    onTap: () {
                      provider.selectShop(shop.id);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
