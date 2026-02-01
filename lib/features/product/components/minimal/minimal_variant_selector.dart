import 'package:flutter/material.dart';

/// Minimal Variant Selector - Matches mockup design exactly
class MinimalVariantSelector extends StatelessWidget {
  final String attributeName;
  final List<String> options;
  final String? selectedValue;
  final Function(String) onSelected;

  const MinimalVariantSelector({
    super.key,
    required this.attributeName,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  String _formatAttributeName(String name) {
    // Convert snake_case to UPPERCASE
    return name.replaceAll('_', ' ').toUpperCase();
  }

  String _formatOptionValue(String value) {
    // Format option values for display - capitalize first letter
    final words = value.split('_');
    return words
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (uppercase, small, gray)
          Text(
            _formatAttributeName(attributeName),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Variant Chips
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedValue == option;

              return GestureDetector(
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00BCD4) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: Color(0x1A00BCD4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _formatOptionValue(option),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
