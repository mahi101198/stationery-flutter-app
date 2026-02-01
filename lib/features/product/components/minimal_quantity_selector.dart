import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';

/// Quantity selector with +/- buttons
/// Matches mockup design with circular buttons - Now reactive
class MinimalQuantitySelector extends StatelessWidget {
  final int maxQuantity;
  final Function() onIncrement;
  final Function() onDecrement;

  const MinimalQuantitySelector({
    super.key,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ProductDetailController.instance;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'QUANTITY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        
        // Selector
        Row(
          children: [
            // Minus Button
            Obx(() {
              final quantity = controller.quantity.value;
              return _buildButton(
                context,
                icon: Icons.remove,
                onTap: quantity > 1 ? onDecrement : null,
              );
            }),
            const SizedBox(width: 16),
            
            // Count Display - Only this part is reactive
            Obx(() {
              final quantity = controller.quantity.value;
              return TweenAnimationBuilder<int>(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                tween: IntTween(begin: quantity, end: quantity),
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                },
              );
            }),
            const SizedBox(width: 16),
            
            // Plus Button
            Obx(() {
              final quantity = controller.quantity.value;
              return _buildButton(
                context,
                icon: Icons.add,
                onTap: quantity < maxQuantity ? onIncrement : null,
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        
        // Limit Text (static)
        Text(
          'Maximum $maxQuantity units per order',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled 
                ? (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB))
                : (isDark ? const Color(0xFF3B4654) : const Color(0xFFE5E7EB)),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled 
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
