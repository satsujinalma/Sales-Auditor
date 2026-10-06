import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/liquid_glass_theme.dart';

/// Glowing liquid glass pill button with tactile scale animation & haptics
class LiquidGlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color glowColor;
  final Color textColor;
  final bool isFullWidth;
  final double height;
  final bool isLoading;
  final bool isSecondary;

  const LiquidGlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.glowColor = LiquidGlassColors.accentEmerald,
    this.textColor = Colors.white,
    this.isFullWidth = true,
    this.height = 50,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.reverse();
    }
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        gradient: widget.isSecondary
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEnabled
                    ? [
                        widget.glowColor,
                        widget.glowColor.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ],
              ),
        border: Border.all(
          color: widget.isSecondary
              ? LiquidGlassColors.glassBorderLight
              : Colors.white.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: isEnabled && !widget.isSecondary
            ? LiquidGlassTheme.neonGlow(color: widget.glowColor)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize:
                    widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: widget.textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
      ),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.isFullWidth
            ? SizedBox(width: double.infinity, child: buttonBody)
            : buttonBody,
      ),
    );
  }
}
