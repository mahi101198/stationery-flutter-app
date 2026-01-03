import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/skleton/product/products_skelton.dart';
import 'package:rps_stationery/features/home/controllers/product_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

import 'package:rps_stationery/components/Banner/unified_banner.dart';
import '../../../../components/product/product_card.dart';
import '../../../../constants.dart';

class FlashSale extends StatelessWidget {
  const FlashSale({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // While loading show 👇
        UnifiedBanner(
          imageUrl: 'https://dummyimage.com/1200x600/000/fff&text=Flash+Sale',
          onTap: () {},
          size: BannerSize.medium,
          title: 'Super Flash Sale',
          subtitle: '50% Off',
        ),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Flash sale",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading show 👇
        Obx(
          () =>
              controller.isLoading.value
                  ? const ProductsSkelton()
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
