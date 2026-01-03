import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class ReviewRepository extends GetxController {
  static ReviewRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<T> safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("ReviewRepository unexpected error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Add a new review
  Future<void> addReview({
    required String productId,
    required String orderId,
    required double rating,
    required String title,
    required String comment,
    List<String>? images,
  }) async {
    return safeCall(() async {
      // Check if user already reviewed this product
      final existingReview = await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .get();

      if (existingReview.exists) {
        throw 'You have already reviewed this product';
      }

      // Get user info
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data();

      final reviewData = {
        'userId': userId,
        'productId': productId,
        'orderId': orderId,
        'userName': '${userData?['firstName'] ?? 'Anonymous'} ${userData?['lastName'] ?? ''}',
        'userAvatar': userData?['profilePictureUrl'],
        'rating': rating,
        'title': title,
        'comment': comment,
        'images': images ?? [],
        'isVerifiedPurchase': true, // Since we have orderId
        'helpfulCount': 0,
        'isReported': false,
        'isHidden': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add review to product subcollection
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .set(reviewData);

      // Add review to global reviews collection
      await _db.collection('reviews').add(reviewData);

      // Update product average rating
      await _updateProductRating(productId);
    });
  }

  /// Update existing review
  Future<void> updateReview({
    required String productId,
    required String title,
    required String comment,
    List<String>? images,
  }) async {
    return safeCall(() async {
      final updateData = {
        'title': title,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (images != null) {
        updateData['images'] = images;
      }

      // Update in product subcollection
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .update(updateData);

      // Update in global reviews collection
      final globalReviews = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in globalReviews.docs) {
        await doc.reference.update(updateData);
      }
    });
  }

  /// Delete review
  Future<void> deleteReview(String productId) async {
    return safeCall(() async {
      // Delete from product subcollection
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .delete();

      // Delete from global reviews collection
      final globalReviews = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in globalReviews.docs) {
        await doc.reference.delete();
      }

      // Update product average rating
      await _updateProductRating(productId);
    });
  }

  /// Get reviews for a product
  Future<List<Map<String, dynamic>>> getProductReviews(
    String productId, {
    int? limit,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) async {
    return safeCall(() async {
      Query query = _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy(orderBy!, descending: descending);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    });
  }

  /// Get user's reviews
  Future<List<Map<String, dynamic>>> getUserReviews() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// Get user's review for a specific product
  Future<Map<String, dynamic>?> getUserProductReview(String productId) async {
    return safeCall(() async {
      final doc = await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    });
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String productId, String reviewUserId) async {
    return safeCall(() async {
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewUserId)
          .update({
            'helpfulCount': FieldValue.increment(1),
          });

      // Update in global reviews collection
      final globalReviews = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: reviewUserId)
          .get();

      for (var doc in globalReviews.docs) {
        await doc.reference.update({
          'helpfulCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// Report review
  Future<void> reportReview(String productId, String reviewUserId, String reason) async {
    return safeCall(() async {
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewUserId)
          .update({
            'isReported': true,
            'reportReason': reason,
            'reportedBy': userId,
            'reportedAt': FieldValue.serverTimestamp(),
          });
    });
  }

  /// Get review statistics for a product
  Future<Map<String, dynamic>> getProductReviewStats(String productId) async {
    return safeCall(() async {
      final reviews = await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .get();

      if (reviews.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }

      int totalReviews = reviews.docs.length;
      double totalRating = 0;
      Map<String, int> ratingDistribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (var doc in reviews.docs) {
        final rating = (doc.data()['rating'] as num).toDouble();
        totalRating += rating;
        ratingDistribution[rating.floor().toString()] = 
            (ratingDistribution[rating.floor().toString()] ?? 0) + 1;
      }

      double averageRating = totalRating / totalReviews;

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    });
  }

  /// Check if user can review a product (must have ordered it)
  Future<bool> canUserReviewProduct(String productId) async {
    return safeCall(() async {
      // Check if user has ordered this product
      final orders = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('orderStatus', isEqualTo: 'delivered')
          .get();

      for (var order in orders.docs) {
        final items = order.data()['items'] as List;
        if (items.any((item) => item['productId'] == productId)) {
          return true;
        }
      }

      return false;
    });
  }

  /// Get reviews that need moderation (Admin only)
  Future<List<Map<String, dynamic>>> getReportedReviews() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('reviews')
          .where('isReported', isEqualTo: true)
          .where('isHidden', isEqualTo: false)
          .orderBy('reportedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// Hide review (Admin only)
  Future<void> hideReview(String reviewId, bool hide) async {
    return safeCall(() async {
      await _db.collection('reviews').doc(reviewId).update({
        'isHidden': hide,
        'hiddenAt': hide ? FieldValue.serverTimestamp() : null,
      });
    });
  }

  /// Update product's average rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final stats = await getProductReviewStats(productId);
      
      await _db.collection('products').doc(productId).update({
        'averageRating': stats['averageRating'],
        'totalReviews': stats['totalReviews'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error updating product rating: $e');
    }
  }

  /// Get reviews stream for real-time updates
  Stream<List<Map<String, dynamic>>> getProductReviewsStream(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    }).handleError((error) {
      log("ReviewsStream error -> $error", error: error);
      throw 'Error loading reviews. Please try again';
    });
  }
}
