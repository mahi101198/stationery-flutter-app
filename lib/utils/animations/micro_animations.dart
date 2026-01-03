import 'package:flutter/material.dart';

/// Micro-animations utility class for consistent app animations
class MicroAnimations {
  // Animation durations following Material Design guidelines
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration lazy = Duration(milliseconds: 800);

  // Standard animation curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve slideUpCurve = Curves.decelerate;

  /// Smooth fade transition
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
    double? begin,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: begin ?? 0.0, end: 1.0),
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: child,
    );
  }

  /// Smooth slide up animation
  static Widget slideUp({
    required Widget child,
    Duration duration = normal,
    Curve curve = slideUpCurve,
    double offset = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: offset, end: 0.0),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value),
        child: child,
      ),
      child: child,
    );
  }

  /// Combined fade and slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
    double slideOffset = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, slideOffset * (1 - value)),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Scale animation for buttons and cards
  static Widget scaleIn({
    required Widget child,
    Duration duration = fast,
    Curve curve = bounceIn,
    double beginScale = 0.8,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: beginScale, end: 1.0),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: child,
    );
  }

  /// Shimmer loading animation
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.linear,
      tween: Tween<double>(begin: -2.0, end: 2.0),
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? Colors.grey[300]!,
                highlightColor ?? Colors.grey[100]!,
                baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                (value - 1).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Smooth container expansion
  static Widget expandHeight({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = normal,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + (delay * index),
      curve: easeOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// Smooth color transition
  static Widget colorTransition({
    required Widget child,
    required Color fromColor,
    required Color toColor,
    Duration duration = normal,
    Curve curve = easeInOut,
  }) {
    return TweenAnimationBuilder<Color?>(
      duration: duration,
      curve: curve,
      tween: ColorTween(begin: fromColor, end: toColor),
      builder: (context, color, child) => ColoredBox(
        color: color!,
        child: child,
      ),
      child: child,
    );
  }

  /// Pulse animation for emphasis
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: minScale, end: maxScale),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: child,
      onEnd: () {
        // Create infinite pulse by rebuilding with reversed values
      },
    );
  }
}

/// Animation wrapper widget for easy implementation
class AnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool fadeIn;
  final bool slideUp;
  final bool scaleIn;
  final double? slideOffset;
  final double? scaleBegin;
  final int? staggerIndex;

  const AnimatedContainer({
    super.key,
    required this.child,
    this.duration = MicroAnimations.normal,
    this.curve = MicroAnimations.easeOut,
    this.fadeIn = false,
    this.slideUp = false,
    this.scaleIn = false,
    this.slideOffset,
    this.scaleBegin,
    this.staggerIndex,
  });

  @override
  Widget build(BuildContext context) {
    Widget animatedChild = child;

    if (staggerIndex != null) {
      animatedChild = MicroAnimations.staggeredListItem(
        index: staggerIndex!,
        duration: duration,
        child: animatedChild,
      );
    } else {
      if (fadeIn && slideUp) {
        animatedChild = MicroAnimations.fadeSlideIn(
          duration: duration,
          curve: curve,
          slideOffset: slideOffset ?? 20.0,
          child: animatedChild,
        );
      } else if (fadeIn) {
        animatedChild = MicroAnimations.fadeIn(
          duration: duration,
          curve: curve,
          child: animatedChild,
        );
      } else if (slideUp) {
        animatedChild = MicroAnimations.slideUp(
          duration: duration,
          curve: curve,
          offset: slideOffset ?? 20.0,
          child: animatedChild,
        );
      }

      if (scaleIn) {
        animatedChild = MicroAnimations.scaleIn(
          duration: duration,
          curve: curve,
          beginScale: scaleBegin ?? 0.8,
          child: animatedChild,
        );
      }
    }

    return animatedChild;
  }
}

/// Smooth page transition animations
class SmoothPageTransitions {
  static Route<T> fadeThrough<T extends Object?>({
    required Widget page,
    Duration duration = MicroAnimations.normal,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  static Route<T> slideUp<T extends Object?>({
    required Widget page,
    Duration duration = MicroAnimations.normal,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  static Route<T> slideFromRight<T extends Object?>({
    required Widget page,
    Duration duration = MicroAnimations.normal,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}
