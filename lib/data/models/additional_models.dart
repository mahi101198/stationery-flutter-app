import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model following enterprise schema
class ReviewModel {
  final String reviewId;
  final String userId;
  final String productId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return ReviewModel(
      reviewId: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      rating: (data['rating'] ?? 5.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
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
}

/// Coupon model following enterprise schema
enum DiscountType { flat, percentage }
enum CouponStatus { active, expired }

class CouponModel {
  final String couponId;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final DateTime expiryDate;
  final CouponStatus status;

  const CouponModel({
    required this.couponId,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.expiryDate,
    required this.status,
  });

  /// Check if coupon is valid
  bool get isValid => status == CouponStatus.active && expiryDate.isAfter(DateTime.now());

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'couponId': couponId,
      'code': code,
      'description': description,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.name,
    };
  }

  /// Create from Firestore document
  factory CouponModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return CouponModel(
      couponId: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: _parseDiscountType(data['discountType']),
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      minOrderAmount: (data['minOrderAmount'] ?? 0.0).toDouble(),
      expiryDate: _parseTimestamp(data['expiryDate']),
      status: _parseCouponStatus(data['status']),
    );
  }

  /// Helper method to parse discount type
  static DiscountType _parseDiscountType(dynamic type) {
    if (type == null) return DiscountType.flat;
    
    switch (type.toString().toLowerCase()) {
      case 'percentage':
        return DiscountType.percentage;
      default:
        return DiscountType.flat;
    }
  }

  /// Helper method to parse coupon status
  static CouponStatus _parseCouponStatus(dynamic status) {
    if (status == null) return CouponStatus.active;
    
    switch (status.toString().toLowerCase()) {
      case 'expired':
        return CouponStatus.expired;
      default:
        return CouponStatus.active;
    }
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
      other is CouponModel &&
          runtimeType == other.runtimeType &&
          couponId == other.couponId;

  @override
  int get hashCode => couponId.hashCode;
}

/// Referral model following enterprise schema
enum ReferralStatus { pending, rewarded, expired }

class ReferralModel {
  final String referralId;
  final String referrerUserId;
  final String referredUserId;
  final double rewardAmount;
  final ReferralStatus status;
  final DateTime createdAt;

  const ReferralModel({
    required this.referralId,
    required this.referrerUserId,
    required this.referredUserId,
    required this.rewardAmount,
    required this.status,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'referralId': referralId,
      'referrerUserId': referrerUserId,
      'referredUserId': referredUserId,
      'rewardAmount': rewardAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory ReferralModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return ReferralModel(
      referralId: doc.id,
      referrerUserId: data['referrerUserId'] ?? '',
      referredUserId: data['referredUserId'] ?? '',
      rewardAmount: (data['rewardAmount'] ?? 0.0).toDouble(),
      status: _parseReferralStatus(data['status']),
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Helper method to parse referral status
  static ReferralStatus _parseReferralStatus(dynamic status) {
    if (status == null) return ReferralStatus.pending;
    
    switch (status.toString().toLowerCase()) {
      case 'rewarded':
        return ReferralStatus.rewarded;
      case 'expired':
        return ReferralStatus.expired;
      default:
        return ReferralStatus.pending;
    }
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
      other is ReferralModel &&
          runtimeType == other.runtimeType &&
          referralId == other.referralId;

  @override
  int get hashCode => referralId.hashCode;
}

/// App Settings model following enterprise schema
/// Unified model for all app configuration from 'settings' collection
class AppSettingsModel {
  // App Info
  final String? appName;
  final String? appVersion;
  final String? currency;
  final String? currencySymbol;
  
  // Delivery & Pricing (tax is already included in product prices)
  final double? deliveryFee;
  final double? freeDeliveryAbove;
  
  // Contact Info
  final String? supportPhone;
  final String? supportEmail;
  
  // Referral Settings
  final double? referrerRewardValue;
  final double? refereeRewardValue;
  final double? minOrderAmount;
  final double? minWithdrawalAmount;
  final bool? isReferralActive;
  
  // Razorpay Config (public key only)
  final String? razorpayKeyId;
  
  // App Download Link
  final String? appDownloadLink;
  
  // Available Pincodes
  final List<String>? availablePincodes;
  
  // Metadata
  final DateTime lastUpdated;

  const AppSettingsModel({
    this.appName,
    this.appVersion,
    this.currency,
    this.currencySymbol,
    this.deliveryFee,
    this.freeDeliveryAbove,
    this.supportPhone,
    this.supportEmail,
    this.referrerRewardValue,
    this.refereeRewardValue,
    this.minOrderAmount,
    this.minWithdrawalAmount,
    this.isReferralActive,
    this.razorpayKeyId,
    this.appDownloadLink,
    this.availablePincodes,
    required this.lastUpdated,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      if (appName != null) 'appName': appName,
      if (appVersion != null) 'appVersion': appVersion,
      if (currency != null) 'currency': currency,
      if (currencySymbol != null) 'currencySymbol': currencySymbol,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (freeDeliveryAbove != null) 'freeDeliveryAbove': freeDeliveryAbove,
      if (supportPhone != null) 'supportPhone': supportPhone,
      if (supportEmail != null) 'supportEmail': supportEmail,
      if (referrerRewardValue != null) 'referrerRewardValue': referrerRewardValue,
      if (refereeRewardValue != null) 'refereeRewardValue': refereeRewardValue,
      if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
      if (minWithdrawalAmount != null) 'minWithdrawalAmount': minWithdrawalAmount,
      if (isReferralActive != null) 'isReferralActive': isReferralActive,
      if (razorpayKeyId != null) 'razorpayKeyId': razorpayKeyId,
      if (appDownloadLink != null) 'appDownloadLink': appDownloadLink,
      if (availablePincodes != null) 'availablePincodes': availablePincodes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create from Firestore document
  factory AppSettingsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return AppSettingsModel(
      appName: data['appName'],
      appVersion: data['appVersion'],
      currency: data['currency'],
      currencySymbol: data['currencySymbol'],
      deliveryFee: data['deliveryFee']?.toDouble(),
      freeDeliveryAbove: data['freeDeliveryAbove']?.toDouble(),
      supportPhone: data['supportPhone'],
      supportEmail: data['supportEmail'],
      referrerRewardValue: data['referrerRewardValue']?.toDouble(),
      refereeRewardValue: data['refereeRewardValue']?.toDouble(),
      minOrderAmount: data['minOrderAmount']?.toDouble(),
      minWithdrawalAmount: data['minWithdrawalAmount']?.toDouble(),
      isReferralActive: data['isReferralActive'],
      razorpayKeyId: data['razorpayKeyId'],
      appDownloadLink: data['appDownloadLink'],
      availablePincodes: data['availablePincodes'] != null 
          ? List<String>.from(data['availablePincodes'])
          : null,
      lastUpdated: _parseTimestamp(data['lastUpdated']),
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
  
  /// Create a copy with updated fields
  AppSettingsModel copyWith({
    String? appName,
    String? appVersion,
    String? currency,
    String? currencySymbol,
    double? deliveryFee,
    double? freeDeliveryAbove,
    String? supportPhone,
    String? supportEmail,
    double? referrerRewardValue,
    double? refereeRewardValue,
    double? minOrderAmount,
    double? minWithdrawalAmount,
    bool? isReferralActive,
    String? razorpayKeyId,
    String? appDownloadLink,
    List<String>? availablePincodes,
    DateTime? lastUpdated,
  }) {
    return AppSettingsModel(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      supportPhone: supportPhone ?? this.supportPhone,
      supportEmail: supportEmail ?? this.supportEmail,
      referrerRewardValue: referrerRewardValue ?? this.referrerRewardValue,
      refereeRewardValue: refereeRewardValue ?? this.refereeRewardValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      minWithdrawalAmount: minWithdrawalAmount ?? this.minWithdrawalAmount,
      isReferralActive: isReferralActive ?? this.isReferralActive,
      razorpayKeyId: razorpayKeyId ?? this.razorpayKeyId,
      appDownloadLink: appDownloadLink ?? this.appDownloadLink,
      availablePincodes: availablePincodes ?? this.availablePincodes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Banner model following enterprise schema
class BannerModel {
  final String bannerId;
  final String imageUrl;
  final String? redirectUrl;
  final bool active;
  final int priority;
  final DateTime validFrom;
  final DateTime validTill;
  final double viewChangeTimeSeconds;
  
  // Compatibility getter
  String get image => imageUrl;

  const BannerModel({
    required this.bannerId,
    required this.imageUrl,
    this.redirectUrl,
    required this.active,
    required this.priority,
    required this.validFrom,
    required this.validTill,
    this.viewChangeTimeSeconds = 0.5,
  });

  /// Check if banner is currently valid
  bool get isValid {
    final now = DateTime.now();
    return active && now.isAfter(validFrom) && now.isBefore(validTill);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bannerId': bannerId,
      'imageUrl': imageUrl,
      'redirectUrl': redirectUrl,
      'active': active,
      'priority': priority,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTill': Timestamp.fromDate(validTill),
      'view_change_time': viewChangeTimeSeconds,
    };
  }

  /// Create from Firestore document
  factory BannerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return BannerModel(
      bannerId: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      redirectUrl: data['redirectUrl'],
      active: data['active'] ?? true,
      priority: (data['priority'] ?? 0).toInt(),
      validFrom: _parseTimestamp(data['validFrom']),
      validTill: _parseTimestamp(data['validTill']),
      viewChangeTimeSeconds: _parseDuration(data['view_change_time'], 0.5),
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

  static double _parseDuration(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) {
      final v = value.toDouble();
      if (v <= 0) return fallback;
      return v;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed <= 0) return fallback;
      return parsed;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BannerModel &&
          runtimeType == other.runtimeType &&
          bannerId == other.bannerId;

  @override
  int get hashCode => bannerId.hashCode;
}

/// Promotion model following enterprise schema
class PromotionModel {
  final String promoId;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime validFrom;
  final DateTime validTill;
  final bool active;

  const PromotionModel({
    required this.promoId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.validFrom,
    required this.validTill,
    required this.active,
  });

  /// Check if promotion is currently valid
  bool get isValid {
    final now = DateTime.now();
    return active && now.isAfter(validFrom) && now.isBefore(validTill);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'promoId': promoId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTill': Timestamp.fromDate(validTill),
      'active': active,
    };
  }

  /// Create from Firestore document
  factory PromotionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return PromotionModel(
      promoId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      validFrom: _parseTimestamp(data['validFrom']),
      validTill: _parseTimestamp(data['validTill']),
      active: data['active'] ?? true,
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
      other is PromotionModel &&
          runtimeType == other.runtimeType &&
          promoId == other.promoId;

  @override
  int get hashCode => promoId.hashCode;
}

/// Log model following enterprise schema (optional)
enum LogEventType {
  login,
  add_to_cart,
  checkout,
  order_placed,
  payment_success,
  payment_failed
}

class LogModel {
  final String eventId;
  final String? userId;
  final LogEventType eventType;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const LogModel({
    required this.eventId,
    this.userId,
    required this.eventType,
    this.metadata,
    required this.timestamp,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventType': eventType.name,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create from Firestore document
  factory LogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return LogModel(
      eventId: data['eventId'] ?? doc.id,
      userId: data['userId'],
      eventType: _parseEventType(data['eventType']),
      metadata: data['metadata'] as Map<String, dynamic>?,
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  /// Helper method to parse event type
  static LogEventType _parseEventType(dynamic type) {
    if (type == null) return LogEventType.login;
    
    switch (type.toString().toLowerCase()) {
      case 'add_to_cart':
        return LogEventType.add_to_cart;
      case 'checkout':
        return LogEventType.checkout;
      case 'order_placed':
        return LogEventType.order_placed;
      case 'payment_success':
        return LogEventType.payment_success;
      case 'payment_failed':
        return LogEventType.payment_failed;
      default:
        return LogEventType.login;
    }
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
      other is LogModel &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}
