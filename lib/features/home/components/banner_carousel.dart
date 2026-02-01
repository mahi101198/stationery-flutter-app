import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/Banner/unified_banner.dart';
import 'package:rps_stationery/components/skleton/unified_skeleton.dart';
import 'package:rps_stationery/features/home/controllers/banner_controller.dart';
import 'package:rps_stationery/services/banner_analytics_service.dart';

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
    if (controller.banners.isEmpty || controller.banners.length <= 1) {
      return;
    }
    if (!mounted) return;
    final currentIndex = controller.selectedIndex.value;
    final seconds = controller.banners[currentIndex].viewChangeTimeSeconds;
    final ms = (seconds * 1000).round();
    timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || controller.banners.isEmpty || controller.banners.length <= 1) {
        return;
      }
      final nextPage = (controller.selectedIndex.value + 1) % controller.banners.length;
      if (pageController.hasClients && mounted) {
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ).then((_) {
          if (mounted) {
            controller.selectedIndex.value = nextPage;
            _startAutoScroll();
          }
        });
      }
    });
  }

  /// Track banner view when it's displayed
  void _trackBannerView(int index) {
    if (controller.banners.isEmpty || index >= controller.banners.length) return;
    
    final banner = controller.banners[index];
    BannerAnalyticsService.trackBannerView(
      bannerId: banner.bannerId,
      source: 'home_carousel',
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
              ? const SizedBox(height: 160) // Empty state with fixed height
              : Container(
                  margin: const EdgeInsets.all(0), // No margins - handled by parent
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08), // Subtle shadow for minimal look
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                              _trackBannerView(index); // Track view when banner is shown
                              _startAutoScroll();
                            },
                            itemBuilder: (context, index) => UnifiedBanner(
                              imageUrl: controller.banners[index].image,
                              onTap: () {},
                              size: BannerSize.large,
                              showOverlay: false,
                              borderRadius: 0,
                              padding: const EdgeInsets.all(0.0),
                              redirectUrl: controller.banners[index].redirectUrl,
                              bannerId: controller.banners[index].bannerId,
                              source: 'home_carousel',
                              metadata: {
                                'carousel_index': index,
                                'total_banners': controller.banners.length,
                              },
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
