import 'package:flutter/material.dart';
import 'package:rps_stationery/components/ui/modern_ui.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

/// Modern product card skeleton loader
class ModernProductCardSkeleton extends StatelessWidget {
  const ModernProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      isInteractive: false,
      elevation: 2,
      padding: EdgeInsets.all(DesignSystem.spacing.sm),
      child: Container(
        width: 160,
        constraints: const BoxConstraints(minHeight: 230),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Skeleton
            ModernSkeleton(
              width: double.infinity,
              height: 120,
              borderRadius: DesignSystem.borders.lg,
            ),
            
            SizedBox(height: DesignSystem.spacing.xs),
            
            // Category Skeleton
            ModernSkeleton.text(
              width: 60,
              height: 10,
            ),
            
            SizedBox(height: DesignSystem.spacing.xs / 2),
            
            // Product Name Skeleton
            ModernSkeleton.text(
              width: double.infinity,
              height: 12,
            ),
            SizedBox(height: 4),
            ModernSkeleton.text(
              width: 100,
              height: 12,
            ),
            
            const Spacer(),
            
            // Price Skeleton
            ModernSkeleton.text(
              width: 80,
              height: 14,
            ),
            SizedBox(height: 2),
            ModernSkeleton.text(
              width: 60,
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern product grid skeleton
class ModernProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ModernProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ModernProductCardSkeleton(),
    );
  }
}

/// Modern product list skeleton
class ModernProductListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ModernProductListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.md),
      child: Row(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              right: index < itemCount - 1 ? DesignSystem.spacing.md : 0,
            ),
            child: const ModernProductCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

/// Modern category card skeleton
class ModernCategoryCardSkeleton extends StatelessWidget {
  const ModernCategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      isInteractive: false,
      elevation: 1,
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Icon Skeleton
          ModernSkeleton.circle(size: 48),
          
          SizedBox(height: DesignSystem.spacing.sm),
          
          // Category Name Skeleton
          ModernSkeleton.text(
            width: 80,
            height: 12,
          ),
        ],
      ),
    );
  }
}

/// Modern banner skeleton
class ModernBannerSkeleton extends StatelessWidget {
  final double? height;
  
  const ModernBannerSkeleton({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.md),
      child: ModernSkeleton(
        width: double.infinity,
        height: height ?? 160,
        borderRadius: DesignSystem.borders.lg,
      ),
    );
  }
}

/// Modern order item skeleton
class ModernOrderItemSkeleton extends StatelessWidget {
  const ModernOrderItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing.md,
        vertical: DesignSystem.spacing.xs,
      ),
      child: ModernCard(
        isInteractive: false,
      child: Row(
        children: [
          // Product Image
          ModernSkeleton(
            width: 60,
            height: 60,
            borderRadius: DesignSystem.borders.md,
          ),
          
          SizedBox(width: DesignSystem.spacing.md),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                ModernSkeleton.text(
                  width: double.infinity,
                  height: 14,
                ),
                SizedBox(height: 4),
                
                // Product details
                ModernSkeleton.text(
                  width: 120,
                  height: 12,
                ),
                SizedBox(height: 8),
                
                // Price
                ModernSkeleton.text(
                  width: 80,
                  height: 14,
                ),
              ],
            ),
          ),
          
          // Quantity controls
          Column(
            children: [
              ModernSkeleton(
                width: 32,
                height: 32,
                borderRadius: DesignSystem.borders.full,
              ),
              SizedBox(height: 8),
              ModernSkeleton.text(width: 20, height: 12),
              SizedBox(height: 8),
              ModernSkeleton(
                width: 32,
                height: 32,
                borderRadius: DesignSystem.borders.full,
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

/// Modern profile item skeleton
class ModernProfileItemSkeleton extends StatelessWidget {
  const ModernProfileItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ModernSkeleton.circle(size: 24),
      title: ModernSkeleton.text(width: double.infinity, height: 14),
      trailing: ModernSkeleton(
        width: 20,
        height: 20,
        borderRadius: DesignSystem.borders.sm,
      ),
    );
  }
}

/// Modern review skeleton
class ModernReviewSkeleton extends StatelessWidget {
  const ModernReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignSystem.spacing.xs),
      child: ModernCard(
        isInteractive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar
              ModernSkeleton.circle(size: 40),
              
              SizedBox(width: DesignSystem.spacing.sm),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name
                    ModernSkeleton.text(width: 120, height: 14),
                    SizedBox(height: 4),
                    
                    // Rating and date
                    Row(
                      children: [
                        ModernSkeleton.text(width: 80, height: 12),
                        const Spacer(),
                        ModernSkeleton.text(width: 60, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignSystem.spacing.sm),
          
          // Review text
          ModernSkeleton.text(width: double.infinity, height: 12),
          SizedBox(height: 4),
          ModernSkeleton.text(width: double.infinity, height: 12),
          SizedBox(height: 4),
          ModernSkeleton.text(width: 200, height: 12),
        ],
        ),
      ),
    );
  }
}
