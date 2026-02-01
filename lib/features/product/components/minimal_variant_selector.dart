import 'package:flutter/material.dart';

/// Variant selector component (e.g., SIZE: Small, Medium, Large)
/// Matches mockup design with cyan selected state
class MinimalVariantSelector extends StatelessWidget {
  final String label;
  final List<String> variants;
  final String? selectedVariant;
  final Function(String) onVariantSelected;

  const MinimalVariantSelector({
    super.key,
    required this.label,
    required this.variants,
    this.selectedVariant,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label.toUpperCase(),
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
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = variant == selectedVariant;
            return _VariantChip(
              label: variant,
              isSelected: isSelected,
              onTap: () => onVariantSelected(variant),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual variant chip
class _VariantChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
