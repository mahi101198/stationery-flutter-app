import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/category/controllers/subcategory_controller.dart';
import 'package:rps_stationery/features/home/controllers/category_controller.dart';
import 'package:rps_stationery/data/repositories/subcategory_repo.dart';
import 'package:rps_stationery/data/models/category_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SubCategorySidebar extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final Function(String categoryId, String? subCategoryId)? onCategorySelected;

  const SubCategorySidebar({
    super.key,
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    print('🏗️ SubCategorySidebar: Building subcategory sidebar...');
    final subCategoryController = Get.find<SubCategoryController>();
    final categoryController = Get.find<CategoryController>();
    print('🏗️ SubCategorySidebar: Controllers obtained');

    return Obx(() {
      print('🔄 SubCategorySidebar: Reactive build triggered');
      print('🔄 SubCategorySidebar: Subcategory state - Loading: ${subCategoryController.isLoading.value}, Error: ${subCategoryController.hasError.value}');
      print('🔄 SubCategorySidebar: Available categories: ${subCategoryController.availableCategories.length}');

      if (subCategoryController.isLoading.value) {
        print('⏳ SubCategorySidebar: Showing loading state');
        return _buildLoadingState();
      }

      if (subCategoryController.hasError.value) {
        print('❌ SubCategorySidebar: Showing error state: ${subCategoryController.errorMessage.value}');
        return _buildErrorState(subCategoryController.errorMessage.value);
      }

      if (subCategoryController.availableCategories.isEmpty) {
        print('! SubCategorySidebar: Showing empty state');
        return _buildEmptyState();
      }

      print('✅ SubCategorySidebar: Showing subcategory sidebar with ${subCategoryController.availableCategories.length} categories');
      return _buildSidebar(context, subCategoryController, categoryController);
    });
  }

  Widget _buildLoadingState() {
    return Container(
      width: 250,
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            height: 60,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: 250,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 250,
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    SubCategoryController subCategoryController,
    CategoryController categoryController,
  ) {
    return Container(
      width: 250,
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            color: Theme.of(context).primaryColor,
            child: const Center(
              child: Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Categories List
          Expanded(
            child: ListView.builder(
              itemCount: subCategoryController.availableCategories.length,
              itemBuilder: (context, index) {
                final categoryId = subCategoryController.availableCategories[index];
                final category = categoryController.getCategoryById(categoryId);
                final subCategories = subCategoryController.getSubCategoriesByCategory(categoryId);
                
                if (category == null) return const SizedBox.shrink();
                
                return _buildCategorySection(
                  context,
                  category,
                  subCategories,
                  subCategoryController,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    CategoryModel category,
    List<SubCategoryModel> subCategories,
    SubCategoryController subCategoryController,
  ) {
    final isSelected = selectedCategoryId == category.id;
    final isExpanded = isSelected;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Category Header
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: category.image.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.image,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.category,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            trailing: subCategories.isNotEmpty
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                  )
                : null,
            onTap: () {
              print('👆 SubCategorySidebar: Category tapped: ${category.name} (${category.id})');
              onCategorySelected?.call(category.id, null);
            },
          ),
          
          // Subcategories (if expanded)
          if (isExpanded && subCategories.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: subCategories.map((subCategory) {
                  final isSubSelected = selectedSubCategoryId == subCategory.id;
                  return ListTile(
                    dense: true,
                    leading: subCategory.image.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: subCategory.image,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.label,
                                size: 16,
                                color: isSubSelected 
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.label,
                                size: 16,
                                color: isSubSelected 
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            ),
                          )
                        : Icon(
                            Icons.label,
                            size: 16,
                            color: isSubSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                    title: Text(
                      subCategory.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSubSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      print('👆 SubCategorySidebar: Subcategory tapped: ${subCategory.name} (${subCategory.id})');
                      onCategorySelected?.call(category.id, subCategory.id);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
