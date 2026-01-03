import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/features/category/controllers/streaming_subcategory_products_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class SubCategoryProductsScreen extends StatelessWidget {
  const SubCategoryProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StreamingSubCategoryProductsController>();
    final arguments = Get.arguments as Map<String, dynamic>?;
    
    if (arguments != null) {
      final subCategoryId = arguments['subCategoryId'] as String?;
      final subCategoryName = arguments['subCategoryName'] as String?;
      
      if (subCategoryId != null && subCategoryName != null) {
        // Start streaming products when screen builds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.startStreamingProducts(subCategoryId, subCategoryName);
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.subCategoryName.isEmpty 
              ? 'Products' 
              : controller.subCategoryName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.offAllNamed(Routes.bottomNav, arguments: 'category'),
        ),
        actions: [
          Obx(() => controller.isLoading || controller.isStreaming
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        // Show loading state
        if (controller.isLoading) {
          return _buildLoadingState(context);
        }

        // Show error state
        if (controller.hasError) {
          return _buildErrorState(context, controller.errorMessage);
        }

        // Show empty state
        if (controller.products.isEmpty && !controller.isStreaming) {
          return _buildEmptyState(context);
        }

        // Show products with streaming indicator
        return _buildProductsGrid(context);
      }),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading products...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Products',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final controller = Get.find<StreamingSubCategoryProductsController>();
                controller.refreshProducts();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'No Products Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no products available in this subcategory yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(Routes.bottomNav, arguments: 'category'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    final controller = Get.find<StreamingSubCategoryProductsController>();
    
    return Column(
      children: [
        // Streaming progress indicator
        if (controller.isStreaming)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => Text(
                    'Loading ${controller.loadedCount}/${controller.totalCount} products...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                ),
                Obx(() => Text(
                  '${((controller.loadedCount / controller.totalCount) * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
        
        // Products count header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                '${controller.products.length} Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )),
              IconButton(
                onPressed: () => controller.refreshProducts(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Products grid
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: controller.productsStream,
            initialData: controller.products,
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              
              if (products.isEmpty) {
                return const Center(child: Text('No products to display'));
              }
              
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    press: () {
                      // Navigate to product details
                      Get.toNamed(
                        Routes.productDetail,
                        arguments: {'productId': product.id},
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
