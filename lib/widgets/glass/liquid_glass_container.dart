import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/liquid_glass_theme.dart';

/// Glassmorphism container with backdrop blur, specular gradient border, and optional glow
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? fillColor;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool isInteractive;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.blurSigma = 16,
    this.fillColor,
    this.border,
    this.shadows,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor ?? LiquidGlassColors.glassFillMedium,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: LiquidGlassColors.glassBorderLight,
              width: 1.0,
            ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: child,
    );

    // Apply BackdropFilter for realistic frosted glass
    Widget glassCard = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );

    if (margin != null) {
      glassCard = Padding(padding: margin!, child: glassCard);
    }

    if (onTap != null || isInteractive) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: LiquidGlassColors.accentEmerald.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: glassCard,
      );
    }

    return glassCard;
  }
}
