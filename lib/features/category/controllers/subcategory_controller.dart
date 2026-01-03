import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/subcategory_repo.dart';

class SubCategoryController extends GetxController {
  static SubCategoryController get instance => Get.find();

  final _subCategoryRepo = Get.put(SubCategoryRepo());

  // Reactive variables
  final RxList<SubCategoryModel> _subCategories = <SubCategoryModel>[].obs;
  final RxMap<String, List<SubCategoryModel>> _groupedSubCategories = <String, List<SubCategoryModel>>{}.obs;
  final RxList<String> _availableCategories = <String>[].obs;

  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('📂 SubCategoryController: Initializing subcategory controller...');
    print('📂 SubCategoryController: Setting up reactive variables...');
    print('📂 SubCategoryController: Subcategories: ${_subCategories.length}, Grouped: ${_groupedSubCategories.length}');
    print('📂 SubCategoryController: Available categories: ${_availableCategories.length}');
    print('📂 SubCategoryController: Loading state: ${isLoading.value}, Error: ${hasError.value}');
  }

  /// Fetch all subcategories and group them by category
  Future<void> fetchSubCategories() async {
    try {
      print('📂 SubCategoryController: Starting subcategory fetch...');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      print('🔄 SubCategoryController: Starting to load all subcategories...');
      print('🔄 SubCategoryController: Current state - Loading: ${isLoading.value}, Error: ${hasError.value}');

      final groupedSubCategories = await _subCategoryRepo.fetchSubCategoriesGroupedByCategory();
      print('📊 SubCategoryController: Repository call completed. Received ${groupedSubCategories.length} category groups');

      _groupedSubCategories.assignAll(groupedSubCategories);
      _availableCategories.assignAll(groupedSubCategories.keys.toList());

      // Flatten all subcategories for easy access
      final allSubCategories = <SubCategoryModel>[];
      for (final subCategoryList in groupedSubCategories.values) {
        allSubCategories.addAll(subCategoryList);
      }
      _subCategories.assignAll(allSubCategories);

      print('✅ SubCategoryController: Successfully loaded subcategories for ${_availableCategories.length} categories');
      print('✅ SubCategoryController: Updating reactive subcategories map...');
      for (var categoryId in _availableCategories) {
        final subCategories = _groupedSubCategories[categoryId] ?? [];
        print('📋 SubCategoryController: Category $categoryId: ${subCategories.length} subcategories');
        for (var subCategory in subCategories) {
          print('  SubCategory: ${subCategory.name} (${subCategory.id}) - Rank: ${subCategory.rank}');
        }
      }
      print('✅ SubCategoryController: Subcategories map updated. Categories: ${_availableCategories.length}');
      print('✅ SubCategoryController: Total subcategories: ${_subCategories.length}');
      print('✅ SubCategoryController: Available categories: ${_availableCategories.join(', ')}');

    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ SubCategoryController: Error fetching subcategories: $e');
    } finally {
      isLoading.value = false;
      print('🏁 SubCategoryController: Subcategory loading completed. Loading: ${isLoading.value}');
    }
  }

  /// Get subcategories for a specific category
  List<SubCategoryModel> getSubCategoriesByCategory(String categoryId) {
    return _groupedSubCategories[categoryId] ?? [];
  }

  /// Get all subcategories
  List<SubCategoryModel> get allSubCategories => _subCategories.toList();

  /// Get list of available category IDs that have subcategories
  List<String> get availableCategories => _availableCategories.toList();

  /// Get a specific subcategory by ID
  SubCategoryModel? getSubCategoryById(String subCategoryId) {
    try {
      return _subCategories.firstWhere((subCategory) => subCategory.id == subCategoryId);
    } catch (e) {
      return null;
    }
  }

  /// Check if there are any subcategories available
  bool get hasSubCategories => _subCategories.isNotEmpty;

  /// Check if a specific category has subcategories
  bool hasSubCategoriesForCategory(String categoryId) {
    return _groupedSubCategories.containsKey(categoryId) && 
           _groupedSubCategories[categoryId]!.isNotEmpty;
  }

  /// Refresh subcategories data
  Future<void> refreshSubCategories() async {
    await fetchSubCategories();
  }

  /// Clear all subcategory data
  void clearSubCategories() {
    _subCategories.clear();
    _groupedSubCategories.clear();
    _availableCategories.clear();
    hasError.value = false;
    errorMessage.value = '';
    print('🧹 SubCategoryController: Cleared all subcategory data');
  }
}
