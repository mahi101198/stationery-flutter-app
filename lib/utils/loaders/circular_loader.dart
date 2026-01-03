import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';

/// A circular loader widget with customizable foreground and background colors.
class TCircularLoader extends StatelessWidget {
  /// Default constructor for the TCircularLoader.
  ///
  /// Parameters:
  ///   - foregroundColor: The color of the circular loader.
  ///   - backgroundColor: The background color of the circular loader.
  const TCircularLoader({
    super.key,
    this.foregroundColor,
    this.backgroundColor,
  });

  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
      ), // Circular background
      child: Center(
        child: CircularProgressIndicator(
          color: effectiveForegroundColor,
          backgroundColor: Colors.transparent,
        ), // Circular loader
      ),
    );
  }
}
