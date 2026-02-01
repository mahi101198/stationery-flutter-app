import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/data/models/home_section_item_model.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

/// Section Item Card - Displays a home section item (SKU-based)
/// Uses embedded data from Firestore (no product lookup needed)
class SectionItemCard extends StatelessWidget {
  final HomeSectionItemModel item;
  final double? width;
  final double? height;

  const SectionItemCard({
    super.key,
    required this.item,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToProduct(context),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Image with badge - takes 60% of height
            Expanded(
              flex: 6,
              child: _buildImage(context),
            ),
            
            // Product info - takes 40% of height
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name - single line with ellipsis
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Price and MRP
                    _buildPriceRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        // Product image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: AspectRatio(
            aspectRatio: 1,
          child: _isValidUrl(item.imageUrl)
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                )
              : _buildErrorWidget(),
        ),
      ),
      
      // Badge (if present)
        if (item.hasBadge)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _parseBadgeColor(item.badgeColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Discount label (if present)
        if (item.hasDiscount && item.displayDiscountLabel.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: ComponentStyles.discountBadgeDecoration(borderRadius: 8),
              child: Text(
                item.displayDiscountLabel,
                style: ComponentStyles.discountBadgeTextStyle(fontSize: 10, bold: true),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Selling Price with gradient (first)
        Flexible(
          fit: FlexFit.loose,
          child: ShaderMask(
            shaderCallback: (bounds) =>
                ComponentStyles.getPriceGradient(isDark).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              item.formattedPrice,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        
        const SizedBox(width: 6),
        
        // MRP (crossed out) - only show if there's a discount
        if (item.hasDiscount)
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              item.formattedMrp,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Color _parseBadgeColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.blue; // Default badge color
    }
    
    try {
      // Remove # if present
      final hex = colorHex.replaceAll('#', '');
      
      // Add FF for full opacity if not present
      final hexColor = hex.length == 6 ? 'FF$hex' : hex;
      
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.blue; // Fallback color
    }
  }

  void _navigateToProduct(BuildContext context) {
    // Validate data before navigation
    if (item.productId.isEmpty || item.skuId.isEmpty) {
      print('❌ SectionItemCard: Cannot navigate - productId or skuId is empty');
      print('   productId: "${item.productId}"');
      print('   skuId: "${item.skuId}"');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product information is incomplete'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('🔍 SectionItemCard: Navigating to product');
    print('   productId: ${item.productId}');
    print('   skuId: ${item.skuId}');
    
    try {
      // Navigate to product details with SKU pre-selected
      Get.toNamed(
        Routes.productDetail,
        arguments: {
          'productId': item.productId,
          'skuId': item.skuId, // Pre-select this SKU
        },
      );
    } catch (e, stackTrace) {
      print('❌ SectionItemCard: Navigation error: $e');
      print('❌ Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening product: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return !url.contains('example.com') && !url.contains('placeholder');
  }

  Widget _buildErrorWidget() {
    // Wrapped in Directionality to prevent "No Directionality widget found" errors
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}
