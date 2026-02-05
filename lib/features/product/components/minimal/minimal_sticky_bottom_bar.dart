import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';

/// Minimal Sticky Bottom Action Bar - Matches mockup design
class MinimalStickyBottomBar extends StatelessWidget {
  final ProductModel product;
  final int quantity;

  const MinimalStickyBottomBar({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ProductDetailController.instance;

    return Obx(() {
      final selectedSKU = controller.selectedSKU.value;
      final isCartUpdating = controller.isCartUpdating.value;
      final hasItemsInCart = controller.hasItemsInCart.value;
      final cartQuantity = controller.cartQuantity.value;

      // Check if user needs to select variants
      final needsVariantSelection = product.hasVariants && selectedSKU == null;
      
      // Determine button state
      final isCurrentProductInCart = cartQuantity > 0;
      // Only show "Go to Cart" if THIS specific product (SKU) is in cart
      final showGoToCart = isCurrentProductInCart;
      
      // Calculate total price
      final unitPrice = selectedSKU?.price ?? (product.productSkus.isNotEmpty ? product.productSkus.first.price : 0.0);
      final totalPrice = unitPrice * quantity;

      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Left: Total Price
                Expanded(
                  flex: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Right: Add to Cart Button (60% of available space)
                Expanded(
                  flex: 60,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: needsVariantSelection || isCartUpdating
                          ? null
                          : () async {
                              if (showGoToCart) {
                                // Go to Cart
                                Get.offNamedUntil(
                                  '/bottom-nav',
                                  arguments: 'cart',
                                  (route) => route.settings.name == '/bottom-nav',
                                );
                              } else {
                                // Add to Cart
                                await controller.addToCart();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        disabledForegroundColor: const Color(0xFF9CA3AF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: isCartUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  showGoToCart 
                                    ? Icons.shopping_cart 
                                    : Icons.shopping_cart_outlined, 
                                  size: 20
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  showGoToCart ? 'Go to Cart' : 'Add to Cart',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
