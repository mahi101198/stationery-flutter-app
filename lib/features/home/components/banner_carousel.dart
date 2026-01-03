import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/Banner/unified_banner.dart';
import 'package:rps_stationery/components/skleton/unified_skeleton.dart';
import 'package:rps_stationery/features/home/controllers/banner_controller.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  Timer? timer;
  late final PageController pageController;
  late final BannerController controller;

  @override
  void initState() {
    super.initState();
    // Ensure controller is initialized before accessing it
    controller = Get.isRegistered<BannerController>() 
        ? Get.find<BannerController>() 
        : Get.put(BannerController());
        
    // Initialize with the last selected index
    pageController = PageController(
      initialPage: controller.selectedIndex.value,
    );

    // Listen to controller index changes (optional, for external updates)
    ever(controller.selectedIndex, (int idx) {
      if (pageController.hasClients && pageController.page?.round() != idx) {
        pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    _startAutoScroll();
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    timer?.cancel();
    
    // Comprehensive null and empty checks
    if (controller.banners.isEmpty || controller.banners.length <= 1) {
      print('⚠️ BannerCarousel: Not starting auto-scroll - insufficient banners (${controller.banners.length})');
      return;
    }
    
    // Additional safety check
    if (!mounted) return;
    
    timer = Timer.periodic(const Duration(seconds: 5), (timer) { // Slower interval
      // Double-check in the timer callback
      if (!mounted || controller.banners.isEmpty || controller.banners.length <= 1) {
        timer.cancel();
        return;
      }
      
      final nextPage = (controller.selectedIndex.value + 1) % controller.banners.length;
      
      // Only update if page controller is ready and mounted
      if (pageController.hasClients && mounted) {
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300), // Faster animation
          curve: Curves.easeOut, // Simpler curve for better performance
        ).then((_) {
          // Update controller after animation completes
          if (mounted) {
            controller.selectedIndex.value = nextPage;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.isLoading.value
          ? const UnifiedSkeleton.banner()
          : controller.banners.isEmpty
              ? const SizedBox(height: 160) // Empty state with fixed height
              : Container(
                  margin: const EdgeInsets.all(0), // Removed all margins for maximum image space
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 2.1, // Increased height for better image utilization
                      child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      PageView.builder(
                          controller: pageController,
                          itemCount: controller.banners.length,
                          onPageChanged: (index) {
                            controller.updatePageIndicator(index);
                            _startAutoScroll();
                          },
                          itemBuilder: (context, index) => UnifiedBanner(
                            imageUrl: controller.banners[index].image,
                            onTap: () {},
                            size: BannerSize.large, // Changed to medium for larger image display
                            showOverlay: false,
                            borderRadius: 0,
                            padding: const EdgeInsets.all(0.0), // Completely removed internal padding for maximum image space
                            redirectUrl: controller.banners[index].redirectUrl,
                            bannerId: controller.banners[index].bannerId,
                            source: 'home_carousel',
                            metadata: {
                              'carousel_index': index,
                              'total_banners': controller.banners.length,
                            },
                          ),
                        ),
                      // Modern dot indicators - Centered bottom
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    controller.banners.length,
                                    (index) => Obx(
                                      () => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: index == controller.selectedIndex.value ? 24 : 6,
                                        height: 6,
                                        margin: EdgeInsets.only(right: index == controller.banners.length - 1 ? 0 : 4),
                                        decoration: BoxDecoration(
                                          color: index == controller.selectedIndex.value
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
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

