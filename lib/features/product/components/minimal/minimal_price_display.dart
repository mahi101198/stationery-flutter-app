import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/product_sku_model.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

/// Minimal Price Display following Material 3 design
class MinimalPriceDisplay extends StatelessWidget {
  final ProductSKUModel? selectedSKU;
  final double? minPrice;
  final double? minMRP;

  const MinimalPriceDisplay({
    super.key,
    this.selectedSKU,
    this.minPrice,
    this.minMRP,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which price to show
    final double currentPrice = selectedSKU?.price ?? minPrice ?? 0.0;
    final double originalPrice = selectedSKU?.mrp ?? minMRP ?? 0.0;
    
    // Calculate discount
    final bool hasDiscount = originalPrice > currentPrice && originalPrice > 0;
    final int discountPercent = hasDiscount 
        ? (((originalPrice - currentPrice) / originalPrice) * 100).round()
        : 0;

    if (currentPrice == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Price with gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                ComponentStyles.getPriceGradient(isDark).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              '₹${currentPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // MRP (strikethrough)
          if (hasDiscount)
            Text(
              '₹${originalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Discount Badge
          if (hasDiscount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$discountPercent% OFF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
