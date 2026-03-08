import 'dart:async';

import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/banner_repo.dart';
import 'package:rps_stationery/data/models/additional_models.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class BannerController extends GetxController {
  final isLoading = false.obs;
  final selectedIndex = 0.obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;

  void updatePageIndicator(index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    print('🎯 BannerController: Initializing banner controller...');
    print('🎯 BannerController: Setting up reactive variables...');
    print('🎯 BannerController: Banners list initialized with ${banners.length} items');
    print('🎯 BannerController: Loading state: ${isLoading.value}');
    print('🎯 BannerController: Selected index: ${selectedIndex.value}');
    
    // Add a small delay to ensure GetX context is fully initialized
    print('🎯 BannerController: Scheduling banner fetch in 100ms...');
    Future.delayed(const Duration(milliseconds: 100), () {
      print('🎯 BannerController: Starting delayed banner fetch...');
      fetchBanners();
    });
  }

  // Fetch banners with optimization
  Future<void> fetchBanners() async {
    try {
      print('🔄 BannerController: Starting banner fetch...');
      print('🔄 BannerController: Current state - Loading: ${isLoading.value}, Banners: ${this.banners.length}');
      
      isLoading.value = true;
      print('🔄 BannerController: State updated - Loading: ${isLoading.value}');
      print('🔄 BannerController: Calling BannerRepo.instance.fetchBanners()...');

      // Use compute to move heavy operations off main thread if needed
      final banners = await BannerRepo.instance.fetchBanners();
      print('📊 BannerController: Repository call completed. Received ${banners.length} banners');
      
      // Update in batch to reduce rebuilds
      if (banners.isNotEmpty) {
        print('✅ BannerController: Successfully loaded ${banners.length} banners');
        print('✅ BannerController: Updating reactive banners list...');
        
        // Sort by rank so position 1 always appears first in the carousel.
        final sorted = List<BannerModel>.from(banners)
          ..sort((a, b) => a.rank.compareTo(b.rank));
        this.banners.assignAll(sorted);
        
        print('✅ BannerController: Banners list updated. Current length: ${this.banners.length}');
        
        // Log banner details for debugging
        print('📋 BannerController: Detailed banner information:');
        for (int i = 0; i < banners.length; i++) {
          print('  Banner $i: ID=${banners[i].bannerId}, Image=${banners[i].imageUrl}, Active=${banners[i].active}, Priority=${banners[i].priority}');
        }
        
        print('✅ BannerController: All banners processed and logged');
      } else {
        print('⚠️ BannerController: No banners found or permission denied - repository returned empty list');
        print('⚠️ BannerController: This could mean no active banners in database or database connection issue');
        // Don't show error snackbar for empty results, just log it
      }
    } catch (e, stackTrace) {
      print('❌ BannerController: Error fetching banners: $e');
      print('❌ BannerController: Error type: ${e.runtimeType}');
      print('❌ BannerController: Stack trace: $stackTrace');
      
      // Only show error if context is available and it's not a permission issue
      if (Get.context != null && !e.toString().contains('permission')) {
        print('❌ BannerController: Showing error snackbar to user');
        TLoaders.errorSnackBar(title: "Banner Error", message: "Unable to load banners: ${e.toString()}");
      } else {
        print('❌ BannerController: Skipping error snackbar (no context or permission error)');
      }
    } finally {
      isLoading.value = false;
      print('🏁 BannerController: Banner fetch completed. Final state - Loading: ${isLoading.value}, Banners: ${banners.length}');
    }
  }
}
