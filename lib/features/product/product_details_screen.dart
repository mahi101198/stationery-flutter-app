import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';
import 'package:rps_stationery/components/enhanced_cart_button.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/features/product/components/product_description.dart';
import 'package:rps_stationery/features/product/components/product_price.dart';
import 'package:rps_stationery/features/product/components/product_return_info.dart';
import 'package:rps_stationery/features/product/components/product_shipping_info.dart';
import 'package:rps_stationery/features/product/components/unavailable_card.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';

import 'components/notify_me_card.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';
import 'components/enhanced_review_card.dart';
import 'components/product_color_selector.dart';
import 'screens/product_reviews_screen.dart';
import 'controllers/review_controller.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProductDetailController.instance;

    return Obx(
      () {
        // Safely get the review controller inside Obx for reactivity
        ReviewController? reviewController;
        try {
          reviewController = controller.reviewController;
        } catch (e) {
          // If review controller is not available, we'll handle it gracefully
          reviewController = null;
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar:
              controller.product.value != null
                  ? controller.product.value!.isAvailable
                      ? controller.product.value!.stock > 0
                          ? EnhancedCartButton(
                            product: controller.product.value!,
                            quantity: controller.quantity.value,
                            cartQuantity: controller.cartQuantity.value,
                            isCartUpdating: controller.isCartUpdating.value,
                            selectedColor: controller.selectedColor.value,
                          )
                          : NotifyMeCard(isNotify: false, onChanged: (value) {})
                      : UnavailableCard()
                  : null,
          body:
              controller.isLoading.value
                  ? _buildLoadingState(context)
                  : controller.product.value == null
                  ? _buildErrorState(context)
                  : _buildProductDetails(context, controller, reviewController),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading product details...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.box_remove,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Product Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Something broke, product detail not found :(',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(
    BuildContext context,
    ProductDetailController controller,
    ReviewController? reviewController,
  ) {
    return Stack(
      children: [
        // Background gradient
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.03),
              ],
            ),
          ),
        ),
        
        // Main content
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar with Glassmorphism
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        controller.toggleWishlist();
                      },
                      icon: controller.isInWishlist.value
                          ? const Icon(
                              Iconsax.heart5,
                              color: Colors.red,
                            )
                          : Icon(
                              Iconsax.heart,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Product Images with enhanced design
            ProductImages(
              images: controller.product.value?.images ?? [],
            ),
            
            // Animated content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      if (controller.product.value != null)
                        ProductInfo(
                          product: controller.product.value!,
                          rating: reviewController?.reviewStats?.averageRating ?? 0.0,
                          reviewCount: reviewController?.reviewStats?.totalReviews ?? 0,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (controller.product.value != null)
              ProductPrice(
                quantity: controller.quantity.value,
                price: controller.product.value!.price,
                discountPrice:
                    controller.product.value!.hasDiscount ? controller.product.value!.mrp : null,
                onQuantityChange: (newQuantity) {
                  controller.setQuantity(newQuantity);
                },
                maxQuantity: controller.product.value!.stock,
                maxQuantityPerUser: controller.product.value!.maxQuantityPerUser,
              ),
            
            // Color Selector
            if (controller.product.value != null && controller.hasColors)
              SliverToBoxAdapter(
                child: Obx(() => ProductColorSelector(
                  colors: controller.product.value!.colors,
                  selectedColor: controller.selectedColor.value,
                  onColorSelected: (color) {
                    controller.selectColor(color);
                  },
                )),
              ),
            
            if (controller.product.value != null)
              ProductDescription(
                description: controller.product.value!.description ?? '',
              ),
            
            if (controller.product.value != null)
              ProductShippingInfo(
                shippingInfo: controller.product.value!.shippingInfo,
                shippingInfoTitle: controller.product.value!.shippingInfoTitle,
              ),
            
            if (controller.product.value != null)
              ProductReturnInfo(
                returnDescription: controller.product.value!.returnDescription,
                returnTitle: controller.product.value!.returnTitle,
              ),
            
            if (controller.product.value != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: EnhancedReviewCard(
                    productId: controller.product.value!.productId,
                    productName: controller.product.value!.name,
                  ),
                ),
              ),
            
            // Only show Reviews navigation for users who can review
            if (reviewController?.canUserReview == true && controller.product.value != null)
              ProductListTile(
                svgSrc: "assets/icons/Chat.svg",
                title: "Reviews",
                isShowBottomBorder: true,
                press: () {
                  Get.to(() => ProductReviewsScreen(
                    productId: controller.product.value!.productId,
                    productName: controller.product.value!.name,
                  ));
                },
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding * 2),
            ),
          ],
        ),
        
        // Confetti positioned at bottom center of body
        Positioned(
          bottom: 40,
          left: MediaQuery.of(context).size.width / 2,
          child: Transform.translate(
            offset: const Offset(-12, 0),
            child: ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.01,
              numberOfParticles: 5,
              maxBlastForce: 10,
              minBlastForce: 8,
              gravity: 0.05,
              particleDrag: 0.08,
              createParticlePath: (size) {
                final path = Path();
                final radius = size.width / 3;
                final innerRadius = radius * 0.5;

                for (int i = 0; i < 10; i++) {
                  final angle = (i * 36) * (pi / 180);
                  final r = i.isEven ? radius : innerRadius;
                  final x = r * cos(angle);
                  final y = r * sin(angle);

                  if (i == 0) {
                    path.moveTo(x, y);
                  } else {
                    path.lineTo(x, y);
                  }
                }
                path.close();
                return path;
              },
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
                Colors.orange.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
