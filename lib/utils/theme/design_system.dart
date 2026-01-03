import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

/// Modern design system with tokens for consistent UI/UX
class DesignSystem {
  // Private constructor
  DesignSystem._();

  /// Design tokens for spacing
  static const spacing = _Spacing();
  
  /// Design tokens for typography
  static const typography = _Typography();
  
  /// Design tokens for shadows
  static const shadows = _Shadows();
  
  /// Design tokens for borders
  static const borders = _Borders();
  
  /// Design tokens for animations
  static const animations = _Animations();
  
  /// Design tokens for breakpoints
  static const breakpoints = _Breakpoints();
}

/// Spacing design tokens
class _Spacing {
  const _Spacing();
  
  // Base spacing unit (8dp)
  static const double _unit = 8.0;
  
  // Semantic spacing
  double get xs => _unit * 0.5; // 4dp
  double get sm => _unit * 1; // 8dp
  double get md => _unit * 2; // 16dp
  double get lg => _unit * 3; // 24dp
  double get xl => _unit * 4; // 32dp
  double get xxl => _unit * 6; // 48dp
  double get xxxl => _unit * 8; // 64dp
  
  // Component-specific spacing
  double get cardPadding => md;
  double get sectionSpacing => lg;
  double get elementSpacing => sm;
  double get screenPadding => md;
}

/// Typography design tokens
class _Typography {
  const _Typography();
  
  // Base font family
  static const String _fontFamily = 'Inter';
  
  // Display text styles
  TextStyle get displayLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: TColors.textPrimary,
  );
  
  TextStyle get displayMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
    color: TColors.textPrimary,
  );
  
  TextStyle get displaySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: TColors.textPrimary,
  );
  
  // Heading text styles
  TextStyle get headlineLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: TColors.textPrimary,
  );
  
  TextStyle get headlineMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: TColors.textPrimary,
  );
  
  TextStyle get headlineSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: TColors.textPrimary,
  );
  
  // Title text styles
  TextStyle get titleLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: TColors.textPrimary,
  );
  
  TextStyle get titleMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: TColors.textPrimary,
  );
  
  TextStyle get titleSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: TColors.textPrimary,
  );
  
  // Body text styles
  TextStyle get bodyLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: TColors.textPrimary,
  );
  
  TextStyle get bodyMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: TColors.textPrimary,
  );
  
  TextStyle get bodySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: TColors.textSecondary,
  );
  
  // Label text styles
  TextStyle get labelLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: TColors.textPrimary,
  );
  
  TextStyle get labelMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: TColors.textPrimary,
  );
  
  TextStyle get labelSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: TColors.textSecondary,
  );
  
  // Special text styles
  TextStyle get caption => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: TColors.textSecondary,
  );
  
  TextStyle get overline => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 1.5,
    color: TColors.textSecondary,
  );
}

/// Shadow design tokens
class _Shadows {
  const _Shadows();
  
  // Elevation shadows
  List<BoxShadow> get elevation1 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  List<BoxShadow> get elevation2 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  List<BoxShadow> get elevation3 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  
  List<BoxShadow> get elevation4 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  // Colored shadows
  List<BoxShadow> primaryShadow(double opacity) => [
    BoxShadow(
      color: TColors.primary.withValues(alpha: opacity * 0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  List<BoxShadow> successShadow(double opacity) => [
    BoxShadow(
      color: TColors.success.withValues(alpha: opacity * 0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  List<BoxShadow> errorShadow(double opacity) => [
    BoxShadow(
      color: TColors.error.withValues(alpha: opacity * 0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}

/// Border design tokens
class _Borders {
  const _Borders();
  
  // Border radius
  BorderRadius get none => BorderRadius.circular(0);
  BorderRadius get sm => BorderRadius.circular(4);
  BorderRadius get md => BorderRadius.circular(8);
  BorderRadius get lg => BorderRadius.circular(12);
  BorderRadius get xl => BorderRadius.circular(16);
  BorderRadius get xxl => BorderRadius.circular(24);
  BorderRadius get full => BorderRadius.circular(9999);
  
  // Border widths
  double get thin => 1;
  double get medium => 2;
  double get thick => 3;
  
  // Border colors
  Color get subtle => TColors.borderPrimary;
  Color get default_ => TColors.borderSecondary;
  Color get strong => TColors.textSecondary;
  Color get accent => TColors.primary;
}

/// Animation design tokens
class _Animations {
  const _Animations();
  
  // Duration tokens
  Duration get fastest => const Duration(milliseconds: 100);
  Duration get fast => const Duration(milliseconds: 200);
  Duration get normal => const Duration(milliseconds: 300);
  Duration get slow => const Duration(milliseconds: 500);
  Duration get slowest => const Duration(milliseconds: 700);
  
  // Curve tokens
  Curve get easeIn => Curves.easeIn;
  Curve get easeOut => Curves.easeOut;
  Curve get easeInOut => Curves.easeInOut;
  Curve get bounce => Curves.bounceOut;
  Curve get elastic => Curves.elasticOut;
  
  // Spring curves
  Curve get spring => Curves.elasticOut;
  Curve get gentleSpring => const Cubic(0.25, 0.46, 0.45, 0.94);
}

/// Breakpoint design tokens
class _Breakpoints {
  const _Breakpoints();
  
  double get mobile => 480;
  double get tablet => 768;
  double get desktop => 1024;
  double get largeDesktop => 1440;
}

/// Design system extensions
extension DesignSystemContext on BuildContext {
  /// Get screen size category
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    if (width < DesignSystem.breakpoints.mobile) return ScreenSize.mobile;
    if (width < DesignSystem.breakpoints.tablet) return ScreenSize.tablet;
    if (width < DesignSystem.breakpoints.desktop) return ScreenSize.desktop;
    return ScreenSize.largeDesktop;
  }
  
  /// Check if screen is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;
  
  /// Check if screen is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;
  
  /// Check if screen is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop || screenSize == ScreenSize.largeDesktop;
}

enum ScreenSize { mobile, tablet, desktop, largeDesktop }

/// Theme extension for design system
extension ThemeExtension on ThemeData {
  /// Get design system typography
  _Typography get designTypography => DesignSystem.typography;
  
  /// Get design system spacing
  _Spacing get designSpacing => DesignSystem.spacing;
  
  /// Get design system shadows
  _Shadows get designShadows => DesignSystem.shadows;
  
  /// Get design system borders
  _Borders get designBorders => DesignSystem.borders;
  
  /// Get design system animations
  _Animations get designAnimations => DesignSystem.animations;
}
