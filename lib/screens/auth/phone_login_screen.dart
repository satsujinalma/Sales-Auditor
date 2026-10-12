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
  bool _isAdminView = false;

  // Staff Login controllers
  final _nameController = TextEditingController();
  final _shopCodeController = TextEditingController();
  final _shopkeeperFormKey = GlobalKey<FormState>();

  // Admin Login controllers
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminFormKey = GlobalKey<FormState>();
  bool _obscureAdminPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _shopCodeController.dispose();
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
        child: SafeArea(
          child: Stack(
            children: [
              // Main Scrollable Content
              Center(
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
                              colors: !_isAdminView
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
                              color: !_isAdminView
                                  ? LiquidGlassColors.accentEmerald
                                  : LiquidGlassColors.accentViolet,
                            ),
                          ),
                          child: Icon(
                            !_isAdminView
                                ? Icons.confirmation_number_rounded
                                : Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        !_isAdminView ? 'SALES AUDIT' : 'HEAD AUDITOR',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: LiquidGlassColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !_isAdminView
                            ? 'Kerala Lottery Real-Time Sales & Audit Tracking'
                            : 'Central Administration & Multi-Counter Monitor',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Card depending on selected view
                      if (!_isAdminView)
                        _buildStaffLoginForm(context, authProvider)
                      else
                        _buildAdminCredentialsForm(context, authProvider),
                    ],
                  ),
                ),
              ),

              // Small Admin Shield Symbol on the Top-Right Side
              Positioned(
                top: 8,
                right: 14,
                child: Tooltip(
                  message: _isAdminView ? 'Back to Staff Login' : 'Admin Login',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('admin_shield_button'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _isAdminView = !_isAdminView;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAdminView
                              ? LiquidGlassColors.accentViolet.withValues(alpha: 0.18)
                              : LiquidGlassColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAdminView
                                ? LiquidGlassColors.accentViolet.withValues(alpha: 0.45)
                                : LiquidGlassColors.glassBorderLight,
                            width: 1.2,
                          ),
                          boxShadow: _isAdminView
                              ? LiquidGlassTheme.neonGlow(
                                  color: LiquidGlassColors.accentViolet,
                                  intensity: 0.20,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAdminView
                                  ? Icons.arrow_back_rounded
                                  : Icons.shield_outlined,
                              size: 18,
                              color: _isAdminView
                                  ? LiquidGlassColors.accentViolet
                                  : LiquidGlassColors.textSecondary,
                            ),
                            if (_isAdminView) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'Staff',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: LiquidGlassColors.accentViolet,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffLoginForm(
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
              'Staff Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LiquidGlassColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your username and shop code to connect to your sales counter.',
              style: TextStyle(fontSize: 12, color: LiquidGlassColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // 1. Staff Username (Required)
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
                labelText: 'Staff Username',
                hintText: 'Enter your username / name',
                icon: Icons.person_outline_rounded,
                accentColor: LiquidGlassColors.accentEmerald,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter staff username';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // 2. Shop Code (Required)
            TextFormField(
              controller: _shopCodeController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: LiquidGlassColors.textPrimary,
              ),
              decoration: _buildInputDecoration(
                labelText: 'Shop Code',
                hintText: 'e.g. KDLR, THIRU',
                icon: Icons.vpn_key_rounded,
                accentColor: LiquidGlassColors.accentEmerald,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter shop code';
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

            // Enter Sales Button
            LiquidGlassButton(
              label: 'ENTER SALES',
              icon: Icons.arrow_forward,
              glowColor: LiquidGlassColors.accentEmerald,
              isLoading: authProvider.isLoggingIn,
              onPressed: authProvider.isLoggingIn
                  ? null
                  : () => _handleShopkeeperLogin(authProvider),
            ),

            const SizedBox(height: 14),

            // Quick Mock Staff Access
            InkWell(
              onTap: () {
                _nameController.text = 'admin';
                authProvider.loginWithAdminCredentials(
                  'admin',
                  'admin123',
                  asStaffUser: true,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: LiquidGlassColors.accentEmerald,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Mock User: admin / admin123 (Direct Access)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: LiquidGlassColors.accentEmerald,
                      ),
                    ),
                  ],
                ),
              ),
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
            const SizedBox(height: 12),

            // Mock User Notice & Auto-fill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LiquidGlassColors.accentTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: LiquidGlassColors.accentTeal.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: LiquidGlassColors.accentTeal,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mock User: username = admin, password = admin123\nDirectly enter Users section without admin approval.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: LiquidGlassColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _adminUsernameController.text = 'admin';
                      _adminPasswordController.text = 'admin123';
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Auto-fill',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: LiquidGlassColors.accentTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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

            // Button 1: LOGIN TO USER SECTION (Direct access to sales terminal without approval)
            LiquidGlassButton(
              label: 'LOGIN TO USER SECTION',
              icon: Icons.storefront_rounded,
              glowColor: LiquidGlassColors.accentEmerald,
              isLoading: authProvider.isLoggingInAsAdmin,
              onPressed: authProvider.isLoggingInAsAdmin
                  ? null
                  : () => _handleAdminLogin(authProvider, asStaffUser: true),
            ),

            const SizedBox(height: 12),

            // Button 2: SIGN IN AS ADMIN (Admin Dashboard)
            LiquidGlassButton(
              label: 'SIGN IN AS ADMIN',
              icon: Icons.shield,
              glowColor: LiquidGlassColors.accentViolet,
              isLoading: authProvider.isLoggingInAsAdmin,
              onPressed: authProvider.isLoggingInAsAdmin
                  ? null
                  : () => _handleAdminLogin(authProvider, asStaffUser: false),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _isAdminView = false);
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 15,
                  color: LiquidGlassColors.textSecondary,
                ),
                label: const Text(
                  'Back to Staff Login',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: LiquidGlassColors.textSecondary,
                  ),
                ),
              ),
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

    final name = _nameController.text.trim();
    if (name.toLowerCase() == 'admin') {
      await authProvider.loginWithAdminCredentials(
        'admin',
        'admin123',
        asStaffUser: true,
      );
      return;
    }

    final shopCode = _shopCodeController.text.trim().toUpperCase();

    await authProvider.loginAsShopkeeper(
      name: name,
      shopCode: shopCode,
    );
  }

  void _handleAdminLogin(AuthProvider authProvider, {bool asStaffUser = false}) async {
    if (!_adminFormKey.currentState!.validate()) return;

    await authProvider.loginWithAdminCredentials(
      _adminUsernameController.text.trim(),
      _adminPasswordController.text.trim(),
      asStaffUser: asStaffUser,
    );
  }
}
