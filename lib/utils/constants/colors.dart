import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Modern Stationery E-commerce Color Palette
  static const Color primary = Color(0xFF4CAF50); // Fresh Green
  static const Color primaryDark = Color(0xFF66BB6A); // Lighter Green for dark mode
  
  static const MaterialColor primaryMaterial =
      MaterialColor(0xFF4CAF50, <int, Color>{
        50: Color(0xFFE8F5E8),
        100: Color(0xFFC8E6C9),
        200: Color(0xFFA5D6A7),
        300: Color(0xFF81C784),
        400: Color(0xFF66BB6A),
        500: Color(0xFF4CAF50),
        600: Color(0xFF43A047),
        700: Color(0xFF388E3C),
        800: Color(0xFF2E7D32),
        900: Color(0xFF1B5E20),
      });

  // App theme colors
  static const Color secondary = Color(0xFFFFC107); // Warm Amber
  static const Color accent = Color(0xFF2196F3); // Blue for actions

  // Text colors (Modern e-commerce theme)
  static const Color textPrimary = Color(0xFF212121); // Dark text for light mode
  static const Color textSecondary = Color(0xFF757575); // Secondary text for light mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Primary text for dark mode
  static const Color textSecondaryDark = Color(0xFFB0BEC5); // Secondary text for dark mode
  static const Color textWhite = Colors.white;

  // Background colors (Clean modern theme)
  static const Color backgroundLight = Color(0xFFF5F5F5); // Light mode background
  static const Color backgroundDark = Color(0xFF121212); // Dark mode background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Cards/surfaces in light mode
  static const Color surfaceDark = Color(0xFF1E1E1E); // Cards/surfaces in dark mode
  
  // Legacy colors for compatibility
  static const Color light = Color(0xFFF5F5F5);
  static const Color dark = Color(0xFF121212);
  static const Color primaryBackground = Color(0xFFF5F5F5);

  // Background Container colors
  static const Color lightContainer = Color(0xFFFFFFFF);
  static Color darkContainer = const Color(0xFF1E1E1E);

  // Button colors (Updated to match new theme)
  static const Color buttonPrimary = Color(0xFF4CAF50); // Green primary
  static const Color buttonSecondary = Color(0xFFFFC107); // Amber secondary
  static const Color buttonDisabled = Color(0xFFBDBDBD);

  // Border colors
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
}

// Alias for compatibility with existing code
typedef TColors = AppColors;
