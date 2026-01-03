import 'package:flutter/material.dart';

/// Dark Theme UI Design Colors for RPS Stationery E-commerce App
/// Following the comprehensive design guide specifications
class DarkThemeColors {
  DarkThemeColors._();

  // ============================================================================
  // PRIMARY COLOR PALETTE (Dark Theme)
  // ============================================================================
  
  /// Background Primary - Deep black gray (#121212)
  static const Color backgroundPrimary = Color(0xFF121212);
  
  /// Background Secondary - Cards, sections (#1E1E1E)
  static const Color backgroundSecondary = Color(0xFF1E1E1E);
  
  /// Primary Accent - Vibrant green (#4CAF50)
  static const Color primaryAccent = Color(0xFF4CAF50);
  
  /// Primary Accent Gradient - Lighter green for gradients
  static const Color primaryAccentLight = Color(0xFF81C784);
  
  /// Secondary Accent - Teal for highlights, links, active icons (#03DAC6)
  static const Color secondaryAccent = Color(0xFF03DAC6);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================
  
  /// Text Primary - White (#FFFFFF)
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Text Secondary - Muted gray for labels, helper text (#B0B0B0)
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  /// Text Muted - Even more muted text (#7D7D7D)
  static const Color textMuted = Color(0xFF7D7D7D);

  // ============================================================================
  // BORDER AND DIVIDER COLORS
  // ============================================================================
  
  /// Borders/Dividers - Subtle lines (#2C2C2C)
  static const Color borderPrimary = Color(0xFF2C2C2C);
  
  /// Stronger borders (#3A3A3A)
  static const Color borderSecondary = Color(0xFF3A3A3A);

  // ============================================================================
  // BUTTON COLORS
  // ============================================================================
  
  /// Primary Button Background - Vibrant green
  static const Color buttonPrimary = primaryAccent;
  
  /// Primary Button Text - White
  static const Color buttonPrimaryText = textPrimary;
  
  /// Secondary Button Background - Transparent
  static const Color buttonSecondary = Colors.transparent;
  
  /// Secondary Button Border - Green accent
  static const Color buttonSecondaryBorder = primaryAccent;
  
  /// Secondary Button Text - Green accent
  static const Color buttonSecondaryText = primaryAccent;
  
  /// Disabled Button Background
  static const Color buttonDisabled = Color(0xFF2C2C2C);
  
  /// Disabled Button Text
  static const Color buttonDisabledText = Color(0xFF7D7D7D);

  // ============================================================================
  // STATUS AND FEEDBACK COLORS
  // ============================================================================
  
  /// Error/Alert - Red (#FF5252)
  static const Color error = Color(0xFFFF5252);
  
  /// Success - Green (matching primary)
  static const Color success = primaryAccent;
  
  /// Warning - Orange
  static const Color warning = Color(0xFFFF9800);
  
  /// Info - Blue
  static const Color info = Color(0xFF2196F3);

  // ============================================================================
  // FORM AND INPUT COLORS
  // ============================================================================
  
  /// Form Field Background
  static const Color formFieldBackground = borderPrimary;
  
  /// Form Field Border (inactive)
  static const Color formFieldBorder = borderSecondary;
  
  /// Form Field Border (focused)
  static const Color formFieldBorderFocused = primaryAccent;
  
  /// Form Field Text
  static const Color formFieldText = textPrimary;
  
  /// Form Field Placeholder
  static const Color formFieldPlaceholder = textSecondary;
  
  /// Form Field Label
  static const Color formFieldLabel = textSecondary;

  // ============================================================================
  // APP BAR AND NAVIGATION COLORS
  // ============================================================================
  
  /// App Bar Background
  static const Color appBarBackground = backgroundSecondary;
  
  /// App Bar Text
  static const Color appBarText = textPrimary;
  
  /// App Bar Icons (active)
  static const Color appBarIconActive = secondaryAccent;
  
  /// App Bar Icons (inactive)
  static const Color appBarIconInactive = textSecondary;

  // ============================================================================
  // BOTTOM NAVIGATION COLORS
  // ============================================================================
  
  /// Bottom Nav Background
  static const Color bottomNavBackground = backgroundSecondary;
  
  /// Bottom Nav Active Icon
  static const Color bottomNavActiveIcon = secondaryAccent;
  
  /// Bottom Nav Inactive Icon
  static const Color bottomNavInactiveIcon = textSecondary;
  
  /// Bottom Nav Active Text
  static const Color bottomNavActiveText = secondaryAccent;
  
  /// Bottom Nav Inactive Text
  static const Color bottomNavInactiveText = textSecondary;

  // ============================================================================
  // CARD AND SURFACE COLORS
  // ============================================================================
  
  /// Card Background
  static const Color cardBackground = backgroundSecondary;
  
  /// Card Border
  static const Color cardBorder = borderPrimary;
  
  /// Surface Background (for elevated elements)
  static const Color surfaceBackground = Color(0xFF1B1B1B);

  // ============================================================================
  // SEARCH BAR COLORS
  // ============================================================================
  
  /// Search Bar Background
  static const Color searchBarBackground = borderPrimary;
  
  /// Search Bar Icon
  static const Color searchBarIcon = secondaryAccent;
  
  /// Search Bar Placeholder
  static const Color searchBarPlaceholder = textSecondary;
  
  /// Search Bar Text
  static const Color searchBarText = textPrimary;

  // ============================================================================
  // SIDEBAR/DRAWER COLORS
  // ============================================================================
  
  /// Sidebar Background
  static const Color sidebarBackground = Color(0xFF1B1B1B);
  
  /// Sidebar Active Item Background
  static const Color sidebarActiveBackground = primaryAccent;
  
  /// Sidebar Active Text
  static const Color sidebarActiveText = textPrimary;
  
  /// Sidebar Inactive Text
  static const Color sidebarInactiveText = textSecondary;
  
  /// Sidebar Divider
  static const Color sidebarDivider = borderPrimary;

  // ============================================================================
  // PRODUCT AND COMMERCE SPECIFIC COLORS
  // ============================================================================
  
  /// Price Text - Accent color for pricing
  static const Color priceText = secondaryAccent;
  
  /// Discount Tag Background - Green accent
  static const Color discountTagBackground = primaryAccent;
  
  /// Discount Tag Text - White
  static const Color discountTagText = textPrimary;
  
  /// Product Card Background
  static const Color productCardBackground = backgroundSecondary;
  
  /// Category Card Border - Gradient highlight
  static const Color categoryCardBorder = primaryAccent;

  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================
  
  /// Primary Button Gradient
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [primaryAccent, primaryAccentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  /// Card Highlight Gradient (for category cards)
  static LinearGradient cardHighlightGradient = LinearGradient(
    colors: [
      primaryAccent.withValues(alpha: 0.3),
      secondaryAccent.withValues(alpha: 0.1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Background Gradient (subtle for main background)
  static LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundPrimary,
      backgroundSecondary.withValues(alpha: 0.8),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // SHADOW DEFINITIONS (Material 3 elevation system adapted for dark theme)
  // ============================================================================
  
  /// Light shadow for subtle elevation (cards)
  static List<BoxShadow> get elevation1 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];
  
  /// Medium shadow for standard elevation
  static List<BoxShadow> get elevation2 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  /// Higher shadow for floating elements
  static List<BoxShadow> get elevation3 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // BORDER RADIUS CONSTANTS
  // ============================================================================
  
  /// Small radius (8dp)
  static const double radiusSmall = 8.0;
  
  /// Medium radius (12dp) - Cards, inputs
  static const double radiusMedium = 12.0;
  
  /// Large radius (16dp) - Large cards
  static const double radiusLarge = 16.0;
  
  /// Extra large radius (24dp) - Special components
  static const double radiusXLarge = 24.0;
  
  /// Pill radius (25dp) - Buttons
  static const double radiusPill = 25.0;
  
  /// Full radius (999dp) - Circular elements
  static const double radiusFull = 999.0;

  // ============================================================================
  // SPACING CONSTANTS (8dp grid system)
  // ============================================================================
  
  /// Extra small spacing (4dp)
  static const double spacingXS = 4.0;
  
  /// Small spacing (8dp)
  static const double spacingSM = 8.0;
  
  /// Medium spacing (16dp)
  static const double spacingMD = 16.0;
  
  /// Large spacing (24dp)
  static const double spacingLG = 24.0;
  
  /// Extra large spacing (32dp)
  static const double spacingXL = 32.0;
  
  /// Extra extra large spacing (48dp)
  static const double spacingXXL = 48.0;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Create gradient with custom colors
  static LinearGradient customGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }
}
