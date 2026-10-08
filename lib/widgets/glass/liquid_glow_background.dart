import 'package:flutter/material.dart';
import '../../theme/liquid_glass_theme.dart';

/// High-performance Light Ambient Glow Background (60/120 FPS optimized with RepaintBoundary)
class LiquidGlowBackground extends StatelessWidget {
  final Widget child;
  final Color primaryGlow;
  final Color secondaryGlow;

  const LiquidGlowBackground({
    super.key,
    required this.child,
    this.primaryGlow = const Color(0xFFCCFBF1), // Soft Emerald/Teal pastel orb
    this.secondaryGlow = const Color(0xFFEDE9FE), // Soft Violet/Purple pastel orb
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiquidGlassColors.background,
      child: Stack(
        children: [
          // RepaintBoundary isolates background rendering so scrolling content never triggers background repaints
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  // Ambient Glow Orb 1 (Top Right - Soft Violet)
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryGlow.withValues(alpha: 0.8),
                            secondaryGlow.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Glow Orb 2 (Middle Left - Soft Emerald/Teal)
                  Positioned(
                    top: 220,
                    left: -70,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryGlow.withValues(alpha: 0.85),
                            primaryGlow.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Glow Orb 3 (Bottom Center - Subtle Cyan/Sky)
                  Positioned(
                    bottom: -60,
                    left: MediaQuery.of(context).size.width * 0.2,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE0F2FE).withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Screen Content
          child,
        ],
      ),
    );
  }
}
