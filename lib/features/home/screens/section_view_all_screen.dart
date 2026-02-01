import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/home/section_item_card.dart';
import 'package:rps_stationery/components/skleton/product/product_card_skelton.dart';
import 'package:rps_stationery/features/home/controllers/home_section_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class SectionViewAllScreen extends StatefulWidget {
  const SectionViewAllScreen({super.key});

  @override
  State<SectionViewAllScreen> createState() => _SectionViewAllScreenState();
}

class _SectionViewAllScreenState extends State<SectionViewAllScreen> {
  late ScrollController _scrollController;
  late String _sectionId;
  late String _sectionTitle;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Get arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    _sectionId = arguments?['sectionId'] ?? '';
    _sectionTitle = arguments?['sectionTitle'] ?? 'All Products';

    // Initialize data loading
    if (_sectionId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<HomeSectionController>().loadAllSectionProducts(_sectionId);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if scrolled to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = Get.find<HomeSectionController>();
      if (controller.hasMoreItemsForSection(_sectionId) &&
          !controller.isLoadingMoreForSection(_sectionId)) {
        controller.loadMoreSectionProducts(_sectionId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeSectionController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _sectionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final isLoading = controller.isLoadingSectionProducts(_sectionId);
        final items = controller.getAllSectionProducts(_sectionId);
        final isLoadingMore = controller.isLoadingMoreForSection(_sectionId);

        // Show loading state
        if (isLoading && items.isEmpty) {
          return _buildLoadingState(context);
        }

        // Show empty state
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        // Show products grid
        return _buildProductsGrid(context, items, isLoadingMore, controller);
      }),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) {
              return ProductCardSkelton(
                height: 240,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new products',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(
    BuildContext context,
    List items,
    bool isLoadingMore,
    HomeSectionController controller,
  ) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        // Show loading skeletons at the end
        if (index >= items.length) {
          return ProductCardSkelton(height: 240);
        }

        final product = items[index];

        // Trigger load more when reaching near end
        if (index == items.length - 4 &&
            controller.hasMoreItemsForSection(_sectionId) &&
            !isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadMoreSectionProducts(_sectionId);
          });
        }

        return SectionItemCard(item: product);
      },
    );
  }
}
