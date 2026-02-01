import 'package:flutter/material.dart';
import 'package:rps_stationery/constants.dart';

/// Dynamic Variant Selector - Renders chip groups from backend variant_attributes
class VariantSelector extends StatelessWidget {
  final Map<String, List<String>> variantAttributes;
  final Map<String, String> selectedAttributes;
  final Function(String attributeName, String value) onAttributeSelected;

  const VariantSelector({
    super.key,
    required this.variantAttributes,
    required this.selectedAttributes,
    required this.onAttributeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (variantAttributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: variantAttributes.entries.map((entry) {
            final attributeName = entry.key;
            final values = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attribute label
                  Text(
                    _formatAttributeName(attributeName),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Attribute values as chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((value) {
                      final isSelected = selectedAttributes[attributeName] == value;
                      
                      return ChoiceChip(
                        label: Text(
                          _formatAttributeValue(value),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => onAttributeSelected(attributeName, value),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        elevation: isSelected ? 2 : 0,
                        pressElevation: 4,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Format attribute name for display (e.g., "pack_size" -> "Pack Size")
  String _formatAttributeName(String name) {
    return name
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Format attribute value for display (e.g., "pack1" -> "Pack 1")
  String _formatAttributeValue(String value) {
    // Handle common patterns
    if (value.toLowerCase().startsWith('pack')) {
      return value.replaceAllMapped(
        RegExp(r'pack(\d+)', caseSensitive: false),
        (match) => 'Pack of ${match.group(1)}',
      );
    }
    
    // Capitalize first letter
    return value.isEmpty ? '' : value[0].toUpperCase() + value.substring(1);
  }
}
