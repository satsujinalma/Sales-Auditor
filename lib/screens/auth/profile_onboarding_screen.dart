import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/pricing_config.dart';
import '../../models/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        elevation: 2,
        title: const Text(
          'Store & Profile Setup',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Color(0xFF4ADE80),
                          size: 26,
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
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentUser?.phoneNumber ?? 'Mobile Verified',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Configure your store profile to begin live sales tracking.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. PERSONAL DETAILS
                _buildSectionHeader('1. SHOPKEEPER DETAILS', Icons.person),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Shopkeeper Name',
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. STORE DETAILS
                _buildSectionHeader(
                  '2. STORE DETAILS',
                  Icons.store,
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
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          hintText: 'Enter shop name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter shop name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. PRICING CONFIGURATION FOR THIS SHOP
                _buildSectionHeader(
                  '3. SHOP PRICING STRUCTURE (KERALA LOTTERY)',
                  Icons.currency_rupee,
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
                        'Configure the base rate and 1-Set (12 tickets) discount for this shop:',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _singleTicketPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '1 Ticket MRP (₹)',
                                hintText: '50',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _setPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '1 Set (12 Tkts) (₹)',
                                hintText: '570',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                                helperText: 'Discounted set rate',
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
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildFormulaChoice(
                        formula: BulkPricingFormula.proRata,
                        title: 'Pro-Rata Set Rate (Recommended)',
                        description:
                            'Price = Qty × (Set Price ÷ 12). e.g., 15 tickets @ ₹47.50 = ₹712.50',
                      ),
                      const Divider(height: 14),
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
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      authProvider.isLoading
                          ? 'SAVING SETUP...'
                          : 'COMPLETE & ENTER SALES TERMINAL',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleSubmit(authProvider),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
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
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? const Color(0xFF0F766E) : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
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
