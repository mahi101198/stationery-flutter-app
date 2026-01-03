import 'package:cloud_firestore/cloud_firestore.dart';

/// Product status enum for internal use
enum ProductStatus { active, inactive, out_of_stock }

/// Unified Product Model - Merges data from products and product_details collections
/// This model represents complete product information from both collections
class ProductModel {
  // Core fields from 'products' collection
  final String productId;        // "1zaaOVRcw81Yd1XhKmhb"
  final String name;             // "blooth"
  final String categoryId;       // "housekeeping"
  final String subcategoryId;    // "tools"
  final double mrp;              // 200
  final double price;            // 150
  final double discount;         // 25 (percentage)
  final String image;            // Single image URL from products collection
  final int stock;               // 222
  final bool isActive;           // true
  final DateTime createdAt;      // Oct 1, 2025
  final DateTime updatedAt;      // Oct 8, 2025

  // Extended fields from 'product_details' collection
  final String? description;     // "osm product need much more qulity"
  final List<String> images;     // Array of images from product_details
  final List<String> tags;       // ["stapler", "organiser"]
  final List<String> miniInfo;   // ["pack of 4"]
  final String? shippingInfo;    // "Shipped within two days"
  final String? shippingInfoTitle; // "Shipping Info"
  final String? returnDescription; // "No returns accepted"
  final String? returnTitle;     // "Return Policy"
  final int maxQuantityPerUser;  // Maximum quantity per user per order
  final List<String> colors;     // Available colors: ["Red", "Blue", "Green"]

  const ProductModel({
    required this.productId,
    required this.name,
    required this.categoryId,
    required this.subcategoryId,
    required this.mrp,
    required this.price,
    required this.discount,
    required this.image,
    required this.stock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.images = const [],
    this.tags = const [],
    this.miniInfo = const [],
    this.shippingInfo,
    this.shippingInfoTitle,
    this.returnDescription,
    this.returnTitle,
    this.maxQuantityPerUser = 10, // Default to 10 items per user
    this.colors = const [],
  });

  // ==================== GETTERS ====================

  /// Check if product has discount
  bool get hasDiscount => discount > 0;
  
  /// Check if product is available for purchase
  bool get isAvailable => isActive && stock > 0;
  
  /// Backward compatibility - some code expects id
  String get id => productId;

  /// Backward compatibility - some code expects primaryImage
  String get primaryImage => image;

  /// Get all images (from both collections)
  List<String> get allImages {
    final allImages = <String>[];
    if (image.isNotEmpty) allImages.add(image); // From products collection
    allImages.addAll(images); // From product_details collection
    return allImages;
  }

  /// Get primary image (prefer from products collection, fallback to product_details)
  String get displayImage => image.isNotEmpty ? image : (images.isNotEmpty ? images.first : '');

  /// Get status enum (backward compatibility)
  ProductStatus get status => isActive ? ProductStatus.active : ProductStatus.inactive;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create from Firestore document (products collection only)
  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return ProductModel(
      productId: data['productId'] ?? doc.id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      mrp: (data['mrp'] ?? 0.0).toDouble(),
      price: (data['price'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      image: data['image'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      maxQuantityPerUser: (data['maxQuantityPerUser'] ?? 10).toInt(),
      // Extended fields will be empty for basic products collection
      description: null,
      images: const [],
      tags: const [],
      miniInfo: const [],
      colors: const [],
    );
  }

  /// Create from Map (for nested data in home sections)
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      mrp: (data['mrp'] ?? 0.0).toDouble(),
      price: (data['price'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      image: data['image'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      maxQuantityPerUser: (data['maxQuantityPerUser'] ?? 10).toInt(),
      // Extended fields will be empty for basic data
      description: null,
      images: const [],
      tags: const [],
      miniInfo: const [],
      colors: const [],
    );
  }

  /// Create complete product by merging data from both collections
  factory ProductModel.fromMergedData({
    required Map<String, dynamic> productsData,
    Map<String, dynamic>? productDetailsData,
  }) {
    return ProductModel(
      // Core fields from products collection
      productId: productsData['productId'] ?? '',
      name: productsData['name'] ?? '',
      categoryId: productsData['categoryId'] ?? '',
      subcategoryId: productsData['subcategoryId'] ?? '',
      mrp: (productsData['mrp'] ?? 0.0).toDouble(),
      price: (productsData['price'] ?? 0.0).toDouble(),
      discount: (productsData['discount'] ?? 0.0).toDouble(),
      image: productsData['image'] ?? '',
      stock: (productsData['stock'] ?? 0).toInt(),
      isActive: productsData['isActive'] ?? true,
      createdAt: _parseTimestamp(productsData['createdAt']),
      updatedAt: _parseTimestamp(productsData['updatedAt']),
      maxQuantityPerUser: (productsData['maxQuantityPerUser'] ?? 10).toInt(),
      
      // Extended fields from product_details collection
      description: productDetailsData?['description'] as String?,
      images: _parseStringList(productDetailsData?['images']),
      tags: _parseStringList(productDetailsData?['tags']),
      miniInfo: _parseStringList(productDetailsData?['miniInfo']),
      shippingInfo: productDetailsData?['shippingInfo'] as String?,
      shippingInfoTitle: productDetailsData?['shippingInfoTitle'] as String?,
      returnDescription: productDetailsData?['returnDescription'] as String?,
      returnTitle: productDetailsData?['returnTitle'] as String?,
      colors: () {
        final colorsList = _parseStringList(productDetailsData?['colors']);
        print('🎨 ProductModel: Parsed colors from product_details: $colorsList');
        return colorsList;
      }(),
    );
  }

  /// Create empty product for fallbacks
  factory ProductModel.empty() {
    final now = DateTime.now();
    return ProductModel(
      productId: '',
      name: 'Unknown Product',
      categoryId: '',
      subcategoryId: '',
      mrp: 0.0,
      price: 0.0,
      discount: 0.0,
      image: '',
      stock: 0,
      isActive: false,
      createdAt: now,
      updatedAt: now,
      maxQuantityPerUser: 10,
      description: null,
      images: const [],
      tags: const [],
      miniInfo: const [],
      colors: const [],
    );
  }

  // ==================== CONVERSION METHODS ====================

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'mrp': mrp,
      'price': price,
      'discount': discount,
      'image': image,
      'stock': stock,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'maxQuantityPerUser': maxQuantityPerUser,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'mrp': mrp,
      'price': price,
      'discount': discount,
      'image': image,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'maxQuantityPerUser': maxQuantityPerUser,
    };
  }

  // ==================== UTILITY METHODS ====================

  /// Create copy with optional parameter overrides
  ProductModel copyWith({
    String? productId,
    String? name,
    String? categoryId,
    String? subcategoryId,
    double? mrp,
    double? price,
    double? discount,
    String? image,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxQuantityPerUser,
    String? description,
    List<String>? images,
    List<String>? tags,
    List<String>? miniInfo,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      mrp: mrp ?? this.mrp,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      image: image ?? this.image,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxQuantityPerUser: maxQuantityPerUser ?? this.maxQuantityPerUser,
      description: description ?? this.description,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      miniInfo: miniInfo ?? this.miniInfo,
      colors: this.colors,
    );
  }

  // ==================== HELPER METHODS ====================

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

  /// Helper method to parse string lists
  static List<String> _parseStringList(dynamic data) {
    if (data == null || data is! List) {
      return [];
    }
    
    return data
        .whereType<String>()
        .map((item) => item)
        .toList();
  }

  // ==================== OVERRIDES ====================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;

  @override
  String toString() => 'ProductModel(productId: $productId, name: $name, mrp: $mrp, price: $price, discount: $discount%)';
}

// ==================== LEGACY COMPATIBILITY ====================

/// Legacy alias for backward compatibility
/// Use ProductModel instead
@Deprecated('Use ProductModel instead')
typedef ProductSummary = ProductModel;
