import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/product/controllers/review_controller.dart';
import 'package:rps_stationery/data/models/review_model.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/features/product/screens/product_reviews_screen.dart';

class EnhancedReviewCard extends StatelessWidget {
  final String productId;
  final String? productName;

  const EnhancedReviewCard({
    super.key,
    required this.productId,
    this.productName,
  });

  @override
  Widget build(BuildContext context) {
    // Safely get the review controller
    ReviewController? reviewController;
    try {
      reviewController = Get.find<ReviewController>();
    } catch (e) {
      // If review controller is not available, show a placeholder
      return _buildControllerNotAvailableState(context);
    }

    return Obx(() {
      if (reviewController!.isLoading) {
        return _buildLoadingState(context);
      }

      if (reviewController!.hasError) {
        return _buildErrorState(context, reviewController!.errorMessage);
      }

      final stats = reviewController!.reviewStats;
      if (stats == null || stats.totalReviews == 0) {
        return _buildEmptyState(context);
      }

      return _buildReviewStats(context, stats, reviewController!);
    });
  }

  Widget _buildControllerNotAvailableState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Iconsax.star,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Reviews',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reviews will be available soon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.warning_2,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load reviews',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.star,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase and receive this product to leave a review',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStats(BuildContext context, ReviewStats stats, ReviewController reviewController) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating and total reviews
          Row(
            children: [
              // Average rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    stats.averageRating.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Iconsax.star1,
                    color: Colors.amber,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Total reviews
              Text(
                '${stats.totalReviews} Review${stats.totalReviews != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Star distribution
          _buildStarDistribution(context, stats),
          
          const SizedBox(height: 16),
          
          // View all reviews button - show to everyone
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAllReviews(context, reviewController),
              icon: const Icon(Iconsax.eye),
              label: const Text('View All Reviews'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarDistribution(BuildContext context, ReviewStats stats) {
    return Column(
      children: [
        _buildStarRow(context, 5, stats.fiveStarCount, stats.totalReviews),
        _buildStarRow(context, 4, stats.fourStarCount, stats.totalReviews),
        _buildStarRow(context, 3, stats.threeStarCount, stats.totalReviews),
        _buildStarRow(context, 2, stats.twoStarCount, stats.totalReviews),
        _buildStarRow(context, 1, stats.oneStarCount, stats.totalReviews),
      ],
    );
  }

  Widget _buildStarRow(BuildContext context, int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Star count
          SizedBox(
            width: 20,
            child: Text(
              '$stars',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Star icon
          Icon(
            Iconsax.star1,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Count
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }


  void _showAllReviews(BuildContext context, ReviewController reviewController) {
    // Navigate to full reviews page
    Get.to(() => ProductReviewsScreen(
      productId: productId,
      productName: productName ?? 'Product',
    ));
  }
}

