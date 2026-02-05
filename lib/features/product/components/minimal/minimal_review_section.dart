import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';
import 'package:rps_stationery/features/product/components/minimal/minimal_review_card.dart';
import 'package:rps_stationery/features/shop/screens/review_submission_screen.dart';

/// Review section for product details page
class MinimalReviewSection extends StatelessWidget {
  final String productId;
  final bool canWriteReview;
  final bool hasExistingReview;

  const MinimalReviewSection({
    super.key,
    required this.productId,
    required this.canWriteReview,
    required this.hasExistingReview,
  });

  @override
  Widget build(BuildContext context) {
    final reviewController = Get.find<ReviewController>();

    // If user hasn't received the product, hide entire review section
    if (!canWriteReview) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews & Ratings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Review statistics
          Obx(() {
            final stats = reviewController.reviewStats;
            final totalReviews = stats['totalReviews'] ?? 0;
            final averageRating = (stats['averageRating'] as num?)?.toDouble() ?? 0.0;
            final distribution = stats['ratingDistribution'] as Map<String, dynamic>? ?? {};

            if (totalReviews == 0) {
              return _buildNoReviewsState(context);
            }

            return _buildReviewStats(context, averageRating, totalReviews, distribution);
          }),
          
          // Write/Edit Review button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.to(() => ReviewSubmissionScreen(
                  productId: productId,
                  orderId: '', // Will be fetched in the screen
                ));
              },
              icon: Icon(
                hasExistingReview ? Iconsax.edit : Iconsax.edit_2,
                size: 18,
              ),
              label: Text(hasExistingReview ? 'Edit Your Review' : 'Write a Review'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Reviews list
          Obx(() {
            final reviews = reviewController.productReviews;
            
            if (reviews.isEmpty) {
              return const SizedBox.shrink();
            }

            final displayReviews = reviews.take(3).toList();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...displayReviews.map((review) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MinimalReviewCard(
                      review: review,
                      onHelpful: () {
                        reviewController.markReviewHelpful(
                          productId,
                          review['userId'],
                        );
                      },
                      onReport: () {
                        reviewController.showReportDialog(
                          productId,
                          review['userId'],
                        );
                      },
                    ),
                  );
                }).toList(),
                
                // See all reviews button
                if (reviews.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to all reviews screen
                        // Get.to(() => ProductReviewsScreen(productId: productId));
                      },
                      child: Text('See all ${reviews.length} reviews'),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoReviewsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.star,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to review this product',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStats(
    BuildContext context,
    double averageRating,
    int totalReviews,
    Map<String, dynamic> distribution,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Average rating
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < averageRating.floor() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Rating distribution
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = distribution['$star'] ?? 0;
                final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
