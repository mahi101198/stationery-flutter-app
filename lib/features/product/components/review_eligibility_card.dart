import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';
import 'package:rps_stationery/features/product/components/review_dialog.dart';
import 'package:rps_stationery/constants.dart';

class ReviewEligibilityCard extends StatelessWidget {
  final String productId;
  final String productName;

  const ReviewEligibilityCard({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final reviewController = Get.find<ReviewController>();

    return Obx(() {
      if (reviewController.isLoading) {
        return _buildLoadingCard(context);
      }

      if (reviewController.hasError) {
        return _buildErrorCard(context, reviewController.errorMessage);
      }

      final canReview = reviewController.canUserReview;
      final hasReview = reviewController.userReview != null;

      if (hasReview) {
        return _buildHasReviewCard(context, reviewController);
      }

      if (canReview) {
        return _buildCanReviewCard(context, reviewController);
      }

      return _buildCannotReviewCard(context);
    });
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Checking review eligibility...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String errorMessage) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.warning_2,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to check review eligibility',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasReviewCard(BuildContext context, ReviewController reviewController) {
    final userReview = reviewController.userReview!;
    
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
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
                Iconsax.star1,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'You reviewed this product',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showReviewDialog(context, reviewController),
                icon: const Icon(Iconsax.edit, size: 18),
                tooltip: 'Edit Review',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < userReview.rating ? Iconsax.star1 : Iconsax.star,
                size: 16,
                color: index < userReview.rating ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            userReview.comment,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCanReviewCard(BuildContext context, ReviewController reviewController) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.verify,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can review this product',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You purchased and received this product',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showReviewDialog(context, reviewController),
            icon: const Icon(Iconsax.star, size: 16),
            label: const Text('Review'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCannotReviewCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase to review',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purchase and receive this product to write a review',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, ReviewController reviewController) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        productId: productId,
        existingReview: reviewController.userReview,
      ),
    );
  }
}
