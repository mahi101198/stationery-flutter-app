import 'package:flutter/material.dart';

/// App spacing constants following Material Design 3 guidelines
/// Based on 8dp grid system for consistent spacing throughout the app
class AppSpacing {
  // Base spacing unit (8dp)
  static const double _baseUnit = 8.0;

  // Standard spacing values
  static const double xs = _baseUnit * 0.5; // 4dp
  static const double sm = _baseUnit; // 8dp
  static const double md = _baseUnit * 2; // 16dp
  static const double lg = _baseUnit * 3; // 24dp
  static const double xl = _baseUnit * 4; // 32dp
  static const double xxl = _baseUnit * 6; // 48dp
  static const double xxxl = _baseUnit * 8; // 64dp

  // Semantic spacing names
  static const double tiny = xs; // 4dp
  static const double small = sm; // 8dp
  static const double medium = md; // 16dp
  static const double large = lg; // 24dp
  static const double extraLarge = xl; // 32dp
  static const double huge = xxl; // 48dp
  static const double massive = xxxl; // 64dp

  // Component-specific spacing
  static const double cardPadding = md; // 16dp
  static const double screenPadding = md; // 16dp
  static const double sectionSpacing = lg; // 24dp
  static const double elementSpacing = sm; // 8dp
  static const double listItemSpacing = md; // 16dp
  static const double buttonPadding = md; // 16dp
  static const double inputPadding = md; // 16dp

  // Layout spacing
  static const double headerSpacing = xl; // 32dp
  static const double footerSpacing = xl; // 32dp
  static const double contentSpacing = lg; // 24dp
  static const double paragraphSpacing = md; // 16dp
  
  // Border radius
  static const double borderRadius = 12.0; // 12dp - standard border radius
  static const double borderRadiusSmall = 8.0; // 8dp - small border radius
  static const double borderRadiusLarge = 16.0; // 16dp - large border radius
  static const double chipBorderRadius = 20.0; // 20dp - chip border radius
  static const double searchBarRadius = 20.0; // 20dp - search bar border radius
  
  // Button specific spacing
  static const double buttonHorizontalPadding = lg; // 24dp
  static const double buttonVerticalPadding = md - 4; // 12dp

  // Custom spacing multipliers
  static double custom(double multiplier) => _baseUnit * multiplier;

  // Responsive spacing based on screen size
  static double responsive(BuildContext context, {
    double mobile = md,
    double tablet = lg,
    double desktop = xl,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1024) {
      return desktop;
    } else if (screenWidth >= 768) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

/// Extension on EdgeInsets for consistent padding/margin
extension AppPadding on EdgeInsets {
  // Standard padding presets
  static const EdgeInsets xs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets sm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets md = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets lg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets xl = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets xxl = EdgeInsets.all(AppSpacing.xxl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: AppSpacing.xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: AppSpacing.xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: AppSpacing.md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: AppSpacing.lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: AppSpacing.xl);

  // Screen-safe padding (including status bar/bottom safe area)
  static EdgeInsets screenSafe(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top + AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: mediaQuery.padding.bottom + AppSpacing.md,
    );
  }

  // Content padding with safe area
  static EdgeInsets contentSafe(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      MediaQuery.of(context).padding.bottom + AppSpacing.md,
    );
  }
}

/// SizedBox extension for consistent spacing
extension AppGaps on SizedBox {
  // Vertical gaps
  static const SizedBox xs = SizedBox(height: AppSpacing.xs);
  static const SizedBox sm = SizedBox(height: AppSpacing.sm);
  static const SizedBox md = SizedBox(height: AppSpacing.md);
  static const SizedBox lg = SizedBox(height: AppSpacing.lg);
  static const SizedBox xl = SizedBox(height: AppSpacing.xl);
  static const SizedBox xxl = SizedBox(height: AppSpacing.xxl);

  // Horizontal gaps
  static const SizedBox horizontalXs = SizedBox(width: AppSpacing.xs);
  static const SizedBox horizontalSm = SizedBox(width: AppSpacing.sm);
  static const SizedBox horizontalMd = SizedBox(width: AppSpacing.md);
  static const SizedBox horizontalLg = SizedBox(width: AppSpacing.lg);
  static const SizedBox horizontalXl = SizedBox(width: AppSpacing.xl);

  // Custom gaps
  static SizedBox height(double value) => SizedBox(height: value);
  static SizedBox width(double value) => SizedBox(width: value);
  
  // Grid-based custom gaps
  static SizedBox customHeight(double multiplier) => SizedBox(height: AppSpacing.custom(multiplier));
  static SizedBox customWidth(double multiplier) => SizedBox(width: AppSpacing.custom(multiplier));
}

/// Divider extension for consistent dividers
extension AppDividers on Divider {
  static const Divider thin = Divider(height: 1, thickness: 0.5);
  static const Divider normal = Divider(height: AppSpacing.sm, thickness: 1);
  static const Divider thick = Divider(height: AppSpacing.md, thickness: 2);
  
  // Themed dividers
  static Divider themed(BuildContext context, {double? height, double? thickness}) {
    return Divider(
      height: height ?? AppSpacing.sm,
      thickness: thickness ?? 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}

/// Border radius extension for consistent border radius
extension AppBorderRadius on BorderRadius {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Spacing validation utility
class SpacingValidator {
  /// Validates if spacing follows 8dp grid system
  static bool isValidSpacing(double value) {
    return (value % 4) == 0; // Allow 4dp increments for flexibility
  }

  /// Suggests closest valid spacing
  static double suggestValidSpacing(double value) {
    return (value / 4).round() * 4.0;
  }

  /// Validates EdgeInsets for proper spacing
  static bool isValidPadding(EdgeInsets padding) {
    return isValidSpacing(padding.top) &&
           isValidSpacing(padding.right) &&
           isValidSpacing(padding.bottom) &&
           isValidSpacing(padding.left);
  }

  /// Debug helper to check spacing in development
  static void debugCheckSpacing(String componentName, EdgeInsets padding) {
    assert(() {
      if (!isValidPadding(padding)) {
        print('⚠️ Invalid spacing in $componentName: $padding');
        print('   Suggested: EdgeInsets.fromLTRB('
              '${suggestValidSpacing(padding.left)}, '
              '${suggestValidSpacing(padding.top)}, '
              '${suggestValidSpacing(padding.right)}, '
              '${suggestValidSpacing(padding.bottom)})');
      }
      return true;
    }());
  }
}
