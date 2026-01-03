import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class BannerScreen extends StatelessWidget {
  const BannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flash Sale")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              /// Banner Image
              Container(
                width: Get.width,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
                  image: const DecorationImage(
                    image: AssetImage(
                      "assets/images/banners/banner_1.jpg",
                    ), // Replace with your banner image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Products
              // TSortableProducts(products: []), // Pass your list of products here
            ],
          ),
        ),
      ),
    );
  }
}
