import 'dart:developer';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/home_section_repo.dart';
import 'package:rps_stationery/data/models/home_section_model.dart';
import 'package:rps_stationery/data/models/home_section_item_model.dart';
import 'package:rps_stationery/data/repositories/product_repo.dart';

/// Home Section Controller - Manages home sections and their items
/// New schema: Sections are global, not category-based
class HomeSectionController extends GetxController {
  static HomeSectionController get instance => Get.find();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Home sections (sorted by rank)
  final RxList<HomeSectionModel> _sections = <HomeSectionModel>[].obs;
  
  // Section items (loaded on-demand)
  final RxMap<String, List<HomeSectionItemModel>> _sectionItems = 
      <String, List<HomeSectionItemModel>>{}.obs;
  
  // Loading states for individual sections
  final RxMap<String, bool> _sectionLoadingStates = <String, bool>{}.obs;

  // Pagination states for subcategory filtering
  final RxMap<String, int> _sectionCurrentPage = <String, int>{}.obs; // page per section
  final RxMap<String, Map<String, List<HomeSectionItemModel>>> _sectionItemsBySubcategory = 
      <String, Map<String, List<HomeSectionItemModel>>>{}.obs; // section -> subcategory -> items
  final RxMap<String, RxBool> _sectionLoadingMoreBySubcategory = <String, RxBool>{}.obs;
  
  // Constants
  static const int BATCH_SIZE = 8; // Load 8 items per batch

  // ==================== GETTERS ====================

  /// Get all active sections sorted by rank
  List<HomeSectionModel> get activeSections => _sections
      .where((s) => s.isLive)
      .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

  /// Get all sections (including inactive)
  List<HomeSectionModel> get allSections => _sections;

  /// Get items for a specific section
  List<HomeSectionItemModel> getSectionItems(String sectionId) {
    return _sectionItems[sectionId] ?? [];
  }

  /// Check if a section's items are loaded
  bool isSectionLoaded(String sectionId) {
    return _sectionItems.containsKey(sectionId);
  }

  /// Check if a section is currently loading
  bool isSectionLoading(String sectionId) {
    return _sectionLoadingStates[sectionId] ?? false;
  }

  /// Get sections by type
  List<HomeSectionModel> getSectionsByType(String type) {
    return activeSections.where((s) => s.type == type).toList();
  }

  /// Get filtered section items by subcategory
  List<HomeSectionItemModel> getFilteredSectionItems(
    String sectionId,
    String? subcategoryId,
  ) {
    final allItems = getSectionItems(sectionId);
    
    // If no subcategory selected ("All"), return all items
    if (subcategoryId == null || subcategoryId.isEmpty) {
      return allItems;
    }
    
    // Filter by subcategory
    return allItems.where((item) => item.subcategoryId == subcategoryId).toList();
  }


  // ==================== CONSTRUCTOR ====================
  
  HomeSectionController() {
    log('🏠 HomeSectionController: Constructor called');
  }

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    log('🏠 HomeSectionController: onInit called');
    log('🏠 HomeSectionController: Initializing...');
    
    // Load sections immediately instead of delayed
    log('🏠 HomeSectionController: Starting sections fetch...');
    loadSections();
  }

  // ==================== SECTION LOADING ====================

  /// Load all active sections
  Future<void> loadSections() async {
    try {
      log('🔄 HomeSectionController: Loading sections...');
      
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final sections = await HomeSectionRepo.instance.fetchActiveSections();
      
      log('📊 HomeSectionController: Loaded ${sections.length} active sections');
      
      if (sections.isNotEmpty) {
        _sections.value = sections;
        
        // Log section details
        for (var section in sections) {
          log('  ✅ ${section.sectionId}: ${section.title} (rank: ${section.rank}, type: ${section.type})');
        }
        
        log('✅ HomeSectionController: Sections loaded successfully');
      } else {
        log('⚠️ HomeSectionController: No active sections found');
      }
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionController: Error loading sections: $e');
      log('❌ Stack trace: $stackTrace');
      
      hasError.value = true;
      errorMessage.value = e.toString();
      
    } finally {
      isLoading.value = false;
    }
  }

  /// Load items for a specific section
  Future<void> loadSectionItems(String sectionId) async {
    try {
      // Skip if already loaded or currently loading
      if (isSectionLoaded(sectionId) || isSectionLoading(sectionId)) {
        log('⏭️ HomeSectionController: Section $sectionId already loaded/loading');
        return;
      }
      
      log('📦 HomeSectionController: Loading items for section: $sectionId');
      
      _sectionLoadingStates[sectionId] = true;
      
      // Find section to get maxItems limit
      final section = _sections.firstWhereOrNull((s) => s.sectionId == sectionId);
      final limit = section?.maxItems;
      
      final items = await HomeSectionRepo.instance.fetchSectionItems(
        sectionId,
        limit: limit,
      );
      
      log('📊 HomeSectionController: Loaded ${items.length} items for $sectionId');
      
      _sectionItems[sectionId] = items;
      
      // Log item details
      for (var item in items.take(3)) {
        log('  ✅ ${item.name} - ${item.formattedPrice} (rank: ${item.rank})');
      }
      if (items.length > 3) {
        log('  ... and ${items.length - 3} more items');
      }
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionController: Error loading items for $sectionId: $e');
      log('❌ Stack trace: $stackTrace');
      
      // Set empty list on error
      _sectionItems[sectionId] = [];
      
    } finally {
      _sectionLoadingStates[sectionId] = false;
    }
  }

  /// Load items for all active sections
  Future<void> loadAllSectionItems() async {
    log('📦 HomeSectionController: Loading items for all sections...');
    
    for (var section in activeSections) {
      await loadSectionItems(section.sectionId);
    }
    
    log('✅ HomeSectionController: All section items loaded');
  }

  /// Preload items for visible sections (first N sections)
  Future<void> preloadVisibleSections({int count = 3}) async {
    log('📦 HomeSectionController: Preloading first $count sections...');
    
    final visibleSections = activeSections.take(count);
    
    for (var section in visibleSections) {
      await loadSectionItems(section.sectionId);
    }
    
    log('✅ HomeSectionController: Preloaded ${visibleSections.length} sections');
  }

  // ==================== SUBCATEGORY PAGINATION ====================

  /// Load paginated products for a section filtered by subcategory from product_details
  Future<void> loadSubcategoryProducts(String sectionId, String? subcategoryId) async {
    try {
      // Initialize pagination state if needed
      if (!_sectionCurrentPage.containsKey(sectionId)) {
        _sectionCurrentPage[sectionId] = 0;
      }
      if (!_sectionItemsBySubcategory.containsKey(sectionId)) {
        _sectionItemsBySubcategory[sectionId] = {};
      }
      
      log('📦 HomeSectionController: Loading products for section=$sectionId, subcategory=$subcategoryId');
      
      // If "All" is selected, just use already loaded items
      if (subcategoryId == null || subcategoryId.isEmpty) {
        log('✅ HomeSectionController: Using default items for "All"');
        return;
      }
      
      final allItems = _sectionItems[sectionId] ?? [];
      final filterKey = subcategoryId;
      
      // Filter existing items first
      final filteredFromCache = allItems
          .where((item) => item.subcategoryId == subcategoryId)
          .toList();
      
      if (filteredFromCache.isNotEmpty) {
        log('✅ HomeSectionController: Found ${filteredFromCache.length} items in cache for subcategory=$subcategoryId');
        _sectionItemsBySubcategory[sectionId]![filterKey] = filteredFromCache;
        return;
      }
      
      // If not enough items in cache, fetch from product_details
      log('🔄 HomeSectionController: Fetching products from product_details for subcategory=$subcategoryId');
      
      final products = await ProductRepo.instance.fetchProductsBySubCategory(
        subcategoryId,
        limit: 100, // Fetch a good batch
        offset: 0,
      );
      
      // Convert to HomeSectionItemModel-like format
      final items = products
          .map((product) => HomeSectionItemModel(
            skuId: product.productId,
            productId: product.productId,
            categoryId: product.category,
            subcategoryId: product.subCategory,
            rank: 0,
            name: product.title,
            imageUrl: product.media.mainImage,
            mrp: product.productSkus.isNotEmpty 
                ? product.productSkus.first.mrp 
                : 0.0,
            price: product.productSkus.isNotEmpty 
                ? product.productSkus.first.price 
                : 0.0,
            discountPercent: 0.0,
            currencyCode: 'INR',
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          ))
          .toList();
      
      log('✅ HomeSectionController: Fetched ${items.length} products for subcategory=$subcategoryId');
      _sectionItemsBySubcategory[sectionId]![filterKey] = items;
      _sectionCurrentPage[sectionId] = 0;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionController: Error loading subcategory products: $e');
      log('❌ Stack trace: $stackTrace');
    }
  }

  /// Load more items for a section filtered by subcategory (pagination)
  Future<void> loadMoreSubcategoryProducts(String sectionId, String subcategoryId) async {
    try {
      // Prevent multiple simultaneous loads
      final loadingKey = '$sectionId-$subcategoryId';
      if (_sectionLoadingMoreBySubcategory[loadingKey]?.value ?? false) {
        log('⏭️ HomeSectionController: Already loading more for $loadingKey');
        return;
      }
      
      // Initialize if needed
      if (!_sectionLoadingMoreBySubcategory.containsKey(loadingKey)) {
        _sectionLoadingMoreBySubcategory[loadingKey] = false.obs;
      }
      
      _sectionLoadingMoreBySubcategory[loadingKey]!.value = true;
      
      log('📦 HomeSectionController: Loading more products for section=$sectionId, subcategory=$subcategoryId');
      
      final currentPage = _sectionCurrentPage[sectionId] ?? 0;
      final offset = currentPage * BATCH_SIZE;
      
      final products = await ProductRepo.instance.fetchProductsBySubCategory(
        subcategoryId,
        limit: BATCH_SIZE,
        offset: offset,
      );
      
      if (products.isEmpty) {
        log('⚠️ HomeSectionController: No more products to load');
        _sectionLoadingMoreBySubcategory[loadingKey]!.value = false;
        return;
      }
      
      // Convert products to items
      final newItems = products
          .map((product) => HomeSectionItemModel(
            skuId: product.productId,
            productId: product.productId,
            categoryId: product.category,
            subcategoryId: product.subCategory,
            rank: 0,
            name: product.title,
            imageUrl: product.media.mainImage,
            mrp: product.productSkus.isNotEmpty 
                ? product.productSkus.first.mrp 
                : 0.0,
            price: product.productSkus.isNotEmpty 
                ? product.productSkus.first.price 
                : 0.0,
            discountPercent: 0.0,
            currencyCode: 'INR',
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          ))
          .toList();
      
      // Add to existing items
      if (!_sectionItemsBySubcategory.containsKey(sectionId)) {
        _sectionItemsBySubcategory[sectionId] = {};
      }
      
      final filterKey = subcategoryId;
      if (!_sectionItemsBySubcategory[sectionId]!.containsKey(filterKey)) {
        _sectionItemsBySubcategory[sectionId]![filterKey] = [];
      }
      
      _sectionItemsBySubcategory[sectionId]![filterKey]!.addAll(newItems);
      _sectionCurrentPage[sectionId] = currentPage + 1;
      
      log('✅ HomeSectionController: Loaded ${newItems.length} more products (Total: ${_sectionItemsBySubcategory[sectionId]![filterKey]!.length})');
      
      // Trigger UI update by reassigning the list
      _sectionItemsBySubcategory.refresh();
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionController: Error loading more subcategory products: $e');
      log('❌ Stack trace: $stackTrace');
    } finally {
      final loadingKey = '$sectionId-$subcategoryId';
      if (_sectionLoadingMoreBySubcategory.containsKey(loadingKey)) {
        _sectionLoadingMoreBySubcategory[loadingKey]!.value = false;
      }
    }
  }

  /// Get filtered items for a section by subcategory with pagination support
  List<HomeSectionItemModel> getFilteredSectionItemsWithPagination(
    String sectionId,
    String? subcategoryId,
  ) {
    // If "All" is selected, return the default items
    if (subcategoryId == null || subcategoryId.isEmpty) {
      return getSectionItems(sectionId);
    }
    
    // Return paginated items for subcategory
    if (!_sectionItemsBySubcategory.containsKey(sectionId)) {
      return [];
    }
    
    return _sectionItemsBySubcategory[sectionId]![subcategoryId] ?? [];
  }

  /// Check if there are more items to load for a subcategory
  bool hasMoreItemsForSubcategory(String sectionId, String subcategoryId) {
    try {
      final items = getFilteredSectionItemsWithPagination(sectionId, subcategoryId);
      // Assume there's more if we've loaded at least BATCH_SIZE items
      return items.length >= BATCH_SIZE;
    } catch (e) {
      return false;
    }
  }

  /// Check if loading more for a specific subcategory
  bool isLoadingMoreForSubcategory(String sectionId, String subcategoryId) {
    final loadingKey = '$sectionId-$subcategoryId';
    return _sectionLoadingMoreBySubcategory[loadingKey]?.value ?? false;
  }

  // ==================== SECTION VIEW ALL ====================

  /// Pagination state for section view all
  final RxMap<String, int> _sectionAllItemsPage = <String, int>{}.obs; // page per section
  final RxMap<String, List<HomeSectionItemModel>> _sectionAllItems = 
      <String, List<HomeSectionItemModel>>{}.obs; // section -> all items
  final RxMap<String, bool> _sectionAllItemsLoading = <String, bool>{}.obs;
  final RxMap<String, bool> _sectionAllItemsLoadingMore = <String, bool>{}.obs;

  /// Load all products for a section with pagination
  Future<void> loadAllSectionProducts(String sectionId) async {
    if (_sectionAllItemsLoading[sectionId] == true) return;
    
    try {
      _sectionAllItemsLoading[sectionId] = true;
      _sectionAllItemsPage[sectionId] = 0;
      _sectionAllItems[sectionId] = [];

      final items = await HomeSectionRepo.instance.fetchSectionItemsPaginated(
        sectionId,
        page: 0,
        limit: BATCH_SIZE,
      );

      _sectionAllItems[sectionId] = items;
      _sectionAllItemsLoading[sectionId] = false;
      
      log('✅ Loaded ${items.length} products for section $sectionId');
    } catch (e) {
      log('❌ Error loading section products: $e');
      _sectionAllItemsLoading[sectionId] = false;
      rethrow;
    }
  }

  /// Load more products for section view all
  Future<void> loadMoreSectionProducts(String sectionId) async {
    if (_sectionAllItemsLoadingMore[sectionId] == true) return;
    if (!hasMoreItemsForSection(sectionId)) return;

    try {
      _sectionAllItemsLoadingMore[sectionId] = true;
      final currentPage = _sectionAllItemsPage[sectionId] ?? 0;
      final nextPage = currentPage + 1;

      final items = await HomeSectionRepo.instance.fetchSectionItemsPaginated(
        sectionId,
        page: nextPage,
        limit: BATCH_SIZE,
      );

      if (items.isNotEmpty) {
        _sectionAllItems[sectionId] = [
          ...(_sectionAllItems[sectionId] ?? []),
          ...items,
        ];
        _sectionAllItemsPage[sectionId] = nextPage;
      }

      _sectionAllItemsLoadingMore[sectionId] = false;
      log('✅ Loaded more products for section $sectionId (page: $nextPage)');
    } catch (e) {
      log('❌ Error loading more section products: $e');
      _sectionAllItemsLoadingMore[sectionId] = false;
      rethrow;
    }
  }

  /// Get all loaded products for a section
  List<HomeSectionItemModel> getAllSectionProducts(String sectionId) {
    return _sectionAllItems[sectionId] ?? [];
  }

  /// Check if loading all section products
  bool isLoadingSectionProducts(String sectionId) {
    return _sectionAllItemsLoading[sectionId] == true;
  }

  /// Check if loading more section products
  bool isLoadingMoreForSection(String sectionId) {
    return _sectionAllItemsLoadingMore[sectionId] == true;
  }

  /// Check if there are more items to load for a section
  bool hasMoreItemsForSection(String sectionId) {
    try {
      final items = _sectionAllItems[sectionId] ?? [];
      // Assume there's more if we've loaded at least BATCH_SIZE items
      return items.length >= BATCH_SIZE;
    } catch (e) {
      return false;
    }
  }

  // ==================== REFRESH ====================

  /// Refresh all sections
  Future<void> refreshSections() async {
    log('🔄 HomeSectionController: Refreshing sections...');
    
    _sections.clear();
    _sectionItems.clear();
    _sectionLoadingStates.clear();
    
    await loadSections();
    
    log('✅ HomeSectionController: Sections refreshed');
  }

  /// Refresh items for a specific section
  Future<void> refreshSectionItems(String sectionId) async {
    log('🔄 HomeSectionController: Refreshing items for $sectionId...');
    
    _sectionItems.remove(sectionId);
    _sectionLoadingStates.remove(sectionId);
    
    await loadSectionItems(sectionId);
    
    log('✅ HomeSectionController: Section $sectionId refreshed');
  }

  // ==================== UTILITY ====================

  /// Get section by ID
  HomeSectionModel? getSectionById(String sectionId) {
    return _sections.firstWhereOrNull((s) => s.sectionId == sectionId);
  }

  /// Check if any sections are loaded
  bool get hasSections => _sections.isNotEmpty;

  /// Check if any active sections exist
  bool get hasActiveSections => activeSections.isNotEmpty;

  /// Get total number of loaded items across all sections
  int get totalLoadedItems {
    return _sectionItems.values.fold(0, (sum, items) => sum + items.length);
  }

  @override
  void onClose() {
    log('🏠 HomeSectionController: Closing...');
    super.onClose();
  }
}
