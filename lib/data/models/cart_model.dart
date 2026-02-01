import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart item model with comprehensive product + SKU data
/// 
/// Enhanced model that stores all necessary product information to avoid
/// product lookups during checkout and ensure reliable order creation
class CartItem {
  // Core IDs
  final String productId;     // Base product ID (e.g., "stapler-kangaro-hd10d")
  final String skuId;         // Full SKU ID (e.g., "stapler-kangaro-hd10d-standard")
  
  // Product Information
  final String title;         // Product title
  final String subtitle;      // Product subtitle
  final String imageUrl;      // Main product image URL
  
  // Pricing (SKU-specific)
  final double price;         // Current selling price
  final double mrp;           // Maximum retail price
  final String currency;      // Currency (INR)
  
  // Cart specific
  final int quantity;         // Quantity in cart
  final DateTime addedAt;     // When added to cart
  
  // Legacy fields (for backward compatibility)
  final String? selectedColor;  // DEPRECATED: Use SKU attributes instead

  const CartItem({
    required this.productId,
    required this.skuId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.mrp,
    required this.currency,
    required this.quantity,
    required this.addedAt,
    this.selectedColor,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      // Core IDs
      'productId': productId,
      'skuId': skuId,
      
      // Product Information
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      
      // Pricing
      'price': price,
      'mrp': mrp,
      'currency': currency,
      
      // Cart specific
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
      
      // Legacy
      if (selectedColor != null) 'selectedColor': selectedColor,
    };
  }

  /// Create from Firestore document (handles both old and new formats)
  factory CartItem.fromFirestore(Map<String, dynamic> data) {
    // Handle legacy format where only basic data was stored
    if (!data.containsKey('skuId')) {
      return CartItem(
        productId: data['productId'] ?? '',
        skuId: data['productId'] ?? '', // Fallback: use productId as skuId
        title: 'Product ${data['productId'] ?? 'Unknown'}',
        subtitle: 'Legacy cart item',
        imageUrl: '',
        price: 0.0,
        mrp: 0.0,
        currency: 'INR',
        quantity: (data['quantity'] ?? 1).toInt(),
        addedAt: _parseTimestamp(data['addedAt']),
        selectedColor: data['selectedColor'] as String?,
      );
    }
    
    // New enhanced format
    return CartItem(
      productId: data['productId'] ?? '',
      skuId: data['skuId'] ?? data['productId'] ?? '',
      title: data['title'] ?? 'Unknown Product',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      mrp: (data['mrp'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'INR',
      quantity: (data['quantity'] ?? 1).toInt(),
      addedAt: _parseTimestamp(data['addedAt']),
      selectedColor: data['selectedColor'] as String?,
    );
  }
  
  /// Create minimal cart item for legacy support (Buy Now, etc.)
  factory CartItem.minimal({
    required String productId,
    required int quantity,
    required DateTime addedAt,
    String? selectedColor,
  }) {
    return CartItem(
      productId: productId,
      skuId: productId, // Use productId as skuId for legacy
      title: 'Product $productId',
      subtitle: 'Minimal cart item',
      imageUrl: '',
      price: 0.0,
      mrp: 0.0,
      currency: 'INR',
      quantity: quantity,
      addedAt: addedAt,
      selectedColor: selectedColor,
    );
  }

  /// Create copy with optional parameter overrides
  CartItem copyWith({
    String? productId,
    String? skuId,
    String? title,
    String? subtitle,
    String? imageUrl,
    double? price,
    double? mrp,
    String? currency,
    int? quantity,
    DateTime? addedAt,
    String? selectedColor,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      skuId: skuId ?? this.skuId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      currency: currency ?? this.currency,
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
          skuId == other.skuId; // Compare by SKU ID for uniqueness

  @override
  int get hashCode => skuId.hashCode;
  
  /// Get total price for this cart item (price × quantity)
  double get totalPrice => price * quantity;
  
  /// Get total discount for this cart item ((mrp - price) × quantity)
  double get totalDiscount => (mrp - price) * quantity;
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

  /// Get item by SKU ID (primary key)
  CartItem? getItem(String skuId) {
    try {
      return items.firstWhere((item) => item.skuId == skuId);
    } catch (e) {
      return null;
    }
  }

  /// Get item by product ID (may return first match if multiple SKUs)
  CartItem? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if SKU exists in cart
  bool containsSku(String skuId) {
    return items.any((item) => item.skuId == skuId);
  }

  /// Check if product exists in cart (any SKU of this product)
  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }
  
  /// Get total cart value (sum of all item totals)
  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  /// Get total discount value
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.totalDiscount);

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
