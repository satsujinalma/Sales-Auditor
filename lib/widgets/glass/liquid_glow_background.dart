import 'package:flutter/material.dart';

/// Ultra-smooth Pearlescent Ambient Gradient Background for Liquid Glass Light UI
class LiquidGlowBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryGlow;
  final Color? secondaryGlow;

  const LiquidGlowBackground({
    super.key,
    required this.child,
    this.primaryGlow,
    this.secondaryGlow,
  });

  @override
  Widget build(BuildContext context) {
    // Soft pastel ambient tones with high diffusion and gentle falloff
    final topGlow = secondaryGlow ?? const Color(0xFFDDD6FE); // Soft Lilac/Lavender mist
    final midGlow = primaryGlow ?? const Color(0xFF99F6E4); // Soft Aquamarine/Seafoam mist
    const bottomGlow = Color(0xFFBAE6FD); // Soft Ice Sky mist

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F5F9), // Soft Slate 100
            Color(0xFFE8EEF5), // Arctic Pearl
            Color(0xFFEDE9FE), // Soft Lavender haze
            Color(0xFFE0F2FE), // Soft Ice Azure haze
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // RepaintBoundary isolates ambient background fields so scrolling content never triggers background repaints
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  // Ambient Diffuse Field 1 (Top Right - Soft Lavender / Iris)
                  Positioned(
                    top: -100,
                    right: -80,
                    child: Container(
                      width: 440,
                      height: 440,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            topGlow.withValues(alpha: 0.35),
                            topGlow.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Diffuse Field 2 (Middle Left - Soft Aquamarine / Seafoam)
                  Positioned(
                    top: 240,
                    left: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            midGlow.withValues(alpha: 0.30),
                            midGlow.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.50, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Diffuse Field 3 (Bottom Center-Right - Soft Ice Azure)
                  Positioned(
                    bottom: -100,
                    right: -60,
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            bottomGlow.withValues(alpha: 0.35),
                            bottomGlow.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
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
