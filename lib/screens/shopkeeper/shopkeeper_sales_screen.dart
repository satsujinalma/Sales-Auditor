import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/pricing_calculator.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/audit_comparison_card.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';
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
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final currentShop = salesProvider.currentShop;
    final summary = salesProvider.todaySummary;

    if (salesProvider.isLoading) {
      return Scaffold(
        backgroundColor: LiquidGlassColors.background,
        body: LiquidGlowBackground(
          child: const Center(
            child: CircularProgressIndicator(color: LiquidGlassColors.accentEmerald),
          ),
        ),
      );
    }

    if (currentShop == null) {
      return Scaffold(
        backgroundColor: LiquidGlassColors.background,
        body: LiquidGlowBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LiquidGlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: LiquidGlassColors.accentEmerald,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Shop Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please sign in with your mobile number or shop details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: LiquidGlassColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    LiquidGlassButton(
                      label: 'Back to Login',
                      icon: Icons.logout,
                      onPressed: () => context.read<AuthProvider>().signOut(),
                    ),
                  ],
                ),
              ),
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
      backgroundColor: LiquidGlassColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storefront,
                  color: LiquidGlassColors.accentEmerald,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentShop.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: LiquidGlassColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${currentShop.code} • 1 Set (12) = ₹${pricing.setPrice12.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: LiquidGlassColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Shop Terminal',
            icon: const Icon(Icons.swap_horiz, color: LiquidGlassColors.textPrimary),
            onPressed: () => _showShopPicker(context, salesProvider),
          ),
          IconButton(
            tooltip: 'Admin Head App',
            icon: const Icon(
              Icons.admin_panel_settings_outlined,
              color: LiquidGlassColors.accentViolet,
            ),
            onPressed: () => _handleSwitchToAdmin(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: LiquidGlassColors.textMuted, size: 20),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: LiquidGlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          color: LiquidGlassColors.accentEmerald,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ONE-TAP SALES ENTRY',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: LiquidGlassColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Grid size toggle (30, 36, 40)
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: LiquidGlassColors.glassBorderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [30, 36, 40].map((size) {
                              final isSelected = _maxButtons == size;
                              return InkWell(
                                onTap: () => setState(() => _maxButtons = size),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? LiquidGlassColors.accentEmerald
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$size',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : LiquidGlassColors.textMuted,
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
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            setState(() => _showAuditAnalysis = !_showAuditAnalysis),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insights_outlined,
                                      size: 16,
                                      color: LiquidGlassColors.accentEmerald,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'AUDIT MONITOR',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: LiquidGlassColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: summary.averagePricePerTicket >= 48.0
                                            ? LiquidGlassColors.accentEmerald.withValues(alpha: 0.20)
                                            : LiquidGlassColors.accentAmber.withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: summary.averagePricePerTicket >= 48.0
                                              ? LiquidGlassColors.accentEmerald.withValues(alpha: 0.40)
                                              : LiquidGlassColors.accentAmber.withValues(alpha: 0.40),
                                        ),
                                      ),
                                      child: Text(
                                        summary.totalTicketsSold > 0
                                            ? 'Avg: ₹${summary.averagePricePerTicket.toStringAsFixed(2)}'
                                            : 'Awaiting sales',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: summary.averagePricePerTicket >= 48.0
                                              ? LiquidGlassColors.accentEmerald
                                              : LiquidGlassColors.accentAmber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showAuditAnalysis
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: LiquidGlassColors.textMuted,
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
                RecentTransactionsList(
                  transactions: summary.transactions,
                  onUndo: () => _handleUndo(salesProvider),
                ),

                const SizedBox(height: 24),
              ],
            ),
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

    return LiquidGlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      fillColor: isStaged
          ? const Color(0xFFF0FDF4)
          : Colors.white.withValues(alpha: 0.85),
      border: Border.all(
        color: isStaged
            ? const Color(0xFF10B981)
            : Colors.white.withValues(alpha: 0.95),
        width: isStaged ? 1.5 : 1.2,
      ),
      shadows: isStaged
          ? [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: isStaged
                            ? LiquidGlassColors.accentEmerald
                            : LiquidGlassColors.glassFillLight,
                        borderRadius: BorderRadius.circular(6),
                        border: isStaged
                            ? null
                            : Border.all(color: LiquidGlassColors.glassBorderLight),
                      ),
                      child: Text(
                        isStaged ? 'CURRENT CUSTOMER' : 'NEW CUSTOMER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isStaged ? Colors.white : LiquidGlassColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isStaged
                            ? 'Order Preview'
                            : 'Select ticket quantity below',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isStaged
                              ? LiquidGlassColors.accentEmerald
                              : LiquidGlassColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isStaged) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _stagedTickets = null),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 12, color: Color(0xFFE11D48)),
                        SizedBox(width: 3),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                      color: LiquidGlassColors.accentEmerald,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (_stagedTickets! > 1) {
                          setState(() => _stagedTickets = _stagedTickets! - 1);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: LiquidGlassColors.glassFillStrong,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$_stagedTickets Tkts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: LiquidGlassColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 24,
                      color: LiquidGlassColors.accentEmerald,
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
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: LiquidGlassColors.accentEmerald,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '₹${calc.effectiveRatePerTicket.toStringAsFixed(2)} / tkt',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LiquidGlassColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CONFIRM & ENTER SALE BUTTON
            LiquidGlassButton(
              label: 'ENTER SALE • ₹${calc.totalAmount.toStringAsFixed(0)}',
              icon: Icons.check_circle,
              glowColor: LiquidGlassColors.accentEmerald,
              onPressed: () => _confirmStagedSale(provider, calc),
            ),
          ] else ...[
            // Empty State
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: LiquidGlassColors.textMuted.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap any number (1–$_maxButtons) to stage customer sale',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: LiquidGlassColors.textMuted,
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
            final isSelected = _stagedTickets == ticketCount;

            final calc = PricingCalculator.calculate(
              ticketCount: ticketCount,
              config: pricing,
            );

            return SizedBox(
              width: itemWidth,
              height: 62,
              child: _OneTapKeypadButton(
                ticketCount: ticketCount,
                isSelected: isSelected,
                calc: calc,
                onTap: () {
                  setState(() {
                    _stagedTickets = ticketCount;
                  });
                },
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
        backgroundColor: LiquidGlassColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: LiquidGlassColors.accentEmerald, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Logged Customer Sale: +$count tickets (₹${total.toStringAsFixed(0)})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LiquidGlassColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: LiquidGlassColors.accentRose,
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
          backgroundColor: LiquidGlassColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: LiquidGlassColors.accentRose.withValues(alpha: 0.4)),
          ),
        ),
      );
    }
  }

  void _showShopPicker(BuildContext context, SalesProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LiquidGlassColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: LiquidGlassColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Switching terminal will track sales under that shop profile',
                  style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                ),
                Divider(
                  height: 20,
                  color: LiquidGlassColors.glassBorderSubtle,
                ),
                if (provider.shops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No retail shop terminals registered yet.',
                        style: TextStyle(fontSize: 13, color: LiquidGlassColors.textMuted),
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
                            ? LiquidGlassColors.accentEmerald.withValues(alpha: 0.25)
                            : LiquidGlassColors.glassFillMedium,
                        child: Icon(
                          Icons.storefront,
                          color: isCurrent
                              ? LiquidGlassColors.accentEmerald
                              : LiquidGlassColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        shop.name,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? LiquidGlassColors.accentEmerald
                              : LiquidGlassColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${shop.code} • 1 Set (12) = ₹${shop.pricingConfig.setPrice12.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: LiquidGlassColors.textMuted),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: LiquidGlassColors.accentEmerald)
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
              backgroundColor: LiquidGlassColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: LiquidGlassColors.glassBorderLight),
              ),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: LiquidGlassColors.accentViolet, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Head App Security',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: LiquidGlassColors.textPrimary,
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
                      style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: LiquidGlassColors.accentRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: LiquidGlassColors.accentRose.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: LiquidGlassColors.accentRose,
                          ),
                        ),
                      ),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: LiquidGlassColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Admin Username',
                        labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary),
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: LiquidGlassColors.textMuted,
                        ),
                        filled: true,
                        fillColor: LiquidGlassColors.glassFillMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: LiquidGlassColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Admin Password',
                        labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary),
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: LiquidGlassColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: LiquidGlassColors.textMuted,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: LiquidGlassColors.glassFillMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: LiquidGlassColors.textSecondary)),
                ),
                LiquidGlassButton(
                  label: 'VERIFY & ENTER',
                  glowColor: LiquidGlassColors.accentViolet,
                  isFullWidth: false,
                  height: 42,
                  isLoading: isLoading,
                  onPressed: () async {
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
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Tactile, juicy Liquid Glass Keypad Button with spring bounce & haptics
class _OneTapKeypadButton extends StatefulWidget {
  final int ticketCount;
  final bool isSelected;
  final PriceCalculationResult calc;
  final VoidCallback onTap;

  const _OneTapKeypadButton({
    required this.ticketCount,
    required this.isSelected,
    required this.calc,
    required this.onTap,
  });

  @override
  State<_OneTapKeypadButton> createState() => _OneTapKeypadButtonState();
}

class _OneTapKeypadButtonState extends State<_OneTapKeypadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.ticketCount;
    final isFullSet = count == 12;
    final isMultiSet24 = count == 24;
    final isMultiSet36 = count == 36;
    final isOtherMultiSet = count > 12 && count % 12 == 0 && !isMultiSet24 && !isMultiSet36;
    final isSelected = widget.isSelected;

    // Harmonious Vibrant Color Palettes:
    // 1. Singles (1 - 11): Crisp Sky Ice Gradient
    // 2. 12 (1 SET): Hero Juicy Emerald Neon Glass
    // 3. Low Bulk (13 - 23): Fresh Seafoam Mint Glaze
    // 4. 24 (2 SETS): Hero Juicy Electric Violet Neon Glass
    // 5. Mid Bulk (25 - 35): Soft Lavender Glaze
    // 6. 36 (3 SETS): Hero Juicy Royal Blue Neon Glass
    // 7. High Bulk (37 - 40): Soft Coral / Rose Glaze

    List<Color> gradientColors;
    Color borderColor;
    Color numberColor;
    Color priceTextColor;
    Color pricePillColor;
    String? setBadgeText;
    Color? badgeBgColor;
    List<BoxShadow> shadows;

    if (isSelected) {
      gradientColors = const [Color(0xFF0F766E), Color(0xFF0D9488)];
      borderColor = const Color(0xFF2DD4BF);
      numberColor = Colors.white;
      priceTextColor = Colors.white;
      pricePillColor = Colors.white.withValues(alpha: 0.22);
      shadows = [
        BoxShadow(
          color: const Color(0xFF0F766E).withValues(alpha: 0.45),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isFullSet) {
      // 1 SET (12): Hero Glowing Emerald
      gradientColors = const [Color(0xFF10B981), Color(0xFF059669)];
      borderColor = const Color(0xFF34D399);
      numberColor = Colors.white;
      priceTextColor = const Color(0xFFFEF08A); // Soft Gold
      pricePillColor = const Color(0xFF064E3B).withValues(alpha: 0.35);
      setBadgeText = '1 SET';
      badgeBgColor = const Color(0xFFF59E0B);
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.40),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else if (isMultiSet24) {
      // 2 SETS (24): Hero Glowing Electric Violet
      gradientColors = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      borderColor = const Color(0xFFA78BFA);
      numberColor = Colors.white;
      priceTextColor = const Color(0xFFFEF08A);
      pricePillColor = const Color(0xFF4C1D95).withValues(alpha: 0.35);
      setBadgeText = '2 SETS';
      badgeBgColor = const Color(0xFFF59E0B);
      shadows = [
        BoxShadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else if (isMultiSet36) {
      // 3 SETS (36): Hero Glowing Royal Blue
      gradientColors = const [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
      borderColor = const Color(0xFF60A5FA);
      numberColor = Colors.white;
      priceTextColor = const Color(0xFFFEF08A);
      pricePillColor = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
      setBadgeText = '3 SETS';
      badgeBgColor = const Color(0xFFF59E0B);
      shadows = [
        BoxShadow(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.40),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else if (isOtherMultiSet) {
      gradientColors = const [Color(0xFF6366F1), Color(0xFF4338CA)];
      borderColor = const Color(0xFF818CF8);
      numberColor = Colors.white;
      priceTextColor = const Color(0xFFFEF08A);
      pricePillColor = Colors.black.withValues(alpha: 0.2);
      setBadgeText = '${count ~/ 12} SETS';
      badgeBgColor = const Color(0xFFF59E0B);
      shadows = [
        BoxShadow(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (count <= 11) {
      // Singles 1 to 11: Crisp Cyan / Ice Sky Glass
      gradientColors = [
        Colors.white,
        const Color(0xFFE0F2FE),
      ];
      borderColor = const Color(0xFFBAE6FD);
      numberColor = const Color(0xFF0F172A);
      priceTextColor = const Color(0xFF0284C7);
      pricePillColor = const Color(0xFF0284C7).withValues(alpha: 0.12);
      shadows = [
        BoxShadow(
          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else if (count <= 23) {
      // Low Bulk 13 to 23: Fresh Mint / Aqua Glaze
      gradientColors = [
        Colors.white,
        const Color(0xFFDCFCE7),
      ];
      borderColor = const Color(0xFFA7F3D0);
      numberColor = const Color(0xFF0F172A);
      priceTextColor = const Color(0xFF059669);
      pricePillColor = const Color(0xFF059669).withValues(alpha: 0.12);
      shadows = [
        BoxShadow(
          color: const Color(0xFF059669).withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else if (count <= 35) {
      // Mid Bulk 25 to 35: Soft Lavender / Lilac Glaze
      gradientColors = [
        Colors.white,
        const Color(0xFFF3E8FF),
      ];
      borderColor = const Color(0xFFDDD6FE);
      numberColor = const Color(0xFF0F172A);
      priceTextColor = const Color(0xFF7C3AED);
      pricePillColor = const Color(0xFF7C3AED).withValues(alpha: 0.12);
      shadows = [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    } else {
      // High Bulk 37 to 40: Soft Coral / Rose Glaze
      gradientColors = [
        Colors.white,
        const Color(0xFFFFE4E6),
      ];
      borderColor = const Color(0xFFFECDD3);
      numberColor = const Color(0xFF0F172A);
      priceTextColor = const Color(0xFFE11D48);
      pricePillColor = const Color(0xFFE11D48).withValues(alpha: 0.12);
      shadows = [
        BoxShadow(
          color: const Color(0xFFE11D48).withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
    }

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTapDown: (_) {
            _controller.forward();
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            _controller.reverse();
          },
          onTapCancel: () {
            _controller.reverse();
          },
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF0F766E) : borderColor,
                width: isSelected ? 2.2 : 1.2,
              ),
              boxShadow: shadows,
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
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor ?? Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      setBadgeText,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: numberColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: pricePillColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${widget.calc.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: priceTextColor,
                          height: 1.0,
                        ),
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
}
}
