import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_product_carousel.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_product_info.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_price_display.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_variant_selector.dart';
import 'package:rps_stationery/features/product/components/minimal_quantity_selector.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_content_card_renderer.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_delivery_info.dart';
import 'package:rps_stationery/data/models/delivery_info_model.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_sticky_bottom_bar.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_divider.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_review_section.dart';
import 'package:rps_stationery/utils/theme/app_colors.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

/// Minimal Product Details Screen - Clean, off-white background design
class MinimalProductDetailsScreen extends StatelessWidget {
  const MinimalProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductDetailController.instance;
    
    print('🎨 MinimalProductDetailsScreen: Building screen');
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Obx(() {
          // Capture ALL reactive values
          final product = controller.product.value;
          final isLoading = controller.isLoading.value;
          final isInWishlist = controller.isInWishlist.value;
          final selectedSKU = controller.selectedSKU.value;
          final selectedAttributes = Map<String, String>.from(controller.selectedAttributes);

          print('🎨 MinimalProductDetailsScreen Obx: isLoading=$isLoading, product=${product?.id}, selectedSKU=${selectedSKU?.skuId}');

          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Product Not Found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load product details',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Sort content cards by order
          final sortedCards = [...product.contentCards]
            ..sort((a, b) => a.order.compareTo(b.order));

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar with Back and Wishlist buttons
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    floating: true,
                    pinned: true,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => controller.toggleWishlist(),
                            icon: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist 
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Product Images Carousel
                  SliverToBoxAdapter(
                    child: MinimalProductCarousel(
                      images: product.media.allImages,
                    ),
                  ),

                  // Divider
                  const SliverToBoxAdapter(
                    child: MinimalDivider(),
                  ),

                  // Product Info
                  SliverToBoxAdapter(
                    child: MinimalProductInfo(
                      product: product,
                    ),
                  ),

                  // Divider
                  const SliverToBoxAdapter(
                    child: MinimalDivider(),
                  ),


                  // Variant Selectors (dynamic based on product)
                  if (product.hasVariants)
                    ...product.variantAttributes.entries.map((entry) {
                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            MinimalVariantSelector(
                              attributeName: entry.key,
                              options: entry.value,
                              selectedValue: selectedAttributes[entry.key],
                              onSelected: (value) {
                                controller.onAttributeSelected(entry.key, value);
                              },
                            ),
                            const MinimalDivider(),
                          ],
                        ),
                      );
                    }).toList(),

                  // Quantity Selector
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: MinimalQuantitySelector(
                            maxQuantity: controller.maxQuantity,
                            onIncrement: () => controller.incrementQuantity(),
                            onDecrement: () => controller.decrementQuantity(),
                          ),
                        ),
                        const MinimalDivider(),
                      ],
                    ),
                  ),

                  // Dynamic Content Cards (sorted by order)
                  // These cards include: Key Benefits, Description, Usage Instructions, Specifications
                  ...sortedCards.map((card) {
                    return SliverToBoxAdapter(
                      child: Column(
                        children: [
                          MinimalContentCardRenderer(card: card),
                          const MinimalDivider(),
                        ],
                      ),
                    );
                  }).toList(),

                  // Reviews & Ratings Section
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final productId = product.id;
                      final canWrite = controller.canWriteReview.value;
                      final hasExisting = controller.hasExistingReview.value;
                      
                      return Column(
                        children: [
                          MinimalReviewSection(
                            productId: productId,
                            canWriteReview: canWrite,
                            hasExistingReview: hasExisting,
                          ),
                          const MinimalDivider(),
                        ],
                      );
                    }),
                  ),

                  // Delivery & Trust Info
                  SliverToBoxAdapter(
                    child: MinimalDeliveryInfo(
                      deliveryInfo: DeliveryInfoModel(
                        codAvailable: true,
                        returnPolicy: '7 days return',
                        deliveryEstimate: '3-5 business days',
                      ),
                    ),
                  ),

                  // Add bottom padding for sticky bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ],
          );
        }),
        bottomNavigationBar: Obx(() {
          final product = controller.product.value;
          final quantity = controller.quantity.value;
          if (product == null) return const SizedBox.shrink();
          return MinimalStickyBottomBar(
            product: product,
            quantity: quantity,
          );
        }),
      ),
    );
  }
}
