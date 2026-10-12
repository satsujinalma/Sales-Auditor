import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/daily_sales_summary.dart';
import '../../models/pricing_config.dart';
import '../../models/shop_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/audit_comparison_card.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';
import '../../widgets/recent_transactions_list.dart';
import '../../widgets/sales_volume_breakdown_widget.dart';
import '../../widgets/three_output_boxes_widget.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitchToShopkeeper;

  const AdminDashboardScreen({
    super.key,
    required this.onSwitchToShopkeeper,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Mirrored View, 1: All Shops Overview, 2: Staff
  Timer? _staffPollingTimer;

  @override
  void initState() {
    super.initState();
    // Periodically sync staff access requests in background every 4 seconds
    _staffPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        context.read<AuthProvider>().refreshUsers();
      }
    });
  }

  @override
  void dispose() {
    _staffPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final shops = adminProvider.shops;
    final selectedShop = adminProvider.selectedShop;
    final summary = adminProvider.selectedShopSummary;

    if (adminProvider.isLoading) {
      return Scaffold(
        backgroundColor: LiquidGlassColors.background,
        body: LiquidGlowBackground(
          child: const Center(
            child: CircularProgressIndicator(color: LiquidGlassColors.accentViolet),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LiquidGlassColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'HEAD APP • AUDIT MONITOR',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (selectedShop != null)
              Text(
                'Monitoring: ${selectedShop.name} (${selectedShop.code})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: LiquidGlassColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Shopkeeper Terminal Mode',
            icon: const Icon(Icons.storefront, color: LiquidGlassColors.accentEmerald),
            onPressed: widget.onSwitchToShopkeeper,
          ),
          IconButton(
            tooltip: 'Pricing & System Settings (PIN Protected)',
            icon: const Icon(Icons.settings, color: LiquidGlassColors.accentViolet),
            onPressed: () => _openSettings(adminProvider),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: LiquidGlassColors.textMuted, size: 20),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: LiquidGlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'MIRROR',
                      icon: Icons.splitscreen,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'ALL SHOPS',
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: 'STAFF',
                      icon: Icons.badge_outlined,
                      badgeCount: context.watch<AuthProvider>().pendingUsers.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: LiquidGlowBackground(
        child: SafeArea(
          child: _selectedTab == 0
              ? _buildMirroredShopkeeperView(
                  context, adminProvider, selectedShop, summary)
              : _selectedTab == 1
                  ? _buildAllShopsSummaryView(context, adminProvider, shops)
                  : _buildStaffApprovalsView(
                      context, context.watch<AuthProvider>(), adminProvider),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 2) {
          context.read<AuthProvider>().refreshUsers();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? LiquidGlassColors.accentViolet
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? LiquidGlassTheme.neonGlow(
                  color: LiquidGlassColors.accentViolet,
                  intensity: 0.25,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : LiquidGlassColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isSelected ? Colors.white : LiquidGlassColors.textSecondary,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : LiquidGlassColors.accentAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? LiquidGlassColors.accentViolet : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// MIRRORED VIEW: Exact user interface (UI) seen by the shopkeepers in STRICTLY VIEW-ONLY mode
  Widget _buildMirroredShopkeeperView(
    BuildContext context,
    AdminProvider adminProvider,
    selectedShop,
    DailySalesSummary summary,
  ) {
    if (selectedShop == null) {
      return const Center(
        child: Text(
          'No shops configured.',
          style: TextStyle(color: LiquidGlassColors.textSecondary),
        ),
      );
    }

    final pricing = selectedShop.pricingConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SHOP SELECTOR BAR
          LiquidGlassContainer(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: LiquidGlassColors.accentViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: LiquidGlassColors.accentViolet,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Counter:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: LiquidGlassColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: LiquidGlassColors.surfaceLight,
                      value: adminProvider.selectedShopId,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: LiquidGlassColors.textSecondary,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: LiquidGlassColors.textPrimary,
                      ),
                      onChanged: (String? newShopId) {
                        if (newShopId != null) {
                          adminProvider.selectShop(newShopId);
                        }
                      },
                      items: adminProvider.shops.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(
                            '${s.name} (${s.code})',
                            style: const TextStyle(color: LiquidGlassColors.textPrimary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LIVE AUDIT STATUS PILL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  size: 14,
                  color: LiquidGlassColors.accentEmerald,
                ),
                SizedBox(width: 6),
                Text(
                  'Live Audit Mode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: LiquidGlassColors.accentEmerald,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // THE 3 SPECIFIC OUTPUT BOXES (MIRRORED LIVE VIEW)
          ThreeOutputBoxesWidget(
            summary: summary,
            isReadOnlyMirror: true,
          ),

          const SizedBox(height: 14),

          // AUDIT BENCHMARK COMPARISON CARD
          AuditComparisonCard(
            summary: summary,
            pricingConfig: pricing,
          ),

          const SizedBox(height: 14),

          // LIVE TRANSACTION AUDIT LOG
          RecentTransactionsList(
            transactions: summary.transactions,
            isReadOnly: true,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// MULTI-SHOP OVERVIEW VIEW
  Widget _buildAllShopsSummaryView(
    BuildContext context,
    AdminProvider adminProvider,
    List shops,
  ) {
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

    int totalNetworkTickets = 0;
    double totalNetworkRevenue = 0.0;

    for (final shop in shops) {
      final summary = adminProvider.allShopSummaries[shop.id];
      if (summary != null) {
        totalNetworkTickets += summary.totalTicketsSold;
        totalNetworkRevenue += summary.totalRevenue;
      }
    }

    final networkAvg = totalNetworkTickets > 0
        ? totalNetworkRevenue / totalNetworkTickets
        : 0.0;

    return RefreshIndicator(
      color: LiquidGlassColors.accentViolet,
      backgroundColor: LiquidGlassColors.surfaceElevated,
      onRefresh: () => adminProvider.refreshAllShopSummaries(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Network Total Card
          LiquidGlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            fillColor: LiquidGlassColors.surfaceElevated.withValues(alpha: 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL NETWORK SUMMARY (TODAY)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.amber,
                      ),
                    ),
                    Icon(Icons.hub, color: Colors.amber, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TICKETS SOLD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: LiquidGlassColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalNetworkTickets',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: LiquidGlassColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL REVENUE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: LiquidGlassColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(totalNetworkRevenue),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: LiquidGlassColors.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NETWORK AVG',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: LiquidGlassColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalNetworkTickets > 0
                                ? avgFormat.format(networkAvg)
                                : '₹0.00',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: networkAvg >= 48.30
                                  ? LiquidGlassColors.accentEmerald
                                  : LiquidGlassColors.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Prominent Register Shop Button (never overflows)
          LiquidGlassButton(
            key: const Key('register_new_shop_button'),
            label: '+ REGISTER NEW SHOP',
            icon: Icons.add_business_rounded,
            glowColor: LiquidGlassColors.accentViolet,
            isFullWidth: true,
            height: 42,
            onPressed: () => _showRegisterShopDialog(context, adminProvider),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTERED SHOPS (${shops.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: LiquidGlassColors.textSecondary,
                ),
              ),
              const Text(
                'Tap shop to view Breakdown',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final shop = shops[index];
              final summary = adminProvider.allShopSummaries[shop.id] ??
                  DailySalesSummary(shopId: shop.id, date: DateTime.now());
              final tickets = summary.totalTicketsSold;
              final rev = summary.totalRevenue;
              final avg = summary.averagePricePerTicket;
              final pricing = shop.pricingConfig;

              final isBelowTarget =
                  tickets > 0 && avg < pricing.targetBenchmarkMin;

              return InkWell(
                onTap: () {
                  _showShopVolumeBreakdownModal(context, shop, summary, adminProvider);
                },
                borderRadius: BorderRadius.circular(16),
                child: LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  border: Border.all(
                    color: isBelowTarget
                        ? Colors.amber.withValues(alpha: 0.6)
                        : LiquidGlassColors.glassBorderLight,
                    width: isBelowTarget ? 1.5 : 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: LiquidGlassColors.accentViolet.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    size: 16,
                                    color: LiquidGlassColors.accentViolet,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: LiquidGlassColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Prominent Shop Code Badge for Counter Staff
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: LiquidGlassColors.accentTeal.withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: LiquidGlassColors.accentTeal.withValues(alpha: 0.45),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.vpn_key_rounded,
                                                  size: 10,
                                                  color: LiquidGlassColors.accentTeal,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'CODE: ${shop.code.toUpperCase()}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.6,
                                                    color: LiquidGlassColors.accentTeal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: shop.code.toUpperCase()));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  duration: const Duration(seconds: 2),
                                                  backgroundColor: LiquidGlassColors.surfaceElevated,
                                                  content: Text(
                                                    'Shop code "${shop.code.toUpperCase()}" copied to clipboard!',
                                                    style: const TextStyle(
                                                      color: LiquidGlassColors.accentTeal,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(4),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(
                                                Icons.copy_rounded,
                                                size: 13,
                                                color: LiquidGlassColors.textMuted,
                                              ),
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: LiquidGlassColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: LiquidGlassColors.glassBorderSubtle,
                              ),
                            ),
                            child: Text(
                              'Set: ₹${pricing.setPrice12.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: LiquidGlassColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tickets Sold',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: LiquidGlassColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '$tickets',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: LiquidGlassColors.accentEmerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Revenue',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: LiquidGlassColors.textMuted,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(rev),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: LiquidGlassColors.accentEmerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Avg Rate',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: LiquidGlassColors.textMuted,
                                  ),
                                ),
                                Text(
                                  tickets > 0
                                      ? avgFormat.format(avg)
                                      : '₹0.00',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: avg >= pricing.targetBenchmarkMin
                                        ? LiquidGlassColors.accentEmerald
                                        : (avg > 0
                                            ? LiquidGlassColors.accentAmber
                                            : LiquidGlassColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: LiquidGlassColors.accentViolet.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: LiquidGlassColors.accentViolet.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 12, color: LiquidGlassColors.accentViolet),
                                SizedBox(width: 3),
                                Text(
                                  'Volume',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: LiquidGlassColors.accentViolet,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (tickets > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: LiquidGlassColors.glassBorderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Singles: ${summary.singleOrdersCount} orders (${summary.singleTicketsSold} tix)',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.accentEmerald,
                                ),
                              ),
                              Text(
                                'Sets: ${summary.setOrdersCount} orders (${summary.bulkTicketsSold} tix)',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.accentViolet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
  }

  void _openSettings(AdminProvider provider) async {
    // If not authenticated, prompt for PIN
    if (!provider.isAuthenticated) {
      final pinController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      String? errorText;

      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                backgroundColor: LiquidGlassColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: LiquidGlassColors.glassBorderLight),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: LiquidGlassColors.accentViolet, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Admin Authentication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter 4-digit Admin PIN to alter ticket pricing and shop rates.',
                        style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        autofocus: true,
                        style: const TextStyle(color: LiquidGlassColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter 4-digit PIN',
                          hintStyle: const TextStyle(color: LiquidGlassColors.textMuted),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: LiquidGlassColors.accentViolet),
                          ),
                          errorText: errorText,
                          prefixIcon: const Icon(Icons.pin, color: LiquidGlassColors.accentViolet),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: LiquidGlassColors.textSecondary)),
                  ),
                  LiquidGlassButton(
                    label: 'Unlock',
                    glowColor: LiquidGlassColors.accentViolet,
                    isFullWidth: false,
                    height: 40,
                    onPressed: () async {
                      final isValid =
                          await provider.verifyPin(pinController.text.trim());
                      if (isValid) {
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } else {
                        setDialogState(() {
                          errorText = 'Invalid PIN. Please try again.';
                        });
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );

      if (success != true || !mounted) return;
    }

    if (!mounted) return;
    // Navigate to Admin Settings Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
    );
  }

  String _deriveShopCode(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    final words = clean.split(RegExp(r'\s+'));
    final firstWord = words.first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (firstWord.length <= 5) {
      return firstWord.toUpperCase();
    } else {
      return firstWord.substring(0, 5).toUpperCase();
    }
  }

  InputDecoration _buildDialogInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary, fontSize: 13),
      hintText: hintText,
      hintStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 13),
      helperText: helperText,
      helperStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 11),
      prefixIcon: Icon(icon, color: LiquidGlassColors.accentViolet, size: 20),
      filled: true,
      fillColor: LiquidGlassColors.glassFillMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiquidGlassColors.accentViolet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiquidGlassColors.accentRose),
      ),
    );
  }

  void _showRegisterShopDialog(BuildContext context, AdminProvider adminProvider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    bool autoGenerateCode = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: LiquidGlassColors.surfaceElevated,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: LiquidGlassColors.accentViolet.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: LiquidGlassColors.accentViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: LiquidGlassColors.accentViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Register New Shop',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set shop name and staff join code.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. Shop Name
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: LiquidGlassColors.textPrimary,
                        ),
                        decoration: _buildDialogInputDecoration(
                          labelText: 'Shop Name',
                          hintText: 'e.g. Thiruvonam Counter',
                          icon: Icons.storefront_rounded,
                        ),
                        onChanged: (val) {
                          if (autoGenerateCode) {
                            final generated = _deriveShopCode(val);
                            setDialogState(() {
                              codeController.text = generated;
                            });
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter shop name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // 2. Shop Code
                      TextFormField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: LiquidGlassColors.accentTeal,
                        ),
                        decoration: _buildDialogInputDecoration(
                          labelText: 'Shop Code (Staff Join Code)',
                          hintText: 'e.g. THIRU',
                          icon: Icons.vpn_key_rounded,
                          helperText: 'Staff will enter this code on login.',
                        ),
                        onChanged: (val) {
                          autoGenerateCode = false;
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter shop code';
                          }
                          final clean = val.trim().toUpperCase();
                          if (clean.length < 2) {
                            return 'Code must be at least 2 characters';
                          }
                          final exists = adminProvider.shops.any(
                            (s) => s.code.toUpperCase() == clean,
                          );
                          if (exists) {
                            return 'Shop code "$clean" is already registered';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: LiquidGlassColors.textSecondary),
                  ),
                ),
                LiquidGlassButton(
                  label: 'REGISTER SHOP',
                  icon: Icons.check_circle_outline_rounded,
                  glowColor: LiquidGlassColors.accentViolet,
                  isFullWidth: false,
                  height: 38,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final cleanName = nameController.text.trim();
                    final cleanCode = codeController.text.trim().toUpperCase();
                    const cleanLocation = 'Kerala Counter';

                    final idBase = cleanCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                    final newShopId = adminProvider.shops.any((s) => s.id == idBase)
                        ? '${idBase}_${DateTime.now().millisecondsSinceEpoch % 10000}'
                        : idBase;

                    final newShop = Shop(
                      id: newShopId,
                      name: cleanName,
                      location: cleanLocation,
                      code: cleanCode,
                      pricingConfig: const PricingConfig(
                        singleTicketPrice: 50.0,
                        setPrice12: 570.0,
                        bulkFormula: BulkPricingFormula.proRata,
                        targetBenchmarkMin: 48.30,
                        targetBenchmarkMax: 48.50,
                        claimedAvgPrice: 47.20,
                      ),
                      isActive: true,
                    );

                    await adminProvider.saveShop(newShop);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: LiquidGlassColors.surfaceElevated,
                          content: Text(
                            'Shop "$cleanName" registered! Staff Join Code: $cleanCode',
                            style: const TextStyle(
                              color: LiquidGlassColors.accentEmerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
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

  void _showShopVolumeBreakdownModal(
    BuildContext context,
    Shop shop,
    DailySalesSummary summary,
    AdminProvider adminProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<AdminProvider>(
          builder: (modalCtx, provider, child) {
            final currentSummary = provider.allShopSummaries[shop.id] ??
                DailySalesSummary(shopId: shop.id, date: DateTime.now());
            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            final avgFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
            final tickets = currentSummary.totalTicketsSold;
            final rev = currentSummary.totalRevenue;
            final avg = currentSummary.averagePricePerTicket;
            final pricing = shop.pricingConfig;
            final isBelowTarget = tickets > 0 && avg < pricing.targetBenchmarkMin;
            final activeOrdersCount = currentSummary.activeTransactions.length;

            return Container(
              decoration: BoxDecoration(
                color: LiquidGlassColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: LiquidGlassColors.glassBorderLight,
                  width: 1.2,
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LiquidGlassColors.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.accentViolet.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: LiquidGlassColors.accentViolet,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: LiquidGlassColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: LiquidGlassColors.accentTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: LiquidGlassColors.accentTeal.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'CODE: ${shop.code.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: LiquidGlassColors.accentTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Target: ₹${pricing.targetBenchmarkMin.toStringAsFixed(2)}/tix',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: LiquidGlassColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: LiquidGlassColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: LiquidGlassColors.glassBorderSubtle, height: 1),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Live Audit Benchmark Health Pill
                          if (tickets > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isBelowTarget
                                    ? const Color(0xFFFFE4E6)
                                    : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isBelowTarget
                                      ? const Color(0xFFFDA4AF)
                                      : const Color(0xFFA7F3D0),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isBelowTarget
                                        ? Icons.warning_amber_rounded
                                        : Icons.verified_rounded,
                                    size: 16,
                                    color: isBelowTarget
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isBelowTarget
                                          ? 'Audit Alert: Live Avg ₹${avg.toStringAsFixed(2)} is ₹${((pricing.targetBenchmarkMin - avg)).abs().toStringAsFixed(2)} below target (₹${pricing.targetBenchmarkMin.toStringAsFixed(2)})'
                                      : 'Audit Healthy: Live Avg ₹${avg.toStringAsFixed(2)} achieves profit target (₹${pricing.targetBenchmarkMin.toStringAsFixed(2)})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isBelowTarget
                                            ? const Color(0xFF9F1239)
                                            : const Color(0xFF065F46),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 2. Quick Metric Bar
                          LiquidGlassContainer(
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tickets Sold',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: LiquidGlassColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$tickets',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: LiquidGlassColors.accentEmerald,
                                        ),
                                      ),
                                      Text(
                                        '$activeOrdersCount orders',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: LiquidGlassColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Revenue',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: LiquidGlassColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(rev),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: LiquidGlassColors.accentEmerald,
                                        ),
                                      ),
                                      Text(
                                        activeOrdersCount > 0
                                            ? '₹${(rev / activeOrdersCount).round()}/ord'
                                            : '₹0/ord',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: LiquidGlassColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Avg Price',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: LiquidGlassColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tickets > 0 ? avgFormat.format(avg) : '₹0.00',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: isBelowTarget
                                              ? const Color(0xFFE11D48)
                                              : (tickets > 0
                                                  ? LiquidGlassColors.accentEmerald
                                                  : LiquidGlassColors.textMuted),
                                        ),
                                      ),
                                      Text(
                                        'Target ₹${pricing.targetBenchmarkMin.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: LiquidGlassColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // THE SALES VOLUME BREAKDOWN (BOX PATTERN)
                          SalesVolumeBreakdownWidget(
                            summary: currentSummary,
                          ),

                          const SizedBox(height: 14),

                          // 1. Mirror terminal for this shop
                          LiquidGlassButton(
                            label: 'MIRROR THIS COUNTER LIVE',
                            icon: Icons.desktop_windows_outlined,
                            glowColor: LiquidGlassColors.accentTeal,
                            isFullWidth: true,
                            height: 40,
                            onPressed: () {
                              Navigator.pop(ctx);
                              provider.selectShop(shop.id);
                              setState(() {
                                _selectedTab = 0;
                              });
                            },
                          ),

                          const SizedBox(height: 10),

                          // 2. Reset Shop Data Button (Admin manual reset after checking)
                          LiquidGlassButton(
                            key: const Key('reset_shop_data_button'),
                            label: 'RESET ${shop.name.toUpperCase()} SALES',
                            icon: Icons.restart_alt_rounded,
                            glowColor: LiquidGlassColors.accentRose,
                            isFullWidth: true,
                            height: 40,
                            onPressed: () => _confirmResetShopData(
                              ctx,
                              shop,
                              currentSummary,
                              provider,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog allowing admin to manually reset sales data for a specific shop after checking
  void _confirmResetShopData(
    BuildContext modalContext,
    Shop shop,
    DailySalesSummary summary,
    AdminProvider adminProvider,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final tickets = summary.totalTicketsSold;
    final rev = summary.totalRevenue;

    showDialog(
      context: modalContext,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: LiquidGlassColors.surfaceElevated,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: LiquidGlassColors.accentRose.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: LiquidGlassColors.accentRose,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset Shop Sales?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${shop.name} (${shop.code.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LiquidGlassColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reset recorded sales for "${shop.name}"?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFDA4AF),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tickets to Reset',
                          style: TextStyle(fontSize: 10, color: Color(0xFF9F1239)),
                        ),
                        Text(
                          '$tickets Tickets',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Revenue to Reset',
                          style: TextStyle(fontSize: 10, color: Color(0xFF9F1239)),
                        ),
                        Text(
                          currencyFormat.format(rev),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '• Only this specific shop\'s sales will be cleared.\n• Other counters will NOT be affected.\n• Action is performed manually after admin review.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: LiquidGlassColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: LiquidGlassColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            LiquidGlassButton(
              key: const Key('confirm_reset_shop_data_button'),
              label: 'CONFIRM RESET',
              icon: Icons.delete_forever_rounded,
              glowColor: LiquidGlassColors.accentRose,
              isFullWidth: false,
              height: 38,
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await adminProvider.resetShopSales(shop.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: LiquidGlassColors.surfaceElevated,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: LiquidGlassColors.accentEmerald, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sales data for "${shop.name}" has been reset to 0.',
                            style: const TextStyle(
                              color: LiquidGlassColors.accentEmerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// STAFF & TERMINAL APPROVALS VIEW: Admin manages counter staff access and approval
  Widget _buildStaffApprovalsView(
    BuildContext context,
    AuthProvider authProvider,
    AdminProvider adminProvider,
  ) {
    final pendingUsers = authProvider.pendingUsers;
    final approvedStaff = authProvider.approvedStaff;
    final shops = adminProvider.shops;

    return RefreshIndicator(
      color: LiquidGlassColors.accentViolet,
      onRefresh: () => authProvider.refreshUsers(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER SUMMARY CARD
            LiquidGlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LiquidGlassColors.accentViolet.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: LiquidGlassColors.accentViolet,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STAFF & TERMINAL ACCESS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: LiquidGlassColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pendingUsers.length} pending approval • ${approvedStaff.length} approved staff',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: LiquidGlassColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Staff Directory',
                    icon: const Icon(Icons.refresh_rounded, color: LiquidGlassColors.accentViolet, size: 20),
                    onPressed: () => authProvider.refreshUsers(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. PENDING REQUESTS SECTION
            Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: LiquidGlassColors.accentAmber, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'PENDING ACCESS REQUESTS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: LiquidGlassColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: pendingUsers.isNotEmpty
                        ? LiquidGlassColors.accentAmber.withValues(alpha: 0.2)
                        : LiquidGlassColors.glassFillMedium,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pendingUsers.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: pendingUsers.isNotEmpty
                          ? LiquidGlassColors.accentAmber
                          : LiquidGlassColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (pendingUsers.isEmpty)
              LiquidGlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: LiquidGlassColors.accentEmerald, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'No pending requests. All counter staff are verified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LiquidGlassColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...pendingUsers.map((user) {
                final targetShop = shops.firstWhere(
                  (s) => s.id == user.shopId,
                  orElse: () => Shop(
                    id: user.shopId ?? '',
                    name: user.shopName ?? 'Requested Counter',
                    location: '',
                    code: 'SHP',
                    pricingConfig: const PricingConfig(),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LiquidGlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    border: Border.all(
                      color: LiquidGlassColors.accentAmber.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: LiquidGlassColors.accentAmber.withValues(alpha: 0.2),
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: LiquidGlassColors.accentAmber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: LiquidGlassColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user.phoneNumber,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: LiquidGlassColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: LiquidGlassColors.accentAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'APPROVAL REQUIRED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: LiquidGlassColors.accentAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront, size: 14, color: LiquidGlassColors.accentTeal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Assigned Counter: ${targetShop.name} (${targetShop.code})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: LiquidGlassColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LiquidGlassButton(
                                label: 'APPROVE STAFF',
                                icon: Icons.check,
                                height: 38,
                                glowColor: LiquidGlassColors.accentEmerald,
                                onPressed: () => authProvider.approveUser(user.id),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => authProvider.rejectUser(user.id),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDA4AF)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.close, size: 14, color: Color(0xFFE11D48)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Reject',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFE11D48),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // 3. APPROVED COUNTER STAFF (Grouped by Shop)
            const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: LiquidGlassColors.accentEmerald, size: 16),
                SizedBox(width: 6),
                Text(
                  'ACTIVE AUTHORIZED COUNTERS & STAFF',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: LiquidGlassColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (approvedStaff.isEmpty)
              LiquidGlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'No staff members approved yet.',
                    style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                  ),
                ),
              )
            else
              ...shops.map((shop) {
                final staffForShop = approvedStaff.where((u) => u.shopId == shop.id).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LiquidGlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.storefront, size: 16, color: LiquidGlassColors.accentEmerald),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${shop.name} (${shop.code})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: LiquidGlassColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${staffForShop.length} Staff',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: LiquidGlassColors.accentEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (staffForShop.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'No counter workers assigned to this shop yet.',
                              style: TextStyle(fontSize: 11, color: LiquidGlassColors.textMuted),
                            ),
                          )
                        else
                          ...staffForShop.map((staff) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: LiquidGlassColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, size: 14, color: LiquidGlassColors.accentViolet),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              staff.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: LiquidGlassColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '(${staff.phoneNumber})',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: LiquidGlassColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => authProvider.revokeUser(staff.id),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: const Text(
                                          'Revoke',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: LiquidGlassColors.accentRose,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
