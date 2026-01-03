import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';
import 'package:rps_stationery/features/home/controllers/category_controller.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/components/skleton/category_skeleton.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/repositories/home_section_repo.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class CategoryHomeSections extends StatelessWidget {
  const CategoryHomeSections({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ CategoryHomeSections: Building category home sections widget...');
    
    final homeSectionController = Get.find<HomeSectionController>();
    final categoryController = Get.find<CategoryController>();
    
    print('🏗️ CategoryHomeSections: Controllers obtained');

    return Obx(() {
      print('🔄 CategoryHomeSections: Reactive build triggered');
      print('🔄 CategoryHomeSections: Home section state - Loading: ${homeSectionController.isLoading.value}, Error: ${homeSectionController.hasError.value}');
      print('🔄 CategoryHomeSections: Available categories: ${homeSectionController.availableCategories.length}');
      print('🔄 CategoryHomeSections: Category state - Loading: ${categoryController.isLoading.value}, HasCategories: ${categoryController.hasCategories}');

      // Show loading state
      if (homeSectionController.isLoading.value || categoryController.isLoading.value) {
        print('⏳ CategoryHomeSections: Showing loading state');
        return const CategorySkeleton();
      }

      // Show error state
      if (homeSectionController.hasError.value) {
        print('❌ CategoryHomeSections: Showing error state');
        return _buildErrorState(context, homeSectionController.errorMessage.value);
      }

      // Show empty state
      if (homeSectionController.availableCategories.isEmpty) {
        print('⚠️ CategoryHomeSections: Showing empty state');
        return _buildEmptyState(context);
      }

      // Show category sections
      print('✅ CategoryHomeSections: Showing category sections with ${homeSectionController.availableCategories.length} categories');
      return _buildCategorySections(context, homeSectionController, categoryController);
    });
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load home sections',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Get.find<HomeSectionController>().refreshHomeSections();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No home sections available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for featured products',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySections(
    BuildContext context,
    HomeSectionController homeSectionController,
    CategoryController categoryController,
  ) {
    print('🏗️ CategoryHomeSections: Building category sections...');
    
    return Column(
      children: homeSectionController.availableCategories.map((categoryId) {
        print('🏗️ CategoryHomeSections: Building section for category: $categoryId');
        
        // Get category info
        final category = categoryController.getCategoryById(categoryId);
        final categoryName = category?.name ?? categoryId;
        
        // Get sections for this category
        final sections = homeSectionController.getCategorySections(categoryId);
        
        print('📋 CategoryHomeSections: Category $categoryId has ${sections.length} sections');
        
        return _buildCategorySection(
          context,
          categoryId,
          categoryName,
          sections,
          homeSectionController,
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryId,
    String categoryName,
    List<HomeSectionData> sections,
    HomeSectionController homeSectionController,
  ) {
    print('🏗️ CategoryHomeSections: Building section for $categoryName ($categoryId)');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header - Minimalist design
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                categoryName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  Get.toNamed(
                    Routes.category,
                    arguments: {'categoryName': categoryName, 'categoryId': categoryId},
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Sections for this category
        ...sections.map((section) {
          print('🏗️ CategoryHomeSections: Building section: ${section.sectionId} (${section.type}) with ${section.products.length} products');
          
          return _buildSection(
            context,
            categoryId,
            section,
            homeSectionController,
          );
        }).toList(),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String categoryId,
    HomeSectionData section,
    HomeSectionController homeSectionController,
  ) {
    print('🏗️ CategoryHomeSections: Building section ${section.sectionId}');
    
    if (section.products.isEmpty) {
      print('⚠️ CategoryHomeSections: Section ${section.sectionId} has no products, skipping');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - Modern design
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (section.type == 'flashSale')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SALE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Products horizontal list
        SizedBox(
          height: 200, // Fixed height for horizontal ListView
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.products.length,
            itemBuilder: (context, index) {
              final product = section.products[index];
              print('🏗️ CategoryHomeSections: Building product card $index: ${product.name}');
              
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 4),
                child: ProductCard(
                  product: product,
                  press: () {
                    print('👆 CategoryHomeSections: Product tapped: ${product.name} (${product.productId})');
                    Get.toNamed(
                      Routes.productDetail,
                      arguments: {'productId': product.productId},
                    );
                  },
                  width: 140,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  /// Convert ProductModel to ProductModel (no conversion needed now)
  ProductModel _convertToProductModel(ProductModel product) {
    // No conversion needed - both are the same model now
    return product;
  }
}
