import 'package:cloud_firestore/cloud_firestore.dart';

/// Home Section Item Model - Represents an item (SKU) in a home section
/// Firestore path: home_sections/{section_id}/items/{sku_id}
class HomeSectionItemModel {
  final String skuId;
  final String productId;
  final String categoryId;
  final String subcategoryId;
  final int rank;
  final String name;
  final String imageUrl;
  final double mrp;
  final double price;
  final double discountPercent;
  final String currencyCode;
  final double? priceOverride;
  final String? discountLabel;
  final String? badgeText;
  final String? badgeColor;
  final DateTime addedAt;
  final DateTime updatedAt;
  final bool isActive;

  const HomeSectionItemModel({
    required this.skuId,
    required this.productId,
    required this.categoryId,
    required this.subcategoryId,
    required this.rank,
    required this.name,
    required this.imageUrl,
    required this.mrp,
    required this.price,
    required this.discountPercent,
    required this.currencyCode,
    this.priceOverride,
    this.discountLabel,
    this.badgeText,
    this.badgeColor,
    required this.addedAt,
    required this.updatedAt,
    required this.isActive,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Get effective price (use override if available)
  double get effectivePrice => priceOverride ?? price;

  /// Check if item has discount
  bool get hasDiscount => discountPercent > 0 || (priceOverride != null && priceOverride! < mrp);

  /// Get formatted price with currency
  String get formattedPrice => '₹${effectivePrice.toStringAsFixed(0)}';

  /// Get formatted MRP with currency
  String get formattedMrp => '₹${mrp.toStringAsFixed(0)}';

  /// Get effective discount percentage
  double get effectiveDiscountPercent {
    if (priceOverride != null && mrp > 0) {
      return ((mrp - priceOverride!) / mrp) * 100;
    }
    return discountPercent;
  }

  /// Get discount label (use custom or generate from percentage)
  String get displayDiscountLabel {
    if (discountLabel != null && discountLabel!.isNotEmpty) {
      return discountLabel!;
    }
    if (hasDiscount) {
      return '${effectiveDiscountPercent.round()}% OFF';
    }
    return '';
  }

  /// Check if item has badge
  bool get hasBadge => badgeText != null && badgeText!.isNotEmpty;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create from Firestore document
  factory HomeSectionItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return HomeSectionItemModel(
      skuId: data['sku_id'] ?? doc.id,
      productId: data['product_id'] ?? '',
      categoryId: data['category_id'] ?? '',
      subcategoryId: data['subcategory_id'] ?? '',
      rank: data['rank'] ?? 0,
      name: data['name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      mrp: (data['mrp'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (data['discount_percent'] as num?)?.toDouble() ?? 0.0,
      currencyCode: data['currency_code'] ?? 'INR',
      priceOverride: (data['price_override'] as num?)?.toDouble(),
      discountLabel: data['discount_label'],
      badgeText: data['badge_text'],
      badgeColor: data['badge_color'],
      addedAt: _parseTimestamp(data['added_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updated_at']) ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }

  /// Create from Map
  factory HomeSectionItemModel.fromMap(Map<String, dynamic> data) {
    return HomeSectionItemModel(
      skuId: data['sku_id'] ?? '',
      productId: data['product_id'] ?? '',
      categoryId: data['category_id'] ?? '',
      subcategoryId: data['subcategory_id'] ?? '',
      rank: data['rank'] ?? 0,
      name: data['name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      mrp: (data['mrp'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (data['discount_percent'] as num?)?.toDouble() ?? 0.0,
      currencyCode: data['currency_code'] ?? 'INR',
      priceOverride: (data['price_override'] as num?)?.toDouble(),
      discountLabel: data['discount_label'],
      badgeText: data['badge_text'],
      badgeColor: data['badge_color'],
      addedAt: _parseTimestamp(data['added_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updated_at']) ?? DateTime.now(),
      isActive: data['is_active'] ?? true,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Parse timestamp from Firestore (handles both Timestamp and number)
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      // Unix timestamp in seconds
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'sku_id': skuId,
      'product_id': productId,
      'rank': rank,
      'name': name,
      'image_url': imageUrl,
      'mrp': mrp,
      'price': price,
      'discount_percent': discountPercent,
      'currency_code': currencyCode,
      'price_override': priceOverride,
      'discount_label': discountLabel,
      'badge_text': badgeText,
      'badge_color': badgeColor,
      'added_at': Timestamp.fromDate(addedAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'HomeSectionItemModel(skuId: $skuId, name: $name, price: $formattedPrice, rank: $rank)';
  }
}
