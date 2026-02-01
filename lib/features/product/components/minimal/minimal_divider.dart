import 'package:flutter/material.dart';

/// Minimal Divider Section
/// Visual separation between sections
/// Height: 8px, Background: #F5F5F5
class MinimalDivider extends StatelessWidget {
  const MinimalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
