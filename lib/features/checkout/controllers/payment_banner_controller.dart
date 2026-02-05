import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/additional_models.dart';

/// Controller for payment screen banners
/// Fetches banners from 'payment-banners' collection and manages carousel
class PaymentBannerController extends GetxController {
  final isLoading = false.obs;
  final selectedIndex = 0.obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;

  Timer? _autoScrollTimer;

  void updatePageIndicator(index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    print('🎯 PaymentBannerController: Initializing...');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      print('🎯 PaymentBannerController: Starting banner fetch...');
      fetchPaymentBanners();
    });
  }

  /// Fetch banners from payment-banners collection
  Future<void> fetchPaymentBanners() async {
    try {
      print('🔄 PaymentBannerController: Starting fetch from payment-banners collection...');
      isLoading.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection('payment-banners')
          .where('isActive', isEqualTo: true)
          .orderBy('rank', descending: false)
          .get();

      print('📊 PaymentBannerController: Retrieved ${snapshot.docs.length} active banners');

      if (snapshot.docs.isNotEmpty) {
        final bannerList = snapshot.docs.map((doc) {
          final data = doc.data();
          
          // Parse the data from payment-banners collection
          final imageUrl = data['imageUrl'] as String? ?? '';
          final title = data['title'] as String? ?? 'Payment Offer';
          final linkTo = data['linkTo'] as String? ?? '';
          final rank = (data['rank'] as num?)?.toInt() ?? 0;
          final viewChangeTime = (data['view_change_time'] as num?)?.toDouble() ?? 5.0;
          
          // Create BannerModel with payment-banners data
          return BannerModel(
            bannerId: doc.id,
            imageUrl: imageUrl,
            redirectUrl: linkTo.isEmpty ? null : linkTo,
            active: data['isActive'] as bool? ?? true,
            priority: rank,
            validFrom: DateTime.now().subtract(const Duration(days: 365)),
            validTill: DateTime.now().add(const Duration(days: 365)),
            viewChangeTimeSeconds: viewChangeTime,
          );
        }).toList();

        // Sort by rank
        bannerList.sort((a, b) => a.priority.compareTo(b.priority));
        
        print('✅ PaymentBannerController: Successfully loaded ${bannerList.length} banners');
        banners.assignAll(bannerList);
        
        // Log banner details
        for (int i = 0; i < bannerList.length; i++) {
          print('  Banner $i: ID=${bannerList[i].bannerId}, Image=${bannerList[i].imageUrl}, ViewTime=${bannerList[i].viewChangeTimeSeconds}s');
        }
      } else {
        print('⚠️ PaymentBannerController: No active banners found');
        banners.clear();
      }
    } catch (e, stackTrace) {
      print('❌ PaymentBannerController: Error fetching banners: $e');
      print('❌ PaymentBannerController: Stack trace: $stackTrace');
      banners.clear();
    } finally {
      isLoading.value = false;
      print('🏁 PaymentBannerController: Fetch completed');
    }
  }

  /// Start auto-scroll timer for banners
  void startAutoScroll(PageController pageController) {
    _stopAutoScroll();
    
    if (banners.isEmpty || banners.length <= 1) {
      print('🔄 PaymentBannerController: Auto-scroll disabled - no banners or single banner');
      return;
    }
    
    final currentIndex = selectedIndex.value;
    if (currentIndex >= banners.length) {
      print('⚠️ PaymentBannerController: Invalid current index $currentIndex');
      return;
    }
    
    final seconds = banners[currentIndex].viewChangeTimeSeconds;
    final ms = (seconds * 1000).round();
    
    print('⏱️ PaymentBannerController: Starting auto-scroll timer for ${ms}ms (${seconds}s)');
    
    _autoScrollTimer = Timer(Duration(milliseconds: ms), () {
      print('⏰ PaymentBannerController: Timer triggered, moving to next banner');
      
      if (banners.isEmpty || banners.length <= 1) {
        print('⚠️ PaymentBannerController: Auto-scroll stopped - no banners');
        return;
      }
      
      final nextPage = (selectedIndex.value + 1) % banners.length;
      print('📍 PaymentBannerController: Moving from ${selectedIndex.value} to $nextPage');
      
      if (pageController.hasClients) {
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ).then((_) {
          selectedIndex.value = nextPage;
          print('✅ PaymentBannerController: Page animation completed, restarting timer');
          startAutoScroll(pageController);
        }).catchError((e) {
          print('❌ PaymentBannerController: Animation error: $e');
        });
      } else {
        print('⚠️ PaymentBannerController: PageController has no clients');
      }
    });
  }

  /// Stop auto-scroll timer
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void onClose() {
    _stopAutoScroll();
    super.onClose();
  }
}
