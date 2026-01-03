import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/components/skleton/product/secondary_products_skeleton.dart';
import 'package:rps_stationery/features/home/controllers/product_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

import '../../../../constants.dart';

class MostPopular extends StatelessWidget {
  const MostPopular({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Most popular",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading use 👇
        Obx(
          () =>
              controller.isLoading.value
                  ? const SecondaryProductsSkeleton()
                  : SizedBox(
                    height: 200, // Fixed height for horizontal ListView
                    child: Builder(
                      builder: (context) {
                        final products = List.of(controller.productList);
                        products.shuffle();
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          itemBuilder:
                              (context, index) => Padding(
                                padding: EdgeInsets.only(
                                  left: 4,
                                  right:
                                      index == products.length - 1
                                          ? 4
                                          : 0,
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
