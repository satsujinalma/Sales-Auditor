import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pricing_config.dart';
import '../../providers/admin_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String? _editingShopId;

  late TextEditingController _singleTicketController;
  late TextEditingController _setPriceController;
  late TextEditingController _benchmarkMinController;
  late TextEditingController _benchmarkMaxController;
  late TextEditingController _claimedAvgController;
  BulkPricingFormula _bulkFormula = BulkPricingFormula.proRata;

  final Map<int, TextEditingController> _tierControllers = {};

  @override
  void initState() {
    super.initState();
    final adminProvider = context.read<AdminProvider>();
    _editingShopId = adminProvider.selectedShopId;
    _singleTicketController = TextEditingController();
    _setPriceController = TextEditingController();
    _benchmarkMinController = TextEditingController();
    _benchmarkMaxController = TextEditingController();
    _claimedAvgController = TextEditingController();

    for (int i = 1; i <= 12; i++) {
      _tierControllers[i] = TextEditingController();
    }

    _loadShopValues(adminProvider);
  }

  void _loadShopValues(AdminProvider provider) {
    final shop = provider.shops.firstWhere(
      (s) => s.id == _editingShopId,
      orElse: () => provider.shops.first,
    );
    final p = shop.pricingConfig;

    _singleTicketController.text = p.singleTicketPrice.toStringAsFixed(0);
    _setPriceController.text = p.setPrice12.toStringAsFixed(0);
    _benchmarkMinController.text = p.targetBenchmarkMin.toStringAsFixed(2);
    _benchmarkMaxController.text = p.targetBenchmarkMax.toStringAsFixed(2);
    _claimedAvgController.text = p.claimedAvgPrice.toStringAsFixed(2);
    _bulkFormula = p.bulkFormula;

    for (int i = 1; i <= 12; i++) {
      _tierControllers[i]!.text = p.getTierPrice(i).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _singleTicketController.dispose();
    _setPriceController.dispose();
    _benchmarkMinController.dispose();
    _benchmarkMaxController.dispose();
    _claimedAvgController.dispose();
    for (final c in _tierControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final shops = adminProvider.shops;

    return Scaffold(
      backgroundColor: LiquidGlassColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Pricing & Audit Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: LiquidGlassColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Change Admin PIN',
            icon: const Icon(Icons.password, color: Colors.amberAccent),
            onPressed: () => _showChangePinDialog(adminProvider),
          ),
          IconButton(
            tooltip: 'Lock / Logout Admin',
            icon: const Icon(Icons.lock_open, color: LiquidGlassColors.textSecondary),
            onPressed: () {
              adminProvider.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: LiquidGlowBackground(
        primaryGlow: LiquidGlassColors.accentViolet,
        secondaryGlow: LiquidGlassColors.accentEmerald,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SHOP SELECTOR
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONFIGURING PRICING FOR SHOP:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: LiquidGlassColors.surfaceDark,
                        style: const TextStyle(
                          color: LiquidGlassColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: LiquidGlassColors.glassFillMedium,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                          ),
                        ),
                        initialValue: _editingShopId,
                        items: shops.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.name} (${s.code})',
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() {
                              _editingShopId = newId;
                              _loadShopValues(adminProvider);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // BASE LOTTERY RATES SECTION
                _buildSectionHeader('1. BASE TICKET & SET RATES', Icons.payments),
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _singleTicketController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                              decoration: _buildInputDeco(
                                label: 'Single Ticket (₹)',
                                hint: '50',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _setPriceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                              decoration: _buildInputDeco(
                                label: '1 Set (12 Tkts) (₹)',
                                hint: '570 / 580',
                                helper: 'e.g. ₹570 Nayarambalam',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // FORMULA FOR > 12 TICKETS
                _buildSectionHeader(
                  '2. BULK PRICING RULE (> 12 TICKETS)',
                  Icons.calculate,
                ),
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildFormulaOption(
                        formula: BulkPricingFormula.proRata,
                        title: 'Pro-Rata Established Average Rate (Recommended)',
                        subtitle:
                            'Price = Quantity × (Set Price ÷ 12). For example, 15 tickets @ ₹47.50 = ₹712.50',
                      ),
                      Divider(height: 16, color: LiquidGlassColors.glassBorderSubtle),
                      _buildFormulaOption(
                        formula: BulkPricingFormula.setPlusRemainder,
                        title: 'Bundled Sets + Remainder Tier',
                        subtitle:
                            'Price = (Sets × Set Rate) + (Remainder × Single Rate). For example, 15 tickets = 1 set (₹570) + 3 singles (₹150) = ₹720',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TIERED PRICING TABLE (1 TO 12 TICKETS)
                _buildSectionHeader(
                  '3. PRE-SET TIERED PRICING (1 TO 12 TICKETS)',
                  Icons.table_chart,
                ),
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure exact price for quantities from 1 to 12 tickets:',
                        style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final count = index + 1;
                          return TextFormField(
                            controller: _tierControllers[count],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: LiquidGlassColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: count == 12 ? '12 (1 Set)' : '$count Tkt',
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                color: LiquidGlassColors.textSecondary,
                              ),
                              prefixText: '₹',
                              prefixStyle: const TextStyle(
                                color: LiquidGlassColors.accentEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                              filled: true,
                              fillColor: LiquidGlassColors.glassFillMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: LiquidGlassColors.glassBorderLight),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AUDIT BENCHMARKS SECTION
                _buildSectionHeader(
                  '4. AUDIT BENCHMARKS & CLAIMS',
                  Icons.analytics,
                ),
                LiquidGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _claimedAvgController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                              decoration: _buildInputDeco(
                                label: 'Shop Claim (₹)',
                                hint: '47.20',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _benchmarkMinController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                              decoration: _buildInputDeco(
                                label: 'Target Min (₹)',
                                hint: '48.30',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _benchmarkMaxController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(color: LiquidGlassColors.textPrimary),
                              decoration: _buildInputDeco(
                                label: 'Target Max (₹)',
                                hint: '48.50',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SAVE BUTTON FOR PRICING
                LiquidGlassButton(
                  label: 'SAVE CONFIGURATION',
                  icon: Icons.save,
                  glowColor: LiquidGlassColors.accentViolet,
                  onPressed: () => _saveConfiguration(adminProvider),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String label,
    required String hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary, fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 12),
      helperText: helper,
      helperStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 10),
      prefixText: '₹ ',
      prefixStyle: const TextStyle(
        color: LiquidGlassColors.accentEmerald,
        fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: LiquidGlassColors.accentViolet),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: LiquidGlassColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaOption({
    required BulkPricingFormula formula,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _bulkFormula == formula;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _bulkFormula = formula),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? LiquidGlassColors.accentViolet
                      : LiquidGlassColors.textMuted,
                  width: isSelected ? 5 : 2,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? LiquidGlassColors.textPrimary
                          : LiquidGlassColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: LiquidGlassColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfiguration(AdminProvider provider) async {
    final singlePrice =
        double.tryParse(_singleTicketController.text.trim()) ?? 50.0;
    final setPrice = double.tryParse(_setPriceController.text.trim()) ?? 570.0;
    final benchMin =
        double.tryParse(_benchmarkMinController.text.trim()) ?? 48.30;
    final benchMax =
        double.tryParse(_benchmarkMaxController.text.trim()) ?? 48.50;
    final claimed = double.tryParse(_claimedAvgController.text.trim()) ?? 47.20;

    final customTiers = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      final val = double.tryParse(_tierControllers[i]!.text.trim());
      if (val != null) {
        customTiers[i] = val;
      }
    }

    final newConfig = PricingConfig(
      singleTicketPrice: singlePrice,
      setPrice12: setPrice,
      customTierPrices: customTiers,
      bulkFormula: _bulkFormula,
      targetBenchmarkMin: benchMin,
      targetBenchmarkMax: benchMax,
      claimedAvgPrice: claimed,
    );

    if (_editingShopId != null) {
      await provider.updatePricing(_editingShopId!, newConfig);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pricing configuration saved successfully!'),
          backgroundColor: LiquidGlassColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: LiquidGlassColors.accentViolet.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
  }

  void _showChangePinDialog(AdminProvider provider) {
    final newPinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: LiquidGlassColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: LiquidGlassColors.glassBorderLight),
          ),
          title: const Text(
            'Change Admin PIN',
            style: TextStyle(color: LiquidGlassColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: newPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: LiquidGlassColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter new 4-digit PIN',
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: LiquidGlassColors.textSecondary)),
            ),
            LiquidGlassButton(
              label: 'Update PIN',
              glowColor: LiquidGlassColors.accentViolet,
              isFullWidth: false,
              height: 40,
              onPressed: () async {
                final pin = newPinController.text.trim();
                if (pin.length == 4) {
                  await provider.updatePin(pin);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Admin PIN updated successfully.'),
                          backgroundColor: LiquidGlassColors.surfaceElevated,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
