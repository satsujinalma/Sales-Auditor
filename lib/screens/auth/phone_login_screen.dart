import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  int _selectedTab = 0; // 0: Shopkeeper, 1: Admin

  // Shopkeeper Login controllers
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopkeeperFormKey = GlobalKey<FormState>();

  // Admin Login controllers
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminFormKey = GlobalKey<FormState>();
  bool _obscureAdminPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: LiquidGlassColors.background,
      body: LiquidGlowBackground(
        primaryGlow: _selectedTab == 0
            ? LiquidGlassColors.accentEmerald
            : LiquidGlassColors.accentViolet,
        secondaryGlow: const Color(0xFF6366F1),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem & Header
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selectedTab == 0
                              ? [
                                  LiquidGlassColors.accentEmerald,
                                  LiquidGlassColors.accentTeal,
                                ]
                              : [
                                  LiquidGlassColors.accentViolet,
                                  LiquidGlassColors.accentIndigo,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: LiquidGlassTheme.neonGlow(
                          color: _selectedTab == 0
                              ? LiquidGlassColors.accentEmerald
                              : LiquidGlassColors.accentViolet,
                        ),
                      ),
                      child: Icon(
                        _selectedTab == 0
                            ? Icons.confirmation_number_rounded
                            : Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'SALES AUDIT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kerala Lottery Real-Time Sales & Audit Tracking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: LiquidGlassColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mode Segmented Switcher
                  LiquidGlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedTab != 0) {
                                setState(() => _selectedTab = 0);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? LiquidGlassColors.accentEmerald.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedTab == 0
                                    ? Border.all(
                                        color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.6),
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront,
                                    size: 16,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : LiquidGlassColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Shopkeeper Login',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : LiquidGlassColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedTab != 1) {
                                setState(() => _selectedTab = 1);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? LiquidGlassColors.accentViolet.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedTab == 1
                                    ? Border.all(
                                        color: LiquidGlassColors.accentViolet.withValues(alpha: 0.6),
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : LiquidGlassColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : LiquidGlassColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Form Card depending on selected tab
                  if (_selectedTab == 0)
                    _buildShopkeeperLoginForm(context, authProvider)
                  else
                    _buildAdminCredentialsForm(context, authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopkeeperLoginForm(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Form(
      key: _shopkeeperFormKey,
      child: LiquidGlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shopkeeper Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LiquidGlassColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your name to open and operate your sales terminal.',
              style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Name TextField (Required)
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Shopkeeper Name',
                hintText: 'Enter your name',
                icon: Icons.person_outline_rounded,
                accentColor: LiquidGlassColors.accentEmerald,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Shop / Counter Name (Optional)
            TextFormField(
              controller: _shopNameController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Shop / Counter Name (Optional)',
                hintText: 'e.g. Nayarambalam Store',
                icon: Icons.storefront_outlined,
                accentColor: LiquidGlassColors.accentEmerald,
              ),
            ),

            const SizedBox(height: 14),

            // Mobile Number (Optional)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Mobile Number (Optional)',
                hintText: 'Enter 10-digit number',
                icon: Icons.phone_android_outlined,
                accentColor: LiquidGlassColors.accentEmerald,
              ),
            ),

            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: LiquidGlassColors.accentRose.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: LiquidGlassColors.accentRose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LiquidGlassColors.accentRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Enter Terminal Button
            LiquidGlassButton(
              label: 'ENTER SALES TERMINAL',
              icon: Icons.arrow_forward,
              glowColor: LiquidGlassColors.accentEmerald,
              isLoading: authProvider.isLoggingIn,
              onPressed: authProvider.isLoggingIn
                  ? null
                  : () => _handleShopkeeperLogin(authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCredentialsForm(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Form(
      key: _adminFormKey,
      child: LiquidGlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Direct Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LiquidGlassColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sign in with Admin username & password to access audit dashboard & multi-shop monitor.',
                        style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: LiquidGlassColors.accentViolet.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: LiquidGlassColors.accentViolet.withValues(alpha: 0.40),
                    ),
                  ),
                  child: const Text(
                    'AUDITOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: LiquidGlassColors.accentViolet,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Username Field
            TextFormField(
              controller: _adminUsernameController,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Admin Username',
                hintText: 'Enter username',
                icon: Icons.person_outline_rounded,
                accentColor: LiquidGlassColors.accentViolet,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter admin username';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Password Field
            TextFormField(
              controller: _adminPasswordController,
              obscureText: _obscureAdminPassword,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Admin Password',
                hintText: 'Enter password',
                icon: Icons.lock_outline_rounded,
                accentColor: LiquidGlassColors.accentViolet,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureAdminPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: LiquidGlassColors.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureAdminPassword = !_obscureAdminPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter admin password';
                }
                return null;
              },
            ),

            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: LiquidGlassColors.accentRose.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: LiquidGlassColors.accentRose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LiquidGlassColors.accentRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Sign In Button
            LiquidGlassButton(
              label: 'SIGN IN AS ADMIN',
              icon: Icons.shield,
              glowColor: LiquidGlassColors.accentViolet,
              isLoading: authProvider.isLoggingInAsAdmin,
              onPressed: authProvider.isLoggingInAsAdmin
                  ? null
                  : () => _handleAdminLogin(authProvider),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    required Color accentColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary, fontSize: 13),
      hintText: hintText,
      hintStyle: const TextStyle(color: LiquidGlassColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      suffixIcon: suffixIcon,
      counterText: '',
      filled: true,
      fillColor: LiquidGlassColors.glassFillLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiquidGlassColors.accentRose),
      ),
    );
  }

  void _handleShopkeeperLogin(AuthProvider authProvider) async {
    if (!_shopkeeperFormKey.currentState!.validate()) return;

    await authProvider.loginAsShopkeeper(
      name: _nameController.text.trim(),
      shopName: _shopNameController.text.trim().isNotEmpty
          ? _shopNameController.text.trim()
          : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );
  }

  void _handleAdminLogin(AuthProvider authProvider) async {
    if (!_adminFormKey.currentState!.validate()) return;

    await authProvider.loginWithAdminCredentials(
      _adminUsernameController.text.trim(),
      _adminPasswordController.text.trim(),
    );
  }
}
