import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';

/// Full-screen review submission form
class ReviewSubmissionScreen extends StatefulWidget {
  final String productId;
  final String orderId;
  final Map<String, dynamic>? existingReview;

  const ReviewSubmissionScreen({
    super.key,
    required this.productId,
    required this.orderId,
    this.existingReview,
  });

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  final reviewController = Get.find<ReviewController>();

  @override
  void initState() {
    super.initState();
    reviewController.initializeReviewForm(
      productId: widget.productId,
      orderId: widget.orderId,
      existingReview: widget.existingReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.existingReview != null ? 'Edit Review' : 'Write a Review',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating selector
            Text(
              'Rate this product',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final rating = reviewController.rating.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      reviewController.rating.value = (index + 1).toDouble();
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Title input
            Text(
              'Review Title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reviewController.titleController,
              decoration: InputDecoration(
                hintText: 'Summarize your experience',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Comment input
            Text(
              'Your Review',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reviewController.commentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this product...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Image picker
            Text(
              'Add Photos (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final localImages = reviewController.reviewImages;
              final networkImages = reviewController.reviewImageUrls;
              final totalImages = localImages.length + networkImages.length;
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Network images
                  ...networkImages.map((url) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              reviewController.removeReviewImage(networkUrl: url);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  
                  // Local images
                  ...localImages.map((file) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              reviewController.removeReviewImage(localFile: file);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  
                  // Add image button
                  if (totalImages < 5)
                    GestureDetector(
                      onTap: () => reviewController.pickReviewImages(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.camera,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => reviewController.submitReview(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.existingReview != null ? 'Update Review' : 'Submit Review',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
