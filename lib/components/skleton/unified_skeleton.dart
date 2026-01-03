import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Unified Skeleton Component
/// Replaces all skeleton variants with a single configurable component
/// following enterprise standards.
class UnifiedSkeleton extends StatelessWidget {
  const UnifiedSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.type = SkeletonType.rectangle,
    this.aspectRatio,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final SkeletonType type;
  final double? aspectRatio;
  final EdgeInsets? margin;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBaseColor = baseColor ?? 
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final effectiveHighlightColor = highlightColor ?? 
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    Widget skeleton = Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBaseColor,
          borderRadius: type == SkeletonType.circle 
            ? null 
            : BorderRadius.circular(borderRadius),
          shape: type == SkeletonType.circle 
            ? BoxShape.circle 
            : BoxShape.rectangle,
        ),
      ),
    );

    if (aspectRatio != null) {
      skeleton = AspectRatio(
        aspectRatio: aspectRatio!,
        child: skeleton,
      );
    }

    if (margin != null) {
      skeleton = Container(
        margin: margin,
        child: skeleton,
      );
    }

    return skeleton;
  }

  // Named constructors for common use cases
  const UnifiedSkeleton.banner({
    super.key,
    this.width,
    this.height = 180,
    this.aspectRatio = 1.87,
    this.margin,
    this.baseColor,
    this.highlightColor,
  }) : borderRadius = 8.0,
       type = SkeletonType.rectangle;

  const UnifiedSkeleton.card({
    super.key,
    this.width,
    this.height = 120,
    this.margin,
    this.baseColor,
    this.highlightColor,
  }) : borderRadius = 12.0,
       type = SkeletonType.rectangle,
       aspectRatio = null;

  const UnifiedSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.margin,
    this.baseColor,
    this.highlightColor,
  }) : borderRadius = 4.0,
       type = SkeletonType.rectangle,
       aspectRatio = null;

  const UnifiedSkeleton.circle({
    super.key,
    required double size,
    this.margin,
    this.baseColor,
    this.highlightColor,
  }) : width = size,
       height = size,
       borderRadius = 0,
       type = SkeletonType.circle,
       aspectRatio = null;

  const UnifiedSkeleton.avatar({
    super.key,
    this.margin,
    this.baseColor,
    this.highlightColor,
  }) : width = 40,
       height = 40,
       borderRadius = 0,
       type = SkeletonType.circle,
       aspectRatio = null;
}

enum SkeletonType {
  rectangle,
  circle,
}

// Legacy aliases for backward compatibility
typedef BannerLSkeleton = UnifiedSkeleton;
typedef BannerMSkeleton = UnifiedSkeleton;
typedef BannerSSkeleton = UnifiedSkeleton;
