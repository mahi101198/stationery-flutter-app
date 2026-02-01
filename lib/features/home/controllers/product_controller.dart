// product_controller.dart
import 'package:get/get.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'dart:developer' as dev;

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  var productList = <ProductModel>[].obs;
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var retryCount = 0;
  static const maxRetries = 3;

  @override
  void onInit() {
    super.onInit();
    // Add a small delay to ensure Firebase is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      fetchProducts();
    });
  }

  /// Reset error state
  void resetError() {
    hasError.value = false;
    errorMessage.value = '';
    retryCount = 0;
  }

  Future<void> fetchProducts({bool showLoader = true}) async {
    try {
      if (showLoader) {
        isLoading.value = true;
        resetError();
      }
      
      dev.log('🔄 Starting product fetch (attempt ${retryCount + 1}/$maxRetries)...', name: 'ProductController');
      
      // Check Firebase connection
      if (AuthRepository.instance.firebaseUser.value == null) {
        dev.log('⚠️ Firebase not properly initialized', name: 'ProductController');
      }
      
      List<ProductModel> products;
      
      // Try ProductCacheService first (new enterprise service)
      try {
        final cacheService = ProductCacheService.instance;
        
        // Combine popular and flash sale products
        final allProducts = <ProductModel>[];
        allProducts.addAll(cacheService.popularProducts);
        allProducts.addAll(cacheService.flashSaleProducts);
        
        // Remove duplicates based on productId
        final seenIds = <String>{};
        products = allProducts.where((product) {
          if (seenIds.contains(product.productId)) {
            return false;
          }
          seenIds.add(product.productId);
          return true;
        }).toList();
        
        dev.log('📦 Using ProductCacheService - combined ${products.length} products', name: 'ProductController');
        
        // If no products in cache, try fallback
        if (products.isEmpty) {
          products = await ProductRepo.instance.fetchAllProducts();
          dev.log('📦 Using ProductRepo fallback - fetched ${products.length} products', name: 'ProductController');
        }
      } catch (cacheError) {
        dev.log('⚠️ ProductCacheService failed: $cacheError', name: 'ProductController');
        // Fallback to ProductRepo (legacy)
        products = await ProductRepo.instance.fetchAllProducts();
        dev.log('📦 Using ProductRepo fallback - fetched ${products.length} products', name: 'ProductController');
      }
      
      dev.log('📦 Fetched ${products.length} products from repository', name: 'ProductController');
      
      // Success - reset retry count and update products
      retryCount = 0;
      productList.assignAll(products);
      resetError();
      
      if (products.isNotEmpty) {
        dev.log('✅ Successfully loaded ${products.length} products', name: 'ProductController');
      } else {
        dev.log('⚠️ No products returned from repository!', name: 'ProductController');
        dev.log('💡 Check if products exist in Firestore product_details collection', name: 'ProductController');
        
        // Only set error if truly no products found after all retries
        hasError.value = true;
        errorMessage.value = "No products found. Please check if products exist in the database.";
        
        if (showLoader) {
          TLoaders.warningSnackBar(
            title: "No Products Found",
            message: "No products are currently available. Please try refreshing."
          );
        }
      }
      
    } catch (e) {
      dev.log('❌ Product fetch failed (attempt ${retryCount + 1}): $e', name: 'ProductController');
      
      hasError.value = true;
      errorMessage.value = _getErrorMessage(e.toString());
      
      // Retry logic
      if (retryCount < maxRetries - 1) {
        retryCount++;
        dev.log('🔄 Retrying product fetch in 2 seconds...', name: 'ProductController');
        await Future.delayed(const Duration(seconds: 2));
        return fetchProducts(showLoader: false);
      } else {
        dev.log('❌ Max retry attempts reached', name: 'ProductController');
        if (showLoader) {
          TLoaders.errorSnackBar(
            title: "Connection Error",
            message: errorMessage.value
          );
        }
      }
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
      dev.log('🏁 Product fetch completed. Loading: ${isLoading.value}, Error: ${hasError.value}', name: 'ProductController');
    }
  }
  
  /// Convert technical error messages to user-friendly messages
  String _getErrorMessage(String error) {
    if (error.contains('permission') || error.contains('403')) {
      return 'Access denied. Please check app permissions.';
    } else if (error.contains('network') || error.contains('timeout')) {
      return 'Network connection issue. Please check your internet.';
    } else if (error.contains('firebase') || error.contains('firestore')) {
      return 'Database connection issue. Please try again later.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}
