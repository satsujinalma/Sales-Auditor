import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/liquid_glass_theme.dart';

/// Full-screen ambient atmospheric background with glowing light orbs
class LiquidGlowBackground extends StatelessWidget {
  final Widget child;
  final Color primaryGlow;
  final Color secondaryGlow;

  const LiquidGlowBackground({
    super.key,
    required this.child,
    this.primaryGlow = const Color(0xFF0F766E), // Emerald/teal lottery glow
    this.secondaryGlow = const Color(0xFF7C3AED), // Violet ambient glow
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiquidGlassColors.background,
      child: Stack(
        children: [
          // Ambient Glow Orb 1 (Top Right / Center - Violet)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryGlow.withValues(alpha: 0.18),
                    secondaryGlow.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ambient Glow Orb 2 (Middle Left - Emerald/Teal)
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGlow.withValues(alpha: 0.15),
                    primaryGlow.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ambient Glow Orb 3 (Bottom Center - Subtle Cyan/Teal)
          Positioned(
            bottom: -80,
            left: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LiquidGlassColors.accentTeal.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blur diffusion layer over background orbs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox.expand(),
            ),
          ),

          // Actual Screen Content
          child,
        ],
      ),
    );
  }
}
