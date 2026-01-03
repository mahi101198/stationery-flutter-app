import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class PaginatedProductController extends GetxController {
  static PaginatedProductController get instance => Get.find();

  // Pagination state
  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> _popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> _flashSaleProducts = <ProductModel>[].obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Pagination constants
  int _currentPage = 0;
  String? _lastDocumentId;

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get popularProducts => _popularProducts;
  List<ProductModel> get flashSaleProducts => _flashSaleProducts;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  /// Load initial data for home screen
  Future<void> _loadInitialData() async {
    try {
      
      isLoading.value = true;
      hasError.value = false;
      

      // Load different product categories in parallel
      await Future.wait([
        _loadPopularProducts(),
        _loadFlashSaleProducts(),
      ]);

    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load products. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load popular products (limited to 8-10 items)
  Future<void> _loadPopularProducts() async {
    try {
      
      final products = await ProductRepo.instance.fetchProductsByCategory(
        category: 'popular',
      );
      
      
      // Take only 8 products
      final limitedProducts = products.take(8).toList();
      
      _popularProducts.assignAll(limitedProducts);
      
      // Log product details
      for (int i = 0; i < limitedProducts.length; i++) {
      }
    } catch (e) {
      // Fallback to random products from all products
      _loadFallbackProducts('popular');
    }
  }

  /// Load flash sale products (limited to 6-8 items)
  Future<void> _loadFlashSaleProducts() async {
    try {
      
      final products = await ProductRepo.instance.fetchProductsByCategory(
        category: 'flash_sale',
      );
      
      
      // Take only 6 products
      final limitedProducts = products.take(6).toList();
      
      _flashSaleProducts.assignAll(limitedProducts);
      
      // Log product details
      for (int i = 0; i < limitedProducts.length; i++) {
      }
    } catch (e) {
      _loadFallbackProducts('flash_sale');
    }
  }


  /// Fallback method to load random products when category-specific loading fails
  Future<void> _loadFallbackProducts(String category) async {
    try {
      final products = await ProductRepo.instance.fetchAllProducts();
      
      // Shuffle and take required amount
      products.shuffle();
      final limitedProducts = products.take(category == 'flash_sale' ? 6 : 8).toList();
      
      switch (category) {
        case 'popular':
          _popularProducts.assignAll(limitedProducts);
          break;
        case 'flash_sale':
          _flashSaleProducts.assignAll(limitedProducts);
          break;
      }
      
    } catch (e) {
      // Log error for debugging
      print('Error in fallback products: $e');
      // Set error state
      hasError.value = true;
      errorMessage.value = 'Failed to load fallback products.';
    }
  }

  /// Load more products for pagination (used in category screens)
  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore.value = true;
      
      final products = await ProductRepo.instance.fetchAllProducts();

      if (products.isEmpty) {
        hasMoreData.value = false;
        return;
      }

      _allProducts.addAll(products);
      _currentPage++;
      
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Error",
        message: "Failed to load more products. Please try again."
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Search products with pagination
  Future<List<ProductModel>> searchProducts(String query, {int limit = 20, int offset = 0}) async {
    try {
      return await ProductRepo.instance.searchProduct(query);
    } catch (e) {
      return [];
    }
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    _currentPage = 0;
    _lastDocumentId = null;
    hasMoreData.value = true;
    
    _allProducts.clear();
    _popularProducts.clear();
    _flashSaleProducts.clear();
    
    await _loadInitialData();
  }

  /// Get products for specific category screen
  Future<List<ProductModel>> getProductsForCategory(String category, {int limit = 20}) async {
    try {
      final products = await ProductRepo.instance.fetchProductsByCategory(
        category: category,
      );
      // Apply limit if needed
      return limit > 0 ? products.take(limit).toList() : products;
    } catch (e) {
      return [];
    }
  }

  /// Reset pagination state
  void resetPagination() {
    _currentPage = 0;
    _lastDocumentId = null;
    hasMoreData.value = true;
    _allProducts.clear();
  }
}
