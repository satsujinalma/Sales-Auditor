import 'package:flutter/material.dart';
import '../../theme/liquid_glass_theme.dart';

/// Ultra-smooth, 120 FPS High-Performance Light Glassmorphism Container
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
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
    this.borderRadius = 16,
    this.fillColor,
    this.border,
    this.shadows,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: LiquidGlassColors.glassBorderLight,
              width: 1.0,
            ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
      ),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null || isInteractive) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: LiquidGlassColors.accentEmerald.withValues(alpha: 0.1),
          highlightColor: Colors.black.withValues(alpha: 0.02),
          child: card,
        ),
      );
    }

    return card;
  }
}
