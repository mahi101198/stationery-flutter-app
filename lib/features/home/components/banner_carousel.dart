import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/Banner/unified_banner.dart';
import 'package:rps_stationery/components/skleton/unified_skeleton.dart';
import 'package:rps_stationery/features/home/controllers/banner_controller.dart';
import 'package:rps_stationery/services/banner_analytics_service.dart';

// A large multiplier so we never hit the real end of the list.
// The PageView item count = bannerCount * _kVirtual, starting midway.
const int _kVirtual = 1000;

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  Timer? _timer;
  PageController? _pageController;
  late final BannerController controller;

  // The current *virtual* page index driving the PageController.
  int _virtualPage = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<BannerController>()
        ? Get.find<BannerController>()
        : Get.put(BannerController());

    // Listen to banners changes and (re)initialise the controller + auto-scroll.
    ever(controller.banners, (_) {
      _initPageController();
      _startAutoScroll();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initPageController();
        _startAutoScroll();
      }
    });
  }

  /// Build / rebuild the PageController so it starts at the midpoint of the
  /// virtual list, which maps to real index 0.
  void _initPageController() {
    if (!mounted) return;
    final count = controller.banners.length;
    if (count == 0) return;

    _pageController?.dispose();

    // Start at the middle of the virtual list so we always have room to go
    // forward (and backward if the user swipes manually).
    final int midStart = ((_kVirtual ~/ 2) * count);
    _virtualPage = midStart; // real index = midStart % count = 0

    setState(() {
      _pageController = PageController(initialPage: _virtualPage);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    final count = controller.banners.length;
    if (count <= 1 || !mounted) return;

    final realIndex = _virtualPage % count;
    final seconds = controller.banners[realIndex].viewChangeTimeSeconds;
    final ms = (seconds * 1000).round();

    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || controller.banners.isEmpty) return;

      // Always move FORWARD by 1 virtual page → no reverse animation ever.
      final nextVirtual = _virtualPage + 1;
      final nextReal = nextVirtual % controller.banners.length;

      _pageController?.animateToPage(
        nextVirtual,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          _virtualPage = nextVirtual;
          controller.updatePageIndicator(nextReal);
          _startAutoScroll();
        }
      });
    });
  }

  void _trackBannerView(int realIndex) {
    if (controller.banners.isEmpty || realIndex >= controller.banners.length) return;
    final banner = controller.banners[realIndex];
    BannerAnalyticsService.trackBannerView(
      bannerId: banner.bannerId,
      source: 'home_carousel',
      metadata: {
        'carousel_index': realIndex,
        'total_banners': controller.banners.length,
        'view_duration_seconds': banner.viewChangeTimeSeconds,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.isLoading.value) return const UnifiedSkeleton.banner();
        if (controller.banners.isEmpty) return const SizedBox(height: 160);

        final count = controller.banners.length;
        final totalVirtual = count * _kVirtual;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 2.1,
              child: _pageController == null
                  ? const SizedBox.shrink()
                  : PageView.builder(
                      controller: _pageController,
                      // Virtually infinite — user can swipe either way freely.
                      itemCount: totalVirtual,
                      onPageChanged: (virtualIndex) {
                        _virtualPage = virtualIndex;
                        final realIndex = virtualIndex % count;
                        controller.updatePageIndicator(realIndex);
                        _trackBannerView(realIndex);
                        _startAutoScroll();
                      },
                      itemBuilder: (context, virtualIndex) {
                        final realIndex = virtualIndex % count;
                        return UnifiedBanner(
                          imageUrl: controller.banners[realIndex].image,
                          onTap: () {},
                          size: BannerSize.large,
                          showOverlay: false,
                          borderRadius: 0,
                          padding: EdgeInsets.zero,
                          redirectUrl: controller.banners[realIndex].redirectUrl,
                          bannerId: controller.banners[realIndex].bannerId,
                          source: 'home_carousel',
                          metadata: {
                            'carousel_index': realIndex,
                            'total_banners': count,
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
