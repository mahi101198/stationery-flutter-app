import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/features/category/controllers/subcategory_controller.dart';
import 'package:rps_stationery/features/category/controllers/subcategory_product_controller.dart';
import 'package:rps_stationery/data/repositories/subcategory_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedCategoryScreen extends StatefulWidget {
  const OptimizedCategoryScreen({super.key});

  @override
  State<OptimizedCategoryScreen> createState() => _OptimizedCategoryScreenState();
}

class _OptimizedCategoryScreenState extends State<OptimizedCategoryScreen> {
  final SubCategoryProductController _productController = Get.put(SubCategoryProductController());
  final SubCategoryController _subCategoryController = Get.put(SubCategoryController());
  final ScrollController _scrollController = ScrollController();
  
  String _categoryName = 'All Products';
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  bool _isViewAllMode = false; // Track if we're in View All mode

  @override
  void initState() {
    super.initState();
    _initializeCategory();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _initializeCategory() async {
    print('🚀 OptimizedCategoryScreen: _initializeCategory() called');
    
    try {
      final arguments = Get.arguments;
      print('🚀 OptimizedCategoryScreen: Raw arguments: $arguments');
      
      if (arguments != null) {
        if (arguments is Map<String, dynamic>) {
          // Arguments from direct navigation (like from home screen)
          _categoryName = arguments['categoryName'] as String? ?? 'All Products';
          _selectedCategoryId = arguments['categoryId'] as String?;
          print('🚀 OptimizedCategoryScreen: Parsed - categoryName: $_categoryName, categoryId: $_selectedCategoryId');
        } else if (arguments is String && arguments == 'category') {
          // Arguments from bottom nav tab (category tab selected)
          _categoryName = 'All Products';
          _selectedCategoryId = null;
          print('🚀 OptimizedCategoryScreen: Loaded as Category tab - setting to View All mode');
        }
      } else {
        // No arguments - default to View All mode
        _categoryName = 'All Products';
        _selectedCategoryId = null;
        print('🚀 OptimizedCategoryScreen: No arguments - defaulting to View All mode');
      }

      // Check if we're in View All mode
      _isViewAllMode = _categoryName == 'All Products' && _selectedCategoryId == null;
      print('🎯 OptimizedCategoryScreen: View All Mode: $_isViewAllMode, Category: $_categoryName');

      // Load subcategories first
      print('🔄 OptimizedCategoryScreen: Fetching subcategories...');
      await _subCategoryController.fetchSubCategories();
      print('✅ OptimizedCategoryScreen: Subcategories fetched successfully');
      print('📊 OptimizedCategoryScreen: Total subcategories: ${_subCategoryController.allSubCategories.length}');
      print('📊 OptimizedCategoryScreen: Available categories: ${_subCategoryController.availableCategories}');
      
      // If NOT in View All mode and we have a specific category, load products
      if (!_isViewAllMode && _selectedCategoryId != null && _selectedCategoryId != 'all') {
        print('🎯 OptimizedCategoryScreen: Loading ALL products for category: $_selectedCategoryId');
        await _productController.loadProductsForCategory(_selectedCategoryId!);
      }
      // If in View All mode, DON'T auto-select first category - show ALL subcategories
      else if (_isViewAllMode) {
        print('🎯 OptimizedCategoryScreen: View All mode - Will show ALL subcategories without auto-selecting');
        // Clear any selected category to show all subcategories
        if (mounted) {
          setState(() {
            _selectedCategoryId = null;
          });
        }
      }
    } catch (e, stackTrace) {
      log('❌ Error initializing category: $e');
      log('Stack trace: $stackTrace');
      
      // Show user-friendly error if mounted
      if (mounted) {
        setState(() {
          _categoryName = 'Error';
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    await _productController.loadMoreProducts();
  }

  void _onCategorySelected(String categoryId, String? subCategoryId) {
    print('🎯 OptimizedCategoryScreen: Category selected - CategoryId: $categoryId, SubCategoryId: $subCategoryId');
    
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _selectedCategoryId = categoryId;
        _selectedSubCategoryId = subCategoryId;
      });
      
      // Update category name for display
      if (subCategoryId != null) {
        final subCategory = _subCategoryController.getSubCategoryById(subCategoryId);
        if (subCategory != null) {
          setState(() {
            _categoryName = subCategory.name;
          });
          print('🎯 OptimizedCategoryScreen: Updated category name to: $_categoryName');
        }
      } else if (categoryId == 'all') {
        setState(() {
          _categoryName = 'All Products';
        });
      }
      
      if (subCategoryId != null) {
        if (_productController.allCategoryProducts.isEmpty) {
          print('🎯 OptimizedCategoryScreen: No category products loaded, fetching for subcategory: $subCategoryId');
          _productController.loadProductsForSubCategory(subCategoryId);
        } else {
          print('🎯 OptimizedCategoryScreen: Filtering products by subcategory: $subCategoryId');
          _productController.filterProductsBySubCategory(subCategoryId);
        }
      } else {
        print('🎯 OptimizedCategoryScreen: Showing all products for category: $categoryId');
        _productController.showAllProductsForCategory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(_categoryName),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.search);
            },
            icon: SvgPicture.asset(
              "assets/icons/Search.svg",
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).textTheme.bodyLarge!.color!,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isViewAllMode
            ? _buildViewAllLayout(context)
            : _buildSingleCategoryLayout(context),
      ),
    );
  }

  /// Build layout for single category mode (existing behavior)
  Widget _buildSingleCategoryLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with subcategories
        _buildSubCategorySidebar(context),
        // Right side with products grid
        _buildProductsGrid(context),
      ],
    );
  }

  /// Build layout for View All mode (main categories in sidebar, all subcategories in main area)
  Widget _buildViewAllLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with MAIN categories
        _buildMainCategorySidebar(context),
        // Right side with ALL subcategories grouped by category
        _buildAllSubCategoriesArea(context),
      ],
    );
  }

  Widget _buildSubCategorySidebar(BuildContext context) {
    return Container(
      width: 80,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Categories header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: defaultPadding,
              horizontal: defaultPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Text(
              !_isViewAllMode && _selectedCategoryId != null ? _categoryName : 'Categories',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Subcategories list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Obx(() {
                if (_subCategoryController.isLoading.value) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                
                if (_subCategoryController.hasError.value) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  );
                }
                
                // Filter subcategories based on selected category
                final allSubCategories = !_isViewAllMode && _selectedCategoryId != null
                    ? _subCategoryController.getSubCategoriesByCategory(_selectedCategoryId!)
                    : _subCategoryController.allSubCategories;

                if (allSubCategories.isEmpty) {
                  return const Center(
                    child: Icon(
                      Icons.category_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: allSubCategories.length,
                  itemBuilder: (context, index) {
                    final subCategory = allSubCategories[index];
                    final isSelected = _selectedSubCategoryId == subCategory.id;
                    
                    // Get gradient colors
                    final gradientColors = _getGradientColors(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onCategorySelected(subCategory.categoryId, subCategory.id),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: isSelected ? BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Category icon with modern design
                                  SizedBox(
                                    width: isSelected ? 52 : 48,
                                    height: isSelected ? 52 : 48,
                                    child: subCategory.image.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: subCategory.image,
                                              fit: BoxFit.cover,
                                              fadeInDuration: const Duration(milliseconds: 200),
                                              fadeOutDuration: const Duration(milliseconds: 200),
                                              placeholder: (context, url) => const SizedBox.shrink(),
                                              errorWidget: (context, url, error) {
                                                print('⚠️ Image load error for ${subCategory.name}: $error');
                                                return Center(
                                                  child: Icon(
                                                    Icons.category_outlined,
                                                    color: isSelected ? Colors.white : Colors.grey[600],
                                                    size: 20,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.category_outlined,
                                              color: isSelected ? Colors.white : Colors.grey[600],
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subCategory.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    return Expanded(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Obx(() {
          try {
            // Show loading state
            if (_productController.isLoading) {
              return const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              );
            }

            // Show error state
            if (_productController.hasError) {
              return _buildErrorState(context);
            }

            // Show empty state
            if (_productController.products.isEmpty) {
              return _buildEmptyState(context);
            }

            // Show products grid
            return RefreshIndicator(
            onRefresh: () => _productController.refreshProducts(),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(defaultPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.72, // Optimized for compact, modern card design
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _productController.products.length + (_productController.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _productController.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final product = _productController.products[index];
                return ProductCard(
                  product: product,
                  press: () {
                    Get.toNamed(
                      Routes.productDetail,
                      arguments: product.productId,
                    );
                  },
                  isCompact: true, // Use compact mode for category screen
                );
              },
            ),
          );
          } catch (e) {
            print('❌ Error in products grid Obx: $e');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading products',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isSubSelected = _selectedSubCategoryId != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: defaultPadding),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            isSubSelected
                ? 'No products in this subcategory yet'
                : 'Try selecting a different category',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (isSubSelected && _selectedCategoryId != null) ...[
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSubCategoryId = null;
                });
                _productController.showAllProductsForCategory();
              },
              child: const Text('View all in this category'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: defaultPadding),
          Text(
            'Error Loading Products',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            _productController.errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () => _productController.refreshProducts(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build main category sidebar for View All mode
  Widget _buildMainCategorySidebar(BuildContext context) {
    return Container(
      width: 90, // Reduced from 120 to 90
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Obx(() {
        final availableCategories = _subCategoryController.availableCategories;
        
        if (availableCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: availableCategories.length,
          itemBuilder: (context, index) {
            final categoryId = availableCategories[index];
            final isSelected = _selectedCategoryId == categoryId;
            
            // Get category name from first subcategory of this category
            final subCats = _subCategoryController.getSubCategoriesByCategory(categoryId);
            final categoryName = subCats.isNotEmpty 
                ? _getCategoryDisplayName(categoryId)
                : categoryId;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Material(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                elevation: isSelected ? 2 : 0,
                child: InkWell(
                  onTap: () {
                    // Use post frame callback to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      
                      setState(() {
                        // If clicking the same category, deselect it (show all subcategories)
                        if (_selectedCategoryId == categoryId) {
                          _selectedCategoryId = null;
                        } else {
                          _selectedCategoryId = categoryId;
                        }
                        _selectedSubCategoryId = null;
                      });
                      
                      if (_selectedCategoryId != null) {
                        _productController.loadProductsForCategory(categoryId);
                      } else {
                        // Clear products when showing all subcategories
                        _productController.clearProducts();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category icon with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 44 : 36,
                          height: isSelected ? 44 : 36,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : [],
                          ),
                          child: Center(
                            child: Text(
                              categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: isSelected ? 18 : 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Category name
                        Text(
                          categoryName,
                          style: TextStyle(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Build all subcategories area for View All mode
  Widget _buildAllSubCategoriesArea(BuildContext context) {
    // Use Obx to make this reactive to subcategory loading
    return Obx(() {
      try {
        // Check if subcategories are still loading
        if (_subCategoryController.isLoading.value) {
          return const Expanded(
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          );
        }

        // In View All mode, show ALL subcategories when no category is selected
        List<SubCategoryModel> subCategories;
        if (_isViewAllMode && _selectedCategoryId == null) {
          // Show ALL subcategories from ALL categories
          subCategories = _subCategoryController.allSubCategories;
          print('🎯 _buildAllSubCategoriesArea: View All Mode - Found ${subCategories.length} subcategories');
          print('🎯 _buildAllSubCategoriesArea: Available categories: ${_subCategoryController.availableCategories.length}');
        } else if (_selectedCategoryId == null) {
          return const Expanded(
            child: Center(
              child: Text(
                'Select a category',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        } else {
          // Show subcategories for selected category
          subCategories = _subCategoryController.getSubCategoriesByCategory(_selectedCategoryId!);
          print('🎯 _buildAllSubCategoriesArea: Category Mode - Found ${subCategories.length} subcategories for $_selectedCategoryId');
        }
        
        if (subCategories.isEmpty) {
          print('⚠️ _buildAllSubCategoriesArea: No subcategories found!');
          print('⚠️ _buildAllSubCategoriesArea: Is View All Mode: $_isViewAllMode');
          print('⚠️ _buildAllSubCategoriesArea: Selected Category ID: $_selectedCategoryId');
          print('⚠️ _buildAllSubCategoriesArea: All subcategories count: ${_subCategoryController.allSubCategories.length}');
          print('⚠️ _buildAllSubCategoriesArea: Available categories: ${_subCategoryController.availableCategories}');
          
          return const Expanded(
            child: Center(
              child: Text(
                'No subcategories found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
    
        return Expanded(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category title
              Text(
                _isViewAllMode && _selectedCategoryId == null 
                    ? 'All Subcategories'
                    : 'Subcategories - ${_getCategoryDisplayName(_selectedCategoryId!)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subcategories grid with modern gradient design
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: subCategories.length,
                itemBuilder: (context, index) {
                  final subCategory = subCategories[index];
                  final isSelected = _selectedSubCategoryId == subCategory.id;
                  final gradientColors = _getGradientColors(index);
                  
                  return AnimatedScale(
                    scale: isSelected ? 1.02 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Get.toNamed(
                            Routes.subCategoryProducts,
                            arguments: {
                              'subCategoryId': subCategory.id,
                              'subCategoryName': subCategory.name,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Dot pattern overlay
                              Opacity(
                                opacity: 0.1,
                                child: CustomPaint(
                                  painter: _DotPatternPainter(),
                                ),
                              ),
                              
                              // Category Image (if available) as background
                              if (subCategory.image.isNotEmpty)
                                Opacity(
                                  opacity: 0.2,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: subCategory.image,
                                      fit: BoxFit.cover,
                                      fadeInDuration: const Duration(milliseconds: 200),
                                      fadeOutDuration: const Duration(milliseconds: 200),
                                      errorWidget: (context, url, error) {
                                        // Silent failure for background images - just don't show them
                                        return const SizedBox.shrink();
                                      },
                                      placeholder: (context, url) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      subCategory.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        height: 1.1,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Explore',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
      } catch (e) {
        print('❌ Error in _buildAllSubCategoriesArea: $e');
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  /// Helper to get display name for category
  String _getCategoryDisplayName(String categoryId) {
    // Capitalize first letter and handle special cases
    if (categoryId == 'stationery') return 'Stationery';
    if (categoryId == 'housekeeping') return 'Housekeeping';
    
    // Generic capitalization
    return categoryId.isEmpty 
        ? 'Unknown'
        : '${categoryId[0].toUpperCase()}${categoryId.substring(1)}';
  }

  /// Modern gradient colors for category cards
  List<Color> _getGradientColors(int index) {
    final colors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Purple
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Pink to Rose
      [const Color(0xFF10B981), const Color(0xFF06B6D4)], // Green to Cyan
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber to Red
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // Purple to Pink
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // Cyan to Blue
    ];
    return colors[index % colors.length];
  }
}

// Custom painter for dot pattern
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 12.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
