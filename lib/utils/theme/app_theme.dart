import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Complete Theme System for RPS Stationery App
/// Features modern Material 3 design with comprehensive accessibility support
class AppTheme {
  AppTheme._();

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  static ThemeData get lightTheme => ThemeData(
    // Core Theme Settings
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightOnSecondary,
      secondaryContainer: AppColors.lightSecondaryContainer,
      onSecondaryContainer: AppColors.lightOnSecondaryContainer,
      tertiary: AppColors.lightTertiary,
      onTertiary: AppColors.lightOnTertiary,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      onTertiaryContainer: AppColors.lightOnTertiaryContainer,
      error: AppColors.lightError,
      onError: AppColors.lightOnError,
      errorContainer: AppColors.lightErrorContainer,
      onErrorContainer: AppColors.lightOnErrorContainer,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      shadow: AppColors.lightShadow,
      scrim: AppColors.black,
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkOnSurface,
      inversePrimary: AppColors.darkPrimary,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    // Typography
    textTheme: AppTypography.lightTextTheme,
    
    // Component Themes - Basic setup
    cardTheme: CardTheme(
      color: AppColors.lightSurface,
      elevation: 0,
      shadowColor: AppColors.lightShadow.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lightOutlineVariant, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // System UI
    splashColor: AppColors.lightPrimary.withValues(alpha: 0.1),
    highlightColor: AppColors.lightPrimary.withValues(alpha: 0.1),
    hoverColor: AppColors.lightPrimary.withValues(alpha: 0.04),
    focusColor: AppColors.lightPrimary.withValues(alpha: 0.1),
    unselectedWidgetColor: AppColors.lightOnSurfaceVariant,
    disabledColor: AppColors.lightOutline,
    hintColor: AppColors.lightOnSurfaceVariant,
    
    // Divider
    dividerColor: AppColors.lightOutlineVariant,
    dividerTheme: const DividerThemeData(
      color: AppColors.lightOutlineVariant,
      thickness: 1.0,
      space: 1.0,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.lightOnSurface,
      size: 24.0,
    ),
    primaryIconTheme: const IconThemeData(
      color: AppColors.lightOnPrimary,
      size: 24.0,
    ),
    
    // Extensions
    extensions: [
      _CustomColorsExtension.light,
    ],
  );

  // ============================================================================
  // DARK THEME
  // ============================================================================

  static ThemeData get darkTheme => ThemeData(
    // Core Theme Settings
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: AppColors.darkShadow,
      scrim: AppColors.black,
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.lightOnSurface,
      inversePrimary: AppColors.lightPrimary,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // Typography
    textTheme: AppTypography.darkTextTheme,
    
    // Component Themes - Basic setup
    cardTheme: CardTheme(
      color: AppColors.darkSurface,
      elevation: 0,
      shadowColor: AppColors.darkShadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.darkOutlineVariant, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // System UI
    splashColor: AppColors.darkPrimary.withValues(alpha: 0.1),
    highlightColor: AppColors.darkPrimary.withValues(alpha: 0.1),
    hoverColor: AppColors.darkPrimary.withValues(alpha: 0.04),
    focusColor: AppColors.darkPrimary.withValues(alpha: 0.1),
    unselectedWidgetColor: AppColors.darkOnSurfaceVariant,
    disabledColor: AppColors.darkOutline,
    hintColor: AppColors.darkOnSurfaceVariant,
    
    // Divider
    dividerColor: AppColors.darkOutlineVariant,
    dividerTheme: const DividerThemeData(
      color: AppColors.darkOutlineVariant,
      thickness: 1.0,
      space: 1.0,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.darkOnSurface,
      size: 24.0,
    ),
    primaryIconTheme: const IconThemeData(
      color: AppColors.darkOnPrimary,
      size: 24.0,
    ),
    
    // Extensions
    extensions: [
      _CustomColorsExtension.dark,
    ],
  );

  // ============================================================================
  // SYSTEM UI OVERLAY STYLES
  // ============================================================================

  /// Light theme system UI overlay style
  static SystemUiOverlayStyle get lightSystemUiOverlayStyle =>
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.lightSurface,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppColors.transparent,
      );

  /// Dark theme system UI overlay style
  static SystemUiOverlayStyle get darkSystemUiOverlayStyle =>
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.darkSurface,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: AppColors.transparent,
      );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Set system UI overlay style based on theme brightness
  static void setSystemUiOverlayStyle(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.light
          ? lightSystemUiOverlayStyle
          : darkSystemUiOverlayStyle,
    );
  }

  /// Get theme based on system brightness
  static ThemeData getThemeFromBrightness(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }
}

// ============================================================================
// CUSTOM COLOR EXTENSIONS
// ============================================================================

/// Custom colors extension for theme-specific semantic colors
@immutable
class _CustomColorsExtension extends ThemeExtension<_CustomColorsExtension> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  const _CustomColorsExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const light = _CustomColorsExtension(
    success: AppColors.lightSuccess,
    onSuccess: AppColors.lightOnSuccess,
    successContainer: AppColors.lightSuccessContainer,
    onSuccessContainer: AppColors.lightOnSuccessContainer,
    warning: AppColors.lightWarning,
    onWarning: AppColors.lightOnWarning,
    warningContainer: AppColors.lightWarningContainer,
    onWarningContainer: AppColors.lightOnWarningContainer,
    info: AppColors.lightInfo,
    onInfo: AppColors.lightOnInfo,
    infoContainer: AppColors.lightInfoContainer,
    onInfoContainer: AppColors.lightOnInfoContainer,
  );

  static const dark = _CustomColorsExtension(
    success: AppColors.darkSuccess,
    onSuccess: AppColors.darkOnSuccess,
    successContainer: AppColors.darkSuccessContainer,
    onSuccessContainer: AppColors.darkOnSuccessContainer,
    warning: AppColors.darkWarning,
    onWarning: AppColors.darkOnWarning,
    warningContainer: AppColors.darkWarningContainer,
    onWarningContainer: AppColors.darkOnWarningContainer,
    info: AppColors.darkInfo,
    onInfo: AppColors.darkOnInfo,
    infoContainer: AppColors.darkInfoContainer,
    onInfoContainer: AppColors.darkOnInfoContainer,
  );

  @override
  ThemeExtension<_CustomColorsExtension> copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return _CustomColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  ThemeExtension<_CustomColorsExtension> lerp(
      ThemeExtension<_CustomColorsExtension>? other, double t) {
    if (other is! _CustomColorsExtension) {
      return this;
    }
    return _CustomColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

/// Extension to access custom colors from BuildContext
extension CustomColorsExtension on BuildContext {
  _CustomColorsExtension get customColors =>
      Theme.of(this).extension<_CustomColorsExtension>()!;
}
