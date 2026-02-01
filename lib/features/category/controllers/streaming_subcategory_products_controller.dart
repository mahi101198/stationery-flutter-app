import 'dart:async';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/services/subcategory_product_service.dart';

/// Controller for streaming subcategory products with non-blocking loading
class StreamingSubCategoryProductsController extends GetxController {
  static StreamingSubCategoryProductsController get instance => Get.find();

  // Service reference
  final SubCategoryProductService _productService = Get.find<SubCategoryProductService>();

  // Current state
  final RxString _currentSubCategoryId = ''.obs;
  final RxString _subCategoryName = ''.obs;
  final RxList<ProductModel> _products = <ProductModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;

  // Streaming state
  final RxBool _isStreaming = false.obs;
  final RxInt _loadedCount = 0.obs;
  final RxInt _totalCount = 0.obs;
  
  // Stream controller for products
  final StreamController<List<ProductModel>> _productsStreamController = StreamController<List<ProductModel>>.broadcast();
  
  // Timer for streaming simulation
  Timer? _streamingTimer;
  static const int _batchSize = 5; // Load 5 products at a time
  static const int _streamingDelay = 200; // 200ms delay between batches

  // Getters
  String get currentSubCategoryId => _currentSubCategoryId.value;
  String get subCategoryName => _subCategoryName.value;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  bool get isStreaming => _isStreaming.value;
  int get loadedCount => _loadedCount.value;
  int get totalCount => _totalCount.value;
  Stream<List<ProductModel>> get productsStream => _productsStreamController.stream;

  @override
  void onInit() {
    super.onInit();
    print('🌊 StreamingSubCategoryProductsController: Initializing streaming controller...');
  }

  @override
  void onClose() {
    _streamingTimer?.cancel();
    _productsStreamController.close();
    super.onClose();
  }

  /// Start streaming products for a subcategory
  Future<void> startStreamingProducts(String subCategoryId, String subCategoryName) async {
    print('🌊 StreamingSubCategoryProductsController: Starting streaming for $subCategoryName ($subCategoryId)');
    
    // Cancel any existing streaming
    _streamingTimer?.cancel();
    
    // Reset state
    _currentSubCategoryId.value = subCategoryId;
    _subCategoryName.value = subCategoryName;
    _products.clear();
    _loadedCount.value = 0;
    _totalCount.value = 0;
    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';
    _isStreaming.value = false;

    try {
      // First, get total count without loading all products
      print('🌊 StreamingSubCategoryProductsController: Getting total product count for: $subCategoryId');
      final totalCount = await _productService.getProductCountForSubCategory(subCategoryId);
      
      // If no products found with the ID, try with the name (as fallback)
      int adjustedTotalCount = totalCount;
      String effectiveSubCategoryId = subCategoryId;
      
      if (totalCount == 0) {
        print('⚠️ StreamingSubCategoryProductsController: No products found with ID: $subCategoryId');
        print('🌊 StreamingSubCategoryProductsController: Trying to find products with name: $subCategoryName');
        
        // Try with subcategory name as fallback
        adjustedTotalCount = await _productService.getProductCountForSubCategory(subCategoryName);
        if (adjustedTotalCount > 0) {
          print('✅ StreamingSubCategoryProductsController: Found ${adjustedTotalCount} products using name: $subCategoryName');
          effectiveSubCategoryId = subCategoryName;
        }
      }
      
      _totalCount.value = adjustedTotalCount;
      
      if (adjustedTotalCount == 0) {
        _isLoading.value = false;
        print('🌊 StreamingSubCategoryProductsController: No products found');
        return;
      }

      print('🌊 StreamingSubCategoryProductsController: Total products to load: $adjustedTotalCount (using ID: $effectiveSubCategoryId)');
      
      // Start streaming
      _isStreaming.value = true;
      _isLoading.value = false;
      
      // Stream products in batches
      await _streamProductsInBatches(effectiveSubCategoryId, adjustedTotalCount);
      
    } catch (e) {
      print('❌ StreamingSubCategoryProductsController: Error starting streaming: $e');
      _hasError.value = true;
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      _isStreaming.value = false;
    }
  }

  /// Stream products in batches to avoid blocking main thread
  Future<void> _streamProductsInBatches(String subCategoryId, int totalCount) async {
    int currentOffset = 0;
    List<ProductModel> allProducts = [];
    
    while (currentOffset < totalCount) {
      try {
        // Load batch of products
        final batch = await _productService.getProductsForSubCategory(
          subCategoryId, 
          limit: _batchSize, 
          offset: currentOffset
        );
        
        if (batch.isEmpty) {
          print('🌊 StreamingSubCategoryProductsController: No more products to load');
          break;
        }
        
        // Add to all products
        allProducts.addAll(batch);
        
        // Update loaded count
        _loadedCount.value = allProducts.length;
        
        // Update products list
        _products.assignAll(allProducts);
        
        // Emit to stream
        _productsStreamController.add(List.from(allProducts));
        
        print('🌊 StreamingSubCategoryProductsController: Loaded ${allProducts.length}/$totalCount products');
        
        // Wait before next batch
        await Future.delayed(Duration(milliseconds: _streamingDelay));
        
        currentOffset += _batchSize;
        
      } catch (e) {
        print('❌ StreamingSubCategoryProductsController: Error loading batch: $e');
        _hasError.value = true;
        _errorMessage.value = e.toString();
        break;
      }
    }
    
    // Streaming complete
    _isStreaming.value = false;
    print('✅ StreamingSubCategoryProductsController: Streaming completed. Total products: ${allProducts.length}');
  }

  /// Refresh products for current subcategory
  Future<void> refreshProducts() async {
    if (_currentSubCategoryId.value.isNotEmpty) {
      await startStreamingProducts(_currentSubCategoryId.value, _subCategoryName.value);
    }
  }

  /// Clear all products
  void clearProducts() {
    _streamingTimer?.cancel();
    _products.clear();
    _loadedCount.value = 0;
    _totalCount.value = 0;
    _isLoading.value = false;
    _hasError.value = false;
    _errorMessage.value = '';
    _isStreaming.value = false;
    _currentSubCategoryId.value = '';
    _subCategoryName.value = '';
  }
}
