import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model following enterprise schema
class ReviewModel {
  final String reviewId;
  final String productId;
  final String userId;
  final int rating;
  final String comment;
  final bool isVerified;
  final bool isVisible;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.isVerified,
    required this.isVisible,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'reviewId': reviewId,
      'productId': productId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'isVerified': isVerified,
      'isVisible': isVisible,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return ReviewModel(
      reviewId: data['reviewId'] ?? doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 1).toInt(),
      comment: data['comment'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isVisible: data['isVisible'] ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Create from Map (for nested data)
  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    return ReviewModel(
      reviewId: data['reviewId'] ?? '',
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 1).toInt(),
      comment: data['comment'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isVisible: data['isVisible'] ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Create copy with optional parameter overrides
  ReviewModel copyWith({
    String? reviewId,
    String? productId,
    String? userId,
    int? rating,
    String? comment,
    bool? isVerified,
    bool? isVisible,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewModel &&
          runtimeType == other.runtimeType &&
          reviewId == other.reviewId;

  @override
  int get hashCode => reviewId.hashCode;

  @override
  String toString() => 'ReviewModel(reviewId: $reviewId, productId: $productId, rating: $rating)';
}

/// Review statistics model
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  /// Calculate review stats from a list of reviews
  factory ReviewStats.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const ReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );
    }

    final visibleReviews = reviews.where((review) => review.isVisible).toList();
    
    if (visibleReviews.isEmpty) {
      return const ReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );
    }

    final totalRating = visibleReviews.fold(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / visibleReviews.length;

    return ReviewStats(
      averageRating: double.parse(averageRating.toStringAsFixed(1)),
      totalReviews: visibleReviews.length,
      fiveStarCount: visibleReviews.where((r) => r.rating == 5).length,
      fourStarCount: visibleReviews.where((r) => r.rating == 4).length,
      threeStarCount: visibleReviews.where((r) => r.rating == 3).length,
      twoStarCount: visibleReviews.where((r) => r.rating == 2).length,
      oneStarCount: visibleReviews.where((r) => r.rating == 1).length,
    );
  }
}

