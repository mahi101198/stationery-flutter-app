import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/controllers/startup_controller.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/data/services/product_service.dart';
import 'package:rps_stationery/data/services/cart_wishlist_service.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/services/database_service.dart';
import 'package:rps_stationery/services/error_handling_service.dart';
import 'package:rps_stationery/services/firebase_init_service.dart';
import 'package:rps_stationery/services/unified_search_service.dart';
import 'package:rps_stationery/utils/helpers/network_manager.dart';
import 'package:rps_stationery/services/network_connectivity_service.dart';
import 'package:rps_stationery/utils/loading/loading_state_manager.dart';
import 'package:rps_stationery/utils/memory/memory_manager.dart';
import 'package:rps_stationery/features/personalization/controllers/theme_controller.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/features/home/controllers/banner_controller.dart';
import 'package:rps_stationery/features/wishlist/controller.dart/wishlist_controller.dart';
import 'package:rps_stationery/features/home/controllers/product_controller.dart';
import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';
import 'package:rps_stationery/data/repositories/category_repo.dart';
import 'package:rps_stationery/data/repositories/home_section_repo.dart';
import 'package:rps_stationery/data/repositories/banner_repo.dart';
import 'package:rps_stationery/data/repositories/subcategory_repo.dart';
import 'package:rps_stationery/data/repositories/review_repo.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:rps_stationery/data/services/subcategory_product_service.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    _initializeCore();
    _initializeServices();
    _initializeControllers();
  }
  
  void _initializeCore() {
    // Core utilities first
    Get.put(NetworkManager(), permanent: true);
    Get.put(NetworkConnectivityService(), permanent: true);
    Get.put(LoadingStateManager(), permanent: true);
    Get.put(MemoryManager(), permanent: true);
    Get.put(ErrorHandlingService(), permanent: true);
    
    // Platform-specific services
    if (!kIsWeb) {
      if (!Get.isRegistered<DatabaseService>()) {
        Get.put(DatabaseService(), permanent: true);
      }
    }
    
    if (!Get.isRegistered<FirebaseInitService>()) {
      Get.put(FirebaseInitService(), permanent: true);
    }
  }
  
  void _initializeServices() {
    // Enterprise Services - in dependency order
    Get.put(UserService(), permanent: true);
    Get.put(ProductService(), permanent: true);
    Get.put(CartWishlistService(), permanent: true);
    
    // Cache service (native platforms only)
    if (!kIsWeb && !Get.isRegistered<ProductCacheService>()) {
      Get.put(ProductCacheService(), permanent: true);
    }
    
    // Unified Search Service (requires ProductCacheService)
    if (!kIsWeb && !Get.isRegistered<UnifiedSearchService>()) {
      Get.put(UnifiedSearchService(), permanent: true);
    }
    
    // Repositories
    Get.put(CategoryRepo(), permanent: true);
    Get.put(HomeSectionRepo(), permanent: true);
    Get.put(BannerRepo(), permanent: true);
    Get.put(SubCategoryRepo(), permanent: true);
    Get.put(ReviewRepo(), permanent: true);
    
    // Legacy ProductRepo (keeping for gradual migration)
    if (!Get.isRegistered<ProductRepo>()) {
      Get.put(ProductRepo(), permanent: true);
    }
    
    // Services
    Get.put(SubCategoryProductService(), permanent: true);
  }
  
  void _initializeControllers() {
    // Initialize theme controller first for proper theming
    Get.put(ThemeController());
    
    // Initialize controllers after all services are ready
    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<BannerController>(() => BannerController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<HomeSectionController>(() => HomeSectionController());
    Get.lazyPut<ReviewController>(() => ReviewController());
    
    // Only initialize WishlistController if ProductCacheService is available
    if (!kIsWeb) {
      Get.lazyPut<WishlistController>(() => WishlistController());
    }
    
    
    // Startup controller last
    Get.put(StartupController());
  }
}
