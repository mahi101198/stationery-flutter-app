import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';
import 'package:rps_stationery/data/models/review_model.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/utils/formatters/formatter.dart';

class ProductReviewsScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    // Safely get the review controller
    ReviewController? reviewController;
    try {
      reviewController = Get.find<ReviewController>();
    } catch (e) {
      // If review controller is not available, show error state
      return _buildControllerNotAvailableState(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for $productName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      body: Obx(() {
        if (reviewController!.isLoading) {
          return _buildLoadingState(context);
        }

        if (reviewController!.hasError) {
          return _buildErrorState(context, reviewController!.errorMessage);
        }

        final reviews = reviewController!.reviews;
        final stats = reviewController!.reviewStats;

        if (reviews.isEmpty) {
          return _buildEmptyState(context, reviewController!);
        }

        return CustomScrollView(
          slivers: [
            // Review Stats Header
            if (stats != null) ...[
              SliverToBoxAdapter(
                child: _buildReviewStatsHeader(context, stats, reviewController!),
              ),
            ],

            // User's Review Section (if exists)
            Obx(() {
              if (reviewController!.userReview != null) {
                return SliverToBoxAdapter(
                  child: _buildUserReviewSection(context, reviewController!),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // All Reviews Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Row(
                  children: [
                    Text(
                      'All Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${reviews.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reviews List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(context, review, reviewController!);
                },
                childCount: reviews.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding * 2),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControllerNotAvailableState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for $productName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Review System Unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The review system is currently unavailable. Please try again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Iconsax.arrow_left),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading reviews...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reviews',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final reviewController = Get.find<ReviewController>();
              reviewController.loadProductReviews(productId);
            },
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReviewController reviewController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_text,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this product!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Review functionality moved to order details screen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.shopping_bag,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Purchase this product to leave a review',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatsHeader(BuildContext context, ReviewStats stats, ReviewController reviewController) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating
          Row(
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(context, stats.averageRating, 20),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalReviews} review${stats.totalReviews != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Add Review Button
              // Review functionality moved to order details screen
              const SizedBox.shrink(),
            ],
          ),

          const SizedBox(height: 16),

          // Rating Breakdown
          ...List.generate(5, (index) {
            final starCount = 5 - index;
            final count = _getStarCount(stats, starCount);
            final percentage = stats.totalReviews > 0 ? count / stats.totalReviews : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '$starCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Iconsax.star1, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserReviewSection(BuildContext context, ReviewController reviewController) {
    final userReview = reviewController.userReview!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.user,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Review',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              // Edit review functionality moved to order details screen
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          _buildStarRating(context, userReview.rating.toDouble(), 16),
          const SizedBox(height: 8),
          Text(
            userReview.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            TFormatter.formatDate(userReview.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review, ReviewController reviewController) {
    final isUserReview = reviewController.userReview?.reviewId == review.reviewId;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 4),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isUserReview 
            ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  'U', // You could fetch user name and use first letter
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'User', // You could fetch and display actual user name
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isUserReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (review.isVerified) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Iconsax.verify,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TFormatter.formatDate(review.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating
              _buildStarRating(context, review.rating.toDouble(), 16),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Comment
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(BuildContext context, double rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;
        final isHalfFilled = starIndex - 0.5 <= rating && starIndex > rating;
        
        return Icon(
          isFilled ? Iconsax.star1 : Iconsax.star,
          size: size,
          color: isFilled || isHalfFilled ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }),
    );
  }

  int _getStarCount(ReviewStats stats, int starCount) {
    switch (starCount) {
      case 5: return stats.fiveStarCount;
      case 4: return stats.fourStarCount;
      case 3: return stats.threeStarCount;
      case 2: return stats.twoStarCount;
      case 1: return stats.oneStarCount;
      default: return 0;
    }
  }

}
