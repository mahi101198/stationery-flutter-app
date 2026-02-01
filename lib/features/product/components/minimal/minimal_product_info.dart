import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/features/product/components/star_rating_widget.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

/// Minimal Product Info Section - Matches mockup design exactly
class MinimalProductInfo extends StatelessWidget {
  final ProductModel product;

  const MinimalProductInfo({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    // Get price info from first SKU or defaults
    final firstSKU = product.productSkus.isNotEmpty ? product.productSkus.first : null;
    final price = firstSKU?.price ?? 0.0;
    final mrp = firstSKU?.mrp ?? 0.0;
    final hasDiscount = firstSKU?.hasDiscount ?? false;
    final discountPercentage = firstSKU?.discountPercentage ?? 0.0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title
          Text(
            product.title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle (if available)
          if (product.subtitle != null && product.subtitle!.isNotEmpty)
            Text(
              product.subtitle!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 12),

          // Breadcrumb (Category > Subcategory)
          if (product.category.isNotEmpty)
            Row(
              children: [
                Text(
                  product.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                if (product.subCategory.isNotEmpty) ...[
                  const Text(
                    ' > ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    product.subCategory,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 12),

          // Star Rating + Review Count
          if (product.averageRating > 0 || product.reviewCount > 0)
            Row(
              children: [
                StarRatingWidget(
                  rating: product.averageRating,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '(${product.reviewCount} Review${product.reviewCount != 1 ? 's' : ''})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Price Block
          Row(
            children: [
              // Current Price with gradient
              ShaderMask(
                shaderCallback: (bounds) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return ComponentStyles.getPriceGradient(isDark).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // MRP (Strikethrough)
              if (mrp > price)
                Text(
                  'MRP ₹${mrp.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

              const SizedBox(width: 8),

              // Discount Badge
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${discountPercentage.toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
