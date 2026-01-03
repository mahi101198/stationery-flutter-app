import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions & Offers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 2,
              color: TColors.primary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.discount_shape,
                      color: TColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Special Offers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Save big on your favorite stationery items',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Placeholder promotions
            ..._buildPromotionCards(),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Browse Products Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.offNamedUntil(
                  Routes.bottomNav,
                  (route) => false,
                ),
                icon: const Icon(Iconsax.shopping_bag),
                label: const Text('Browse Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPromotionCards() {
    final promotions = [
      {
        'title': 'Back to School Sale',
        'subtitle': 'Up to 50% off on notebooks and pens',
        'discount': '50% OFF',
        'color': Colors.green,
        'icon': Iconsax.book,
      },
      {
        'title': 'Office Supplies Bundle',
        'subtitle': 'Buy 3 get 1 free on office essentials',
        'discount': 'BUY 3 GET 1',
        'color': Colors.blue,
        'icon': Iconsax.briefcase,
      },
      {
        'title': 'Art Supplies Special',
        'subtitle': 'Free shipping on art supplies over ₹500',
        'discount': 'FREE SHIPPING',
        'color': Colors.purple,
        'icon': Iconsax.brush_1,
      },
      {
        'title': 'Student Discount',
        'subtitle': 'Extra 20% off for students with ID',
        'discount': '20% OFF',
        'color': Colors.orange,
        'icon': Iconsax.book_1,
      },
    ];

    return promotions.map((promo) {
      return Container(
        margin: const EdgeInsets.only(bottom: TSizes.md),
        child: Card(
          elevation: 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  (promo['color'] as Color).withValues(alpha: 0.1),
                  (promo['color'] as Color).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: (promo['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      promo['icon'] as IconData,
                      color: promo['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          promo['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: promo['color'] as Color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      promo['discount'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
