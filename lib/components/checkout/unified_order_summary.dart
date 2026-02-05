import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:collection/collection.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/price_calculator.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

/// Unified order summary component used across all checkout screens
/// This replaces all duplicate order summary widgets
class UnifiedOrderSummary extends StatelessWidget {
  final List<dynamic> cartItems;
  final UserAddress deliveryAddress;
  final double orderTotal;
  final double couponDiscount;
  final double walletDiscount;
  final bool showCouponSection;
  final bool showWalletSection;
  final bool showDetailedBreakdown;
  final VoidCallback? onEditAddress;
  final VoidCallback? onEditItems;

  const UnifiedOrderSummary({
    super.key,
    required this.cartItems,
    required this.deliveryAddress,
    required this.orderTotal,
    this.couponDiscount = 0.0,
    this.walletDiscount = 0.0,
    this.showCouponSection = false,
    this.showWalletSection = false,
    this.showDetailedBreakdown = true,
    this.onEditAddress,
    this.onEditItems,
  });

  @override
  Widget build(BuildContext context) {
    final priceBreakdown = PriceCalculator.getPriceBreakdown(
      orderTotal: orderTotal,
      couponDiscount: couponDiscount,
      walletDiscount: walletDiscount,
    );

    final freeDeliveryInfo = PriceCalculator.getFreeDeliveryInfo(orderTotal);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onEditItems != null)
                  TextButton(
                    onPressed: onEditItems,
                    child: Text(
                      'Edit',
                      style: TextStyle(color: TColors.primary),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: TSizes.md),
            
            // Items count
            _buildItemsCount(context),
            
            if (showDetailedBreakdown) ...[
              const SizedBox(height: TSizes.md),
              const Divider(),
              const SizedBox(height: TSizes.md),
              
              // Price breakdown
              _buildPriceBreakdown(context, priceBreakdown, freeDeliveryInfo),
            ],
            
            const SizedBox(height: TSizes.md),
            const Divider(),
            
            // Final total
            _buildFinalTotal(context, priceBreakdown['finalAmount']!),
            
            const SizedBox(height: TSizes.md),
            
            // Delivery address
            _buildDeliveryAddress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCount(BuildContext context) {
    if (showDetailedBreakdown) {
      // Show price summary when detailed breakdown is enabled
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Items (${cartItems.length})',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '₹${orderTotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      // Show item details when detailed breakdown is disabled
      return _buildItemDetails(context);
    }
  }

  Widget _buildItemDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${cartItems.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TSizes.sm),
        ...cartItems.take(3).map((item) => _buildMiniProductCard(context, item)).toList(),
        if (cartItems.length > 3) ...[
          const SizedBox(height: TSizes.xs),
          Text(
            '+ ${cartItems.length - 3} more items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TColors.darkerGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniProductCard(BuildContext context, dynamic item) {
    // Check if cart item has enhanced data (price > 0 means it has comprehensive data)
    if (item.price != null && item.price > 0) {
      // Use enhanced cart data directly
      return _buildEnhancedProductCard(context, item);
    } else {
      // Fallback to product lookup for legacy cart items
      return FutureBuilder<ProductModel?>(
        future: ProductRepo.instance.getProductBySKUId(item.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingCard(context);
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorCard(context, item);
          }
          
          final product = snapshot.data!;
          return _buildProductCard(context, product, item.quantity, item.productId);
        },
      );
    }
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: TSizes.xs),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Loading placeholder for image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          // Loading placeholder for text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, dynamic item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: TSizes.xs),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.warning_2,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product ID: ${item.productId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unable to load details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: 2),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Qty: ${item.quantity}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: TColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, int quantity, String skuId) {
    // Find the SKU details
    final sku = product.productSkus.firstWhereOrNull((s) => s.skuId == skuId);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: TSizes.xs),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: product.displayImage,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                child: Icon(
                  Iconsax.image,
                  size: 20,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // SKU Variant Details
                if (sku != null && sku.attributes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sku.attributes.entries
                        .map((e) => '${e.key.replaceAll('_', ' ')}: ${e.value}')
                        .join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Price
                if (sku != null && sku.hasDiscount) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [TColors.primary, Colors.purple.shade400],
                        ).createShader(bounds),
                        child: Text(
                          '₹${sku.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${sku.mrp.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else if (sku != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${sku.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: 2),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Qty: $quantity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: TColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(BuildContext context, Map<String, double> breakdown, Map<String, dynamic> freeDeliveryInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TSizes.sm),
        
        // Items Total
        _buildPriceRow(context, 'Items Total', '₹${breakdown['orderTotal']!.toStringAsFixed(2)}'),
        
        // Delivery Fee
        _buildPriceRow(
          context,
          'Delivery Fee',
          freeDeliveryInfo['isFreeDelivery'] ? 'FREE' : '₹${breakdown['deliveryCharge']!.toStringAsFixed(2)}',
          isFree: freeDeliveryInfo['isFreeDelivery'],
        ),
        
        // Free delivery hint
        if (!freeDeliveryInfo['isFreeDelivery'] && freeDeliveryInfo['remainingForFree'] > 0) ...[
          const SizedBox(height: TSizes.xs),
          Text(
            'Add ₹${freeDeliveryInfo['remainingForFree']!.toStringAsFixed(2)} more for free delivery',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TColors.info,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        
        // Coupon Discount
        if (couponDiscount > 0)
          _buildPriceRow(context, 'Coupon Discount', '- ₹${couponDiscount.toStringAsFixed(2)}', isDiscount: true),
        
        // Wallet Payment
        if (walletDiscount > 0)
          _buildPriceRow(context, 'Wallet Payment', '- ₹${walletDiscount.toStringAsFixed(2)}', isDiscount: true),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isDiscount = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDiscount || isFree ? TColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalTotal(BuildContext context, double finalAmount) {
    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹${finalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: TColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.location,
              size: 16,
              color: TColors.darkerGrey,
            ),
            const SizedBox(width: TSizes.xs),
            Text(
              'Delivery to: ${deliveryAddress.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TColors.darkerGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (onEditAddress != null)
              TextButton(
                onPressed: onEditAddress,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: TColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TSizes.xs),
        Text(
          '${deliveryAddress.line1}${deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}, ${deliveryAddress.city}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: TColors.darkerGrey,
          ),
        ),
      ],
    );
  }

  /// Build product card using enhanced cart data directly
  Widget _buildEnhancedProductCard(BuildContext context, dynamic cartItem) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: TSizes.xs),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.sm),
        border: Border.all(color: TColors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.xs),
            child: SizedBox(
              width: 50,
              height: 50,
              child: cartItem.imageUrl != null && cartItem.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: cartItem.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: TColors.grey.withValues(alpha: 0.1),
                        child: const Icon(Icons.image, size: 24, color: TColors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: TColors.grey.withValues(alpha: 0.1),
                        child: const Icon(Icons.image, size: 24, color: TColors.grey),
                      ),
                    )
                  : Container(
                      color: TColors.grey.withValues(alpha: 0.1),
                      child: const Icon(Icons.image, size: 24, color: TColors.grey),
                    ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.title ?? 'Product ${cartItem.productId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cartItem.subtitle != null && cartItem.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cartItem.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TColors.darkerGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Price with discount if applicable
                if (cartItem.mrp != null && cartItem.mrp > cartItem.price) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [TColors.primary, Colors.purple.shade400],
                        ).createShader(bounds),
                        child: Text(
                          '₹${cartItem.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${cartItem.mrp.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${cartItem.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: 2),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Qty: ${cartItem.quantity}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: TColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
