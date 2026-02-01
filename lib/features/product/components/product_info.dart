import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../constants.dart';

class ProductInfo extends StatelessWidget {
  const ProductInfo({
    super.key,
    required this.product,
    required this.rating,
    required this.reviewCount,
  });

  final ProductModel product;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and Brand tags
            Row(
              children: [
                // Category tag
                if (product.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.category,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.category.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (product.category.isNotEmpty && product.brand.isNotEmpty)
                  const SizedBox(width: 8),
                
                // Brand tag
                if (product.brand.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      product.brand,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Product title with modern typography
            Text(
              product.title,
              maxLines: 2,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rating and availability row with modern cards
            Row(
              children: [
                // Rating card
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.star1,
                          size: 15,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            "$rating ($reviewCount)",
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Availability tag
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: product.isAvailable
                            ? [
                                Colors.green.withValues(alpha: 0.15),
                                Colors.teal.withValues(alpha: 0.1),
                              ]
                            : [
                                Colors.red.withValues(alpha: 0.15),
                                Colors.orange.withValues(alpha: 0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (product.isAvailable
                                ? Colors.green
                                : Colors.red)
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: product.isAvailable
                                ? Colors.green
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            product.isAvailable ? "In Stock" : "Out of Stock",
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: product.isAvailable
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
