import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';
import 'package:rps_stationery/data/models/review_model.dart';

class ReviewDialog extends StatefulWidget {
  final String productId;
  final ReviewModel? existingReview;

  const ReviewDialog({
    super.key,
    required this.productId,
    this.existingReview,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final ReviewController _reviewController = Get.find<ReviewController>();
  
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEditing ? Iconsax.edit : Iconsax.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Review' : 'Write a Review',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Iconsax.close_circle),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Rating Section
            Text(
              'Rating',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Star Rating
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      index < _rating ? Iconsax.star1 : Iconsax.star,
                      color: index < _rating 
                          ? Colors.amber 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Comment Section
            Text(
              'Your Review',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Comment TextField
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with this product...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Submit Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEditing ? 'Update Review' : 'Submit Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please write a review comment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.existingReview != null) {
        // Update existing review
        await _reviewController.updateReview(
          productId: widget.productId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );
      } else {
        // Add new review
        await _reviewController.addReview(
          productId: widget.productId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );
      }

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the controller
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

