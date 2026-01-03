import 'package:flutter/material.dart';
import 'dart:math' show pow;

/// App Colors System for RPS Stationery
/// Provides consistent color palette for light and dark themes
class AppColors {
  AppColors._();

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================
  
  // Primary Colors - Vibrant Teal for stationery business (student-friendly)
  static const Color lightPrimary = Color(0xFF00BCD4); // Vibrant teal/cyan
  static const Color lightPrimaryContainer = Color(0xFFE0F7FA);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnPrimaryContainer = Color(0xFF006064);

  // Secondary Colors - Coral/Orange for energy and creativity
  static const Color lightSecondary = Color(0xFFFF6B6B); // Coral red
  static const Color lightSecondaryContainer = Color(0xFFFFEBEE);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnSecondaryContainer = Color(0xFFD32F2F);

  // Tertiary Colors - Green accents for success states
  static const Color lightTertiary = Color(0xFF4CAF50);
  static const Color lightTertiaryContainer = Color(0xFFE8F5E8);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightOnTertiaryContainer = Color(0xFF1B5E20);

  // Background Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightOnSurfaceVariant = Color(0xFF424242);

  // Outline Colors
  static const Color lightOutline = Color(0xFFE0E0E0);
  static const Color lightOutlineVariant = Color(0xFFF0F0F0);

  // Semantic Colors
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightErrorContainer = Color(0xFFFFEBEE);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightOnErrorContainer = Color(0xFFB71C1C);

  static const Color lightWarning = Color(0xFFFFA000);
  static const Color lightWarningContainer = Color(0xFFFFF8E1);
  static const Color lightOnWarning = Color(0xFFFFFFFF);
  static const Color lightOnWarningContainer = Color(0xFFFF8F00);

  static const Color lightSuccess = Color(0xFF4CAF50);
  static const Color lightSuccessContainer = Color(0xFFE8F5E8);
  static const Color lightOnSuccess = Color(0xFFFFFFFF);
  static const Color lightOnSuccessContainer = Color(0xFF2E7D32);

  static const Color lightInfo = Color(0xFF2196F3);
  static const Color lightInfoContainer = Color(0xFFE3F2FD);
  static const Color lightOnInfo = Color(0xFFFFFFFF);
  static const Color lightOnInfoContainer = Color(0xFF1976D2);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  // Primary Colors - Vibrant teal adjusted for dark theme
  static const Color darkPrimary = Color(0xFF4DD0E1); // Lighter teal for dark
  static const Color darkPrimaryContainer = Color(0xFF006064);
  static const Color darkOnPrimary = Color(0xFF0A0A0A);
  static const Color darkOnPrimaryContainer = Color(0xFFE0F7FA);

  // Secondary Colors - Softer coral for dark theme
  static const Color darkSecondary = Color(0xFFFF8A80); // Lighter coral
  static const Color darkSecondaryContainer = Color(0xFFD32F2F);
  static const Color darkOnSecondary = Color(0xFF0A0A0A);
  static const Color darkOnSecondaryContainer = Color(0xFFFFEBEE);

  // Tertiary Colors
  static const Color darkTertiary = Color(0xFF81C784); // Lighter green
  static const Color darkTertiaryContainer = Color(0xFF1B5E20);
  static const Color darkOnTertiary = Color(0xFF0A0A0A);
  static const Color darkOnTertiaryContainer = Color(0xFFE8F5E8);

  // Background Colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkOnBackground = Color(0xFFE5E5E5);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkOnSurface = Color(0xFFE5E5E5);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkOnSurfaceVariant = Color(0xFFBDBDBD);

  // Outline Colors
  static const Color darkOutline = Color(0xFF3A3A3A);
  static const Color darkOutlineVariant = Color(0xFF2A2A2A);

  // Semantic Colors
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkErrorContainer = Color(0xFFB71C1C);
  static const Color darkOnError = Color(0xFF0A0A0A);
  static const Color darkOnErrorContainer = Color(0xFFFFCDD2);

  static const Color darkWarning = Color(0xFFFFCC02);
  static const Color darkWarningContainer = Color(0xFFFF8F00);
  static const Color darkOnWarning = Color(0xFF0A0A0A);
  static const Color darkOnWarningContainer = Color(0xFFFFF8E1);

  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkSuccessContainer = Color(0xFF2E7D32);
  static const Color darkOnSuccess = Color(0xFF0A0A0A);
  static const Color darkOnSuccessContainer = Color(0xFFE8F5E8);

  static const Color darkInfo = Color(0xFF64B5F6);
  static const Color darkInfoContainer = Color(0xFF1976D2);
  static const Color darkOnInfo = Color(0xFF0A0A0A);
  static const Color darkOnInfoContainer = Color(0xFFE3F2FD);

  // ============================================================================
  // UTILITY COLORS (Constant across themes)
  // ============================================================================

  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Shadow Colors
  static const Color lightShadow = Color(0x1A000000);
  static const Color darkShadow = Color(0x3A000000);

  // Shimmer Colors
  static const Color lightShimmerBase = Color(0xFFF0F0F0);
  static const Color lightShimmerHighlight = Color(0xFFFFFFFF);
  static const Color darkShimmerBase = Color(0xFF2A2A2A);
  static const Color darkShimmerHighlight = Color(0xFF3A3A3A);

  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================

  // Light Gradients
  static const LinearGradient lightPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightPrimary, Color(0xFF1976D2)],
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
  );

  // Dark Gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPrimary, Color(0xFF1976D2)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
  );

  // ============================================================================
  // THEME SPECIFIC GETTERS
  // ============================================================================

  /// Get appropriate shadow color based on theme brightness
  static Color getShadowColor(Brightness brightness) {
    return brightness == Brightness.light ? lightShadow : darkShadow;
  }

  /// Get appropriate shimmer colors based on theme brightness
  static List<Color> getShimmerColors(Brightness brightness) {
    return brightness == Brightness.light
        ? [lightShimmerBase, lightShimmerHighlight]
        : [darkShimmerBase, darkShimmerHighlight];
  }

  /// Get appropriate primary gradient based on theme brightness
  static LinearGradient getPrimaryGradient(Brightness brightness) {
    return brightness == Brightness.light ? lightPrimaryGradient : darkPrimaryGradient;
  }

  /// Get appropriate card gradient based on theme brightness
  static LinearGradient getCardGradient(Brightness brightness) {
    return brightness == Brightness.light ? lightCardGradient : darkCardGradient;
  }

  // ============================================================================
  // ACCESSIBILITY HELPERS
  // ============================================================================

  /// Check if color combination meets WCAG AA contrast ratio (4.5:1)
  static bool hasGoodContrast(Color foreground, Color background) {
    final double ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 4.5;
  }

  /// Check if color combination meets WCAG AAA contrast ratio (7:1)
  static bool hasExcellentContrast(Color foreground, Color background) {
    final double ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 7.0;
  }

  static double _calculateContrastRatio(Color foreground, Color background) {
    final double foregroundLuminance = _calculateLuminance(foreground);
    final double backgroundLuminance = _calculateLuminance(background);
    
    final double lighterLuminance = foregroundLuminance > backgroundLuminance 
        ? foregroundLuminance 
        : backgroundLuminance;
    final double darkerLuminance = foregroundLuminance > backgroundLuminance 
        ? backgroundLuminance 
        : foregroundLuminance;
    
    return (lighterLuminance + 0.05) / (darkerLuminance + 0.05);
  }

  static double _calculateLuminance(Color color) {
    final double r = _getRelativeLuminance((color.r * 255).round());
    final double g = _getRelativeLuminance((color.g * 255).round());
    final double b = _getRelativeLuminance((color.b * 255).round());
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _getRelativeLuminance(int value) {
    final double normalizedValue = value / 255.0;
    return normalizedValue <= 0.03928
        ? normalizedValue / 12.92
        : pow((normalizedValue + 0.055) / 1.055, 2.4).toDouble();
  }
}

/// Extension to easily access theme-aware colors from BuildContext
extension AppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get backgroundColor => Theme.of(this).colorScheme.surface;
  Color get textColor => Theme.of(this).colorScheme.onSurface;
  
  Color get shadowColor => AppColors.getShadowColor(Theme.of(this).brightness);
  LinearGradient get primaryGradient => AppColors.getPrimaryGradient(Theme.of(this).brightness);
  LinearGradient get cardGradient => AppColors.getCardGradient(Theme.of(this).brightness);
}

