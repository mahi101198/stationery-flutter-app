import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/services/subcategory_product_service.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

/// Controller for managing subcategory-based product display with caching
class SubCategoryProductController extends GetxController {
  static SubCategoryProductController get instance => Get.find();

  // Service reference
  final SubCategoryProductService _productService = Get.find<SubCategoryProductService>();

  // Current state
  final RxString _currentSubCategoryId = ''.obs;
  final RxString _currentCategoryId = ''.obs;
  final RxList<ProductModel> _allCategoryProducts = <ProductModel>[].obs; // All products for current category
  final RxList<ProductModel> _products = <ProductModel>[].obs; // Currently displayed products
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;

  // Pagination state
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMoreData = true.obs;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Getters
  String get currentSubCategoryId => _currentSubCategoryId.value;
  String get currentCategoryId => _currentCategoryId.value;
  List<ProductModel> get products => _products;
  List<ProductModel> get allCategoryProducts => _allCategoryProducts;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  bool get hasMoreData => _hasMoreData.value;

  @override
  void onInit() {
    super.onInit();
    print('📦 SubCategoryProductController: Initializing subcategory product controller...');
    print('📦 SubCategoryProductController: Current subcategory: ${_currentSubCategoryId.value}');
    print('📦 SubCategoryProductController: Products: ${_products.length}, Loading: ${_isLoading.value}, Error: ${_hasError.value}');
  }

  /// Load ALL products for a specific category
  Future<void> loadProductsForCategory(String categoryId, {bool forceRefresh = false}) async {
    print('📦 SubCategoryProductController: Loading ALL products for category: $categoryId');
    
    _currentCategoryId.value = categoryId;
    _currentSubCategoryId.value = ''; // Reset subcategory
    _resetPagination();

    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';

    try {
      print('📦 SubCategoryProductController: Fetching all products for category from service...');
      
      // Get all products for the category from service
      final fetchedProducts = await _productService.getProductsForCategory(
        categoryId, 
        forceRefresh: forceRefresh
      );

      print('📦 SubCategoryProductController: Service returned ${fetchedProducts.length} products for category');

      // Store all products and display them
      _allCategoryProducts.assignAll(fetchedProducts);
      _products.assignAll(fetchedProducts);
      
      // Update pagination state
      _hasMoreData.value = fetchedProducts.length >= _pageSize;
      _currentPage = 0;

      print('✅ SubCategoryProductController: Successfully loaded ${fetchedProducts.length} products for category $categoryId');

    } catch (e) {
      print('❌ SubCategoryProductController: Error loading products for category $categoryId: $e');
      _hasError.value = true;
      _errorMessage.value = e.toString();
      
      // Show error to user
      TLoaders.errorSnackBar(
        title: "Error Loading Products",
        message: "Failed to load products for this category. Please try again."
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Filter products by subcategory (from already loaded category products)
  void filterProductsBySubCategory(String subCategoryId) {
    print('📦 SubCategoryProductController: Filtering products by subcategory: $subCategoryId');
    
    _currentSubCategoryId.value = subCategoryId;
    
    // Filter from all category products
    final filteredProducts = _allCategoryProducts
        .where((product) => product.subcategoryId == subCategoryId)
        .toList();
    
    _products.assignAll(filteredProducts);
    _resetPagination();
    if (filteredProducts.isEmpty) {
      _hasMoreData.value = false;
    }
    
    print('✅ SubCategoryProductController: Filtered to ${filteredProducts.length} products for subcategory $subCategoryId');
  }

  /// Show all products for the current category (remove subcategory filter)
  void showAllProductsForCategory() {
    print('📦 SubCategoryProductController: Showing all products for category: ${_currentCategoryId.value}');
    
    _currentSubCategoryId.value = '';
    _products.assignAll(_allCategoryProducts);
    _resetPagination();
    
    print('✅ SubCategoryProductController: Showing all ${_allCategoryProducts.length} products for category');
  }

  /// Load products for a specific subcategory (legacy method - kept for compatibility)
  Future<void> loadProductsForSubCategory(String subCategoryId, {bool forceRefresh = false}) async {
    print('📦 SubCategoryProductController: Loading products for subcategory: $subCategoryId');
    
    // Reset pagination state when loading new subcategory
    if (_currentSubCategoryId.value != subCategoryId) {
      _resetPagination();
      _currentSubCategoryId.value = subCategoryId;
    }

    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';

    try {
      print('📦 SubCategoryProductController: Fetching products from service...');
      
      // Get products from service (with caching)
      final fetchedProducts = await _productService.getProductsForSubCategory(
        subCategoryId, 
        forceRefresh: forceRefresh
      );

      print('📦 SubCategoryProductController: Service returned ${fetchedProducts.length} products');

      // Update products list
      _products.assignAll(fetchedProducts);
      
      // Update pagination state
      _hasMoreData.value = fetchedProducts.length >= _pageSize;
      _currentPage = 0;

      print('✅ SubCategoryProductController: Successfully loaded ${fetchedProducts.length} products for $subCategoryId');

    } catch (e) {
      print('❌ SubCategoryProductController: Error loading products for $subCategoryId: $e');
      _hasError.value = true;
      _errorMessage.value = e.toString();
      
      // Show error to user
      TLoaders.errorSnackBar(
        title: "Error Loading Products",
        message: "Failed to load products for this category. Please try again."
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore.value || !_hasMoreData.value || _currentSubCategoryId.value.isEmpty) {
      return;
    }

    _isLoadingMore.value = true;

    try {
      print('📦 SubCategoryProductController: Loading more products for ${_currentSubCategoryId.value}...');
      
      // For now, we'll use the cached products and simulate pagination
      // In a real implementation, you might want to implement server-side pagination
      final cachedProducts = _productService.getCachedProducts(_currentSubCategoryId.value);
      
      if (cachedProducts.length > _products.length) {
        // Add more products from cache
        final startIndex = _products.length;
        final endIndex = (startIndex + _pageSize).clamp(0, cachedProducts.length);
        final newProducts = cachedProducts.sublist(startIndex, endIndex);
        
        _products.addAll(newProducts);
        _currentPage++;
        
        // Check if we have more data
        _hasMoreData.value = endIndex < cachedProducts.length;
        
        print('📦 SubCategoryProductController: Loaded ${newProducts.length} more products (Total: ${_products.length})');
      } else {
        _hasMoreData.value = false;
        print('📦 SubCategoryProductController: No more products to load');
      }

    } catch (e) {
      print('❌ SubCategoryProductController: Error loading more products: $e');
      TLoaders.errorSnackBar(
        title: "Error",
        message: "Failed to load more products. Please try again."
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh current subcategory products
  Future<void> refreshProducts() async {
    if (_currentSubCategoryId.value.isNotEmpty) {
      print('🔄 SubCategoryProductController: Refreshing products for ${_currentSubCategoryId.value}');
      await loadProductsForSubCategory(_currentSubCategoryId.value, forceRefresh: true);
    }
  }

  /// Clear current products
  void clearProducts() {
    _products.clear();
    _allCategoryProducts.clear();
    _currentSubCategoryId.value = '';
    _currentCategoryId.value = '';
    _resetPagination();
    print('🧹 SubCategoryProductController: Cleared all products');
  }

  /// Reset pagination state
  void _resetPagination() {
    _currentPage = 0;
    _hasMoreData.value = true;
    _isLoadingMore.value = false;
  }

  /// Check if products are cached for a subcategory
  bool isCached(String subCategoryId) {
    return _productService.getCachedProducts(subCategoryId).isNotEmpty;
  }

  /// Preload products for a subcategory
  Future<void> preloadProducts(String subCategoryId) async {
    print('🚀 SubCategoryProductController: Preloading products for $subCategoryId');
    await _productService.preloadProducts(subCategoryId);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _productService.getCacheStats();
  }

  /// Clear all cache
  void clearAllCache() {
    _productService.clearAllCache();
    clearProducts();
    print('🧹 SubCategoryProductController: Cleared all cache and products');
  }
}
