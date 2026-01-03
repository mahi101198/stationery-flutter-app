import 'package:flutter/material.dart';

/// Utilities for detecting and preventing overflow issues
class OverflowHelpers {
  /// Safe text widget that prevents overflow
  static Widget safeText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines ?? 2,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: true,
    );
  }

  /// Flexible text that adapts to available space
  static Widget flexibleText(
    String text, {
    TextStyle? style,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
    int flex = 1,
  }) {
    return Flexible(
      flex: flex,
      child: safeText(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  /// Expanded text that takes all available space
  static Widget expandedText(
    String text, {
    TextStyle? style,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: safeText(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  /// Safe container with constrained dimensions
  static Widget safeContainer({
    required Widget child,
    double? width,
    double? height,
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
      ),
      child: child,
    );
  }

  /// Safe column that prevents overflow
  static Widget safeColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool shrinkWrap = false,
  }) {
    if (shrinkWrap) {
      return IntrinsicHeight(
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        ),
      );
    }
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// Safe row that prevents horizontal overflow
  static Widget safeRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool wrap = false,
  }) {
    if (wrap) {
      return Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// Responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth >= 1024 
        ? desktop 
        : screenWidth >= 768 
            ? tablet 
            : mobile;
    return EdgeInsets.all(padding);
  }

  /// Safe image widget that handles errors gracefully
  static Widget safeImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    Widget imageWidget;
    
    if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? 
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? 
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              );
        },
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? 
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              );
        },
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Safe list view that handles empty states
  static Widget safeListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    Widget? emptyWidget,
  }) {
    if (children.isEmpty) {
      return emptyWidget ?? 
          const Center(
            child: Text('No items to display'),
          );
    }

    return ListView(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }

  /// Safe grid view with responsive columns
  static Widget safeGridView({
    required List<Widget> children,
    required int crossAxisCount,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
    bool shrinkWrap = false,
    Widget? emptyWidget,
  }) {
    if (children.isEmpty) {
      return emptyWidget ?? 
          const Center(
            child: Text('No items to display'),
          );
    }

    return GridView.count(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
  }

  /// Constrained width wrapper for better responsive design
  static Widget constrainedWidth({
    required Widget child,
    double maxWidth = 600,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null 
            ? Padding(padding: padding, child: child)
            : child,
      ),
    );
  }

  /// Screen size breakpoints
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Responsive columns count based on screen size
  static int responsiveColumns(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Safe scaffold with proper constraints
  static Widget safeScaffold({
    Key? key,
    PreferredSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    Widget? drawer,
    Widget? endDrawer,
    Widget? bottomNavigationBar,
    Widget? bottomSheet,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    return Scaffold(
      key: key,
      appBar: appBar,
      body: body != null 
          ? SafeArea(
              child: body,
            )
          : null,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Widget for debugging overflow issues in development
class OverflowDebugger extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const OverflowDebugger({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Banner(
      message: 'DEBUG',
      location: BannerLocation.topEnd,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Extension on BuildContext for easy overflow prevention
extension OverflowContext on BuildContext {
  /// Get responsive padding
  EdgeInsets get responsivePadding => OverflowHelpers.responsivePadding(this);
  
  /// Check if screen is mobile
  bool get isMobile => OverflowHelpers.isMobile(this);
  
  /// Check if screen is tablet
  bool get isTablet => OverflowHelpers.isTablet(this);
  
  /// Check if screen is desktop
  bool get isDesktop => OverflowHelpers.isDesktop(this);
  
  /// Get responsive columns count
  int responsiveColumns({
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) => OverflowHelpers.responsiveColumns(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
