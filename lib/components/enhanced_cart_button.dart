import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import '../constants.dart';

class EnhancedCartButton extends StatefulWidget {
  const EnhancedCartButton({
    super.key,
    required this.product,
    required this.quantity,
    this.cartQuantity,
    this.isCartUpdating = false,
    this.selectedColor,
  });

  final ProductModel product;
  final int quantity;
  final int? cartQuantity;
  final bool isCartUpdating;
  final String? selectedColor;

  @override
  State<EnhancedCartButton> createState() => _EnhancedCartButtonState();
}

class _EnhancedCartButtonState extends State<EnhancedCartButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.price * widget.quantity;
    final isInCart = (widget.cartQuantity ?? 0) > 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // Buttons Row with modern design
            Row(
              children: [
                // Add to Cart / Update Cart / Go to Cart Button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: OutlinedButton(
                        onPressed: widget.isCartUpdating ? null : () async {
                          if (isInCart) {
                            if (widget.cartQuantity != widget.quantity) {
                              // Update quantity in cart
                              final cartController = CartController.instance;
                              await cartController.updateCartItemQuantity(
                                widget.product.productId, 
                                widget.quantity
                              );
                            } else {
                              // Go to Cart
                              Get.offNamedUntil(
                                Routes.bottomNav,
                                arguments: 'cart',
                                (route) => route.settings.name == Routes.bottomNav,
                              );
                            }
                          } else {
                            // Check if product has colors and user hasn't selected one
                            if (widget.product.colors.isNotEmpty && widget.selectedColor == null) {
                              TLoaders.errorSnackBar(
                                title: 'Color Required',
                                message: 'Please select a color option before adding to cart',
                              );
                              return;
                            }
                            // Add to Cart
                            final cartController = CartController.instance;
                            await cartController.addToCart(
                              widget.product.productId, 
                              widget.quantity,
                              selectedColor: widget.selectedColor,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: widget.isCartUpdating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isInCart 
                                        ? (widget.cartQuantity != widget.quantity 
                                            ? Iconsax.refresh 
                                            : Iconsax.shopping_cart)
                                        : Iconsax.shopping_bag,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      isInCart 
                                          ? (widget.cartQuantity != widget.quantity 
                                              ? 'Update Cart' 
                                              : 'Go to Cart')
                                          : 'Add to Cart',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Buy Now Button with gradient
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: GestureDetector(
                      onTapDown: (_) => _controller.forward(),
                      onTapUp: (_) {
                        _controller.reverse();
                        if (!widget.isCartUpdating) {
                          _buyNow(context);
                        }
                      },
                      onTapCancel: () => _controller.reverse(),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.isCartUpdating ? null : () => _buyNow(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.flash_1,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  void _buyNow(BuildContext context) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        TLoaders.errorSnackBar(
          title: 'Authentication Required',
          message: 'Please sign in to continue with purchase',
        );
        return;
      }

      // Check if product has colors and user hasn't selected one
      if (widget.product.colors.isNotEmpty && widget.selectedColor == null) {
        TLoaders.errorSnackBar(
          title: 'Color Required',
          message: 'Please select a color option before proceeding',
        );
        return;
      }

      // Navigate to address selection for Buy Now
      Get.toNamed(
        Routes.addressSelection,
        arguments: {
          'isBuyNow': true,
          'product': widget.product,
          'quantity': widget.quantity,
          'productId': widget.product.productId,
          'name': widget.product.name,
          'price': widget.product.price,
          'productImage': widget.product.image,
          'discountPrice': widget.product.price,
          if (widget.selectedColor != null) 'selectedColor': widget.selectedColor,
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Purchase Error',
        message: 'Failed to proceed with purchase. Please try again.',
      );
    }
  }
}
