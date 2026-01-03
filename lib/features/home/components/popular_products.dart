import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/components/skleton/product/optimized_products_skelton.dart';
import 'package:rps_stationery/features/home/controllers/product_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';


class PopularProducts extends StatelessWidget {
  const PopularProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Popular Products",
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Get.toNamed(
                    Routes.category,
                    arguments: {'categoryName': 'All Products'},
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Products list
        Obx(
          () => controller.isLoading.value
              ? const OptimizedProductsSkelton()
              : SizedBox(
                  height: 200, // Fixed height for horizontal ListView
                  child: Builder(
                    builder: (context) {
                      final products = List.of(controller.productList);
                      products.shuffle();
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        itemCount: products.length,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(
                            left: 2,
                            right: index == products.length - 1 ? 2 : 0,
                          ),
                          child: ProductCard(
                            product: products[index],
                            press: () {
                              Get.toNamed(
                                Routes.productDetail,
                                arguments: products[index].productId,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
