import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/features/product/components/product_quantity.dart';
import 'package:rps_stationery/features/product/components/unit_price.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';
import 'package:iconsax/iconsax.dart';

class ProductPrice extends StatefulWidget {
  const ProductPrice({super.key});

  @override
  State<ProductPrice> createState() => _ProductPriceState();
}

class _ProductPriceState extends State<ProductPrice> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProductDetailController.instance;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding,
      ),
      sliver: SliverToBoxAdapter(
        child: Obx(() {
          final selectedSKU = controller.selectedSKU.value;
          
          // If no SKU is selected, show selection prompt
          if (selectedSKU == null) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.availabilityMessage ?? 'Select product options to see price',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // SKU is selected, show pricing
          final price = selectedSKU.price;
          final mrp = selectedSKU.mrp;
          final hasDiscount = selectedSKU.hasDiscount;
          final quantity = controller.quantity.value;
          final savingsAmount = hasDiscount ? (mrp - price) * quantity : 0.0;
          final savingsPercentage = selectedSKU.discountPercentage.round();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.tag,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Price",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              UnitPrice(
                                price: price,
                                priceAfterDiscount: hasDiscount ? mrp : null,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Quantity section
                        ProductQuantity(
                          quantity: quantity,
                          onQuantityChange: controller.setQuantity,
                          maxQuantity: controller.maxQuantity,
                          maxQuantityPerUser: null, // Not used in new schema
                        ),
                      ],
                    ),
                    
                    // Discount badge if applicable
                    if (hasDiscount) ...[ 
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withValues(alpha: 0.15),
                              Colors.teal.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.discount_shape,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You Save ₹${savingsAmount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    '$savingsPercentage% off on this product',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$savingsPercentage%',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Limited stock warning
                    if (selectedSKU.hasLimitedStock) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.warning_2,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Limited stock - Only ${selectedSKU.availableQuantity} left',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Total price display
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$quantity ${quantity > 1 ? 'items' : 'item'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return ComponentStyles.getPriceGradient(isDark).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              '₹${(price * quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
