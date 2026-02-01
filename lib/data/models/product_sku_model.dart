import 'package:cloud_firestore/cloud_firestore.dart';

/// Product SKU Model - Represents a single stock keeping unit with its own pricing and inventory
class ProductSKUModel {
  final String skuId;
  final Map<String, String> attributes; // e.g., {"color": "blue", "pack_size": "pack1"}
  final double price;
  final double mrp;
  final String availability; // "in_stock" | "out_of_stock" | "limited"
  final int availableQuantity;
  final int maxPerOrder; // Maximum quantity allowed per order

  const ProductSKUModel({
    required this.skuId,
    required this.attributes,
    required this.price,
    required this.mrp,
    required this.availability,
    required this.availableQuantity,
    this.maxPerOrder = 999, // Default: effectively unlimited
  });

  /// Check if SKU has discount
  bool get hasDiscount => mrp > price;

  /// Get discount percentage
  double get discountPercentage => hasDiscount ? ((mrp - price) / mrp * 100) : 0.0;

  /// Check if SKU is available for purchase
  bool get isAvailable => availability == 'in_stock' && availableQuantity > 0;

  /// Check if SKU is out of stock
  bool get isOutOfStock => availability == 'out_of_stock' || availableQuantity <= 0;

  /// Check if SKU has limited stock
  bool get hasLimitedStock => availability == 'limited';

  /// Create from Firestore document
  /// Supports both new flattened structure and old nested structure
  factory ProductSKUModel.fromFirestore(Map<String, dynamic> data) {
    // Try new flattened structure first
    double price = 0.0;
    double mrp = 0.0;
    String availability = 'out_of_stock';
    int availableQuantity = 0;
    int maxPerOrder = 999; // Default
    String currency = 'INR';
    
    // Check if new flat structure exists
    if (data['price'] != null) {
      // NEW STRUCTURE (flattened)
      price = _toDouble(data['price']);
      mrp = _toDouble(data['mrp']);
      availability = data['availability'] ?? 'out_of_stock';
      availableQuantity = _toInt(data['available_quantity']);
      currency = data['currency'] ?? 'INR';
      
      // Parse purchase limits
      final purchaseLimits = data['purchase_limits'] as Map<String, dynamic>?;
      if (purchaseLimits != null) {
        maxPerOrder = _toInt(purchaseLimits['max_per_order']) ?? 999;
      }
    } else if (data['pricing'] != null || data['inventory'] != null) {
      // OLD STRUCTURE (nested) - for backward compatibility
      final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
      final inventory = data['inventory'] as Map<String, dynamic>? ?? {};
      
      price = _toDouble(pricing['selling_price']);
      mrp = _toDouble(pricing['mrp'] ?? pricing['selling_price']);
      currency = pricing['currency'] ?? 'INR';
      
      final stockQty = _toInt(inventory['stock_qty']);
      availableQuantity = stockQty;
      
      // Determine availability from stock quantity
      if (stockQty > 10) {
        availability = 'in_stock';
      } else if (stockQty > 0) {
        availability = 'limited';
      } else {
        availability = 'out_of_stock';
      }
      
      // Old structure might not have purchase limits, use default
      maxPerOrder = 999;
    }
    
    return ProductSKUModel(
      skuId: data['sku_id'] ?? '',
      attributes: _parseAttributes(data['attributes']),
      price: price,
      mrp: mrp,
      availability: availability,
      availableQuantity: availableQuantity,
      maxPerOrder: maxPerOrder,
    );
  }


  /// Helper to safely convert to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper to safely convert to int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper to parse attributes map
  static Map<String, String> _parseAttributes(dynamic data) {
    if (data == null || data is! Map) {
      return {};
    }
    
    return Map<String, String>.from(
      data.map((key, value) => MapEntry(key.toString(), value.toString()))
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'sku_id': skuId,
      'attributes': attributes,
      'price': price,
      'mrp': mrp,
      'availability': availability,
      'available_quantity': availableQuantity,
      'purchase_limits': {
        'max_per_order': maxPerOrder,
      },
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() => toFirestore();

  /// Create copy with optional parameter overrides
  ProductSKUModel copyWith({
    String? skuId,
    Map<String, String>? attributes,
    double? price,
    double? mrp,
    String? availability,
    int? availableQuantity,
    int? maxPerOrder,
  }) {
    return ProductSKUModel(
      skuId: skuId ?? this.skuId,
      attributes: attributes ?? this.attributes,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      availability: availability ?? this.availability,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      maxPerOrder: maxPerOrder ?? this.maxPerOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSKUModel &&
          runtimeType == other.runtimeType &&
          skuId == other.skuId;

  @override
  int get hashCode => skuId.hashCode;

  @override
  String toString() => 'ProductSKUModel(skuId: $skuId, price: $price, mrp: $mrp, availability: $availability, quantity: $availableQuantity, maxPerOrder: $maxPerOrder)';
}
