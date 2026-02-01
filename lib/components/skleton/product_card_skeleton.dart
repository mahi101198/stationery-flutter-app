import 'package:flutter/material.dart';
import 'package:rps_stationery/components/skleton/skeleton_loader.dart';

/// Skeleton loader for product card
class ProductCardSkeleton extends StatelessWidget {
  final double? width;
  final double? height;

  const ProductCardSkeleton({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SkeletonLoader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: const Color(0xFFF5F5F5),
                ),
              ),
            ),
            
            // Product info skeleton
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name - 2 lines
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Price section
                  Row(
                    children: [
                      // Price
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // MRP
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
