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
    // Cohesive slate / titanium ambient tones with high diffusion and gentle falloff
    final topGlow = secondaryGlow ?? const Color(0xFFCBD5E1); // Soft Titanium Slate mist
    final midGlow = primaryGlow ?? Colors.white; // Soft Specular White ambient glow
    const bottomGlow = Color(0xFFD5DBE2); // Neutral Cool Grey mist

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAEEF3), // Clean cool grey
            Color(0xFFE2E8F0), // Modern slate grey
            Color(0xFFDCE2EA), // Balanced neutral grey base
          ],
          stops: [0.0, 0.50, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // RepaintBoundary isolates ambient background fields so scrolling content never triggers background repaints
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  // Ambient Diffuse Field 1 (Top Right - Soft Titanium Slate)
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
                            topGlow.withValues(alpha: 0.40),
                            topGlow.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Diffuse Field 2 (Middle Left - Specular White Highlight)
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
                            midGlow.withValues(alpha: 0.50),
                            midGlow.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.50, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Ambient Diffuse Field 3 (Bottom Center-Right - Neutral Cool Grey)
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
                            bottomGlow.withValues(alpha: 0.40),
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
