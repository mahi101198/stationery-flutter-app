import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/features/home/controllers/subcategory_filter_controller.dart';
import 'package:rps_stationery/components/skleton/subcategory_filter_skeleton.dart';

/// Subcategory Filter Row - Horizontal scrolling filter with card-based design
/// Shows "All" option + subcategory cards with icon on top and name below
class SubcategoryFilterRow extends StatelessWidget {
  const SubcategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubcategoryFilterController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const SubcategoryFilterSkeleton();
      }

      if (controller.subcategories.isEmpty) {
        return _buildEmptyState();
      }

      return _buildFilterRow(controller);
    });
  }

  /// Loading state
  Widget _buildLoadingState() {
    return const SubcategoryFilterSkeleton();
  }

  /// Empty state (show only "All" if no subcategories)
  Widget _buildEmptyState() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Center(
        child: Text('No subcategories available'),
      ),
    );
  }

  /// Main filter row
  Widget _buildFilterRow(SubcategoryFilterController controller) {
    return Container(
      height: 110, // Increased height for card layout
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.subcategories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            return Obx(() => _buildAllCard(controller));
          }

          // Subcategory card
          final subcategory = controller.subcategories[index - 1];

          return Obx(() {
            final isSelected = controller.isSubcategorySelected(subcategory.id);
            
            return _buildSubcategoryCard(
              controller: controller,
              subcategoryId: subcategory.id,
              name: subcategory.name,
              imageUrl: subcategory.image,
              isSelected: isSelected,
            );
          });
        },
      ),
    );
  }

  /// "All" card
  Widget _buildAllCard(SubcategoryFilterController controller) {
    final isSelected = controller.isAllSelected;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => controller.selectAll(),
        child: Builder(
          builder: (context) => Container(
            width: 80,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                // Text
                Text(
                  'All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subcategory card
  Widget _buildSubcategoryCard({
    required SubcategoryFilterController controller,
    required String subcategoryId,
    required String name,
    required String imageUrl,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => controller.selectSubcategory(subcategoryId),
        child: Builder(
          builder: (context) => Container(
            width: 80,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image/Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.category_outlined,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.category_outlined,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
