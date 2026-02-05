import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';

/// Horizontal Product Item Component
/// 
/// Displays product information in Amazon-like horizontal layout:
/// - Left side: Product image (40% width)
/// - Right side: Product details including name, rating, price, and add to cart button (60% width)

class HorizontalProductItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const HorizontalProductItem({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ThemeAwareCard(
        padding: EdgeInsets.zero,
        elevation: 2,
        onTap: onTap ?? () => Get.toNamed(Routes.productDetail, arguments: product.id),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - Left Side (40% width)
              Expanded(
                flex: 4,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Main product image
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: product.displayImage.isNotEmpty
                              ? Image.network(
                                  product.displayImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderImage(context),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : _buildPlaceholderImage(context),
                        ),
                        
                        // Discount badge if applicable
                        if (product.hasDiscount)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discount.toInt()}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Product Details - Right Side (60% width)
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name and category
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Brand and availability
                      Row(
                        children: [
                          const Spacer(),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.isAvailable 
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.isAvailable ? 'In Stock' : 'Out of Stock',
                                style: TextStyle(
                                  color: product.isAvailable ? Colors.green : Colors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Price section with discount badge
                      Row(
                        children: [
                          // Prices
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // MRP (crossed out) - only show if there's a discount
                                if (product.hasDiscount) ...[
                                  Text(
                                    '₹${product.mrp.toInt()}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                      decorationThickness: 2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                // Selling Price with gradient effect
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    '₹${product.price.toInt()}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Discount badge
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.error,
                                    Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.discount.toInt()}% OFF',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Add to Cart / Go to Cart Button
                      Obx(() {
                        final cartController = CartController.instance;
                        final cartItem = cartController.getCartItemByProductId(product.productId);
                        final isInCart = cartItem != null;
                        
                        return SizedBox(
                          width: double.infinity,
                          child: ThemeAwareButton(
                            text: isInCart ? 'Go to Cart' : 'Add to Cart',
                            variant: isInCart ? ButtonVariant.secondary : ButtonVariant.primary,
                            size: ButtonSize.small,
                            icon: isInCart ? Iconsax.shopping_cart : Iconsax.add,
                            onPressed: onAddToCart ?? () async {
                              if (isInCart) {
                                // Go to cart
                                Get.offNamedUntil(
                                  Routes.bottomNav,
                                  arguments: 'cart',
                                  (route) => route.settings.name == Routes.bottomNav,
                                );
                              } else {
                                // Add to cart using CartController with full product context
                                final cartController = CartController.instance;
                                await cartController.addToCart(
                                  product.productId, 
                                  1,
                                  productContext: product,
                                );
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.image,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
