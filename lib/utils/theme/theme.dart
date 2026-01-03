import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/theme/custom_themes/text_theme.dart';
import 'package:rps_stationery/utils/theme/theme_data.dart';
import 'package:rps_stationery/utils/theme/widget_themes/bottom_sheet_theme.dart';
import 'package:rps_stationery/utils/theme/widget_themes/checkbox_theme.dart';
import 'package:rps_stationery/utils/theme/widget_themes/chip_theme.dart';
import 'package:rps_stationery/utils/theme/widget_themes/elevated_button_theme.dart';
import 'package:rps_stationery/utils/theme/widget_themes/outlined_button_theme.dart';
import 'package:rps_stationery/utils/theme/widget_themes/text_field_theme.dart';

import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta',
    disabledColor: AppColors.grey,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primarySwatch: AppColors.primaryMaterial,
    secondaryHeaderColor: AppColors.secondary,
    textTheme: AppTextTheme.lightTextTheme,
    chipTheme: TChipTheme.lightChipTheme,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.surfaceLight,
    appBarTheme: appBarLightTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    dividerColor: AppColors.borderPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: AppColors.textWhite,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textWhite,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta',
    disabledColor: AppColors.darkGrey,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    primarySwatch: AppColors.primaryMaterial,
    secondaryHeaderColor: AppColors.secondary,
    textTheme: AppTextTheme.darkTextTheme,
    chipTheme: TChipTheme.darkChipTheme,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.surfaceDark,
    appBarTheme: appBarDarkTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    dividerColor: AppColors.darkGrey,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimaryDark,
      onError: AppColors.textWhite,
    ),
  );
}
