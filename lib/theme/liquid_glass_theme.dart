import 'package:flutter/material.dart';

class LiquidGlassColors {
  // Backgrounds
  static const Color background = Color(0xFF0C0E14);
  static const Color surfaceDark = Color(0xFF141721);
  static const Color surfaceElevated = Color(0xFF1B1F2C);

  // Glass Fills (Translucent)
  static final Color glassFillLight = Colors.white.withValues(alpha: 0.07);
  static final Color glassFillMedium = Colors.white.withValues(alpha: 0.10);
  static final Color glassFillStrong = Colors.white.withValues(alpha: 0.14);
  static final Color glassFillDark = const Color(0xFF1E2230).withValues(alpha: 0.70);

  // Glass Specular Borders (1px light sheen)
  static final Color glassBorderLight = Colors.white.withValues(alpha: 0.15);
  static final Color glassBorderGlow = Colors.white.withValues(alpha: 0.28);
  static final Color glassBorderSubtle = Colors.white.withValues(alpha: 0.08);

  // Luminous Accents
  static const Color accentEmerald = Color(0xFF10B981); // Primary Lottery Brand / Live
  static const Color accentTeal = Color(0xFF06B6D4); // Fresh highlight
  static const Color accentViolet = Color(0xFF8B5CF6); // Modern glow
  static const Color accentIndigo = Color(0xFF6366F1); // Action buttons
  static const Color accentRose = Color(0xFFF43F5E); // Warning / Deficit / Delete
  static const Color accentAmber = Color(0xFFF59E0B); // Caution / Pending

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textGlow = Color(0xFFE2E8F0);
}

class LiquidGlassTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LiquidGlassColors.background,
      colorScheme: const ColorScheme.dark(
        primary: LiquidGlassColors.accentEmerald,
        secondary: LiquidGlassColors.accentViolet,
        surface: LiquidGlassColors.surfaceDark,
        error: LiquidGlassColors.accentRose,
      ),
      fontFamily: null, // Uses system SF Pro / Roboto
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: LiquidGlassColors.glassFillMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LiquidGlassColors.glassBorderLight),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: LiquidGlassColors.glassBorderSubtle,
        thickness: 1,
      ),
    );
  }

  // Specular Border Gradient for Glass Cards
  static LinearGradient get borderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  // Active Neon Border Gradient
  static LinearGradient get activeBorderGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LiquidGlassColors.accentEmerald,
          LiquidGlassColors.accentTeal,
        ],
      );

  // Card Diffuse Glow Shadow
  static List<BoxShadow> get subtleGlowShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.05),
          blurRadius: 30,
          spreadRadius: 2,
        ),
      ];

  // Button Neon Glow Shadow
  static List<BoxShadow> neonGlow({
    Color color = LiquidGlassColors.accentEmerald,
    double intensity = 0.35,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
