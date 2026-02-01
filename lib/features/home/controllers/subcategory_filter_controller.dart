import 'dart:developer';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/subcategory_repo.dart';

/// Subcategory Filter Controller - Manages subcategory filtering for home page
class SubcategoryFilterController extends GetxController {
  static SubcategoryFilterController get instance => Get.find();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedSubcategoryId = Rx<String?>(null); // null = "All"
  final RxList<SubCategoryModel> subcategories = <SubCategoryModel>[].obs;

  // ==================== GETTERS ====================

  /// Check if "All" is selected
  bool get isAllSelected => selectedSubcategoryId.value == null;

  /// Get selected subcategory name
  String get selectedSubcategoryName {
    if (isAllSelected) return 'All';
    final selected = subcategories.firstWhereOrNull(
      (s) => s.id == selectedSubcategoryId.value,
    );
    return selected?.name ?? 'All';
  }

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    log('🏷️ SubcategoryFilterController: Initializing...');
    loadSubcategories();
  }

  // ==================== SUBCATEGORY LOADING ====================

  /// Load all active subcategories from Firestore
  Future<void> loadSubcategories() async {
    try {
      log('🔄 SubcategoryFilterController: Loading subcategories...');
      
      isLoading.value = true;
      
      final allSubcategories = await SubCategoryRepo.instance.fetchAllSubCategories();
      
      // Filter only active subcategories and sort by rank
      final activeSubcategories = allSubcategories
          .where((s) => s.isActive)
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));
      
      subcategories.value = activeSubcategories;
      
      log('✅ SubcategoryFilterController: Loaded ${activeSubcategories.length} active subcategories');
      
    } catch (e, stackTrace) {
      log('❌ SubcategoryFilterController: Error loading subcategories: $e');
      log('❌ Stack trace: $stackTrace');
      
      // Set empty list on error
      subcategories.value = [];
      
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== SELECTION ====================

  /// Select a subcategory (null = "All")
  void selectSubcategory(String? subcategoryId) {
    log('🏷️ SubcategoryFilterController: Selecting subcategory: ${subcategoryId ?? "All"}');
    selectedSubcategoryId.value = subcategoryId;
  }

  /// Select "All" (clear filter)
  void selectAll() {
    selectSubcategory(null);
  }

  /// Check if a subcategory is selected
  bool isSubcategorySelected(String? subcategoryId) {
    return selectedSubcategoryId.value == subcategoryId;
  }

  // ==================== REFRESH ====================

  /// Refresh subcategories
  Future<void> refreshSubcategories() async {
    log('🔄 SubcategoryFilterController: Refreshing subcategories...');
    
    subcategories.clear();
    selectedSubcategoryId.value = null;
    
    await loadSubcategories();
    
    log('✅ SubcategoryFilterController: Subcategories refreshed');
  }

  @override
  void onClose() {
    log('🏷️ SubcategoryFilterController: Closing...');
    super.onClose();
  }
}
