import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/app_update_service.dart';
import '../../services/pricing_calculator.dart';
import '../../widgets/app_update_dialog.dart';
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
  int? _stagedTickets; // Currently selected customer order
  bool _showAuditAnalysis = false; // Collapsible to keep UI ultra-minimal

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdates();
    });
  }

  void _checkForAppUpdates() async {
    try {
      final updateService = AppUpdateService();
      final updateInfo = await updateService.checkForUpdate();
      if (updateInfo.hasUpdate && mounted) {
        AppUpdateDialog.show(context, updateInfo, updateService: updateService);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final currentShop = salesProvider.currentShop;
    final summary = salesProvider.todaySummary;

    if (salesProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    if (currentShop == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F766E),
          title: const Text(
            'Sales Terminal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => context.read<AuthProvider>().signOut(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 56, color: Color(0xFF0F766E)),
                const SizedBox(height: 16),
                const Text(
                  'No Retail Shops Registered',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in with your mobile number to complete shop setup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Back to Login'),
                  onPressed: () => context.read<AuthProvider>().signOut(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pricing = currentShop.pricingConfig;
    final calc = _stagedTickets != null && _stagedTickets! > 0
        ? PricingCalculator.calculate(
            ticketCount: _stagedTickets!,
            config: pricing,
          )
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentShop.name,
                    style: const TextStyle(
                      fontSize: 15,
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
            tooltip: 'Admin Head App',
            icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
            onPressed: () => _handleSwitchToAdmin(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP CUMULATIVE & METRICS STRIP (Box 1, Box 2, Box 3)
              ThreeOutputBoxesWidget(summary: summary),

              const SizedBox(height: 12),

              // 2. CURRENT CUSTOMER SALE STAGING BOX
              _buildCurrentCustomerOrderBox(context, salesProvider, pricing, calc),

              const SizedBox(height: 14),

              // 3. ONE-TAP SELECTION GRID HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ONE-TAP SALES ENTRY',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Grid size toggle (30, 36, 40)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          children: [30, 36, 40].map((size) {
                            final isSelected = _maxButtons == size;
                            return InkWell(
                              onTap: () => setState(() => _maxButtons = size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
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
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 4. ONE-TAP KEYPAD GRID (1 to 30/36/40)
              _buildOneTapGrid(context, salesProvider, pricing),

              const SizedBox(height: 14),

              // 5. AUDIT BENCHMARK MONITOR (Collapsible)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          setState(() => _showAuditAnalysis = !_showAuditAnalysis),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.insights_outlined,
                                  size: 16,
                                  color: Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AUDIT BENCHMARK MONITOR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: summary.averagePricePerTicket >= 48.0
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    summary.totalTicketsSold > 0
                                        ? 'Avg: ₹${summary.averagePricePerTicket.toStringAsFixed(2)}'
                                        : 'Awaiting sales',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: summary.averagePricePerTicket >= 48.0
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showAuditAnalysis
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF64748B),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showAuditAnalysis)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: AuditComparisonCard(
                          summary: summary,
                          pricingConfig: pricing,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. LIVE RECENT TRANSACTIONS LOG
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: RecentTransactionsList(
                  transactions: summary.transactions,
                  onUndo: () => _handleUndo(salesProvider),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCustomerOrderBox(
    BuildContext context,
    SalesProvider provider,
    pricing,
    PriceCalculationResult? calc,
  ) {
    final isStaged = _stagedTickets != null && _stagedTickets! > 0 && calc != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStaged ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStaged ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
          width: isStaged ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isStaged ? const Color(0xFF16A34A) : Colors.black)
                .withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
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
                      color: isStaged
                          ? const Color(0xFF166534)
                          : const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isStaged ? 'CURRENT CUSTOMER' : 'NEW CUSTOMER',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isStaged
                        ? 'Customer Order Preview'
                        : 'Select ticket quantity below',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isStaged
                          ? const Color(0xFF166534)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (isStaged)
                InkWell(
                  onTap: () => setState(() => _stagedTickets = null),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (isStaged) ...[
            // Main Amount & Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Ticket count & Stepper
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 24,
                      color: const Color(0xFF166534),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (_stagedTickets! > 1) {
                          setState(() => _stagedTickets = _stagedTickets! - 1);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        '$_stagedTickets Tkts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 24,
                      color: const Color(0xFF166534),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() => _stagedTickets = _stagedTickets! + 1);
                      },
                    ),
                  ],
                ),

                // Right: Total Bill Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${calc.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '₹${calc.effectiveRatePerTicket.toStringAsFixed(2)} / tkt',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CONFIRM & ENTER SALE BUTTON
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  'ENTER SALE • ₹${calc.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                onPressed: () => _confirmStagedSale(provider, calc),
              ),
            ),
          ] else ...[
            // Empty State
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap any number (1–$_maxButtons) to stage customer sale',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        // Dynamic grid with 4 columns
        const crossAxisCount = 4;
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_maxButtons, (index) {
            final ticketCount = index + 1;
            final isFullSet = ticketCount == 12;
            final isMultiSet = ticketCount > 12 && ticketCount % 12 == 0;
            final isSelected = _stagedTickets == ticketCount;

            final calc = PricingCalculator.calculate(
              ticketCount: ticketCount,
              config: pricing,
            );

            // Styling
            Color bgColor;
            Color borderColor;
            Color textColor;
            String? setBadgeText;

            if (isSelected) {
              bgColor = const Color(0xFFDCFCE7);
              borderColor = const Color(0xFF15803D);
              textColor = const Color(0xFF14532D);
            } else if (isFullSet) {
              bgColor = const Color(0xFF0F766E);
              borderColor = const Color(0xFF042F2E);
              textColor = Colors.white;
              setBadgeText = '1 SET';
            } else if (isMultiSet) {
              bgColor = const Color(0xFF115E59);
              borderColor = const Color(0xFF042F2E);
              textColor = Colors.white;
              setBadgeText = '${ticketCount ~/ 12} SETS';
            } else {
              bgColor = Colors.white;
              borderColor = const Color(0xFFE2E8F0);
              textColor = const Color(0xFF0F172A);
            }

            return SizedBox(
              width: itemWidth,
              height: 56,
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                elevation: isSelected ? 2 : (isFullSet || isMultiSet ? 1 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _stagedTickets = ticketCount;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 2.5 : (isFullSet || isMultiSet ? 1.5 : 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                                  fontSize: 7.5,
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '₹${calc.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isFullSet || isMultiSet
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF16A34A),
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

  void _confirmStagedSale(
    SalesProvider provider,
    PriceCalculationResult calc,
  ) async {
    if (_stagedTickets == null || _stagedTickets! <= 0) return;

    HapticFeedback.mediumImpact();
    final count = _stagedTickets!;
    final total = calc.totalAmount;

    final tx = await provider.recordSale(count);
    if (!mounted || tx == null) return;

    setState(() {
      _stagedTickets = null; // Reset for next customer
    });

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
                'Logged Customer Sale: +$count tickets (₹${total.toStringAsFixed(0)})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
                if (provider.shops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No retail shop terminals registered yet.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                  )
                else
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

  void _handleSwitchToAdmin(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser?.role == UserRole.admin) {
      widget.onSwitchToAdmin();
      return;
    }

    _showAdminAuthDialog(context);
  }

  void _showAdminAuthDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF1E293B), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Head App Security',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Master Admin credentials to unlock Central Head App access.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Admin Username',
                        isDense: true,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Admin Password',
                        isDense: true,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();

                          if (username.isEmpty || password.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Please enter both username and password.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          final authProvider = context.read<AuthProvider>();
                          final success = await authProvider
                              .loginWithAdminCredentials(username, password);

                          if (dialogContext.mounted) {
                            if (success) {
                              Navigator.pop(dialogContext);
                              widget.onSwitchToAdmin();
                            } else {
                              setDialogState(() {
                                isLoading = false;
                                errorMessage = authProvider.errorMessage ??
                                    'Invalid admin credentials.';
                              });
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('VERIFY & ENTER'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
