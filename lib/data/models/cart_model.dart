import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart item model following enterprise schema
class CartItem {
  final String productId;
  final int quantity;
  final DateTime addedAt;
  final String? selectedColor;  // Selected color option

  const CartItem({
    required this.productId,
    required this.quantity,
    required this.addedAt,
    this.selectedColor,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
      if (selectedColor != null) 'selectedColor': selectedColor,
    };
  }

  /// Create from Firestore document
  factory CartItem.fromFirestore(Map<String, dynamic> data) {
    return CartItem(
      productId: data['productId'] ?? '',
      quantity: (data['quantity'] ?? 1).toInt(),
      addedAt: _parseTimestamp(data['addedAt']),
      selectedColor: data['selectedColor'] as String?,
    );
  }

  /// Create copy with optional parameter overrides
  CartItem copyWith({
    String? productId,
    int? quantity,
    DateTime? addedAt,
    String? selectedColor,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      selectedColor: selectedColor ?? this.selectedColor,
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
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}

/// Cart model following enterprise schema
class CartModel {
  final String userId;
  final List<CartItem> items;
  final DateTime updatedAt;

  const CartModel({
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  /// Get total items count
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;

  /// Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product exists in cart
  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory CartModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return CartModel(
      userId: doc.id,
      items: _parseItems(data['items']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create copy with optional parameter overrides
  CartModel copyWith({
    String? userId,
    List<CartItem>? items,
    DateTime? updatedAt,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to parse items
  static List<CartItem> _parseItems(dynamic itemsData) {
    if (itemsData == null || itemsData is! List) {
      return [];
    }

    return itemsData
        .whereType<Map<String, dynamic>>()
        .map((item) => CartItem.fromFirestore(item))
        .toList();
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
      other is CartModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'CartModel(userId: $userId, itemsCount: ${items.length})';
}

/// Wishlist model following enterprise schema
class WishlistModel {
  final String userId;
  final List<String> products;
  final DateTime updatedAt;

  const WishlistModel({
    required this.userId,
    required this.products,
    required this.updatedAt,
  });

  /// Check if wishlist is empty
  bool get isEmpty => products.isEmpty;

  /// Check if wishlist is not empty
  bool get isNotEmpty => products.isNotEmpty;

  /// Get total products count
  int get totalProducts => products.length;

  /// Check if product exists in wishlist
  bool containsProduct(String productId) {
    return products.contains(productId);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'products': products,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory WishlistModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return WishlistModel(
      userId: doc.id,
      products: _parseProducts(data['products']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create copy with optional parameter overrides
  WishlistModel copyWith({
    String? userId,
    List<String>? products,
    DateTime? updatedAt,
  }) {
    return WishlistModel(
      userId: userId ?? this.userId,
      products: products ?? this.products,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to parse products
  static List<String> _parseProducts(dynamic productsData) {
    if (productsData == null || productsData is! List) {
      return [];
    }

    return productsData
        .whereType<String>()
        .map((product) => product)
        .toList();
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
      other is WishlistModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'WishlistModel(userId: $userId, productsCount: ${products.length})';
}
