import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';
import 'package:rps_stationery/components/home/section_item_card.dart';
import 'package:rps_stationery/components/skleton/home_section_skeleton.dart';
import 'package:rps_stationery/components/skleton/product_card_skeleton.dart';
import 'package:rps_stationery/data/models/home_section_model.dart';
import 'package:rps_stationery/features/home/controllers/subcategory_filter_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

/// Home Sections List - Displays all active home sections with pagination support
/// Supports lazy loading and subcategory filtering with batch loading
class HomeSectionsList extends StatefulWidget {
  const HomeSectionsList({super.key});

  @override
  State<HomeSectionsList> createState() => _HomeSectionsListState();
}

class _HomeSectionsListState extends State<HomeSectionsList> {
  late ScrollController _scrollController;
  late HomeSectionController _sectionController;
  late SubcategoryFilterController _filterController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _sectionController = Get.find<HomeSectionController>();
    _filterController = Get.find<SubcategoryFilterController>();
    
    // Add scroll listener for lazy loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll for lazy loading more products
  void _onScroll() {
    // Load more when approaching end of scroll (200px from bottom)
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more products for current filtered subcategory
      final subcategoryId = _filterController.selectedSubcategoryId.value;
      if (subcategoryId != null && subcategoryId.isNotEmpty) {
        // Load more for each section if needed
        for (var section in _sectionController.activeSections) {
          if (_sectionController.hasMoreItemsForSubcategory(section.sectionId, subcategoryId)) {
            _sectionController.loadMoreSubcategoryProducts(section.sectionId, subcategoryId);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HomeSectionsList: Building...');
    
    try {
      print('✅ HomeSectionsList: Controller found');
      print('📊 HomeSectionsList: Loading=${_sectionController.isLoading.value}, Error=${_sectionController.hasError.value}, Sections=${_sectionController.activeSections.length}');

      return Obx(() {
        print('🔄 HomeSectionsList: Obx rebuilding - Loading=${_sectionController.isLoading.value}, Sections=${_sectionController.activeSections.length}');
        
        // Show loading state with multiple section skeletons
        if (_sectionController.isLoading.value) {
          print('⏳ HomeSectionsList: Showing loading state');
          return Column(
            children: List.generate(
              3, // Show 3 skeleton sections
              (index) => const HomeSectionSkeleton(),
            ),
          );
        }

        // Show error state
        if (_sectionController.hasError.value) {
          print('❌ HomeSectionsList: Showing error state: ${_sectionController.errorMessage.value}');
          return _buildErrorState(context, _sectionController.errorMessage.value);
        }

        // Show empty state
        if (_sectionController.activeSections.isEmpty) {
          print('📭 HomeSectionsList: No active sections found');
          return _buildEmptyState(context);
        }

        print('✅ HomeSectionsList: Building sections list with ${_sectionController.activeSections.length} sections');
        return _buildSectionsList(context);
      });
    } catch (e, stackTrace) {
      print('❌ HomeSectionsList: Error finding controller: $e');
      print('❌ Stack trace: $stackTrace');
      return Center(child: Text('Error: $e'));
    }
  }

  /// Build the list of sections
  Widget _buildSectionsList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sectionController.activeSections.length,
      itemBuilder: (context, index) {
        final section = _sectionController.activeSections[index];
        return _buildSection(context, section);
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    HomeSectionModel section,
  ) {
    // Load items if not already loaded
    if (!_sectionController.isSectionLoaded(section.sectionId)) {
      _sectionController.loadSectionItems(section.sectionId);
    }

    return Obx(() {
      final selectedSubcategoryId = _filterController.selectedSubcategoryId.value;
      
      // When subcategory is selected, load products for that subcategory
      if (selectedSubcategoryId != null && selectedSubcategoryId.isNotEmpty) {
        _sectionController.loadSubcategoryProducts(section.sectionId, selectedSubcategoryId);
      }
      
      // Get filtered items based on subcategory
      final filteredItems = _sectionController.getFilteredSectionItemsWithPagination(
        section.sectionId,
        selectedSubcategoryId,
      );
      
      final isLoading = _sectionController.isSectionLoading(section.sectionId);
      final isLoadingMore = _sectionController.isLoadingMoreForSubcategory(
        section.sectionId, 
        selectedSubcategoryId ?? '',
      );

      // Skip empty sections
      if (!isLoading && filteredItems.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(context, section),
            
            const SizedBox(height: 12),
            
            // Section items with shimmer skeleton
            if (isLoading)
              _buildLoadingItems(context)
            else
              _buildSectionItemsWithPagination(
                context, 
                section.sectionId,
                filteredItems,
                selectedSubcategoryId,
                isLoadingMore,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(BuildContext context, HomeSectionModel section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Section icon (if available)
          if (section.iconUrl != null && section.iconUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.network(
                section.iconUrl!,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          
          // Section title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (section.subtitle != null && section.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      section.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // View All button (if enabled)
          if (section.shouldShowViewAll)
            TextButton(
              onPressed: () => _handleViewAll(section),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionItems(BuildContext context, List items) {
    // Calculate width to show ~3 cards with even spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3.1;
    
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SectionItemCard(
            item: item,
            width: cardWidth,
          );
        },
      ),
    );
  }

  /// Build section items with pagination support
  /// Shows items in batches and loads more when scrolling to end
  Widget _buildSectionItemsWithPagination(
    BuildContext context,
    String sectionId,
    List items,
    String? subcategoryId,
    bool isLoadingMore,
  ) {
    // Calculate width to show ~3 cards with even spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3.1;
    
    return SizedBox(
      height: 240,
      child: Obx(() {
        // Get updated items
        final filteredItems = _sectionController.getFilteredSectionItemsWithPagination(
          sectionId,
          subcategoryId,
        );
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end
            if (index == filteredItems.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Container(
                    width: cardWidth,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }

            final item = filteredItems[index];
            
            // Trigger load more when reaching end (for horizontal scroll)
            if (index == filteredItems.length - 2 && 
                subcategoryId != null && 
                subcategoryId.isNotEmpty &&
                _sectionController.hasMoreItemsForSubcategory(sectionId, subcategoryId) &&
                !isLoadingMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _sectionController.loadMoreSubcategoryProducts(sectionId, subcategoryId);
              });
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SectionItemCard(
                item: item,
                width: cardWidth,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildLoadingItems(BuildContext context) {
    // Calculate width to show ~3 cards with even spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3.1;
    
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ProductCardSkeleton(
            width: cardWidth,
            height: 240,
          );
        },
      ),
    );
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
              Get.find<HomeSectionController>().refreshSections();
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
            'No sections available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new products and deals',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleViewAll(HomeSectionModel section) {
    // Navigate to section view all screen
    Get.toNamed(
      Routes.sectionViewAll,
      arguments: {
        'sectionId': section.sectionId,
        'sectionTitle': section.title,
      },
    );
  }
}
