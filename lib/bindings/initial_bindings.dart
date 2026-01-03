import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/banner_repo.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/data/services/product_service.dart';
import 'package:rps_stationery/data/services/cart_wishlist_service.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/features/home/controllers/banner_controller.dart';
import 'package:rps_stationery/features/home/controllers/product_controller.dart';
import 'package:rps_stationery/features/wishlist/controller.dart/wishlist_controller.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // Legacy Repositories (keeping for gradual migration)
    Get.put(BannerRepo());
    Get.put(ProductRepo());

    // Enterprise Services
    Get.put(UserService());
    Get.put(ProductService());
    Get.put(CartWishlistService());
    Get.put(ProductCacheService());

    // Controllers
    Get.put(CartController());
    Get.put(BannerController());
    Get.put(ProductController()); // Keep legacy controller for gradual migration
    Get.put(WishlistController());
  }
}
