import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/pricing_config.dart';
import '../../models/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shopkeeper Personal Field
  final _nameController = TextEditingController();

  // Shop Details Fields
  final _shopNameController = TextEditingController();
  final _singleTicketPriceController = TextEditingController(text: '50');
  final _setPriceController = TextEditingController(text: '570');
  final _claimedAvgController = TextEditingController(text: '47.20');
  BulkPricingFormula _bulkFormula = BulkPricingFormula.proRata;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _singleTicketPriceController.dispose();
    _setPriceController.dispose();
    _claimedAvgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: LiquidGlassColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Store & Profile Setup',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: LiquidGlassColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: LiquidGlassColors.textMuted, size: 20),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: LiquidGlowBackground(
        primaryGlow: LiquidGlassColors.accentEmerald,
        secondaryGlow: LiquidGlassColors.accentViolet,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Banner
                  LiquidGlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    fillColor: LiquidGlassColors.accentEmerald.withValues(alpha: 0.12),
                    border: Border.all(
                      color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.35),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.accentEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FIRST TIME SHOP SETUP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: LiquidGlassColors.accentEmerald,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentUser?.phoneNumber ?? 'Mobile Verified',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: LiquidGlassColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Configure your store profile to begin live sales tracking.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: LiquidGlassColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 1. PERSONAL DETAILS
                  _buildSectionHeader('1. SHOPKEEPER DETAILS', Icons.person_outline),
                  LiquidGlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LiquidGlassColors.textPrimary,
                      ),
                      decoration: _buildInputDeco(
                        label: 'Shopkeeper Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. STORE DETAILS
                  _buildSectionHeader('2. STORE DETAILS', Icons.storefront_outlined),
                  LiquidGlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: TextFormField(
                      controller: _shopNameController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LiquidGlassColors.textPrimary,
                      ),
                      decoration: _buildInputDeco(
                        label: 'Shop Name',
                        hint: 'e.g. Nayarambalam Counter',
                        icon: Icons.storefront_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter shop name';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. PRICING CONFIGURATION FOR THIS SHOP
                  _buildSectionHeader(
                    '3. SHOP PRICING STRUCTURE (KERALA LOTTERY)',
                    Icons.currency_rupee,
                  ),
                  LiquidGlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configure the base rate and 1-Set (12 tickets) discount for this shop:',
                          style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _singleTicketPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.textPrimary,
                                ),
                                decoration: _buildInputDeco(
                                  label: '1 Ticket MRP (₹)',
                                  hint: '50',
                                  prefixText: '₹ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _setPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.textPrimary,
                                ),
                                decoration: _buildInputDeco(
                                  label: '1 Set (12 Tkts) (₹)',
                                  hint: '570',
                                  prefixText: '₹ ',
                                  helper: 'Discounted set rate',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Formula for transactions > 12 tickets:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: LiquidGlassColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildFormulaChoice(
                          formula: BulkPricingFormula.proRata,
                          title: 'Pro-Rata Set Rate (Recommended)',
                          description:
                              'Price = Qty × (Set Price ÷ 12). e.g., 15 tickets @ ₹47.50 = ₹712.50',
                        ),
                        const Divider(height: 14, color: LiquidGlassColors.glassBorderLight),
                        _buildFormulaChoice(
                          formula: BulkPricingFormula.setPlusRemainder,
                          title: 'Bundled Sets + Remainder',
                          description:
                              'Price = (Sets × Set Rate) + (Remainder × Single Rate)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SUBMIT BUTTON
                  LiquidGlassButton(
                    label: 'COMPLETE & ENTER SALES TERMINAL',
                    icon: Icons.check_circle_outline,
                    glowColor: LiquidGlassColors.accentEmerald,
                    isLoading: authProvider.isLoading,
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleSubmit(authProvider),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String label,
    required String hint,
    IconData? icon,
    String? prefixText,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary, fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 12),
      helperText: helper,
      helperStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 10),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: LiquidGlassColors.accentEmerald,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: icon != null ? Icon(icon, color: LiquidGlassColors.accentEmerald, size: 20) : null,
      filled: true,
      fillColor: LiquidGlassColors.glassFillMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LiquidGlassColors.glassBorderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LiquidGlassColors.glassBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LiquidGlassColors.accentEmerald, width: 1.5),
      ),
    );
  }

  Widget _buildFormulaChoice({
    required BulkPricingFormula formula,
    required String title,
    required String description,
  }) {
    final isSelected = _bulkFormula == formula;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _bulkFormula = formula),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? LiquidGlassColors.accentEmerald
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
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? LiquidGlassColors.accentEmerald
                          : LiquidGlassColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: LiquidGlassColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: LiquidGlassColors.accentEmerald),
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

  void _handleSubmit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final singlePrice =
        double.tryParse(_singleTicketPriceController.text.trim()) ?? 50.0;
    final setPrice =
        double.tryParse(_setPriceController.text.trim()) ?? 570.0;
    final claimedAvg =
        double.tryParse(_claimedAvgController.text.trim()) ?? 47.20;

    final shopName = _shopNameController.text.trim();
    final sanitizedId = shopName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '_',
        );
    final shopId = sanitizedId.isNotEmpty
        ? sanitizedId
        : 'shop_${DateTime.now().millisecondsSinceEpoch}';

    final alphaCode = shopName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final cleanCode = alphaCode.length > 6
        ? alphaCode.substring(0, 6)
        : (alphaCode.isNotEmpty ? alphaCode : 'SHOP');

    final newShop = Shop(
      id: shopId,
      name: shopName,
      location: shopName,
      code: cleanCode,
      pricingConfig: PricingConfig(
        singleTicketPrice: singlePrice,
        setPrice12: setPrice,
        bulkFormula: _bulkFormula,
        claimedAvgPrice: claimedAvg,
      ),
    );

    final success = await authProvider.completeOnboarding(
      name: _nameController.text.trim(),
      role: UserRole.shopkeeper,
      initialShop: newShop,
    );

    if (success && mounted) {
      // Select the newly registered shop in SalesProvider
      context.read<SalesProvider>().selectShop(newShop.id);
    }
  }
}
