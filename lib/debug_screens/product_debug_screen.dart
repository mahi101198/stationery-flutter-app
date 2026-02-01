import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';

/// Debug screen to check what products are cached locally
class ProductDebugScreen extends StatelessWidget {
  const ProductDebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productService = ProductCacheService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Database Debug')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Check if stapler product exists
            _buildSection(
              'Checking for Stapler Product',
              [
                FutureBuilder(
                  future: productService.getProductById('stapler-kangaro-hd10d'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      final product = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ Found: ${product.name}'),
                          Text('   Price: ${product.price}'),
                          Text('   SKUs: ${product.productSkus.length}'),
                          if (product.productSkus.isNotEmpty) ...[
                            const Text('   SKU Details:'),
                            ...product.productSkus.map((sku) => Text(
                              '     - ${sku.skuId}: Price=${sku.price}, MRP=${sku.mrp}'
                            )).toList(),
                          ],
                        ],
                      );
                    }
                    return const Text('❌ Product NOT found: stapler-kangaro-hd10d');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 2: Check all products in cache
            _buildSection(
              'All Cached Products',
              [
                Obx(() {
                  final products = productService.popularProducts;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total cached: ${products.length}'),
                      if (products.isEmpty)
                        const Text('❌ No products cached!')
                      else
                        ...products.take(5).map((product) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${product.productId}: ${product.name}'),
                              Text('  Price: ${product.price}, SKUs: ${product.productSkus.length}'),
                            ],
                          );
                        }).toList(),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Try to fetch the SKU directly
            _buildSection(
              'Searching for SKU by Service',
              [
                FutureBuilder(
                  future: productService.getProductsByIds(['stapler-kangaro-hd10d-standard']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      final product = snapshot.data!.first;
                      return Text('✅ Found via getProductsByIds: ${product.name}');
                    }
                    return const Text('❌ SKU not found via service');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
