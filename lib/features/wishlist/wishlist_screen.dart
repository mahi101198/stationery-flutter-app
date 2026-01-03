import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/features/wishlist/controller.dart/wishlist_controller.dart';
import 'package:rps_stationery/utils/animations/micro_animations.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized before accessing instance
    WishlistController controller;
    try {
      controller = Get.find<WishlistController>();
    } catch (_) {
      controller = Get.put(WishlistController());
    }
    controller.refreshWishlist();

    return Scaffold(
      body: Obx(
        () => CustomScrollView(
          slivers: [
            // Add top padding for status bar and camera area
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 16),
            ),
            // While loading use 👇
            //  BookMarksSlelton(),
            controller.products.isEmpty
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 32,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            // Enhanced empty state illustration
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.heart,
                                size: 80,
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Your wishlist is empty',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Save items you love for later!\nStart browsing and add products to your wishlist.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            
                            // Single action button
                            SizedBox(
                              width: double.infinity,
                              child: ThemeAwareButton(
                                text: 'Start Shopping',
                                icon: Iconsax.bag_2,
                                variant: ButtonVariant.primary,
                                size: ButtonSize.large,
                                fullWidth: true,
                                onPressed: () {
                                  // Navigate to home tab
                                  try {
                                    Get.offAndToNamed(Routes.bottomNav, arguments: 'home');
                                  } catch (e) {
                                    // Fallback to simple back navigation
                                    Get.back();
                                  }
                                },
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wishlist header with count
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Wishlist',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${controller.products.length} saved items',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              // Clear all button
                              if (controller.products.isNotEmpty)
                                ThemeAwareButton(
                                  text: 'Clear All',
                                  variant: ButtonVariant.ghost,
                                  size: ButtonSize.small,
                                  onPressed: () {
                                    // Show confirmation dialog
                                    _showClearWishlistDialog(context, controller);
                                  },
                                ),
                            ],
                          ),
                        ),
                        
                        // Enhanced product grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                              childAspectRatio: 0.72, // Optimized for compact, modern card design
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: controller.products.length,
                            itemBuilder: (context, index) {
                              return MicroAnimations.staggeredListItem(
                                index: index,
                                duration: MicroAnimations.normal,
                                child: ThemeAwareCard(
                                  elevation: 4,
                                  borderRadius: 16,
                                  onTap: () {
                                    Get.toNamed(
                                      Routes.productDetail,
                                      arguments: controller.products[index].id,
                                    );
                                  },
                                  child: ProductCard(
                                    product: controller.products[index],
                                    press: () {
                                      Get.toNamed(
                                        Routes.productDetail,
                                        arguments: controller.products[index].id,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showClearWishlistDialog(BuildContext context, WishlistController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Clear Wishlist?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This will remove all items from your wishlist.\nThis action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ThemeAwareButton(
                      text: 'Cancel',
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.medium,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ThemeAwareButton(
                      text: 'Clear All',
                      variant: ButtonVariant.danger,
                      size: ButtonSize.medium,
                      onPressed: () {
                        // Clear wishlist
                        controller.clearWishlist();
                        Get.back();
                        Get.snackbar(
                          'Wishlist Cleared',
                          'All items have been removed from your wishlist',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
