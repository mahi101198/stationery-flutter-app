import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Component Theme Styles for RPS Stationery
/// Provides consistent styling for UI components
class ComponentThemes {
  ComponentThemes._();

  // ============================================================================
  // ELEVATION LEVELS
  // ============================================================================
  
  static const double elevationLevel1 = 1.0; // Buttons, small cards
  static const double elevationLevel2 = 2.0; // Standard cards
  static const double elevationLevel3 = 4.0; // Floating elements
  static const double elevationLevel4 = 6.0; // App bars, nav bars
  static const double elevationLevel5 = 8.0; // Dialogs, sheets

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  
  static const double radiusSmall = 8.0;   // Small buttons, chips
  static const double radiusMedium = 12.0; // Cards, inputs
  static const double radiusLarge = 16.0;  // Large cards, sheets
  static const double radiusExtra = 24.0;  // Special components

  // ============================================================================
  // CARD THEMES
  // ============================================================================

  /// Light theme card style
  static CardTheme get lightCardTheme => CardTheme(
    color: AppColors.lightSurface,
    shadowColor: AppColors.lightShadow,
    surfaceTintColor: AppColors.lightSurface,
    elevation: elevationLevel2,
    margin: const EdgeInsets.all(8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    clipBehavior: Clip.antiAlias,
  );

  /// Dark theme card style
  static CardTheme get darkCardTheme => CardTheme(
    color: AppColors.darkSurface,
    shadowColor: AppColors.darkShadow,
    surfaceTintColor: AppColors.darkSurface,
    elevation: elevationLevel2,
    margin: const EdgeInsets.all(8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    clipBehavior: Clip.antiAlias,
  );

  // ============================================================================
  // ELEVATED BUTTON THEMES
  // ============================================================================

  /// Light theme elevated button style
  static ElevatedButtonThemeData get lightElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.lightOnPrimary,
          backgroundColor: AppColors.lightPrimary,
          disabledForegroundColor: AppColors.lightOnSurfaceVariant,
          disabledBackgroundColor: AppColors.lightOutline,
          shadowColor: AppColors.lightShadow,
          elevation: elevationLevel1,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          minimumSize: const Size(64.0, 48.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );

  /// Dark theme elevated button style
  static ElevatedButtonThemeData get darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.darkOnPrimary,
          backgroundColor: AppColors.darkPrimary,
          disabledForegroundColor: AppColors.darkOnSurfaceVariant,
          disabledBackgroundColor: AppColors.darkOutline,
          shadowColor: AppColors.darkShadow,
          elevation: elevationLevel1,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          minimumSize: const Size(64.0, 48.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ============================================================================
  // OUTLINED BUTTON THEMES
  // ============================================================================

  /// Light theme outlined button style
  static OutlinedButtonThemeData get lightOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          disabledForegroundColor: AppColors.lightOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          disabledBackgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          minimumSize: const Size(64.0, 48.0),
          side: const BorderSide(
            color: AppColors.lightOutline,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      );

  /// Dark theme outlined button style
  static OutlinedButtonThemeData get darkOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          disabledForegroundColor: AppColors.darkOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          disabledBackgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          minimumSize: const Size(64.0, 48.0),
          side: const BorderSide(
            color: AppColors.darkOutline,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ============================================================================
  // TEXT BUTTON THEMES
  // ============================================================================

  /// Light theme text button style
  static TextButtonThemeData get lightTextButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          disabledForegroundColor: AppColors.lightOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          minimumSize: const Size(64.0, 48.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      );

  /// Dark theme text button style
  static TextButtonThemeData get darkTextButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          disabledForegroundColor: AppColors.darkOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          minimumSize: const Size(64.0, 48.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ============================================================================
  // ICON BUTTON THEMES
  // ============================================================================

  /// Light theme icon button style
  static IconButtonThemeData get lightIconButtonTheme => IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.lightOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          disabledForegroundColor: AppColors.lightOutline,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          minimumSize: const Size(48.0, 48.0),
          padding: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      );

  /// Dark theme icon button style
  static IconButtonThemeData get darkIconButtonTheme => IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkOnSurfaceVariant,
          backgroundColor: AppColors.transparent,
          disabledForegroundColor: AppColors.darkOutline,
          shadowColor: AppColors.transparent,
          elevation: 0.0,
          minimumSize: const Size(48.0, 48.0),
          padding: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      );

  // ============================================================================
  // INPUT DECORATION THEMES
  // ============================================================================

  /// Light theme input decoration
  static InputDecorationTheme get lightInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.all(16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightOutline,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightOutline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightPrimary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightError,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightError,
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.lightOutlineVariant,
            width: 1.0,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: AppColors.lightError,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: AppColors.lightOnSurfaceVariant,
        suffixIconColor: AppColors.lightOnSurfaceVariant,
      );

  /// Dark theme input decoration
  static InputDecorationTheme get darkInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.all(16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkOutline,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkOutline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkPrimary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkError,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkError,
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.darkOutlineVariant,
            width: 1.0,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: AppColors.darkError,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: AppColors.darkOnSurfaceVariant,
        suffixIconColor: AppColors.darkOnSurfaceVariant,
      );

  // ============================================================================
  // APP BAR THEMES
  // ============================================================================

  /// Light theme app bar style
  static AppBarTheme get lightAppBarTheme => const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0.0,
        centerTitle: false,
        titleSpacing: 16.0,
        titleTextStyle: TextStyle(
          color: AppColors.lightOnSurface,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.0,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightOnSurface,
          size: 24.0,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.lightOnSurface,
          size: 24.0,
        ),
        shadowColor: AppColors.lightShadow,
        surfaceTintColor: AppColors.lightSurface,
        scrolledUnderElevation: elevationLevel1,
      );

  /// Dark theme app bar style
  static AppBarTheme get darkAppBarTheme => const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0.0,
        centerTitle: false,
        titleSpacing: 16.0,
        titleTextStyle: TextStyle(
          color: AppColors.darkOnSurface,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.0,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkOnSurface,
          size: 24.0,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.darkOnSurface,
          size: 24.0,
        ),
        shadowColor: AppColors.darkShadow,
        surfaceTintColor: AppColors.darkSurface,
        scrolledUnderElevation: elevationLevel1,
      );

  // ============================================================================
  // BOTTOM NAVIGATION BAR THEMES
  // ============================================================================

  /// Light theme bottom navigation bar style
  static BottomNavigationBarThemeData get lightBottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: elevationLevel2,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightOnSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: AppColors.lightPrimary,
          size: 24.0,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.lightOnSurfaceVariant,
          size: 24.0,
        ),
        selectedLabelStyle: TextStyle(
          color: AppColors.lightPrimary,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          color: AppColors.lightOnSurfaceVariant,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  /// Dark theme bottom navigation bar style
  static BottomNavigationBarThemeData get darkBottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: elevationLevel2,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
        selectedIconTheme: IconThemeData(
          color: AppColors.darkPrimary,
          size: 24.0,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.darkOnSurfaceVariant,
          size: 24.0,
        ),
        selectedLabelStyle: TextStyle(
          color: AppColors.darkPrimary,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          color: AppColors.darkOnSurfaceVariant,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // ============================================================================
  // CHIP THEMES
  // ============================================================================

  /// Light theme chip style
  static ChipThemeData get lightChipTheme => ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        deleteIconColor: AppColors.lightOnSurfaceVariant,
        disabledColor: AppColors.lightOutlineVariant,
        selectedColor: AppColors.lightPrimaryContainer,
        secondarySelectedColor: AppColors.lightSecondaryContainer,
        shadowColor: AppColors.transparent,
        selectedShadowColor: AppColors.transparent,
        side: const BorderSide(
          color: AppColors.lightOutline,
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.lightOnSecondaryContainer,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        labelPadding: EdgeInsets.zero,
        iconTheme: const IconThemeData(
          color: AppColors.lightOnSurfaceVariant,
          size: 18.0,
        ),
        elevation: 0.0,
        pressElevation: 0.0,
      );

  /// Dark theme chip style
  static ChipThemeData get darkChipTheme => ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        deleteIconColor: AppColors.darkOnSurfaceVariant,
        disabledColor: AppColors.darkOutlineVariant,
        selectedColor: AppColors.darkPrimaryContainer,
        secondarySelectedColor: AppColors.darkSecondaryContainer,
        shadowColor: AppColors.transparent,
        selectedShadowColor: AppColors.transparent,
        side: const BorderSide(
          color: AppColors.darkOutline,
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkOnSurfaceVariant,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.darkOnSecondaryContainer,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        labelPadding: EdgeInsets.zero,
        iconTheme: const IconThemeData(
          color: AppColors.darkOnSurfaceVariant,
          size: 18.0,
        ),
        elevation: 0.0,
        pressElevation: 0.0,
      );

  // ============================================================================
  // FLOATING ACTION BUTTON THEMES
  // ============================================================================

  /// Light theme FAB style
  static FloatingActionButtonThemeData get lightFabTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: elevationLevel3,
        focusElevation: elevationLevel3,
        hoverElevation: elevationLevel3,
        highlightElevation: elevationLevel4,
        disabledElevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
      );

  /// Dark theme FAB style
  static FloatingActionButtonThemeData get darkFabTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: elevationLevel3,
        focusElevation: elevationLevel3,
        hoverElevation: elevationLevel3,
        highlightElevation: elevationLevel4,
        disabledElevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
      );

  // ============================================================================
  // DIALOG THEMES
  // ============================================================================

  /// Light theme dialog style
  static DialogTheme get lightDialogTheme => DialogTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: elevationLevel5,
        shadowColor: AppColors.lightShadow,
        surfaceTintColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.lightOnSurface,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.lightOnSurface,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      );

  /// Dark theme dialog style
  static DialogTheme get darkDialogTheme => DialogTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: elevationLevel5,
        shadowColor: AppColors.darkShadow,
        surfaceTintColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.darkOnSurface,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.darkOnSurface,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      );

  // ============================================================================
  // SNACK BAR THEMES
  // ============================================================================

  /// Light theme snack bar style
  static SnackBarThemeData get lightSnackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.lightOnSurface,
        contentTextStyle: const TextStyle(
          color: AppColors.lightSurface,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: AppColors.lightPrimary,
        disabledActionTextColor: AppColors.lightOutline,
        elevation: elevationLevel3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        width: null,
      );

  /// Dark theme snack bar style
  static SnackBarThemeData get darkSnackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.darkOnSurface,
        contentTextStyle: const TextStyle(
          color: AppColors.darkSurface,
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: AppColors.darkPrimary,
        disabledActionTextColor: AppColors.darkOutline,
        elevation: elevationLevel3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        width: null,
      );
}
