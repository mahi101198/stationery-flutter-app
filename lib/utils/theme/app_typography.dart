import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography System for RPS Stationery
/// Provides consistent text styles with accessibility in mind
class AppTypography {
  AppTypography._();

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================
  
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================================================
  // BASE FONT CONFIGURATIONS
  // ============================================================================

  /// Primary font family for headings and important text
  static TextStyle _primaryFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.0,
      height: height ?? 1.4,
    );
  }

  /// Secondary font family for body text and content
  static TextStyle _bodyFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.4,
      height: height ?? 1.5,
    );
  }

  // ============================================================================
  // LIGHT THEME TEXT STYLES
  // ============================================================================

  // Display Styles (for hero sections, splash screens)
  static final TextStyle lightDisplayLarge = _primaryFont(
    fontSize: 36.0,
    fontWeight: bold,
    color: AppColors.lightOnBackground,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static final TextStyle lightDisplayMedium = _primaryFont(
    fontSize: 28.0,
    fontWeight: bold,
    color: AppColors.lightOnBackground,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static final TextStyle lightDisplaySmall = _primaryFont(
    fontSize: 24.0,
    fontWeight: semiBold,
    color: AppColors.lightOnBackground,
    letterSpacing: 0.0,
    height: 1.3,
  );

  // Headline Styles (for page titles, section headers)
  static final TextStyle lightHeadlineLarge = _primaryFont(
    fontSize: 22.0,
    fontWeight: semiBold,
    color: AppColors.lightOnBackground,
    height: 1.3,
  );

  static final TextStyle lightHeadlineMedium = _primaryFont(
    fontSize: 20.0,
    fontWeight: semiBold,
    color: AppColors.lightOnBackground,
    height: 1.4,
  );

  static final TextStyle lightHeadlineSmall = _primaryFont(
    fontSize: 18.0,
    fontWeight: medium,
    color: AppColors.lightOnBackground,
    height: 1.4,
  );

  // Title Styles (for card titles, product names)
  static final TextStyle lightTitleLarge = _primaryFont(
    fontSize: 16.0,
    fontWeight: medium,
    color: AppColors.lightOnBackground,
    height: 1.4,
  );

  static final TextStyle lightTitleMedium = _primaryFont(
    fontSize: 14.0,
    fontWeight: medium,
    color: AppColors.lightOnBackground,
    height: 1.4,
  );

  static final TextStyle lightTitleSmall = _primaryFont(
    fontSize: 12.0,
    fontWeight: medium,
    color: AppColors.lightOnSurfaceVariant,
    height: 1.4,
  );

  // Body Styles (for content, descriptions)
  static final TextStyle lightBodyLarge = _bodyFont(
    fontSize: 16.0,
    fontWeight: regular,
    color: AppColors.lightOnBackground,
  );

  static final TextStyle lightBodyMedium = _bodyFont(
    fontSize: 14.0,
    fontWeight: regular,
    color: AppColors.lightOnBackground,
  );

  static final TextStyle lightBodySmall = _bodyFont(
    fontSize: 12.0,
    fontWeight: regular,
    color: AppColors.lightOnSurfaceVariant,
  );

  // Label Styles (for buttons, chips, form labels)
  static final TextStyle lightLabelLarge = _primaryFont(
    fontSize: 14.0,
    fontWeight: medium,
    color: AppColors.lightOnBackground,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static final TextStyle lightLabelMedium = _primaryFont(
    fontSize: 12.0,
    fontWeight: medium,
    color: AppColors.lightOnBackground,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static final TextStyle lightLabelSmall = _primaryFont(
    fontSize: 10.0,
    fontWeight: medium,
    color: AppColors.lightOnSurfaceVariant,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // ============================================================================
  // DARK THEME TEXT STYLES
  // ============================================================================

  // Display Styles
  static final TextStyle darkDisplayLarge = lightDisplayLarge.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkDisplayMedium = lightDisplayMedium.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkDisplaySmall = lightDisplaySmall.copyWith(
    color: AppColors.darkOnBackground,
  );

  // Headline Styles
  static final TextStyle darkHeadlineLarge = lightHeadlineLarge.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkHeadlineMedium = lightHeadlineMedium.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkHeadlineSmall = lightHeadlineSmall.copyWith(
    color: AppColors.darkOnBackground,
  );

  // Title Styles
  static final TextStyle darkTitleLarge = lightTitleLarge.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkTitleMedium = lightTitleMedium.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkTitleSmall = lightTitleSmall.copyWith(
    color: AppColors.darkOnSurfaceVariant,
  );

  // Body Styles
  static final TextStyle darkBodyLarge = lightBodyLarge.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkBodyMedium = lightBodyMedium.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkBodySmall = lightBodySmall.copyWith(
    color: AppColors.darkOnSurfaceVariant,
  );

  // Label Styles
  static final TextStyle darkLabelLarge = lightLabelLarge.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkLabelMedium = lightLabelMedium.copyWith(
    color: AppColors.darkOnBackground,
  );

  static final TextStyle darkLabelSmall = lightLabelSmall.copyWith(
    color: AppColors.darkOnSurfaceVariant,
  );

  // ============================================================================
  // SPECIALIZED TEXT STYLES
  // ============================================================================

  // Price Styles
  static final TextStyle lightPriceStyle = _primaryFont(
    fontSize: 18.0,
    fontWeight: bold,
    color: AppColors.lightPrimary,
    height: 1.2,
  );

  static final TextStyle darkPriceStyle = lightPriceStyle.copyWith(
    color: AppColors.darkPrimary,
  );

  // Original Price (strikethrough)
  static final TextStyle lightOriginalPriceStyle = _bodyFont(
    fontSize: 14.0,
    fontWeight: regular,
    color: AppColors.lightOnSurfaceVariant,
  ).copyWith(
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.lightOnSurfaceVariant,
  );

  static final TextStyle darkOriginalPriceStyle = lightOriginalPriceStyle.copyWith(
    color: AppColors.darkOnSurfaceVariant,
    decorationColor: AppColors.darkOnSurfaceVariant,
  );

  // Discount Badge
  static final TextStyle lightDiscountStyle = _primaryFont(
    fontSize: 12.0,
    fontWeight: bold,
    color: AppColors.lightOnError,
    height: 1.2,
  );

  static final TextStyle darkDiscountStyle = lightDiscountStyle.copyWith(
    color: AppColors.darkOnError,
  );

  // Rating Text
  static final TextStyle lightRatingStyle = _bodyFont(
    fontSize: 12.0,
    fontWeight: medium,
    color: AppColors.lightOnSurfaceVariant,
    height: 1.2,
  );

  static final TextStyle darkRatingStyle = lightRatingStyle.copyWith(
    color: AppColors.darkOnSurfaceVariant,
  );

  // Status Text (In Stock, Out of Stock, etc.)
  static final TextStyle lightStatusSuccessStyle = _primaryFont(
    fontSize: 12.0,
    fontWeight: medium,
    color: AppColors.lightSuccess,
    height: 1.2,
  );

  static final TextStyle darkStatusSuccessStyle = lightStatusSuccessStyle.copyWith(
    color: AppColors.darkSuccess,
  );

  static final TextStyle lightStatusErrorStyle = _primaryFont(
    fontSize: 12.0,
    fontWeight: medium,
    color: AppColors.lightError,
    height: 1.2,
  );

  static final TextStyle darkStatusErrorStyle = lightStatusErrorStyle.copyWith(
    color: AppColors.darkError,
  );

  // Button Text Styles
  static final TextStyle lightButtonTextLarge = _primaryFont(
    fontSize: 16.0,
    fontWeight: semiBold,
    color: AppColors.lightOnPrimary,
    letterSpacing: 0.4,
    height: 1.0,
  );

  static final TextStyle darkButtonTextLarge = lightButtonTextLarge.copyWith(
    color: AppColors.darkOnPrimary,
  );

  static final TextStyle lightButtonTextMedium = _primaryFont(
    fontSize: 14.0,
    fontWeight: medium,
    color: AppColors.lightOnPrimary,
    letterSpacing: 0.4,
    height: 1.0,
  );

  static final TextStyle darkButtonTextMedium = lightButtonTextMedium.copyWith(
    color: AppColors.darkOnPrimary,
  );

  // ============================================================================
  // TEXT THEME BUILDERS
  // ============================================================================

  /// Build light theme TextTheme
  static TextTheme get lightTextTheme => TextTheme(
    displayLarge: lightDisplayLarge,
    displayMedium: lightDisplayMedium,
    displaySmall: lightDisplaySmall,
    headlineLarge: lightHeadlineLarge,
    headlineMedium: lightHeadlineMedium,
    headlineSmall: lightHeadlineSmall,
    titleLarge: lightTitleLarge,
    titleMedium: lightTitleMedium,
    titleSmall: lightTitleSmall,
    bodyLarge: lightBodyLarge,
    bodyMedium: lightBodyMedium,
    bodySmall: lightBodySmall,
    labelLarge: lightLabelLarge,
    labelMedium: lightLabelMedium,
    labelSmall: lightLabelSmall,
  );

  /// Build dark theme TextTheme
  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: darkDisplayLarge,
    displayMedium: darkDisplayMedium,
    displaySmall: darkDisplaySmall,
    headlineLarge: darkHeadlineLarge,
    headlineMedium: darkHeadlineMedium,
    headlineSmall: darkHeadlineSmall,
    titleLarge: darkTitleLarge,
    titleMedium: darkTitleMedium,
    titleSmall: darkTitleSmall,
    bodyLarge: darkBodyLarge,
    bodyMedium: darkBodyMedium,
    bodySmall: darkBodySmall,
    labelLarge: darkLabelLarge,
    labelMedium: darkLabelMedium,
    labelSmall: darkLabelSmall,
  );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get appropriate text style based on theme brightness
  static TextStyle getDisplayLarge(Brightness brightness) {
    return brightness == Brightness.light ? lightDisplayLarge : darkDisplayLarge;
  }

  static TextStyle getPriceStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightPriceStyle : darkPriceStyle;
  }

  static TextStyle getOriginalPriceStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightOriginalPriceStyle : darkOriginalPriceStyle;
  }

  static TextStyle getDiscountStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightDiscountStyle : darkDiscountStyle;
  }

  static TextStyle getRatingStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightRatingStyle : darkRatingStyle;
  }

  static TextStyle getStatusSuccessStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightStatusSuccessStyle : darkStatusSuccessStyle;
  }

  static TextStyle getStatusErrorStyle(Brightness brightness) {
    return brightness == Brightness.light ? lightStatusErrorStyle : darkStatusErrorStyle;
  }

  static TextStyle getButtonTextLarge(Brightness brightness) {
    return brightness == Brightness.light ? lightButtonTextLarge : darkButtonTextLarge;
  }

  static TextStyle getButtonTextMedium(Brightness brightness) {
    return brightness == Brightness.light ? lightButtonTextMedium : darkButtonTextMedium;
  }
}

/// Extension to easily access theme-aware text styles from BuildContext
extension AppTypographyExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Quick access to common text styles
  TextStyle get displayLarge => AppTypography.getDisplayLarge(Theme.of(this).brightness);
  TextStyle get priceStyle => AppTypography.getPriceStyle(Theme.of(this).brightness);
  TextStyle get originalPriceStyle => AppTypography.getOriginalPriceStyle(Theme.of(this).brightness);
  TextStyle get discountStyle => AppTypography.getDiscountStyle(Theme.of(this).brightness);
  TextStyle get ratingStyle => AppTypography.getRatingStyle(Theme.of(this).brightness);
  TextStyle get statusSuccessStyle => AppTypography.getStatusSuccessStyle(Theme.of(this).brightness);
  TextStyle get statusErrorStyle => AppTypography.getStatusErrorStyle(Theme.of(this).brightness);
  TextStyle get buttonTextLarge => AppTypography.getButtonTextLarge(Theme.of(this).brightness);
  TextStyle get buttonTextMedium => AppTypography.getButtonTextMedium(Theme.of(this).brightness);
}
