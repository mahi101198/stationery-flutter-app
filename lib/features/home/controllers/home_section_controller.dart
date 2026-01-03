import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/home_section_repo.dart';
import 'package:rps_stationery/data/models/product_model.dart';

class HomeSectionController extends GetxController {
  static HomeSectionController get instance => Get.find();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Home sections data organized by category
  final RxMap<String, List<HomeSectionData>> _homeSections = <String, List<HomeSectionData>>{}.obs;
  
  // Individual section products for quick access
  final RxMap<String, List<ProductModel>> _sectionProducts = <String, List<ProductModel>>{}.obs;
  
  // Available categories with home sections
  final RxList<String> _availableCategories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('🏠 HomeSectionController: Initializing home section controller...');
    print('🏠 HomeSectionController: Setting up reactive variables...');
    print('🏠 HomeSectionController: Home sections: ${_homeSections.length}, Section products: ${_sectionProducts.length}');
    print('🏠 HomeSectionController: Available categories: ${_availableCategories.length}');
    print('🏠 HomeSectionController: Loading state: ${isLoading.value}, Error: ${hasError.value}');
    
    // Load home sections after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      print('🏠 HomeSectionController: Starting delayed home sections fetch...');
      loadAllHomeSections();
    });
  }

  /// Load all home sections for all categories
  Future<void> loadAllHomeSections() async {
    try {
      print('🔄 HomeSectionController: Starting to load all home sections...');
      print('🔄 HomeSectionController: Current state - Loading: ${isLoading.value}, Error: ${hasError.value}');
      
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      print('🔄 HomeSectionController: State updated - Loading: ${isLoading.value}, Error: ${hasError.value}');
      print('🔄 HomeSectionController: Calling HomeSectionRepo.instance.fetchAllHomeSections()...');
      
      final allSections = await HomeSectionRepo.instance.fetchAllHomeSections();
      
      print('📊 HomeSectionController: Repository call completed. Received ${allSections.length} categories');
      
      if (allSections.isNotEmpty) {
        print('✅ HomeSectionController: Successfully loaded home sections for ${allSections.length} categories');
        print('✅ HomeSectionController: Updating reactive home sections map...');
        
        _homeSections.clear();
        _sectionProducts.clear();
        _availableCategories.clear();
        
        for (var entry in allSections.entries) {
          final categoryId = entry.key;
          final sections = entry.value;
          
          _homeSections[categoryId] = sections;
          _availableCategories.add(categoryId);
          
          print('📋 HomeSectionController: Processing category: $categoryId with ${sections.length} sections');
          
          // Store individual section products for quick access
          for (var section in sections) {
            final sectionKey = '${categoryId}_${section.sectionId}';
            _sectionProducts[sectionKey] = section.products;
            
            print('  Section: ${section.sectionId} (${section.type}) - ${section.products.length} products');
          }
        }
        
        print('✅ HomeSectionController: Home sections map updated. Categories: ${_homeSections.length}');
        print('✅ HomeSectionController: Section products map updated. Sections: ${_sectionProducts.length}');
        print('✅ HomeSectionController: Available categories: ${_availableCategories.join(', ')}');
        
      } else {
        print('⚠️ HomeSectionController: No home sections found - repository returned empty map');
        print('⚠️ HomeSectionController: This could mean no home sections in database or database connection issue');
      }
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionController: Error loading home sections: $e');
      print('❌ HomeSectionController: Error type: ${e.runtimeType}');
      print('❌ HomeSectionController: Stack trace: $stackTrace');
      
      hasError.value = true;
      errorMessage.value = e.toString();
      
      print('❌ HomeSectionController: Error state updated - Error: ${hasError.value}, Message: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
      print('🏁 HomeSectionController: Home sections loading completed. Loading: ${isLoading.value}');
    }
  }

  /// Load home sections for a specific category
  Future<void> loadHomeSectionsForCategory(String categoryId) async {
    try {
      print('🎯 HomeSectionController: Loading home sections for category: $categoryId');
      
      final sections = await HomeSectionRepo.instance.fetchHomeSectionsForCategory(categoryId);
      
      if (sections.isNotEmpty) {
        _homeSections[categoryId] = sections;
        
        // Update section products
        for (var section in sections) {
          final sectionKey = '${categoryId}_${section.sectionId}';
          _sectionProducts[sectionKey] = section.products;
        }
        
        if (!_availableCategories.contains(categoryId)) {
          _availableCategories.add(categoryId);
        }
        
        print('✅ HomeSectionController: Loaded ${sections.length} sections for $categoryId');
      } else {
        print('⚠️ HomeSectionController: No sections found for category: $categoryId');
      }
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionController: Error loading sections for $categoryId: $e');
      print('❌ HomeSectionController: Stack trace: $stackTrace');
    }
  }

  /// Get products for a specific section
  List<ProductModel> getSectionProducts(String categoryId, String sectionType) {
    final sectionKey = '${categoryId}_$sectionType';
    final products = _sectionProducts[sectionKey] ?? [];
    print('📦 HomeSectionController: Retrieved ${products.length} products for $sectionKey');
    return products;
  }

  /// Get all sections for a category
  List<HomeSectionData> getCategorySections(String categoryId) {
    final sections = _homeSections[categoryId] ?? [];
    print('📋 HomeSectionController: Retrieved ${sections.length} sections for $categoryId');
    return sections;
  }

  /// Get flash sale products for a category
  List<ProductModel> getFlashSaleProducts(String categoryId) {
    return getSectionProducts(categoryId, 'flashSale');
  }

  /// Get popular products for a category
  List<ProductModel> getPopularProducts(String categoryId) {
    return getSectionProducts(categoryId, 'popular');
  }

  /// Get recommended products for a category
  List<ProductModel> getRecommendedProducts(String categoryId) {
    return getSectionProducts(categoryId, 'recommended');
  }

  /// Get all available categories
  List<String> get availableCategories => _availableCategories.toList();

  /// Get all home sections
  Map<String, List<HomeSectionData>> get homeSections => _homeSections;

  /// Check if a category has home sections
  bool hasCategorySections(String categoryId) {
    return _homeSections.containsKey(categoryId) && _homeSections[categoryId]!.isNotEmpty;
  }

  /// Check if a specific section exists
  bool hasSection(String categoryId, String sectionType) {
    final sectionKey = '${categoryId}_$sectionType';
    return _sectionProducts.containsKey(sectionKey) && _sectionProducts[sectionKey]!.isNotEmpty;
  }

  /// Refresh all home sections
  Future<void> refreshHomeSections() async {
    print('🔄 HomeSectionController: Refreshing all home sections...');
    await loadAllHomeSections();
  }

  /// Clear all data
  void clearHomeSections() {
    print('🗑️ HomeSectionController: Clearing all home sections data...');
    _homeSections.clear();
    _sectionProducts.clear();
    _availableCategories.clear();
    hasError.value = false;
    errorMessage.value = '';
    print('✅ HomeSectionController: All data cleared');
  }
}
