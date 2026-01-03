
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/category_model.dart';
import 'package:rps_stationery/data/repositories/category_repo.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  // Reactive variables
  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get hasCategories => _categories.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    print('📂 CategoryController: Initializing category controller...');
    print('📂 CategoryController: Setting up reactive variables...');
    print('📂 CategoryController: Categories list initialized with ${_categories.length} items');
    print('📂 CategoryController: Loading state: ${isLoading.value}');
    print('📂 CategoryController: Error state: ${hasError.value}');
    
    // Add a small delay to ensure GetX context is fully initialized
    print('📂 CategoryController: Scheduling category fetch in 100ms...');
    Future.delayed(const Duration(milliseconds: 100), () {
      print('📂 CategoryController: Starting delayed category fetch...');
      fetchCategories();
    });
  }

  /// Fetch all active categories
  Future<void> fetchCategories() async {
    try {
      print('🔄 CategoryController: Starting to fetch categories...');
      print('🔄 CategoryController: Current state - Loading: ${isLoading.value}, Error: ${hasError.value}, Categories: ${_categories.length}');
      
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      print('🔄 CategoryController: State updated - Loading: ${isLoading.value}, Error: ${hasError.value}');
      print('🔄 CategoryController: Calling CategoryRepo.instance.fetchAllCategories()...');

      final categories = await CategoryRepo.instance.fetchAllCategories();
      print('📊 CategoryController: Repository call completed. Received ${categories.length} categories');
      
      if (categories.isNotEmpty) {
        print('✅ CategoryController: Successfully loaded ${categories.length} categories');
        print('✅ CategoryController: Updating reactive categories list...');
        
        _categories.assignAll(categories);
        
        print('✅ CategoryController: Categories list updated. Current length: ${_categories.length}');
        
        // Log category details for debugging
        print('📋 CategoryController: Detailed category information:');
        for (int i = 0; i < categories.length; i++) {
          print('  Category $i: ID=${categories[i].id}, Name=${categories[i].name}, Active=${categories[i].isActive}, Rank=${categories[i].rank}, Image=${categories[i].image.isNotEmpty ? "Present" : "Missing"}');
        }
        
        print('✅ CategoryController: All categories processed and logged');
      } else {
        print('⚠️ CategoryController: No categories found - repository returned empty list');
        print('⚠️ CategoryController: This could mean no active categories in database or database connection issue');
        // Don't show error snackbar for empty results, just log it
      }
    } catch (e, stackTrace) {
      print('❌ CategoryController: Error fetching categories: $e');
      print('❌ CategoryController: Error type: ${e.runtimeType}');
      print('❌ CategoryController: Stack trace: $stackTrace');
      
      hasError.value = true;
      errorMessage.value = e.toString();
      
      print('❌ CategoryController: Error state updated - Error: ${hasError.value}, Message: ${errorMessage.value}');
      
      // Only show error if context is available and it's not a permission issue
      if (Get.context != null && !e.toString().contains('permission')) {
        print('❌ CategoryController: Showing error snackbar to user');
        TLoaders.errorSnackBar(
          title: "Category Error", 
          message: "Unable to load categories: ${e.toString()}"
        );
      } else {
        print('❌ CategoryController: Skipping error snackbar (no context or permission error)');
      }
    } finally {
      isLoading.value = false;
      print('🏁 CategoryController: Category fetch completed. Final state - Loading: ${isLoading.value}, Error: ${hasError.value}, Categories: ${_categories.length}');
    }
  }

  /// Refresh categories data
  Future<void> refreshCategories() async {
    print('🔄 CategoryController: Refreshing categories data...');
    print('🔄 CategoryController: Current categories count: ${_categories.length}');
    
    _categories.clear();
    print('🔄 CategoryController: Categories list cleared');
    
    await fetchCategories();
    print('🔄 CategoryController: Refresh completed');
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String id) {
    print('🔍 CategoryController: Searching for category with ID: $id');
    print('🔍 CategoryController: Available categories: ${_categories.length}');
    
    try {
      final category = _categories.firstWhere((category) => category.id == id);
      print('✅ CategoryController: Found category: ${category.name}');
      return category;
    } catch (e) {
      print('❌ CategoryController: Category with ID $id not found');
      print('❌ CategoryController: Available IDs: ${_categories.map((c) => c.id).toList()}');
      return null;
    }
  }

  /// Get categories by rank (for home screen display)
  List<CategoryModel> getCategoriesForHome({int limit = 6}) {
    print('🏠 CategoryController: Getting categories for home display (limit: $limit)');
    print('🏠 CategoryController: Total available categories: ${_categories.length}');
    
    if (_categories.isEmpty) {
      print('⚠️ CategoryController: No categories available for home display');
      return [];
    }
    
    // Sort by rank and take the specified limit
    final sortedCategories = List<CategoryModel>.from(_categories)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    
    final result = sortedCategories.take(limit).toList();
    print('✅ CategoryController: Returning ${result.length} categories for home display');
    print('✅ CategoryController: Categories: ${result.map((c) => '${c.name}(${c.rank})').toList()}');
    
    return result;
  }

  /// Search categories by name
  List<CategoryModel> searchCategories(String query) {
    print('🔍 CategoryController: Searching categories with query: "$query"');
    print('🔍 CategoryController: Total categories to search: ${_categories.length}');
    
    if (query.isEmpty) {
      print('🔍 CategoryController: Empty query, returning all categories');
      return _categories;
    }
    
    final results = _categories
        .where((category) => 
            category.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    print('🔍 CategoryController: Found ${results.length} matching categories');
    print('🔍 CategoryController: Results: ${results.map((c) => c.name).toList()}');
    
    return results;
  }

  /// Clear all categories (useful for logout)
  void clearCategories() {
    print('🗑️ CategoryController: Clearing all categories...');
    print('🗑️ CategoryController: Current categories count: ${_categories.length}');
    
    _categories.clear();
    hasError.value = false;
    errorMessage.value = '';
    
    print('🗑️ CategoryController: Categories cleared. New count: ${_categories.length}');
    print('🗑️ CategoryController: Error state reset - Error: ${hasError.value}');
  }
}
