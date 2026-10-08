import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/glass/liquid_glass_button.dart';
import '../../widgets/glass/liquid_glass_container.dart';
import '../../widgets/glass/liquid_glow_background.dart';

class PendingApprovalScreen extends StatefulWidget {
  final AppUser user;

  const PendingApprovalScreen({
    super.key,
    required this.user,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds for instant reaction when admin approves
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkApprovalStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApprovalStatus() async {
    if (!mounted || _isChecking) return;
    setState(() => _isChecking = true);
    await context.read<AuthProvider>().refreshCurrentUser();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser ?? widget.user;
    final isRejected = currentUser.approvalStatus == ApprovalStatus.rejected;

    return Scaffold(
      backgroundColor: LiquidGlassColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glowing Pulsing Security Shield Icon
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRejected
                              ? [
                                  LiquidGlassColors.accentRose,
                                  const Color(0xFFBE123C),
                                ]
                              : [
                                  LiquidGlassColors.accentAmber,
                                  const Color(0xFFB45309),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: LiquidGlassTheme.neonGlow(
                          color: isRejected
                              ? LiquidGlassColors.accentRose
                              : LiquidGlassColors.accentAmber,
                          intensity: 0.35,
                        ),
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.block_flipped
                            : Icons.hourglass_top_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    isRejected
                        ? 'ACCESS REQUEST REJECTED'
                        : 'ACCESS PENDING APPROVAL',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: LiquidGlassColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isRejected
                        ? 'Your access request to this counter was denied by the Admin. Please contact the administrator.'
                        : 'Your counter terminal request has been sent to the Central Admin for verification.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: LiquidGlassColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Staff & Counter Details Card
                  LiquidGlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'REQUEST DETAILS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: LiquidGlassColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isRejected
                                    ? LiquidGlassColors.accentRose.withValues(alpha: 0.18)
                                    : LiquidGlassColors.accentAmber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isRejected
                                      ? LiquidGlassColors.accentRose.withValues(alpha: 0.40)
                                      : LiquidGlassColors.accentAmber.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Text(
                                isRejected ? 'REJECTED' : 'PENDING APPROVAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isRejected
                                      ? LiquidGlassColors.accentRose
                                      : LiquidGlassColors.accentAmber,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Staff Name',
                          value: currentUser.name,
                        ),
                        const SizedBox(height: 10),

                        _buildInfoRow(
                          icon: Icons.phone_android_outlined,
                          label: 'Phone Number',
                          value: currentUser.phoneNumber,
                        ),
                        const SizedBox(height: 10),

                        _buildInfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Requested Counter / Shop',
                          value: currentUser.shopName ??
                              currentUser.shopId ??
                              'Retail Counter',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LiquidGlassColors.glassFillMedium,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: LiquidGlassColors.glassBorderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isRejected
                              ? LiquidGlassColors.accentRose
                              : LiquidGlassColors.accentTeal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isRejected
                                ? 'Please switch account or request permission from the shop owner.'
                                : 'As soon as the Admin approves your account from the Head App, your sales terminal will unlock automatically.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: LiquidGlassColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions: Refresh & Sign Out
                  if (!isRejected) ...[
                    LiquidGlassButton(
                      label: _isChecking
                          ? 'CHECKING STATUS...'
                          : 'CHECK APPROVAL STATUS',
                      icon: Icons.refresh_rounded,
                      glowColor: LiquidGlassColors.accentEmerald,
                      isLoading: _isChecking,
                      onPressed: _checkApprovalStatus,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextButton.icon(
                    icon: const Icon(Icons.logout, size: 16, color: LiquidGlassColors.textSecondary),
                    label: const Text(
                      'Sign Out / Switch Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LiquidGlassColors.textSecondary,
                      ),
                    ),
                    onPressed: () => authProvider.signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: LiquidGlassColors.glassFillLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LiquidGlassColors.glassBorderSubtle),
          ),
          child: Icon(icon, size: 16, color: LiquidGlassColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LiquidGlassColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
