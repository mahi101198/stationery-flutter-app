// Stub implementation for unsupported platforms
import 'package:drift/drift.dart';

// Mock table classes for platforms that don't support the database
class Product {
  final String productId;
  final String name;
  final String description;
  final String categoryId;
  final bool isAvailable;
  final double originalPrice;
  final double discountedPrice;
  final int stockQuantity;
  final List<String> images;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.categoryId,
    this.isAvailable = true,
    required this.originalPrice,
    this.discountedPrice = 0.0,
    this.stockQuantity = 0,
    this.images = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasDiscount => discountedPrice > 0 && discountedPrice < originalPrice;
}

class CartItem {
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.productId,
    this.quantity = 1,
    required this.createdAt,
    required this.updatedAt,
  });
}

class WishlistItem {
  final String productId;
  final DateTime createdAt;

  WishlistItem({
    required this.productId,
    required this.createdAt,
  });
}

class CacheMetadataData {
  final String key;
  final String value;
  final DateTime updatedAt;

  CacheMetadataData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
}

// Mock database class for unsupported platforms
class AppDatabase {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  AppDatabase._();

  static Future<void> closeInstance() async {
    _instance = null;
  }

  // Mock database methods
  Future<List<Product>> get allProducts async => [];
  Future<List<CartItem>> get allCartItems async => [];
  Future<List<WishlistItem>> get allWishlistItems async => [];
  Future<List<CacheMetadataData>> get allCacheMetadata async => [];

  Future<int> insertProduct(Insertable<Product> product) async => 1;
  Future<int> insertCartItem(Insertable<CartItem> item) async => 1;
  Future<int> insertWishlistItem(Insertable<WishlistItem> item) async => 1;
  Future<int> insertCacheMetadata(Insertable<CacheMetadataData> data) async => 1;

  Future<bool> updateProduct(Insertable<Product> product) async => true;
  Future<bool> updateCartItem(Insertable<CartItem> item) async => true;
  Future<bool> updateWishlistItem(Insertable<WishlistItem> item) async => true;
  Future<bool> updateCacheMetadata(Insertable<CacheMetadataData> data) async => true;

  Future<int> deleteProduct(String id) async => 1;
  Future<int> deleteCartItem(String productId) async => 1;
  Future<int> deleteWishlistItem(String productId) async => 1;
  Future<int> deleteCacheMetadata(String key) async => 1;

  Future<void> close() async {}
}
