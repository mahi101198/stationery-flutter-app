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
    return Stack(
      children: [
        Column(
          children: [
            // Flat card design with subtle border - matching reference image
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFE8E8E9),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.productDetail, arguments: widget.product.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Image + Title/Subtitle Column
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image - left side
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F0F1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: widget.product.displayImage.isNotEmpty
                                    ? Image.network(
                                        widget.product.displayImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Color(0xFFF0F0F1),
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 24,
                                                color: Color(0xFFD0D0D2),
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Color(0xFFF0F0F1),
                                            child: Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFD0D0D2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Color(0xFFF0F0F1),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 24,
                                            color: Color(0xFFD0D0D2),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 14),
                          
                          // Title + Subtitle Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Product name
                                Text(
                                  widget.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                
                                SizedBox(height: 4),
                                
                                // Subtitle
                                Text(
                                  (widget.product.subtitle?.isNotEmpty ?? false) 
                                      ? widget.product.subtitle! 
                                      : (widget.selectedColor ?? ''),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF8E8E93),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Bottom Row: Quantity Selector (LEFT) + Price (RIGHT)
                      // Wrapped with Obx for real-time updates without rebuilding entire widget
                      Obx(() {
                        // Get current quantity from controller using SKU ID
                        final cartItem = controller.cartItems.firstWhereOrNull(
                          (item) => item.productId == widget.skuId
                        );
                        final currentQuantity = cartItem?.quantity ?? widget.quantity;
                        
                        // Find data for this SKU to check limits
                        final sku = widget.product.productSkus.firstWhereOrNull(
                          (s) => s.skuId == widget.skuId
                        );
                        final maxLimit = sku?.maxPerOrder ?? 999;
                        final isLimitReached = currentQuantity >= maxLimit;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Premium Circular Quantity Selector - 3 separate circular boxes
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Minus button - circular
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => controller.updateCartItemQuantity(
                                      widget.skuId, 
                                      currentQuantity - 1,
                                      productContext: widget.product,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16), // Circular
                                        border: Border.all(
                                          color: currentQuantity == 1 
                                              ? Color(0xFFC91C3D).withValues(alpha: 0.3)
                                              : Color(0xFF6B8FA3).withValues(alpha: 0.4), // Blue shade
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          currentQuantity == 1 ? Iconsax.trash : Iconsax.minus,
                                          size: 16,
                                          color: currentQuantity == 1 
                                              ? Color(0xFFC91C3D)
                                              : Color(0xFF6B8FA3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(width: 10),
                                
                                // Quantity display - circular (updates in real-time)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16), // Circular
                                    border: Border.all(
                                      color: Color(0xFF6B8FA3).withValues(alpha: 0.4), // Blue shade
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      currentQuantity.toString(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(width: 10),
                                
                                // Plus button - circular
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isLimitReached
                                      ? () {
                                          // Show gentle toast when at limit
                                          TLoaders.customToast(
                                            message: "Maximum $maxLimit units per order",
                                          );
                                        }
                                      : () => controller.updateCartItemQuantity(
                                        widget.skuId, 
                                        currentQuantity + 1,
                                        productContext: widget.product,
                                      ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isLimitReached ? Colors.grey[100] : Colors.white,
                                        borderRadius: BorderRadius.circular(16), // Circular
                                        border: Border.all(
                                          color: isLimitReached
                                              ? Colors.grey[300]!
                                              : Color(0xFF6B8FA3).withValues(alpha: 0.4), // Blue shade
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Iconsax.add,
                                          size: 16,
                                          color: isLimitReached 
                                              ? Colors.grey[400] 
                                              : Color(0xFF6B8FA3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Price - right side of quantity selector row (updates in real-time)
                            Text(
                              '₹${(widget.product.price * currentQuantity).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        );
                      }),
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
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF6B8FA3).withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
