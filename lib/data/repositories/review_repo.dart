import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/review_model.dart';
import 'package:rps_stationery/data/models/order_model.dart';

/// Repository for handling review operations
class ReviewRepo extends GetxController {
  static ReviewRepo get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Safe call wrapper for error handling
  Future<T> safeCall<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      log('❌ ReviewRepo Firebase error: ${e.code} - ${e.message}', name: 'ReviewRepo');
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      log('❌ ReviewRepo unexpected error: $e', name: 'ReviewRepo');
      throw 'Something went wrong. Please try again';
    }
  }

  /// Check if user can review a product (has delivered order with this product)
  Future<bool> canUserReviewProduct(String productId) async {
    if (_currentUserId == null) return false;

    return safeCall(() async {
      log('🔍 ReviewRepo: Checking if user can review product: $productId', name: 'ReviewRepo');

      // Query orders where user has delivered items with this product
      final ordersQuery = await _db
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      for (var orderDoc in ordersQuery.docs) {
        final order = OrderModel.fromFirestore(orderDoc);
        
        // Check if order is delivered and contains the product
        if (order.isDelivered && order.deliveredProductIds.contains(productId)) {
          log('✅ ReviewRepo: User can review product $productId (found in delivered order ${order.orderId})', name: 'ReviewRepo');
          return true;
        }
      }

      log('❌ ReviewRepo: User cannot review product $productId (no delivered orders found)', name: 'ReviewRepo');
      return false;
    });
  }

  /// Get reviews for a product
  Future<List<ReviewModel>> getProductReviews(String productId, {int limit = 20}) async {
    return safeCall(() async {
      log('🔍 ReviewRepo: Fetching reviews for product: $productId', name: 'ReviewRepo');

      final reviewsQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final reviews = reviewsQuery.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      log('✅ ReviewRepo: Found ${reviews.length} reviews for product $productId', name: 'ReviewRepo');
      return reviews;
    });
  }

  /// Get review statistics for a product
  Future<ReviewStats> getProductReviewStats(String productId) async {
    return safeCall(() async {
      log('🔍 ReviewRepo: Fetching review stats for product: $productId', name: 'ReviewRepo');

      final reviewsQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('isVisible', isEqualTo: true)
          .get();

      final reviews = reviewsQuery.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      final stats = ReviewStats.fromReviews(reviews);
      log('✅ ReviewRepo: Review stats for product $productId - Avg: ${stats.averageRating}, Total: ${stats.totalReviews}', name: 'ReviewRepo');
      
      return stats;
    });
  }

  /// Add a review for a product
  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (_currentUserId == null) {
      throw 'User must be logged in to add a review';
    }

    return safeCall(() async {
      log('🔍 ReviewRepo: Adding review for product: $productId', name: 'ReviewRepo');

      // Check if user can review this product
      final canReview = await canUserReviewProduct(productId);
      if (!canReview) {
        throw 'You can only review products you have purchased and received';
      }

      // Check if user already reviewed this product
      final existingReviewQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      if (existingReviewQuery.docs.isNotEmpty) {
        throw 'You have already reviewed this product';
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw 'Rating must be between 1 and 5 stars';
      }

      // Validate comment
      if (comment.trim().isEmpty) {
        throw 'Please write a review comment';
      }

      // Create review
      final reviewId = _db.collection('reviews').doc().id;
      final review = ReviewModel(
        reviewId: reviewId,
        productId: productId,
        userId: _currentUserId!,
        rating: rating,
        comment: comment.trim(),
        isVerified: true, // Verified because user has delivered order
        isVisible: true,  // Visible by default
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _db.collection('reviews').doc(reviewId).set(review.toFirestore());

      log('✅ ReviewRepo: Successfully added review for product $productId', name: 'ReviewRepo');
    });
  }

  /// Update user's review for a product
  Future<void> updateReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (_currentUserId == null) {
      throw 'User must be logged in to update a review';
    }

    return safeCall(() async {
      log('🔍 ReviewRepo: Updating review for product: $productId', name: 'ReviewRepo');

      // Find existing review
      final existingReviewQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      if (existingReviewQuery.docs.isEmpty) {
        throw 'No review found to update';
      }

      final reviewDoc = existingReviewQuery.docs.first;
      final existingReview = ReviewModel.fromFirestore(reviewDoc);

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw 'Rating must be between 1 and 5 stars';
      }

      // Validate comment
      if (comment.trim().isEmpty) {
        throw 'Please write a review comment';
      }

      // Update review
      final updatedReview = existingReview.copyWith(
        rating: rating,
        comment: comment.trim(),
      );

      // Save to Firestore
      await reviewDoc.reference.update(updatedReview.toFirestore());

      log('✅ ReviewRepo: Successfully updated review for product $productId', name: 'ReviewRepo');
    });
  }

  /// Delete user's review for a product
  Future<void> deleteReview(String productId) async {
    if (_currentUserId == null) {
      throw 'User must be logged in to delete a review';
    }

    return safeCall(() async {
      log('🔍 ReviewRepo: Deleting review for product: $productId', name: 'ReviewRepo');

      // Find existing review
      final existingReviewQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      if (existingReviewQuery.docs.isEmpty) {
        throw 'No review found to delete';
      }

      // Delete review
      await existingReviewQuery.docs.first.reference.delete();

      log('✅ ReviewRepo: Successfully deleted review for product $productId', name: 'ReviewRepo');
    });
  }

  /// Get user's review for a product
  Future<ReviewModel?> getUserReview(String productId) async {
    if (_currentUserId == null) return null;

    return safeCall(() async {
      log('🔍 ReviewRepo: Getting user review for product: $productId', name: 'ReviewRepo');

      final reviewQuery = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      if (reviewQuery.docs.isEmpty) {
        log('❌ ReviewRepo: No review found for product $productId', name: 'ReviewRepo');
        return null;
      }

      final review = ReviewModel.fromFirestore(reviewQuery.docs.first);
      log('✅ ReviewRepo: Found user review for product $productId', name: 'ReviewRepo');
      return review;
    });
  }

  /// Get user's delivered orders (for review eligibility)
  Future<List<OrderModel>> getUserDeliveredOrders() async {
    if (_currentUserId == null) return [];

    return safeCall(() async {
      log('🔍 ReviewRepo: Getting user delivered orders', name: 'ReviewRepo');

      final ordersQuery = await _db
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final deliveredOrders = ordersQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((order) => order.isDelivered)
          .toList();

      log('✅ ReviewRepo: Found ${deliveredOrders.length} delivered orders', name: 'ReviewRepo');
      return deliveredOrders;
    });
  }
}

