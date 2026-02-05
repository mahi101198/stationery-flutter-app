import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/Banner/unified_banner.dart';
import 'package:rps_stationery/components/skleton/unified_skeleton.dart';
import 'package:rps_stationery/features/checkout/controllers/payment_banner_controller.dart';
import 'package:rps_stationery/services/banner_analytics_service.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

/// Banner carousel for payment screen
/// Displays promotional banners with auto-scroll and smooth transitions
class PaymentBannerCarousel extends StatefulWidget {
  const PaymentBannerCarousel({super.key});

  @override
  State<PaymentBannerCarousel> createState() => _PaymentBannerCarouselState();
}

class _PaymentBannerCarouselState extends State<PaymentBannerCarousel> {
  late final PageController pageController;
  late final PaymentBannerController controller;

  @override
  void initState() {
    super.initState();
    
    // Initialize or get existing controller
    controller = Get.isRegistered<PaymentBannerController>()
        ? Get.find<PaymentBannerController>()
        : Get.put(PaymentBannerController());

    // Initialize PageController with current index
    pageController = PageController(
      initialPage: controller.selectedIndex.value,
    );

    // Listen to controller index changes
    ever(controller.selectedIndex, (int idx) {
      if (pageController.hasClients && pageController.page?.round() != idx) {
        pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Listen to banners changes and start auto-scroll when banners are loaded
    ever(controller.banners, (_) {
      print('🔔 PaymentBannerCarousel: Banners updated, restarting auto-scroll');
      _startAutoScroll();
    });

    // Start auto-scroll after a small delay to ensure everything is initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        print('🚀 PaymentBannerCarousel: Starting initial auto-scroll');
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (mounted) {
      controller.startAutoScroll(pageController);
    }
  }

  /// Track banner view when displayed
  void _trackBannerView(int index) {
    if (controller.banners.isEmpty || index >= controller.banners.length) return;

    final banner = controller.banners[index];
    BannerAnalyticsService.trackBannerView(
      bannerId: banner.bannerId,
      source: 'payment_carousel',
      metadata: {
        'carousel_index': index,
        'total_banners': controller.banners.length,
        'view_duration_seconds': banner.viewChangeTimeSeconds,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.isLoading.value
          ? const UnifiedSkeleton.banner()
          : controller.banners.isEmpty
              // Empty state with premium spacing
              ? Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(DesignSystem.spacing.md),
                  ),
                )
              // Banner carousel
              : Container(
                  margin: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.xs, vertical: DesignSystem.spacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: DesignSystem.shadows.elevation1,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // PageView for banners
                          PageView.builder(
                            controller: pageController,
                            itemCount: controller.banners.length,
                            onPageChanged: (index) {
                              controller.updatePageIndicator(index);
                              _trackBannerView(index);
                              _startAutoScroll();
                            },
                            itemBuilder: (context, index) => UnifiedBanner(
                              imageUrl: controller.banners[index].imageUrl,
                              onTap: () {},
                              size: BannerSize.large,
                              showOverlay: false,
                              borderRadius: 0,
                              padding: const EdgeInsets.all(0),
                              redirectUrl: controller.banners[index].redirectUrl,
                              bannerId: controller.banners[index].bannerId,
                              source: 'payment_carousel',
                              metadata: {
                                'carousel_index': index,
                                'total_banners': controller.banners.length,
                              },
                            ),
                          ),

                          // Dot indicators at bottom
                          if (controller.banners.length > 1)
                            Positioned(
                              bottom: DesignSystem.spacing.md,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  controller.banners.length,
                                  (index) => Obx(
                                    () => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: controller.selectedIndex.value == index ? 24 : 8,
                                      height: 8,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: DesignSystem.spacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: controller.selectedIndex.value == index
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
