import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

/// Service for managing subcategory-based product fetching with caching
class SubCategoryProductService extends GetxService {
  static SubCategoryProductService get instance => Get.find();

  // Cache for subcategory products
  final RxMap<String, List<ProductModel>> _subCategoryProductsCache = <String, List<ProductModel>>{}.obs;
  
  // Cache timestamps to implement cache expiration
  final RxMap<String, DateTime> _cacheTimestamps = <String, DateTime>{}.obs;
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Loading states for each subcategory
  final RxMap<String, bool> _loadingStates = <String, bool>{}.obs;
  
  // Error states for each subcategory
  final RxMap<String, String> _errorStates = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔄 SubCategoryProductService: Initializing subcategory product service...');
    print('🔄 SubCategoryProductService: Cache initialized with ${_subCategoryProductsCache.length} entries');
  }

  /// Get ALL products for a specific category with caching
  Future<List<ProductModel>> getProductsForCategory(String categoryId, {bool forceRefresh = false}) async {
    print('📦 SubCategoryProductService: Getting ALL products for category: $categoryId');
    
    // Check if we have cached data and it's not expired
    if (!forceRefresh && _isCacheValid(categoryId)) {
      final cachedProducts = _subCategoryProductsCache[categoryId] ?? [];
      print('📦 SubCategoryProductService: Returning ${cachedProducts.length} cached products for category $categoryId');
      return cachedProducts;
    }

    // Check if already loading this category
    if (_loadingStates[categoryId] == true) {
      print('📦 SubCategoryProductService: Already loading products for category $categoryId, waiting...');
      // Wait for current loading to complete
      while (_loadingStates[categoryId] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return cached result after loading completes
      return _subCategoryProductsCache[categoryId] ?? [];
    }

    // Start loading
    _loadingStates[categoryId] = true;
    _errorStates.remove(categoryId);

    try {
      print('📦 SubCategoryProductService: Fetching fresh products for category: $categoryId');
      
      // Fetch products from database based on category
      final products = await _fetchProductsFromDatabaseByCategory(categoryId);
      
      // Cache the results
      _subCategoryProductsCache[categoryId] = products;
      _cacheTimestamps[categoryId] = DateTime.now();
      
      print('✅ SubCategoryProductService: Successfully cached ${products.length} products for category $categoryId');
      
      return products;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Error fetching products for category $categoryId: $e');
      _errorStates[categoryId] = e.toString();
      
      // Return cached data if available, even if expired
      final cachedProducts = _subCategoryProductsCache[categoryId] ?? [];
      if (cachedProducts.isNotEmpty) {
        print('📦 SubCategoryProductService: Returning ${cachedProducts.length} stale cached products for category $categoryId');
        return cachedProducts;
      }
      
      // Show error to user only if no cached data available
      TLoaders.errorSnackBar(
        title: "Error Loading Products",
        message: "Failed to load products for this category. Please try again."
      );
      
      return [];
      
    } finally {
      _loadingStates[categoryId] = false;
    }
  }

  /// Get product count for a specific subcategory
  Future<int> getProductCountForSubCategory(String subCategoryId) async {
    try {
      print('📦 SubCategoryProductService: Getting product count for subcategory: $subCategoryId');
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('subcategoryId', isEqualTo: subCategoryId)
          .get();
      
      final count = snapshot.docs.length;
      print('📦 SubCategoryProductService: Found $count products for subcategory: $subCategoryId');
      return count;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Error getting product count for $subCategoryId: $e');
      throw Exception('Failed to get product count: $e');
    }
  }

  /// Get products for a specific subcategory with pagination support
  Future<List<ProductModel>> getProductsForSubCategory(String subCategoryId, {
    bool forceRefresh = false,
    int limit = 10,
    int offset = 0
  }) async {
    print('📦 SubCategoryProductService: Getting products for subcategory: $subCategoryId (limit: $limit, offset: $offset)');
    
    try {
      // For now, get all products and slice them (Firestore doesn't support offset directly)
      // In a production app, you'd use cursor-based pagination with startAfter
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('subcategoryId', isEqualTo: subCategoryId);

      final QuerySnapshot snapshot = await query.get();
      
      final allProducts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Add document ID to the data
        data['productId'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
      
      // Apply offset and limit manually
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, allProducts.length);
      final products = allProducts.sublist(
        startIndex.clamp(0, allProducts.length),
        endIndex
      );
      
      print('📦 SubCategoryProductService: Retrieved ${products.length} products for $subCategoryId (from ${allProducts.length} total)');
      return products;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Error getting paginated products for $subCategoryId: $e');
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get all products for a specific subcategory with caching (original method)
  Future<List<ProductModel>> getAllProductsForSubCategory(String subCategoryId, {bool forceRefresh = false}) async {
    print('📦 SubCategoryProductService: Getting products for subcategory: $subCategoryId');
    
    // Check if we have cached data and it's not expired
    if (!forceRefresh && _isCacheValid(subCategoryId)) {
      final cachedProducts = _subCategoryProductsCache[subCategoryId] ?? [];
      print('📦 SubCategoryProductService: Returning ${cachedProducts.length} cached products for $subCategoryId');
      return cachedProducts;
    }

    // Check if already loading this subcategory
    if (_loadingStates[subCategoryId] == true) {
      print('📦 SubCategoryProductService: Already loading products for $subCategoryId, waiting...');
      // Wait for current loading to complete
      while (_loadingStates[subCategoryId] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return cached result after loading completes
      return _subCategoryProductsCache[subCategoryId] ?? [];
    }

    // Start loading
    _loadingStates[subCategoryId] = true;
    _errorStates.remove(subCategoryId);

    try {
      print('📦 SubCategoryProductService: Fetching fresh products for subcategory: $subCategoryId');
      
      // Fetch products from database based on subcategory
      final products = await _fetchProductsFromDatabase(subCategoryId);
      
      // Cache the results
      _subCategoryProductsCache[subCategoryId] = products;
      _cacheTimestamps[subCategoryId] = DateTime.now();
      
      print('✅ SubCategoryProductService: Successfully cached ${products.length} products for $subCategoryId');
      
      return products;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Error fetching products for $subCategoryId: $e');
      _errorStates[subCategoryId] = e.toString();
      
      // Return cached data if available, even if expired
      final cachedProducts = _subCategoryProductsCache[subCategoryId] ?? [];
      if (cachedProducts.isNotEmpty) {
        print('📦 SubCategoryProductService: Returning ${cachedProducts.length} stale cached products for $subCategoryId');
        return cachedProducts;
      }
      
      // Show error to user only if no cached data available
      TLoaders.errorSnackBar(
        title: "Error Loading Products",
        message: "Failed to load products for this category. Please try again."
      );
      
      return [];
      
    } finally {
      _loadingStates[subCategoryId] = false;
    }
  }

  /// Fetch products from database based on category ID
  Future<List<ProductModel>> _fetchProductsFromDatabaseByCategory(String categoryId) async {
    try {
      print('🔍 SubCategoryProductService: Querying database for category: $categoryId');
      
      // Use ProductRepo to fetch products by category
      final products = await ProductRepo.instance.fetchProductsByCategory(category: categoryId);
      
      print('📊 SubCategoryProductService: Database returned ${products.length} products for category $categoryId');
      
      return products;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Database error for category $categoryId: $e');
      rethrow;
    }
  }

  /// Fetch products from database based on subcategory ID
  Future<List<ProductModel>> _fetchProductsFromDatabase(String subCategoryId) async {
    try {
      print('🔍 SubCategoryProductService: Querying database for subcategory: $subCategoryId');
      
      // Use ProductRepo to fetch products by subcategory
      // Note: This assumes your products collection has a subcategoryId field
      final products = await ProductRepo.instance.fetchProductsBySubCategory(subCategoryId);
      
      print('📊 SubCategoryProductService: Database returned ${products.length} products for $subCategoryId');
      
      return products;
      
    } catch (e) {
      print('❌ SubCategoryProductService: Database error for $subCategoryId: $e');
      rethrow;
    }
  }

  /// Check if cache is valid (not expired)
  bool _isCacheValid(String subCategoryId) {
    final timestamp = _cacheTimestamps[subCategoryId];
    if (timestamp == null) return false;
    
    final isExpired = DateTime.now().difference(timestamp) > _cacheDuration;
    if (isExpired) {
      print('⏰ SubCategoryProductService: Cache expired for $subCategoryId, will refresh');
      return false;
    }
    
    return true;
  }

  /// Get cached products for a subcategory (without fetching)
  List<ProductModel> getCachedProducts(String subCategoryId) {
    return _subCategoryProductsCache[subCategoryId] ?? [];
  }

  /// Check if products are currently loading for a subcategory
  bool isLoading(String subCategoryId) {
    return _loadingStates[subCategoryId] == true;
  }

  /// Check if there's an error for a subcategory
  String? getError(String subCategoryId) {
    return _errorStates[subCategoryId];
  }

  /// Clear cache for a specific subcategory
  void clearCache(String subCategoryId) {
    _subCategoryProductsCache.remove(subCategoryId);
    _cacheTimestamps.remove(subCategoryId);
    _loadingStates.remove(subCategoryId);
    _errorStates.remove(subCategoryId);
    print('🧹 SubCategoryProductService: Cleared cache for $subCategoryId');
  }

  /// Clear all cache
  void clearAllCache() {
    _subCategoryProductsCache.clear();
    _cacheTimestamps.clear();
    _loadingStates.clear();
    _errorStates.clear();
    print('🧹 SubCategoryProductService: Cleared all cache');
  }

  /// Preload products for a subcategory (useful for predictive loading)
  Future<void> preloadProducts(String subCategoryId) async {
    if (!_isCacheValid(subCategoryId)) {
      print('🚀 SubCategoryProductService: Preloading products for $subCategoryId');
      await getProductsForSubCategory(subCategoryId);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedSubCategories': _subCategoryProductsCache.length,
      'totalCachedProducts': _subCategoryProductsCache.values.fold(0, (sum, products) => sum + products.length),
      'loadingSubCategories': _loadingStates.values.where((loading) => loading).length,
      'errorSubCategories': _errorStates.length,
    };
  }

  /// Refresh all cached data
  Future<void> refreshAllCache() async {
    print('🔄 SubCategoryProductService: Refreshing all cached data...');
    final subCategoryIds = _subCategoryProductsCache.keys.toList();
    
    for (final subCategoryId in subCategoryIds) {
      await getProductsForSubCategory(subCategoryId, forceRefresh: true);
    }
    
    print('✅ SubCategoryProductService: All cache refreshed');
  }
}
