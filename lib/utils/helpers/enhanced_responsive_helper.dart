import 'package:flutter/material.dart';

/// Enhanced responsive design helper for handling different screen sizes
class EnhancedResponsiveHelper {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;
  static const double _desktopBreakpoint = 1440;

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _tabletBreakpoint;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: getResponsiveValue(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }

  /// Get responsive grid columns count
  static int getGridColumns(BuildContext context, {double itemWidth = 200.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getResponsivePadding(context).horizontal;
    final availableWidth = screenWidth - padding;
    final columns = (availableWidth / itemWidth).floor();
    return columns.clamp(1, 4);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < _mobileBreakpoint) {
      return baseFontSize * 0.9;
    } else if (screenWidth < _tabletBreakpoint) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get status bar height
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get navigation bar height
  static double getNavigationBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Check if device has notch
  static bool hasNotch(BuildContext context) {
    return MediaQuery.of(context).padding.top > 24;
  }

  /// Get device orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(
    BuildContext context, {
    double? maxWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultMaxWidth = getResponsiveValue(
      context,
      mobile: screenWidth,
      tablet: 800.0,
      desktop: maxWidth ?? 1200.0,
    );

    return BoxConstraints(
      maxWidth: defaultMaxWidth,
      minWidth: 0,
    );
  }
}

/// Extension on BuildContext for easy access to responsive helpers
extension EnhancedResponsiveExtension on BuildContext {
  bool get isMobile => EnhancedResponsiveHelper.isMobile(this);
  bool get isTablet => EnhancedResponsiveHelper.isTablet(this);
  bool get isDesktop => EnhancedResponsiveHelper.isDesktop(this);
  bool get isLandscape => EnhancedResponsiveHelper.isLandscape(this);
  bool get isPortrait => EnhancedResponsiveHelper.isPortrait(this);
  bool get hasNotch => EnhancedResponsiveHelper.hasNotch(this);

  EdgeInsets get responsivePadding => EnhancedResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get safeAreaPadding => EnhancedResponsiveHelper.getSafeAreaPadding(this);
  
  double get statusBarHeight => EnhancedResponsiveHelper.getStatusBarHeight(this);
  double get navigationBarHeight => EnhancedResponsiveHelper.getNavigationBarHeight(this);

  T getEnhancedResponsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      EnhancedResponsiveHelper.getResponsiveValue(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  int getEnhancedGridColumns({double itemWidth = 200.0}) =>
      EnhancedResponsiveHelper.getGridColumns(this, itemWidth: itemWidth);

  double getEnhancedResponsiveFontSize(double baseFontSize) =>
      EnhancedResponsiveHelper.getResponsiveFontSize(this, baseFontSize);

  BoxConstraints getEnhancedResponsiveConstraints({double? maxWidth}) =>
      EnhancedResponsiveHelper.getResponsiveConstraints(this, maxWidth: maxWidth);
}

/// Enhanced responsive wrapper widget that adapts to screen size
class EnhancedResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const EnhancedResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!;
    }
    if (context.isTablet && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Enhanced safe area wrapper with consistent padding
class EnhancedSafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets? minimum;

  const EnhancedSafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum ?? EdgeInsets.zero,
      child: child,
    );
  }
}

/// Enhanced responsive layout builder
class EnhancedResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      builder;
  final double? maxWidth;

  const EnhancedResponsiveLayoutBuilder({
    super.key,
    required this.builder,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveConstraints = context.getEnhancedResponsiveConstraints(
          maxWidth: maxWidth,
        );
        
        return Center(
          child: Container(
            constraints: responsiveConstraints,
            child: builder(context, constraints),
          ),
        );
      },
    );
  }
}
