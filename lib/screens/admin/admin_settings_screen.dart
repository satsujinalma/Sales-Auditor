import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pricing_config.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

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

  // Admin credentials controllers
  late TextEditingController _adminUsernameController;
  late TextEditingController _adminPasswordController;
  bool _obscureCredPassword = true;
  bool _isSavingCreds = false;

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

    _adminUsernameController = TextEditingController(text: 'admin');
    _adminPasswordController = TextEditingController(text: 'vazhapazhamadmin@321');

    for (int i = 1; i <= 12; i++) {
      _tierControllers[i] = TextEditingController();
    }

    _loadShopValues(adminProvider);
    _loadAdminCredentials();
  }

  void _loadAdminCredentials() async {
    final authProvider = context.read<AuthProvider>();
    final creds = await authProvider.getAdminCredentials();
    if (mounted) {
      setState(() {
        _adminUsernameController.text = creds['username'] ?? 'admin';
        _adminPasswordController.text =
            creds['password'] ?? 'vazhapazhamadmin@321';
      });
    }
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
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Pricing & Audit Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
            icon: const Icon(Icons.lock_open, color: Colors.white70),
            onPressed: () {
              adminProvider.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SHOP SELECTOR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONFIGURING PRICING FOR SHOP:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      initialValue: _editingShopId,
                      items: shops.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (${s.code})'),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _singleTicketController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Single Ticket (₹)',
                              hintText: '50',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _setPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '1 Set (12 Tkts) (₹)',
                              hintText: '570 / 580',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                              helperText: 'e.g. ₹570 Nayarambalam',
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildFormulaOption(
                      formula: BulkPricingFormula.proRata,
                      title: 'Pro-Rata Established Average Rate (Recommended)',
                      subtitle:
                          'Price = Quantity × (Set Price ÷ 12). For example, 15 tickets @ ₹47.50 = ₹712.50',
                    ),
                    const Divider(height: 16),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure exact price for quantities from 1 to 12 tickets:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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
                          decoration: InputDecoration(
                            labelText: count == 12 ? '12 (1 Set)' : '$count Tkt',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            prefixText: '₹',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
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
                            decoration: const InputDecoration(
                              labelText: 'Shopkeeper Claim (₹)',
                              hintText: '47.20',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _benchmarkMinController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Target Min (₹)',
                              hintText: '48.30',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _benchmarkMaxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Target Max (₹)',
                              hintText: '48.50',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'SAVE CONFIGURATION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () => _saveConfiguration(adminProvider),
              ),

              const SizedBox(height: 28),

              // SECTION 5: MASTER ADMIN CREDENTIALS (CLOUD PERSISTED)
              _buildSectionHeader(
                '5. MASTER ADMIN LOGIN CREDENTIALS (CLOUD SYNC)',
                Icons.admin_panel_settings,
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direct Login Credentials (No Phone / OTP Required)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Anyone with this username & password can sign in as Admin. Saved in Firebase Cloud Firestore (settings/admin_credentials).',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _adminUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Username',
                        hintText: 'admin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminPasswordController,
                      obscureText: _obscureCredPassword,
                      decoration: InputDecoration(
                        labelText: 'Admin Password',
                        hintText: 'vazhapazhamadmin@321',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCredPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCredPassword = !_obscureCredPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isSavingCreds
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(
                          _isSavingCreds
                              ? 'UPDATING CLOUD...'
                              : 'UPDATE ADMIN CREDENTIALS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: _isSavingCreds
                            ? null
                            : () => _saveAdminCredentials(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.black54,
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
                  color: isSelected ? const Color(0xFF0F766E) : Colors.grey,
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
                      color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
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
        const SnackBar(
          content: Text('Pricing configuration saved successfully!'),
          backgroundColor: Color(0xFF0F766E),
        ),
      );
    }
  }

  void _saveAdminCredentials() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username and password cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingCreds = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateAdminCredentials(
      username: username,
      password: password,
    );

    if (mounted) {
      setState(() => _isSavingCreds = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Master Admin credentials updated and synced to Cloud Firestore!',
            ),
            backgroundColor: Color(0xFF1E293B),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update credentials.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePinDialog(AdminProvider provider) {
    final newPinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Admin PIN'),
          content: TextField(
            controller: newPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter new 4-digit PIN',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final pin = newPinController.text.trim();
                if (pin.length == 4) {
                  await provider.updatePin(pin);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin PIN updated successfully.'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Update PIN'),
            ),
          ],
        );
      },
    );
  }
}
