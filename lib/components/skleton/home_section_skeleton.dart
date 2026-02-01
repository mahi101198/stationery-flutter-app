import 'package:flutter/material.dart';
import 'package:rps_stationery/components/skleton/skeleton_loader.dart';
import 'package:rps_stationery/components/skleton/product_card_skeleton.dart';

/// Skeleton loader for home section (header + horizontal product list)
class HomeSectionSkeleton extends StatelessWidget {
  const HomeSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(
              child: Row(
                children: [
                  // Title
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  // View All button
                  Container(
                    width: 70,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Horizontal product list skeleton
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ProductCardSkeleton(
                  width: (MediaQuery.of(context).size.width - 48) / 4.2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
