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
                    ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

