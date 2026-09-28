import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/daily_sales_summary.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/audit_comparison_card.dart';
import '../../widgets/recent_transactions_list.dart';
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
  int _selectedTab = 0; // 0: Mirrored View, 1: All Shops Overview

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final shops = adminProvider.shops;
    final selectedShop = adminProvider.selectedShop;
    final summary = adminProvider.selectedShopSummary;

    if (adminProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Navy/Slate for Head App
        elevation: 3,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: Colors.amber, size: 16),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'HEAD APP • AUDIT MONITOR',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
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
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Shopkeeper Terminal Mode',
            icon: const Icon(Icons.storefront, color: Colors.white),
            onPressed: widget.onSwitchToShopkeeper,
          ),
          IconButton(
            tooltip: 'Pricing & System Settings (PIN Protected)',
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _openSettings(adminProvider),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'LIVE MIRRORED UI',
                      icon: Icons.splitscreen,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'ALL SHOPS SUMMARY',
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _selectedTab == 0
            ? _buildMirroredShopkeeperView(
                context, adminProvider, selectedShop, summary)
            : _buildAllShopsSummaryView(context, adminProvider, shops),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.4,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
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
      return const Center(child: Text('No shops configured.'));
    }

    final pricing = selectedShop.pricingConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SHOP SELECTOR BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF0F766E),
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
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: adminProvider.selectedShopId,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF64748B),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      onChanged: (String? newShopId) {
                        if (newShopId != null) {
                          adminProvider.selectShop(newShopId);
                        }
                      },
                      items: adminProvider.shops.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text('${s.name} (${s.code})'),
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
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 6),
                Text(
                  'Live Audit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFF166534),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: RecentTransactionsList(
              transactions: summary.transactions,
              isReadOnly: true,
            ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Network Total Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
                const SizedBox(height: 10),
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
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '$totalNetworkTickets',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            currencyFormat.format(totalNetworkRevenue),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4ADE80),
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
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            totalNetworkTickets > 0
                                ? avgFormat.format(networkAvg)
                                : '₹0.00',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: networkAvg >= 48.30
                                  ? const Color(0xFF4ADE80)
                                  : Colors.amberAccent,
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

          const Text(
            'INDIVIDUAL SHOP STATUS & AUDIT SPREAD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
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
                  adminProvider.selectShop(shop.id);
                  setState(() => _selectedTab = 0);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBelowTarget
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFE2E8F0),
                      width: isBelowTarget ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  size: 16,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    shop.code,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Set: ₹${pricing.setPrice12.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
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
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  '$tickets',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F766E),
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
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(rev),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF166534),
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
                                    color: Color(0xFF64748B),
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
                                        ? const Color(0xFF15803D)
                                        : (avg > 0
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFF0F766E), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Admin Authentication',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'PIN (Default: 1234)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: errorText,
                          prefixIcon: const Icon(Icons.pin),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final isValid =
                          await provider.verifyPin(pinController.text.trim());
                      if (isValid) {
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } else {
                        setDialogState(() {
                          errorText = 'Invalid PIN. Default is 1234';
                        });
                      }
                    },
                    child: const Text('Unlock'),
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
}
