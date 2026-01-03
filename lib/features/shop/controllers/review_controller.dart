import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rps_stationery/data/repositories/review_repository.dart';
import 'package:rps_stationery/utils/loaders/full_screen_loader.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final reviewRepository = Get.put(ReviewRepository());
  final ImagePicker imagePicker = ImagePicker();
  
  // Observable variables
  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> productReviews = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> userReviews = <Map<String, dynamic>>[].obs;
  Rx<Map<String, dynamic>?> userProductReview = Rx<Map<String, dynamic>?>(null);
  RxMap<String, dynamic> reviewStats = <String, dynamic>{}.obs;
  
  // Form controllers
  final titleController = TextEditingController();
  final commentController = TextEditingController();
  RxDouble rating = 0.0.obs;
  RxList<File> reviewImages = <File>[].obs;
  RxList<String> reviewImageUrls = <String>[].obs;
  
  // Current state
  RxString currentProductId = ''.obs;
  RxString currentOrderId = ''.obs;
  RxBool isEditMode = false.obs;

  @override
  void onClose() {
    titleController.dispose();
    commentController.dispose();
    super.onClose();
  }

  /// Initialize review form for a product
  void initializeReviewForm({
    required String productId,
    required String orderId,
    Map<String, dynamic>? existingReview,
  }) {
    currentProductId.value = productId;
    currentOrderId.value = orderId;
    
    if (existingReview != null) {
      // Edit mode
      isEditMode.value = true;
      titleController.text = existingReview['title'] ?? '';
      commentController.text = existingReview['comment'] ?? '';
      rating.value = (existingReview['rating'] as num?)?.toDouble() ?? 0.0;
      
      final images = existingReview['images'] as List<dynamic>?;
      if (images != null) {
        reviewImageUrls.value = images.cast<String>();
      }
    } else {
      // Add mode
      isEditMode.value = false;
      clearForm();
    }
    
    // Load existing review if available
    getUserProductReview(productId);
  }

  /// Clear review form
  void clearForm() {
    titleController.clear();
    commentController.clear();
    rating.value = 0.0;
    reviewImages.clear();
    reviewImageUrls.clear();
  }

  /// Add or update review
  Future<void> submitReview() async {
    try {
      // Validate form
      if (rating.value == 0) {
        TLoaders.errorSnackBar(
          title: 'Rating Required',
          message: 'Please select a rating for this product.',
        );
        return;
      }

      if (titleController.text.trim().isEmpty) {
        TLoaders.errorSnackBar(
          title: 'Title Required',
          message: 'Please provide a title for your review.',
        );
        return;
      }

      if (commentController.text.trim().isEmpty) {
        TLoaders.errorSnackBar(
          title: 'Comment Required',
          message: 'Please write your review comment.',
        );
        return;
      }

      TFullScreenLoader.openLoadingDialog('Submitting your review...');

      // Upload new images if any
      List<String> allImageUrls = [...reviewImageUrls];
      if (reviewImages.isNotEmpty) {
        final newImageUrls = await uploadReviewImages();
        allImageUrls.addAll(newImageUrls);
      }

      if (isEditMode.value) {
        // Update existing review
        await reviewRepository.updateReview(
          productId: currentProductId.value,
          title: titleController.text.trim(),
          comment: commentController.text.trim(),
          images: allImageUrls.isNotEmpty ? allImageUrls : null,
        );

        TLoaders.successSnackBar(
          title: 'Review Updated',
          message: 'Your review has been updated successfully.',
        );
      } else {
        // Add new review
        await reviewRepository.addReview(
          productId: currentProductId.value,
          orderId: currentOrderId.value,
          rating: rating.value,
          title: titleController.text.trim(),
          comment: commentController.text.trim(),
          images: allImageUrls.isNotEmpty ? allImageUrls : null,
        );

        TLoaders.successSnackBar(
          title: 'Review Added',
          message: 'Thank you for your review!',
        );
      }

      // Refresh data
      await Future.wait([
        getProductReviews(currentProductId.value),
        getProductReviewStats(currentProductId.value),
        getUserProductReview(currentProductId.value),
      ]);

      // Clear form and close
      clearForm();
      Get.back();

    } catch (e) {
      log('Error submitting review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      TFullScreenLoader.stopLoading();
    }
  }

  /// Delete review
  Future<void> deleteReview(String productId) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Review'),
          content: const Text(
            'Are you sure you want to delete your review? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      TFullScreenLoader.openLoadingDialog('Deleting review...');

      await reviewRepository.deleteReview(productId);

      TLoaders.successSnackBar(
        title: 'Review Deleted',
        message: 'Your review has been deleted successfully.',
      );

      // Refresh data
      await Future.wait([
        getProductReviews(productId),
        getProductReviewStats(productId),
      ]);
      
      userProductReview.value = null;

    } catch (e) {
      log('Error deleting review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      TFullScreenLoader.stopLoading();
    }
  }

  /// Get reviews for a product
  Future<void> getProductReviews(String productId, {int? limit}) async {
    try {
      isLoading.value = true;
      final reviews = await reviewRepository.getProductReviews(
        productId,
        limit: limit,
      );
      productReviews.value = reviews;
    } catch (e) {
      log('Error getting product reviews: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load reviews. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get user's reviews
  Future<void> getUserReviews() async {
    try {
      isLoading.value = true;
      final reviews = await reviewRepository.getUserReviews();
      userReviews.value = reviews;
    } catch (e) {
      log('Error getting user reviews: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load your reviews. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get user's review for a specific product
  Future<void> getUserProductReview(String productId) async {
    try {
      final review = await reviewRepository.getUserProductReview(productId);
      userProductReview.value = review;
    } catch (e) {
      log('Error getting user product review: $e');
      userProductReview.value = null;
    }
  }

  /// Get review statistics for a product
  Future<void> getProductReviewStats(String productId) async {
    try {
      final stats = await reviewRepository.getProductReviewStats(productId);
      reviewStats.value = stats;
    } catch (e) {
      log('Error getting review stats: $e');
      reviewStats.clear();
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String productId, String reviewUserId) async {
    try {
      await reviewRepository.markReviewHelpful(productId, reviewUserId);
      
      // Update the review in the local list
      final reviewIndex = productReviews.indexWhere(
        (review) => review['userId'] == reviewUserId,
      );
      
      if (reviewIndex != -1) {
        final updatedReview = Map<String, dynamic>.from(productReviews[reviewIndex]);
        updatedReview['helpfulCount'] = (updatedReview['helpfulCount'] as int) + 1;
        productReviews[reviewIndex] = updatedReview;
      }

      TLoaders.successSnackBar(
        title: 'Thank You',
        message: 'You found this review helpful.',
      );
    } catch (e) {
      log('Error marking review helpful: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark review as helpful. Please try again.',
      );
    }
  }

  /// Report review
  Future<void> reportReview(String productId, String reviewUserId, String reason) async {
    try {
      await reviewRepository.reportReview(productId, reviewUserId, reason);
      
      TLoaders.successSnackBar(
        title: 'Review Reported',
        message: 'Thank you for reporting. We will review this content.',
      );
    } catch (e) {
      log('Error reporting review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to report review. Please try again.',
      );
    }
  }

  /// Check if user can review a product
  Future<bool> canUserReviewProduct(String productId) async {
    try {
      return await reviewRepository.canUserReviewProduct(productId);
    } catch (e) {
      log('Error checking if user can review: $e');
      return false;
    }
  }

  /// Pick images for review
  Future<void> pickReviewImages() async {
    try {
      final List<XFile> selectedImages = await imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (selectedImages.isNotEmpty) {
        // Limit to 5 images total
        final currentImageCount = reviewImages.length + reviewImageUrls.length;
        final availableSlots = 5 - currentImageCount;
        
        if (availableSlots <= 0) {
          TLoaders.warningSnackBar(
            title: 'Image Limit',
            message: 'You can add maximum 5 images per review.',
          );
          return;
        }

        final imagesToAdd = selectedImages.take(availableSlots).toList();
        
        for (final image in imagesToAdd) {
          reviewImages.add(File(image.path));
        }

        if (selectedImages.length > availableSlots) {
          TLoaders.warningSnackBar(
            title: 'Some Images Skipped',
            message: 'Only ${imagesToAdd.length} images were added due to the 5 image limit.',
          );
        }
      }
    } catch (e) {
      log('Error picking images: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to pick images. Please try again.',
      );
    }
  }

  /// Remove review image
  void removeReviewImage({File? localFile, String? networkUrl}) {
    if (localFile != null) {
      reviewImages.remove(localFile);
    } else if (networkUrl != null) {
      reviewImageUrls.remove(networkUrl);
    }
  }

  /// Upload review images to Firebase Storage
  Future<List<String>> uploadReviewImages() async {
    final List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < reviewImages.length; i++) {
        final file = reviewImages[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('reviews')
            .child(currentProductId.value)
            .child(fileName);

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }
      
      return uploadedUrls;
    } catch (e) {
      log('Error uploading review images: $e');
      throw 'Failed to upload images. Please try again.';
    }
  }

  /// Get product reviews stream
  Stream<List<Map<String, dynamic>>> getProductReviewsStream(String productId) {
    return reviewRepository.getProductReviewsStream(productId);
  }

  /// Show review sort options
  void showSortOptions(String productId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              'Most Recent',
              () => _sortReviews(productId, 'createdAt', true),
            ),
            _buildSortOption(
              'Oldest First',
              () => _sortReviews(productId, 'createdAt', false),
            ),
            _buildSortOption(
              'Highest Rating',
              () => _sortReviews(productId, 'rating', true),
            ),
            _buildSortOption(
              'Lowest Rating',
              () => _sortReviews(productId, 'rating', false),
            ),
            _buildSortOption(
              'Most Helpful',
              () => _sortReviews(productId, 'helpfulCount', true),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Widget _buildSortOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Get.back();
        onTap();
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _sortReviews(String productId, String orderBy, bool descending) async {
    try {
      isLoading.value = true;
      final reviews = await reviewRepository.getProductReviews(
        productId,
        orderBy: orderBy,
        descending: descending,
      );
      productReviews.value = reviews;
    } catch (e) {
      log('Error sorting reviews: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to sort reviews. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show report dialog
  void showReportDialog(String productId, String reviewUserId) {
    final reasons = [
      'Inappropriate content',
      'Spam or fake review',
      'Offensive language',
      'Irrelevant to product',
      'Personal information',
      'Other',
    ];

    RxString selectedReason = ''.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this review?'),
            const SizedBox(height: 16),
            ...reasons.map(
              (reason) => Obx(
                () => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason.value,
                  onChanged: (value) => selectedReason.value = value ?? '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => TextButton(
              onPressed: selectedReason.value.isEmpty
                  ? null
                  : () {
                      Get.back();
                      reportReview(productId, reviewUserId, selectedReason.value);
                    },
              child: const Text('Report'),
            ),
          ),
        ],
      ),
    );
  }
}
