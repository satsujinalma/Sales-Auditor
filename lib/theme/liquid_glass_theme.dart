import 'package:flutter/material.dart';

class LiquidGlassColors {
  // Light Mode Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceCard = Color(0xFFF8FAFC);

  // Light Glass Fills (Translucent White / Pearlescent)
  static final Color glassFillLight = Colors.white.withValues(alpha: 0.70);
  static final Color glassFillMedium = Colors.white.withValues(alpha: 0.85);
  static final Color glassFillStrong = Colors.white.withValues(alpha: 0.95);
  static final Color glassFillTintedEmerald = const Color(0xFFF0FDF4).withValues(alpha: 0.90);

  // Glass Specular Borders (1px light sheen on light mode)
  static const Color glassBorderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color glassBorderGlow = Color(0xFFCBD5E1); // Slate 300
  static const Color glassBorderSubtle = Color(0xFFF1F5F9); // Slate 100
  static final Color glassBorderWhite = Colors.white.withValues(alpha: 0.9);

  // Vibrant Brand & Lottery Accents
  static const Color accentEmerald = Color(0xFF0F766E); // Deep Teal / Emerald
  static const Color accentEmeraldBright = Color(0xFF10B981); // Bright Emerald
  static const Color accentTeal = Color(0xFF0D9488); // Teal
  static const Color accentCyan = Color(0xFF0284C7); // Cyan
  static const Color accentViolet = Color(0xFF7C3AED); // Modern Violet
  static const Color accentIndigo = Color(0xFF4F46E5); // Indigo
  static const Color accentRose = Color(0xFFE11D48); // Warning / Deficit / Delete
  static const Color accentAmber = Color(0xFFD97706); // Caution / Pending

  // High-Contrast Light Mode Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textGlow = Color(0xFF1E293B); // Slate 800
}

class LiquidGlassTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LiquidGlassColors.background,
      colorScheme: const ColorScheme.light(
        primary: LiquidGlassColors.accentEmerald,
        secondary: LiquidGlassColors.accentViolet,
        surface: LiquidGlassColors.surfaceLight,
        error: LiquidGlassColors.accentRose,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: LiquidGlassColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: LiquidGlassColors.glassFillMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LiquidGlassColors.glassBorderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LiquidGlassColors.glassBorderLight,
        thickness: 1,
      ),
    );
  }

  // Specular Border Gradient for Glass Cards
  static LinearGradient get borderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
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

  // Ultra-Smooth Glass Shadows (60/120 FPS Optimized)
  static List<BoxShadow> get subtleGlowShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: LiquidGlassColors.accentEmerald.withValues(alpha: 0.03),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];

  // Button Glow Shadow for Light Theme
  static List<BoxShadow> neonGlow({
    Color color = LiquidGlassColors.accentEmerald,
    double intensity = 0.25,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
}
