import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/network_image_with_loader.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class CartProduct extends StatelessWidget {
  const CartProduct({
    super.key,
    required this.product,
    this.quantity = 1,
    this.isLastInList = false,
    this.selectedColor,
  });

  final ProductModel product;
  final int quantity;
  final bool isLastInList;
  final String? selectedColor;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Stack(
      children: [
        Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed(Routes.productDetail, arguments: product.id),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Product Image with modern styling
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.displayImage.isNotEmpty
                              ? NetworkImageWithLoader(
                                  product.displayImage,
                                  radius: 12,
                                )
                              : Icon(
                                  Icons.image_not_supported,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            
                            // Show selected color if available
                            if (selectedColor != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Color: $selectedColor',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 8),
                            
                            // Price and quantity info - optimized to only rebuild when needed
                            Row(
                              children: [
                                Text(
                                  "₹${(product.price * quantity).toStringAsFixed(0)}",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "$quantity ${quantity > 1 ? 'units' : 'unit'}",
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Quantity controls
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Increase button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => controller.updateCartItemQuantity(product.id, quantity + 1),
                                    icon: const Icon(Iconsax.add, size: 14),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                
                                // Quantity display
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  width: 36,
                                  child: Text(
                                    quantity.toString(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                
                                // Decrease button - removes item when quantity is 1
                                Container(
                                  decoration: BoxDecoration(
                                    color: quantity == 1
                                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => controller.updateCartItemQuantity(product.id, quantity - 1),
                                    icon: Icon(
                                      quantity == 1 ? Iconsax.trash : Iconsax.minus,
                                      size: 14,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: quantity == 1
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        // Subtle loading overlay when updating - Only this part is reactive
        Obx(() {
          final isUpdating = controller.isItemUpdating(product.id);
          
          if (!isUpdating) return const SizedBox.shrink();
          
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
