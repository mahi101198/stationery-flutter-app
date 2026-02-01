import 'package:flutter/material.dart';
import 'package:rps_stationery/components/skleton/skeleton_loader.dart';

/// Skeleton loader for subcategory filter row
class SubcategoryFilterSkeleton extends StatelessWidget {
  const SubcategoryFilterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SkeletonLoader(
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circle for icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rectangle for text
                    Container(
                      width: 50,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
