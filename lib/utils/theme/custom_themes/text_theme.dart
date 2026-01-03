import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    // Headlines - For main titles and important headings
    headlineLarge: const TextStyle().copyWith(
      fontSize: 32.0, 
      fontWeight: FontWeight.bold, 
      color: AppColors.textPrimary,
      height: 1.2,
    ),
    headlineMedium: const TextStyle().copyWith(
      fontSize: 28.0, 
      fontWeight: FontWeight.w700, 
      color: AppColors.textPrimary,
      height: 1.2,
    ),
    headlineSmall: const TextStyle().copyWith(
      fontSize: 24.0, 
      fontWeight: FontWeight.w600, 
      color: AppColors.textPrimary,
      height: 1.3,
    ),

    // Titles - For section headers and card titles
    titleLarge: const TextStyle().copyWith(
      fontSize: 20.0, 
      fontWeight: FontWeight.w600, 
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    titleMedium: const TextStyle().copyWith(
      fontSize: 18.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    titleSmall: const TextStyle().copyWith(
      fontSize: 16.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textPrimary,
      height: 1.4,
    ),

    // Body text - For main content and descriptions
    bodyLarge: const TextStyle().copyWith(
      fontSize: 16.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: const TextStyle().copyWith(
      fontSize: 14.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodySmall: const TextStyle().copyWith(
      fontSize: 12.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textSecondary,
      height: 1.4,
    ),

    // Labels - For captions and small text
    labelLarge: const TextStyle().copyWith(
      fontSize: 12.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: 11.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
    labelSmall: const TextStyle().copyWith(
      fontSize: 10.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    // Headlines - For main titles and important headings
    headlineLarge: const TextStyle().copyWith(
      fontSize: 32.0, 
      fontWeight: FontWeight.bold, 
      color: AppColors.textPrimaryDark,
      height: 1.2,
    ),
    headlineMedium: const TextStyle().copyWith(
      fontSize: 28.0, 
      fontWeight: FontWeight.w700, 
      color: AppColors.textPrimaryDark,
      height: 1.2,
    ),
    headlineSmall: const TextStyle().copyWith(
      fontSize: 24.0, 
      fontWeight: FontWeight.w600, 
      color: AppColors.textPrimaryDark,
      height: 1.3,
    ),

    // Titles - For section headers and card titles
    titleLarge: const TextStyle().copyWith(
      fontSize: 20.0, 
      fontWeight: FontWeight.w600, 
      color: AppColors.textPrimaryDark,
      height: 1.3,
    ),
    titleMedium: const TextStyle().copyWith(
      fontSize: 18.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textPrimaryDark,
      height: 1.3,
    ),
    titleSmall: const TextStyle().copyWith(
      fontSize: 16.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textPrimaryDark,
      height: 1.4,
    ),

    // Body text - For main content and descriptions
    bodyLarge: const TextStyle().copyWith(
      fontSize: 16.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textPrimaryDark,
      height: 1.5,
    ),
    bodyMedium: const TextStyle().copyWith(
      fontSize: 14.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textPrimaryDark,
      height: 1.5,
    ),
    bodySmall: const TextStyle().copyWith(
      fontSize: 12.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textSecondaryDark,
      height: 1.4,
    ),

    // Labels - For captions and small text
    labelLarge: const TextStyle().copyWith(
      fontSize: 12.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textSecondaryDark,
      letterSpacing: 0.5,
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: 11.0, 
      fontWeight: FontWeight.w500, 
      color: AppColors.textSecondaryDark,
      letterSpacing: 0.5,
    ),
    labelSmall: const TextStyle().copyWith(
      fontSize: 10.0, 
      fontWeight: FontWeight.w400, 
      color: AppColors.textSecondaryDark,
      letterSpacing: 0.5,
    ),
  );

}
