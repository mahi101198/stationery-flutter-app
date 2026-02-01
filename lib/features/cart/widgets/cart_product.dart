import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/network_image_with_loader.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class CartProduct extends StatefulWidget {
  const CartProduct({
    super.key,
    required this.product,
    required this.skuId,
    this.quantity = 1,
    this.isLastInList = false,
    this.selectedColor,
  });

  final ProductModel product;
  final String skuId; // SKU ID from cart item
  final int quantity;
  final bool isLastInList;
  final String? selectedColor;

  @override
  State<CartProduct> createState() => _CartProductState();
}

class _CartProductState extends State<CartProduct> {
  late CartController controller;

  @override
  void initState() {
    super.initState();
    controller = CartController.instance;
    
    // DEBUG: Log when CartProduct is initialized (only once)
    print('\n═══════════════════════════════════════════');
    print('🖼️  CartProduct INITIALIZED:');
    print('   SKU ID: ${widget.skuId}');
    print('   Product ID: ${widget.product.id}');
    print('   Product Name: ${widget.product.name}');
    print('   Initial Quantity: ${widget.quantity}');
    print('═══════════════════════════════════════════\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      children: [
        Column(
          children: [
            // Two-column card design matching reference image
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.productDetail, arguments: widget.product.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUMN 1: Product Image (Left) - STATIC, no rebuilds
                      _buildProductImage(theme, isDark),
                      
                      SizedBox(width: 12),
                      
                      // COLUMN 2: Content (Right) - Title, Quantity + Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Product Title (Single line with ellipsis) - STATIC
                            Text(
                              widget.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1.3,
                                letterSpacing: -0.1,
                              ),
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Quantity Selector + Price (Only this part will rebuild)
                            _buildQuantityAndPrice(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Spacing between items
            if (!widget.isLastInList) SizedBox(height: 12),
          ],
        ),
        
        // Subtle loading overlay when updating
        Obx(() {
          final isUpdating = controller.isItemUpdating(widget.skuId);
          
          if (!isUpdating) return const SizedBox.shrink();
          
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
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

  /// Build product image - STATIC component (no rebuilds)
  Widget _buildProductImage(ThemeData theme, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surfaceContainerHighest
            : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: widget.product.displayImage.isNotEmpty
            ? NetworkImageWithLoader(
                widget.product.displayImage,
                fit: BoxFit.cover,
                radius: 8,
              )
            : Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  /// Build quantity and price section - DYNAMIC component (will rebuild)
  Widget _buildQuantityAndPrice(ThemeData theme) {
    return Obx(() {
      // Get current quantity from controller using SKU ID
      final cartItem = controller.cartItems.firstWhereOrNull(
        (item) => item.skuId == widget.skuId
      );
      final currentQuantity = cartItem?.quantity ?? widget.quantity;
      
      // Find data for this SKU to check limits
      final sku = widget.product.productSkus.firstWhereOrNull(
        (s) => s.skuId == widget.skuId
      );
      final maxLimit = sku?.maxPerOrder ?? 999;
      final isLimitReached = currentQuantity >= maxLimit;
      final totalPrice = _getSkuPrice() * currentQuantity;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quantity Selector - Circular buttons with blue border
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus button (removes item when qty = 1)
              _buildCircularButton(
                context: context,
                icon: Iconsax.minus,
                onTap: () => controller.updateCartItemQuantity(
                  widget.skuId, 
                  currentQuantity - 1,
                  productContext: widget.product,
                ),
                theme: theme,
              ),
              
              SizedBox(width: 8),
              
              // Quantity display - circular with blue border
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    currentQuantity.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 8),
              
              // Plus button
              _buildCircularButton(
                context: context,
                icon: Iconsax.add,
                onTap: isLimitReached
                  ? () {
                      TLoaders.customToast(
                        message: "Maximum $maxLimit units per order",
                      );
                    }
                  : () => controller.updateCartItemQuantity(
                    widget.skuId, 
                    currentQuantity + 1,
                    productContext: widget.product,
                  ),
                isDisabled: isLimitReached,
                theme: theme,
              ),
            ],
          ),
          
          // Price with gradient color (INR)
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              '₹${totalPrice.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white, // Required for ShaderMask
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Build circular button for quantity selector
  Widget _buildCircularButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool isDisabled = false,
    required ThemeData theme,
  }) {
    final Color borderColor = isDisabled
        ? theme.colorScheme.outline.withValues(alpha: 0.3)
        : theme.colorScheme.primary.withValues(alpha: 0.4);
    
    final Color iconColor = isDisabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : theme.colorScheme.primary;
    
    final Color backgroundColor = isDisabled 
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Get SKU-specific price from product
  double _getSkuPrice() {
    // Find the SKU that matches widget.skuId
    final matchingSku = widget.product.productSkus.firstWhere(
      (sku) => sku.skuId == widget.skuId,
      orElse: () => widget.product.productSkus.first, // Fallback to first SKU
    );
    
    return matchingSku.price.toDouble();
  }
}
