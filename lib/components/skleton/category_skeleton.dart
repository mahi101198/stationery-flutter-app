import 'package:flutter/material.dart';

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 2, // Show only 2 skeleton items
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          // Removed icon - just blank skeleton
        );
      },
    );
  }
}
