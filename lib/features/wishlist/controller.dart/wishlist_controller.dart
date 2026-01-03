import 'package:get/get.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find();

  // Dependencies
  late final ProductCacheService _cacheService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }
  
  void _initializeServices() {
    try {
      _cacheService = Get.find<ProductCacheService>();
    } catch (e) {
      // Fallback if service is not yet available
      _cacheService = ProductCacheService.instance;
    }
  }

  // Reactive state - directly linked to cache service
  RxList<ProductModel> get products => _cacheService.wishlistProducts;
  RxBool get isLoading => _cacheService.isInitializing;
  RxSet<String> get wishlistIds => _cacheService.wishlistIds;

  // Computed properties
  double get total => products.fold(
    0.0,
    (sum, product) => sum + product.price,
  );
  int get itemCount => products.length;
  bool get isEmpty => products.isEmpty;
  bool get isNotEmpty => products.isNotEmpty;


  /// Refresh wishlist by triggering cache sync
  Future<void> refreshWishlist() async {
    try {
      if (_cacheService.isOnline.value) {
        await _cacheService.performManualRefresh();
      } else {
        TLoaders.warningSnackBar(
          title: "Offline Mode",
          message:
              "Showing cached wishlist items. Connect to internet for latest updates.",
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "Refresh Failed", message: e.toString());
    }
  }

  /// Add product to wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      await _cacheService.addItemToWishlist(productId);
      TLoaders.successSnackBar(
        title: "Added to Wishlist",
        message: "Product added to your wishlist",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "Failed to Add", message: e.toString());
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      await _cacheService.removeItemFromWishlist(productId);
      TLoaders.successSnackBar(
        title: "Removed from Wishlist",
        message: "Product removed from your wishlist",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "Failed to Remove", message: e.toString());
    }
  }

  /// Toggle wishlist status for a product
  Future<void> toggleWishlist(String productId) async {
    try {
      await _cacheService.toggleWishlistStatus(productId);
    } catch (e) {
      TLoaders.errorSnackBar(title: "Action Failed", message: e.toString());
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return wishlistIds.contains(productId);
  }

  /// Get wishlist product by ID
  ProductModel? getWishlistProduct(String productId) {
    return _cacheService.getWishlistProductById(productId);
  }

  /// Clear all wishlist items
  Future<void> clearWishlist() async {
    try {
      // Remove each item individually to maintain sync
      final productIds = List<String>.from(wishlistIds);
      for (final productId in productIds) {
        await _cacheService.removeItemFromWishlist(productId);
      }
      TLoaders.successSnackBar(
        title: "Wishlist Cleared",
        message: "All items removed from wishlist",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "Failed to Clear", message: e.toString());
    }
  }

  /// Get connection status
  bool get isOnline => _cacheService.isOnline.value;

  /// Get sync status
  bool get isSyncing => _cacheService.isSyncing.value;
}
