import 'package:flutter/material.dart';
import '../network_image_with_loader.dart';
import '../../utils/navigation/url_navigation_service.dart';

/// Unified Banner Component
/// Replaces all banner variants (BannerL, BannerM, BannerS, etc.)
/// with a single configurable component following enterprise standards.
class UnifiedBanner extends StatelessWidget {
  const UnifiedBanner({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.size = BannerSize.medium,
    this.overlayColor = Colors.black45,
    this.borderRadius = 8.0,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.alignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.all(16.0),
    this.showOverlay = true,
    this.children = const [],
    this.width,
    this.height,
    this.aspectRatio,
    this.redirectUrl,
    this.bannerId,
    this.source,
    this.metadata,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final BannerSize size;
  final Color overlayColor;
  final double borderRadius;
  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final AlignmentGeometry alignment;
  final EdgeInsets padding;
  final bool showOverlay;
  final List<Widget> children;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final String? redirectUrl;
  final String? bannerId;
  final String? source;
  final Map<String, dynamic>? metadata;

  @override
  Widget build(BuildContext context) {
    final bannerSize = _getBannerDimensions();
    
    Widget banner = Container(
      width: width ?? bannerSize.width,
      height: height ?? bannerSize.height,
      child: AspectRatio(
        aspectRatio: aspectRatio ?? bannerSize.aspectRatio,
        child: GestureDetector(
          onTap: () => _handleBannerTap(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                NetworkImageWithLoader(
                  imageUrl,
                  radius: 0,
                  fit: BoxFit.cover,
                ),
                
                // Overlay
                if (showOverlay)
                  Container(color: overlayColor),
                
                // Content
                if (title != null || subtitle != null)
                  Positioned.fill(
                    child: Padding(
                      padding: padding,
                      child: Align(
                        alignment: alignment,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: _getCrossAxisAlignment(),
                          children: [
                            if (title != null)
                              Text(
                                title!,
                                style: titleStyle ?? _getDefaultTitleStyle(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (title != null && subtitle != null)
                              const SizedBox(height: 4),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: subtitleStyle ?? _getDefaultSubtitleStyle(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Custom children
                ...children,
              ],
            ),
          ),
        ),
      ),
    );

    return banner;
  }

  /// Handle banner tap - either navigate to URL or call custom onTap
  void _handleBannerTap() {
    if (redirectUrl != null && redirectUrl!.isNotEmpty) {
      // Navigate to URL if provided with analytics tracking
      UrlNavigationService.navigateToUrl(
        redirectUrl,
        bannerId: bannerId,
        source: source,
        metadata: metadata,
      );
    } else {
      // Call custom onTap callback
      onTap();
    }
  }

  BannerDimensions _getBannerDimensions() {
    switch (size) {
      case BannerSize.small:
        return BannerDimensions(width: null, height: 120, aspectRatio: 2.5);
      case BannerSize.medium:
        return BannerDimensions(width: null, height: 180, aspectRatio: 1.87);
      case BannerSize.large:
        return BannerDimensions(width: null, height: 240, aspectRatio: 1.6);
      case BannerSize.hero:
        return BannerDimensions(width: null, height: 300, aspectRatio: 1.4);
    }
  }

  CrossAxisAlignment _getCrossAxisAlignment() {
    if (alignment == Alignment.centerLeft || alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) {
      return CrossAxisAlignment.start;
    } else if (alignment == Alignment.centerRight || alignment == Alignment.topRight || alignment == Alignment.bottomRight) {
      return CrossAxisAlignment.end;
    } else {
      return CrossAxisAlignment.center;
    }
  }

  TextStyle _getDefaultTitleStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle _getDefaultSubtitleStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
  }
}

enum BannerSize {
  small,
  medium,
  large,
  hero,
}

class BannerDimensions {
  final double? width;
  final double? height;
  final double aspectRatio;

  BannerDimensions({
    required this.width,
    required this.height,
    required this.aspectRatio,
  });
}

// Legacy aliases for backward compatibility
typedef BannerL = UnifiedBanner;
typedef BannerM = UnifiedBanner;
typedef BannerS = UnifiedBanner;
