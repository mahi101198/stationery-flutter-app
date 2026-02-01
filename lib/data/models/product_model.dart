import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_sku_model.dart';
import 'content_card_model.dart';
import 'delivery_info_model.dart';

/// Product status enum for backward compatibility
enum ProductStatus { active, inactive, out_of_stock }

/// Media Model - Represents product media (images/videos)
class ProductMediaModel {
  final String mainImage;
  final List<String> galleryImages;

  const ProductMediaModel({
    required this.mainImage,
    this.galleryImages = const [],
  });

  /// Get all images (main + gallery)
  List<String> get allImages {
    final images = <String>[];
    if (mainImage.isNotEmpty) images.add(mainImage);
    images.addAll(galleryImages);
    return images;
  }

  factory ProductMediaModel.fromFirestore(Map<String, dynamic> data) {
    // Parse main_image - can be either a string URL or an object with 'url' field
    String mainImageUrl = '';
    final mainImageData = data['main_image'];
    
    if (mainImageData is String) {
      mainImageUrl = mainImageData;
    } else if (mainImageData is Map) {
      mainImageUrl = mainImageData['url'] ?? '';
    }
    
    // Sanitize URL
    if (mainImageUrl.contains('example.com') || mainImageUrl.contains('placeholder')) {
      mainImageUrl = '';
    }
    
    return ProductMediaModel(
      mainImage: mainImageUrl,
      galleryImages: _parseStringList(data['gallery_images']),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null || data is! List) return [];
    return data.whereType<String>().toList();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'main_image': mainImage,
      'gallery_images': galleryImages,
    };
  }

  factory ProductMediaModel.empty() {
    return const ProductMediaModel(mainImage: '', galleryImages: []);
  }
}

/// SKU-Based Product Model - Complete product information from product_details collection
class ProductModel {
  // Core product information
  final String productId;
  final String title;
  final String? subtitle; // Optional subtitle for product
  final String description;
  final String brand;
  final String category;
  final String subCategory;

  // Media
  final ProductMediaModel media;

  // Variant system
  final Map<String, List<String>> variantAttributes; // e.g., {"color": ["blue", "black"], "pack_size": ["pack1", "pack5"]}
  final List<ProductSKUModel> productSkus;
  final String overallAvailability; // "in_stock" | "out_of_stock" | "limited"

  // Dynamic content
  final List<ContentCardModel> contentCards;

  // Delivery & trust
  final DeliveryInfoModel deliveryInfo;

  // Rating & Reviews
  final double averageRating;
  final int reviewCount;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.productId,
    required this.title,
    this.subtitle,
    required this.description,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.media,
    required this.variantAttributes,
    required this.productSkus,
    required this.overallAvailability,
    required this.contentCards,
    required this.deliveryInfo,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ==================== GETTERS ====================

  /// Backward compatibility - some code expects id
  String get id => productId;

  /// Backward compatibility - some code expects primaryImage
  String get primaryImage => media.mainImage;

  /// Get all images
  List<String> get allImages => media.allImages;

  /// Get display image (main image or first gallery image)
  String get displayImage => media.mainImage.isNotEmpty 
      ? media.mainImage 
      : (media.galleryImages.isNotEmpty ? media.galleryImages.first : '');

  /// Check if product has any SKUs available
  bool get isAvailable => overallAvailability != 'out_of_stock' && productSkus.any((sku) => sku.isAvailable);

  /// Check if product has variants
  bool get hasVariants => variantAttributes.isNotEmpty && variantAttributes.values.any((values) => values.length > 1);

  /// Check if product has only one SKU
  bool get hasSingleSKU => productSkus.length == 1;

  /// Get the single SKU (if only one exists)
  ProductSKUModel? get singleSKU => hasSingleSKU ? productSkus.first : null;

  /// Get minimum price across all SKUs
  double? get minPrice {
    if (productSkus.isEmpty) return null;
    return productSkus.map((sku) => sku.price).reduce((a, b) => a < b ? a : b);
  }

  /// Get maximum price across all SKUs
  double? get maxPrice {
    if (productSkus.isEmpty) return null;
    return productSkus.map((sku) => sku.price).reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum MRP across all SKUs
  double? get minMRP {
    if (productSkus.isEmpty) return null;
    return productSkus.map((sku) => sku.mrp).reduce((a, b) => a < b ? a : b);
  }

  /// Get maximum MRP across all SKUs
  double? get maxMRP {
    if (productSkus.isEmpty) return null;
    return productSkus.map((sku) => sku.mrp).reduce((a, b) => a > b ? a : b);
  }

  /// Check if any SKU has discount
  bool get hasDiscount => productSkus.any((sku) => sku.hasDiscount);

  // ==================== DISPLAY PROPERTIES (Backward Compatibility) ====================
  
  /// Backward compatibility - some code expects 'name' instead of 'title'
  String get name => title;

  /// Display price - returns the minimum price across all SKUs
  /// This is used for product cards and listings
  double get price => minPrice ?? 0.0;

  /// Display MRP - returns the minimum MRP across all SKUs
  /// This is used for showing the original price before discount
  double get mrp => minMRP ?? 0.0;

  /// Display discount percentage - calculated from price and MRP
  /// Returns the maximum discount percentage across all SKUs
  double get discount {
    if (!hasDiscount || mrp == 0) return 0.0;
    return ((mrp - price) / mrp) * 100;
  }

  // ==================== ADDITIONAL BACKWARD COMPATIBILITY ====================
  
  /// Total stock - sum of available quantities across all SKUs
  int get stock {
    if (productSkus.isEmpty) return 0;
    return productSkus
        .where((sku) => sku.isAvailable)
        .fold(0, (sum, sku) => sum + (sku.availableQuantity ?? 0));
  }

  /// Primary image - maps to media.mainImage
  String get image => media.mainImage;

  /// Additional images - maps to media.galleryImages
  List<String> get images => media.galleryImages;

  /// Category ID - maps to category field
  String get categoryId => category;

  /// Subcategory ID - maps to subCategory field
  String get subcategoryId => subCategory;

  /// Tags - derived from category and subcategory for search
  List<String> get tags {
    final tagList = <String>[];
    if (category.isNotEmpty) tagList.add(category);
    if (subCategory.isNotEmpty) tagList.add(subCategory);
    if (brand.isNotEmpty) tagList.add(brand);
    return tagList;
  }

  /// Colors - derived from variant attributes
  List<String> get colors {
    if (variantAttributes.containsKey('color')) {
      return variantAttributes['color'] ?? [];
    }
    return [];
  }

  /// Is active - derived from availability
  bool get isActive => overallAvailability != 'out_of_stock' && productSkus.any((sku) => sku.isAvailable);

  /// Maximum quantity per user - from purchase_limits or default to 10
  int get maxQuantityPerUser {
    // Try to get from deliveryInfo.purchaseLimits first (if it exists there)
    // Otherwise use a reasonable default
    return 10; // Will be updated when we add PurchaseLimitsModel
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create from Firestore document (product_details collection)
  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return ProductModel(
      productId: data['product_id'] ?? doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['sub_category'] ?? '',
      media: data['media'] != null 
          ? ProductMediaModel.fromFirestore(data['media'] as Map<String, dynamic>)
          : ProductMediaModel.empty(),
      variantAttributes: _parseVariantAttributes(data['variant_attributes']),
      productSkus: _parseProductSKUs(data['product_skus'], data['purchase_limits']),
      overallAvailability: data['overall_availability'] ?? 'out_of_stock',
      contentCards: _parseContentCards(data['content_cards']),
      deliveryInfo: data['delivery_info'] != null
          ? DeliveryInfoModel.fromFirestore(data['delivery_info'] as Map<String, dynamic>)
          : DeliveryInfoModel.empty(),
      averageRating: _parseRating(data),
      reviewCount: _parseReviewCount(data),
      createdAt: _parseTimestamp(data['created_at']),
      updatedAt: _parseTimestamp(data['updated_at']),
    );
  }

  /// Create from Map
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      productId: data['product_id'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['sub_category'] ?? '',
      media: data['media'] != null 
          ? ProductMediaModel.fromFirestore(data['media'] as Map<String, dynamic>)
          : ProductMediaModel.empty(),
      variantAttributes: _parseVariantAttributes(data['variant_attributes']),
      productSkus: _parseProductSKUs(data['product_skus'], data['purchase_limits']),
      overallAvailability: data['overall_availability'] ?? 'out_of_stock',
      contentCards: _parseContentCards(data['content_cards']),
      deliveryInfo: data['delivery_info'] != null
          ? DeliveryInfoModel.fromFirestore(data['delivery_info'] as Map<String, dynamic>)
          : DeliveryInfoModel.empty(),
      averageRating: _parseRating(data),
      reviewCount: _parseReviewCount(data),
      createdAt: _parseTimestamp(data['created_at']),
      updatedAt: _parseTimestamp(data['updated_at']),
    );
  }

  /// Create empty product for fallbacks
  factory ProductModel.empty() {
    final now = DateTime.now();
    return ProductModel(
      productId: '',
      title: 'Unknown Product',
      subtitle: null,
      description: '',
      brand: '',
      category: '',
      subCategory: '',
      media: ProductMediaModel.empty(),
      variantAttributes: const {},
      productSkus: const [],
      overallAvailability: 'out_of_stock',
      contentCards: const [],
      deliveryInfo: DeliveryInfoModel.empty(),
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==================== CONVERSION METHODS ====================

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'title': title,
      'description': description,
      'brand': brand,
      'category': category,
      'sub_category': subCategory,
      'media': media.toFirestore(),
      'variant_attributes': variantAttributes,
      'product_skus': productSkus.map((sku) => sku.toFirestore()).toList(),
      'overall_availability': overallAvailability,
      'content_cards': contentCards.map((card) => card.toFirestore()).toList(),
      'delivery_info': deliveryInfo.toFirestore(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() => toFirestore();

  // ==================== UTILITY METHODS ====================

  /// Create copy with optional parameter overrides
  ProductModel copyWith({
    String? productId,
    String? title,
    String? subtitle,
    String? description,
    String? brand,
    String? category,
    String? subCategory,
    ProductMediaModel? media,
    Map<String, List<String>>? variantAttributes,
    List<ProductSKUModel>? productSkus,
    String? overallAvailability,
    List<ContentCardModel>? contentCards,
    DeliveryInfoModel? deliveryInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      media: media ?? this.media,
      variantAttributes: variantAttributes ?? this.variantAttributes,
      productSkus: productSkus ?? this.productSkus,
      overallAvailability: overallAvailability ?? this.overallAvailability,
      contentCards: contentCards ?? this.contentCards,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      // Handle Unix timestamp in seconds or milliseconds
      if (timestamp > 10000000000) {
        // Milliseconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        // Seconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  /// Helper method to parse rating (handles both old and new structure)
  static double _parseRating(Map<String, dynamic> data) {
    // Try new structure first: rating.average
    if (data['rating'] != null && data['rating'] is Map) {
      final ratingMap = data['rating'] as Map<String, dynamic>;
      final average = ratingMap['average'];
      if (average != null) {
        if (average is double) return average;
        if (average is int) return average.toDouble();
        if (average is String) return double.tryParse(average) ?? 0.0;
      }
    }
    
    // Fall back to old structure: average_rating
    final oldRating = data['average_rating'];
    if (oldRating != null) {
      if (oldRating is double) return oldRating;
      if (oldRating is int) return oldRating.toDouble();
      if (oldRating is String) return double.tryParse(oldRating) ?? 0.0;
    }
    
    return 0.0;
  }

  /// Helper method to parse review count (handles both old and new structure)
  static int _parseReviewCount(Map<String, dynamic> data) {
    // Try new structure first: rating.count
    if (data['rating'] != null && data['rating'] is Map) {
      final ratingMap = data['rating'] as Map<String, dynamic>;
      final count = ratingMap['count'];
      if (count != null) {
        if (count is int) return count;
        if (count is double) return count.toInt();
        if (count is String) return int.tryParse(count) ?? 0;
      }
    }
    
    // Fall back to old structure: review_count
    final oldCount = data['review_count'];
    if (oldCount != null) {
      if (oldCount is int) return oldCount;
      if (oldCount is double) return oldCount.toInt();
      if (oldCount is String) return int.tryParse(oldCount) ?? 0;
    }
    
    return 0;
  }

  /// Helper method to parse variant attributes
  static Map<String, List<String>> _parseVariantAttributes(dynamic data) {
    if (data == null || data is! Map) return {};
    
    final Map<String, List<String>> result = {};
    data.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.whereType<String>().toList();
      }
    });
    
    return result;
  }

  /// Helper method to parse product SKUs
  static List<ProductSKUModel> _parseProductSKUs(dynamic data, dynamic purchaseLimitsData) {
    if (data == null || data is! List) return [];
    
    // Parse parent product's purchase limits
    int maxPerOrder = 999;
    if (purchaseLimitsData is Map<String, dynamic>) {
      maxPerOrder = (purchaseLimitsData['max_per_order'] as num?)?.toInt() ?? 999;
    }
    
    return data
        .whereType<Map<String, dynamic>>()
        .map((skuData) {
          // Add purchase_limits to SKU data if not already present
          if (skuData['purchase_limits'] == null) {
            skuData['purchase_limits'] = {'max_per_order': maxPerOrder};
          }
          return ProductSKUModel.fromFirestore(skuData);
        })
        .toList();
  }

  /// Helper method to parse content cards
  static List<ContentCardModel> _parseContentCards(dynamic data) {
    if (data == null || data is! List) return [];
    
    return data
        .whereType<Map<String, dynamic>>()
        .map((cardData) => ContentCardModel.fromFirestore(cardData))
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
  String toString() => 'ProductModel(productId: $productId, title: $title, skus: ${productSkus.length}, availability: $overallAvailability)';
}
