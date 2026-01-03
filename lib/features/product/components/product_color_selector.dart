import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/constants.dart';

/// Product Color Selector Component
/// Displays available color options for a product
class ProductColorSelector extends StatelessWidget {
  const ProductColorSelector({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<String> colors;
  final String selectedColor;
  final Function(String color) onColorSelected;

  @override
  Widget build(BuildContext context) {
    // Don't show if no colors
    if (colors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding / 2),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Colors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = color == selectedColor;

              return _ColorOption(
                color: color,
                isSelected: isSelected,
                onTap: () {
                  if (!isSelected) {
                    onColorSelected(color);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String color;
  final bool isSelected;
  final VoidCallback onTap;

  Color _getColorFromName() {
    // Map common color names to Flutter colors
    final colorName = color.toLowerCase();
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'lime':
        return Colors.lime;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = _getColorFromName();
    final isDarkColor = displayColor.computeLuminance() < 0.5;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkColor ? Colors.white : Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: isDarkColor ? Colors.white : Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // Color name
            Text(
              color,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

