import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Component Styles - Centralized styling for all UI components
/// Provides consistent styling across light and dark themes
class ComponentStyles {
  ComponentStyles._();

  // ============================================================================
  // CARD STYLES
  // ============================================================================

  static BoxDecoration productCardLight(BuildContext context) {
    return BoxDecoration(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.lightShadow.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: AppColors.lightOutlineVariant,
        width: 1,
      ),
    );
  }

  static BoxDecoration productCardDark(BuildContext context) {
    return BoxDecoration(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkShadow.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: AppColors.darkOutlineVariant,
        width: 1,
      ),
    );
  }

  static BoxDecoration getProductCardDecoration(
    BuildContext context,
    bool isDark,
  ) {
    return isDark ? productCardDark(context) : productCardLight(context);
  }

  // ============================================================================
  // PRICE DISPLAY STYLES
  // ============================================================================

  /// Price gradient for light theme: primary → secondary (teal → coral)
  static LinearGradient priceGradientLight = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.lightPrimary,      // Teal
      AppColors.lightSecondary,    // Coral
    ],
  );

  /// Price gradient for dark theme: primary → primary dimmed
  static LinearGradient priceGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.darkPrimary,                              // Light teal
      AppColors.darkPrimary.withValues(alpha: 0.7),      // Dimmed teal
    ],
  );

  static LinearGradient getPriceGradient(bool isDark) {
    return isDark ? priceGradientDark : priceGradientLight;
  }

  /// Get original price text style (struck through)
  static TextStyle originalPriceStyle(ThemeData theme, bool isDark) {
    return TextStyle(
      fontSize: 10,
      color: isDark
          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      decoration: TextDecoration.lineThrough,
      decorationColor: isDark
          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      decorationThickness: 1.5,
      height: 1.1,
    );
  }

  /// Get selling price text style (with gradient)
  static TextStyle sellingPriceStyle(ThemeData theme, bool isCompact) {
    return TextStyle(
      fontSize: isCompact ? 14 : 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 0.2,
      height: 1.1,
    );
  }

  // ============================================================================
  // DISCOUNT BADGE STYLES
  // ============================================================================

  /// Discount badge gradient: coral gradient
  static const LinearGradient discountBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),  // Coral
      Color(0xFFEE5A6F),  // Darker coral
    ],
  );

  static BoxDecoration discountBadgeDecoration({
    required double borderRadius,
  }) {
    return BoxDecoration(
      gradient: discountBadgeGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Get discount badge text style
  static TextStyle discountBadgeTextStyle({
    required double fontSize,
    required bool bold,
  }) {
    return TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      letterSpacing: 0.3,
    );
  }

  // ============================================================================
  // BUTTON STYLES
  // ============================================================================

  static ElevatedButtonThemeData elevatedButtonThemeLight() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData elevatedButtonThemeDark() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }

  static TextButtonThemeData textButtonThemeLight() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static TextButtonThemeData textButtonThemeDark() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ============================================================================
  // CHIP STYLES
  // ============================================================================

  static ChipThemeData chipThemeLight() {
    return ChipThemeData(
      backgroundColor: AppColors.lightPrimaryContainer,
      labelStyle: const TextStyle(
        color: AppColors.lightOnPrimaryContainer,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.lightOnPrimaryContainer,
        fontSize: 13,
      ),
      brightness: Brightness.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      side: const BorderSide(
        color: AppColors.lightOutlineVariant,
        width: 1,
      ),
    );
  }

  static ChipThemeData chipThemeDark() {
    return ChipThemeData(
      backgroundColor: AppColors.darkPrimaryContainer,
      labelStyle: const TextStyle(
        color: AppColors.darkOnPrimaryContainer,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.darkOnPrimaryContainer,
        fontSize: 13,
      ),
      brightness: Brightness.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      side: const BorderSide(
        color: AppColors.darkOutlineVariant,
        width: 1,
      ),
    );
  }

  // ============================================================================
  // DIVIDER STYLES
  // ============================================================================

  static Color dividerColorLight() => AppColors.lightOutlineVariant;
  static Color dividerColorDark() => AppColors.darkOutlineVariant;

  static Color getDividerColor(bool isDark) {
    return isDark ? dividerColorDark() : dividerColorLight();
  }

  // ============================================================================
  // BADGE & LABEL STYLES
  // ============================================================================

  /// Success badge (green)
  static BoxDecoration successBadgeDecoration() {
    return BoxDecoration(
      color: AppColors.lightSuccessContainer,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: AppColors.lightSuccess,
        width: 1,
      ),
    );
  }

  static TextStyle successBadgeTextStyle() {
    return const TextStyle(
      color: AppColors.lightOnSuccessContainer,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }

  /// Warning badge (orange)
  static BoxDecoration warningBadgeDecoration() {
    return BoxDecoration(
      color: AppColors.lightWarningContainer,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: AppColors.lightWarning,
        width: 1,
      ),
    );
  }

  static TextStyle warningBadgeTextStyle() {
    return const TextStyle(
      color: AppColors.lightOnWarningContainer,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }

  /// Error badge (red)
  static BoxDecoration errorBadgeDecoration() {
    return BoxDecoration(
      color: AppColors.lightErrorContainer,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: AppColors.lightError,
        width: 1,
      ),
    );
  }

  static TextStyle errorBadgeTextStyle() {
    return const TextStyle(
      color: AppColors.lightOnErrorContainer,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }

  // ============================================================================
  // SHADOW STYLES
  // ============================================================================

  static List<BoxShadow> elevationShadowLight(double elevation) {
    return [
      BoxShadow(
        color: AppColors.lightShadow.withValues(alpha: 0.05 * elevation / 8),
        blurRadius: elevation,
        offset: Offset(0, elevation / 4),
      ),
    ];
  }

  static List<BoxShadow> elevationShadowDark(double elevation) {
    return [
      BoxShadow(
        color: AppColors.darkShadow.withValues(alpha: 0.1 * elevation / 8),
        blurRadius: elevation,
        offset: Offset(0, elevation / 4),
      ),
    ];
  }

  static List<BoxShadow> getElevationShadow(double elevation, bool isDark) {
    return isDark
        ? elevationShadowDark(elevation)
        : elevationShadowLight(elevation);
  }

  // ============================================================================
  // BORDER STYLES
  // ============================================================================

  static BorderSide borderLight({double width = 1}) {
    return BorderSide(
      color: AppColors.lightOutlineVariant,
      width: width,
    );
  }

  static BorderSide borderDark({double width = 1}) {
    return BorderSide(
      color: AppColors.darkOutlineVariant,
      width: width,
    );
  }

  static BorderSide getBorder(bool isDark, {double width = 1}) {
    return isDark ? borderDark(width: width) : borderLight(width: width);
  }

  // ============================================================================
  // BACKGROUND STYLES
  // ============================================================================

  static Color scaffoldBackgroundLight() => AppColors.lightBackground;
  static Color scaffoldBackgroundDark() => AppColors.darkBackground;

  static Color getScaffoldBackground(bool isDark) {
    return isDark ? scaffoldBackgroundDark() : scaffoldBackgroundLight();
  }

  static Color cardBackgroundLight() => AppColors.lightSurface;
  static Color cardBackgroundDark() => AppColors.darkSurface;

  static Color getCardBackground(bool isDark) {
    return isDark ? cardBackgroundDark() : cardBackgroundLight();
  }

  // ============================================================================
  // INPUT FIELD STYLES
  // ============================================================================

  static InputDecoration searchInputDecorationLight(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.lightSurface,
      hintText: 'Search products...',
      hintStyle: TextStyle(
        color: AppColors.lightOnSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.lightOutlineVariant,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.lightOutlineVariant,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.lightPrimary,
          width: 2,
        ),
      ),
      prefixIcon: Icon(
        Icons.search,
        color: AppColors.lightOnSurfaceVariant,
        size: 20,
      ),
      suffixIcon: Icon(
        Icons.close,
        color: AppColors.lightOnSurfaceVariant,
        size: 20,
      ),
    );
  }

  static InputDecoration searchInputDecorationDark(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.darkSurface,
      hintText: 'Search products...',
      hintStyle: TextStyle(
        color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.darkOutlineVariant,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.darkOutlineVariant,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.darkPrimary,
          width: 2,
        ),
      ),
      prefixIcon: Icon(
        Icons.search,
        color: AppColors.darkOnSurfaceVariant,
        size: 20,
      ),
      suffixIcon: Icon(
        Icons.close,
        color: AppColors.darkOnSurfaceVariant,
        size: 20,
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get theme-aware style based on brightness
  static T getThemedStyle<T>(bool isDark, T lightStyle, T darkStyle) {
    return isDark ? darkStyle : lightStyle;
  }
}
