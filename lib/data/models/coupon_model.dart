import 'package:cloud_firestore/cloud_firestore.dart';

/// Coupon/Promo Code Model
class CouponModel {
  final String couponId;
  final String code;
  final String title;
  final String description;
  final String type; // 'percentage' or 'flat'
  final double value; // Discount value (percentage or flat amount)
  final double minOrderValue;
  final double maxDiscount; // Max discount for percentage type
  final int maxUsage;
  final int usedCount;
  final bool isActive;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> applicableCategories;
  final List<String> applicableProducts;

  const CouponModel({
    required this.couponId,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.maxUsage,
    required this.usedCount,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
    required this.updatedAt,
    this.applicableCategories = const [],
    this.applicableProducts = const [],
  });

  /// Create from Firestore document
  factory CouponModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Helper to safely convert list items to strings
    List<String> _parseStringList(dynamic listData) {
      if (listData == null) return [];
      if (listData is! List) return [];
      
      return listData.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map) {
          // Try to extract ID from map
          if (item.containsKey('id')) {
            return item['id'].toString();
          } else if (item.containsKey('categoryId')) {
            return item['categoryId'].toString();
          } else if (item.containsKey('productId')) {
            return item['productId'].toString();
          } else {
            // Use first value
            return item.values.first.toString();
          }
        } else {
          return item.toString();
        }
      }).toList();
    }
    
    return CouponModel(
      couponId: doc.id,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'percentage',
      value: (data['value'] ?? 0).toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 0).toDouble(),
      maxDiscount: (data['maxDiscount'] ?? 0).toDouble(),
      maxUsage: (data['maxUsage'] ?? 0).toInt(),
      usedCount: (data['usedCount'] ?? 0).toInt(),
      isActive: data['isActive'] ?? false,
      validFrom: _parseTimestamp(data['validFrom']),
      validUntil: _parseTimestamp(data['validUntil']),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      applicableCategories: _parseStringList(data['applicableCategories']),
      applicableProducts: _parseStringList(data['applicableProducts']),
    );
  }

  /// Parse timestamp from Firestore
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type,
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'maxUsage': maxUsage,
      'usedCount': usedCount,
      'isActive': isActive,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'applicableCategories': applicableCategories,
      'applicableProducts': applicableProducts,
    };
  }

  /// Calculate discount amount for given order total
  double calculateDiscount(double orderTotal) {
    if (type == 'percentage') {
      final discount = (orderTotal * value) / 100;
      return discount > maxDiscount ? maxDiscount : discount;
    } else {
      // Flat discount
      return value;
    }
  }

  /// Check if coupon is valid
  bool isValid() {
    final now = DateTime.now();
    // maxUsage = 0 means unlimited usage
    final hasUsageLeft = maxUsage == 0 || usedCount < maxUsage;
    return isActive &&
        hasUsageLeft &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil);
  }

  /// Check if order meets minimum value requirement
  bool meetsMinimumOrder(double orderTotal) {
    return orderTotal >= minOrderValue;
  }

  /// Check if coupon is applicable to products/categories
  bool isApplicableToCart({
    List<String>? productIds,
    List<String>? categoryIds,
  }) {
    // If no restrictions, applicable to all
    if (applicableProducts.isEmpty && applicableCategories.isEmpty) {
      return true;
    }

    // Check products
    if (applicableProducts.isNotEmpty && productIds != null) {
      for (final productId in productIds) {
        if (applicableProducts.contains(productId)) {
          return true;
        }
      }
    }

    // Check categories
    if (applicableCategories.isNotEmpty && categoryIds != null) {
      for (final categoryId in categoryIds) {
        if (applicableCategories.contains(categoryId)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get discount display text
  String getDiscountText() {
    if (type == 'percentage') {
      return '${value.toInt()}% OFF (Max ₹${maxDiscount.toInt()})';
    } else {
      return '₹${value.toInt()} OFF';
    }
  }

  /// Get validity display text
  String getValidityText() {
    return 'Valid till ${_formatDate(validUntil)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Copy with method
  CouponModel copyWith({
    String? couponId,
    String? code,
    String? title,
    String? description,
    String? type,
    double? value,
    double? minOrderValue,
    double? maxDiscount,
    int? maxUsage,
    int? usedCount,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? applicableCategories,
    List<String>? applicableProducts,
  }) {
    return CouponModel(
      couponId: couponId ?? this.couponId,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      maxUsage: maxUsage ?? this.maxUsage,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      applicableProducts: applicableProducts ?? this.applicableProducts,
    );
  }

  @override
  String toString() {
    return 'CouponModel(code: $code, type: $type, value: $value, isActive: $isActive)';
  }
}


