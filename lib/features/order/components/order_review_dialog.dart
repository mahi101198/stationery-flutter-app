import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/product/controllers/review_controller.dart';
import 'package:rps_stationery/data/repositories/review_repo.dart';

class OrderReviewDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final String? productImage;

  const OrderReviewDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.productImage,
  });

  @override
  State<OrderReviewDialog> createState() => _OrderReviewDialogState();
}

class _OrderReviewDialogState extends State<OrderReviewDialog> {
  late ReviewController _reviewController;
  
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _rating = 5; // Default to 5 stars
    _commentController = TextEditingController();
    
    // Initialize ReviewController safely
    try {
      _reviewController = Get.find<ReviewController>();
    } catch (e) {
      // If ReviewController is not found, create a new instance
      // Also ensure ReviewRepo is available
      if (!Get.isRegistered<ReviewRepo>()) {
        Get.put(ReviewRepo(), permanent: true);
      }
      _reviewController = Get.put(ReviewController());
    }
    
    // Load existing review if user has already reviewed this product
    _loadExistingReview();
  }
  
  Future<void> _loadExistingReview() async {
    try {
      await _reviewController.loadProductReviews(widget.productId);
      
      if (_reviewController.userReview != null) {
        setState(() {
          _isEditing = true;
          _rating = _reviewController.userReview!.rating;
          _commentController.text = _reviewController.userReview!.comment;
        });
      }
    } catch (e) {
      // If there's an error loading reviews, continue with new review
      print('Error loading existing review: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Iconsax.star,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Review' : 'Review Product',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Iconsax.close_circle),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Product Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.productImage != null && widget.productImage!.isNotEmpty
                            ? Image.network(
                                widget.productImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Iconsax.image,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              )
                            : Icon(
                                Iconsax.image,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Name
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Rating Section
              Text(
                'How would you rate this product?',
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
              
              const SizedBox(height: 16),
              
              // Comment Section
              Text(
                'Share your experience',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Comment TextField
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell others about your experience with this product...',
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
              
              const SizedBox(height: 16),
              
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                          : Text(_isEditing ? 'Update Review' : 'Submit Review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      // Load product reviews first to ensure controller is properly initialized
      await _reviewController.loadProductReviews(widget.productId);
      
      if (_isEditing) {
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
      // Show error message to user
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to submit review: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
