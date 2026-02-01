import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class ProductRepo extends GetxController {
  static ProductRepo get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  
  // Get userId safely, returning empty string if not authenticated
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<T> safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("ProductRepo unexpected error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Fetch all products (legacy method - use with caution)
  Future<List<ProductModel>> fetchAllProducts() async {
    return safeCall(() async {
      log('🔄 ProductRepo: Starting Firestore query for products', name: 'ProductRepo');
      
      final products =
          await _db
              .collection('product_details')
              .get();
              
      log('📊 ProductRepo: Query returned ${products.docs.length} documents', name: 'ProductRepo');
      
      if (products.docs.isEmpty) {
        log('⚠️ ProductRepo: No products found in Firestore product_details collection!', name: 'ProductRepo');
        return [];
      }
      
      final productList = products.docs
          .map((snapshot) {
            try {
              final product = ProductModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              log('✅ ProductRepo: Successfully parsed product: ${product.name}', name: 'ProductRepo');
              return product;
            } catch (e) {
              log('❌ ProductRepo: Failed to parse product ${snapshot.id}: $e', name: 'ProductRepo');
              rethrow;
            }
          })
          .toList();
          
      log('✅ ProductRepo: Successfully processed ${productList.length} products', name: 'ProductRepo');
      return productList;
    });
  }

  /// Fetch products with pagination
  Future<List<ProductModel>> fetchProducts({
    int limit = 20,
    int offset = 0,
    String? lastDocumentId,
  }) async {
    return safeCall(() async {
      log('🔄 ProductRepo: Fetching products with pagination (limit: $limit, offset: $offset)', name: 'ProductRepo');
      
      Query query = _db
          .collection('product_details')
          .limit(limit);

      // Add offset using cursor-based pagination if lastDocumentId is provided
      if (lastDocumentId != null) {
        final lastDoc = await _db.collection('product_details').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      } else if (offset > 0) {
        // For simple offset-based pagination (less efficient but simpler)
        query = query.limit(offset + limit);
      }

      final products = await query.get();
      
      log('📊 ProductRepo: Paginated query returned ${products.docs.length} documents', name: 'ProductRepo');
      
      if (products.docs.isEmpty) {
        log('⚠️ ProductRepo: No more products found', name: 'ProductRepo');
        return [];
      }

      // Apply offset if not using cursor-based pagination
      final docsToProcess = lastDocumentId == null && offset > 0 
          ? products.docs.skip(offset).toList()
          : products.docs;
      
      final productList = docsToProcess
          .map((snapshot) {
            try {
              final product = ProductModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              return product;
            } catch (e) {
              log('❌ ProductRepo: Failed to parse product ${snapshot.id}: $e', name: 'ProductRepo');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<ProductModel>()
          .toList();
          
      log('✅ ProductRepo: Successfully processed ${productList.length} products', name: 'ProductRepo');
      return productList;
    });
  }

  /// Fetch products by category with pagination
  Future<List<ProductModel>> fetchProductsByCategory({
    required String category,
    int limit = 20,
    int offset = 0,
  }) async {
    return safeCall(() async {
      log('🔄 ProductRepo: Fetching products for category: $category', name: 'ProductRepo');
      
      Query query = _db
          .collection('product_details')
          .where('category', isEqualTo: category)
          .limit(limit);

      if (offset > 0) {
        query = query.limit(offset + limit);
      }

      final products = await query.get();
      
      log('📊 ProductRepo: Category query returned ${products.docs.length} documents', name: 'ProductRepo');
      
      if (products.docs.isEmpty) {
        log('⚠️ ProductRepo: No products found for category: $category', name: 'ProductRepo');
        return [];
      }

      // Apply offset if needed
      final docsToProcess = offset > 0 
          ? products.docs.skip(offset).toList()
          : products.docs;
      
      final productList = docsToProcess
          .map((snapshot) {
            try {
              final product = ProductModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              return product;
            } catch (e) {
              log('❌ ProductRepo: Failed to parse product ${snapshot.id}: $e', name: 'ProductRepo');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<ProductModel>()
          .toList();
          
      log('✅ ProductRepo: Successfully processed ${productList.length} products for category: $category', name: 'ProductRepo');
      return productList;
    });
  }

  /// Fetch products by subcategory with pagination
  Future<List<ProductModel>> fetchProductsBySubCategory(String subCategoryId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return safeCall(() async {
      log('🔄 ProductRepo: Fetching products for subcategory: $subCategoryId', name: 'ProductRepo');
      
      Query query = _db
          .collection('product_details')
          .where('sub_category', isEqualTo: subCategoryId)
          .limit(limit);

      if (offset > 0) {
        query = query.limit(offset + limit);
      }

      final products = await query.get();
      
      log('📊 ProductRepo: Subcategory query returned ${products.docs.length} documents', name: 'ProductRepo');
      
      if (products.docs.isEmpty) {
        log('⚠️ ProductRepo: No products found for subcategory: $subCategoryId', name: 'ProductRepo');
        return [];
      }

      // Apply offset if needed
      final docsToProcess = offset > 0 
          ? products.docs.skip(offset).toList()
          : products.docs;
      
      final productList = docsToProcess
          .map((snapshot) {
            try {
              final product = ProductModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              return product;
            } catch (e) {
              log('❌ ProductRepo: Failed to parse product ${snapshot.id}: $e', name: 'ProductRepo');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<ProductModel>()
          .toList();
          
      log('✅ ProductRepo: Successfully processed ${productList.length} products for subcategory: $subCategoryId', name: 'ProductRepo');
      return productList;
    });
  }

  /// Search products with pagination
  Future<List<ProductModel>> searchProduct(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    return safeCall(() async {
      log('🔍 ProductRepo: Searching for products with query: "$query"', name: 'ProductRepo');
      
      // First try exact prefix match (for performance)
      Query searchQuery = _db
          .collection('product_details')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query~')
          .limit(limit);

      if (offset > 0) {
        searchQuery = searchQuery.limit(offset + limit);
      }

      final productsSnapshot = await searchQuery.get();
      
      log('📊 ProductRepo: Prefix search returned ${productsSnapshot.docs.length} documents', name: 'ProductRepo');

      // If we have enough results from prefix search, return them
      if (productsSnapshot.docs.length >= limit) {
        final productList = productsSnapshot.docs
            .map((doc) {
              try {
                final product = ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                return product;
              } catch (e) {
                log('❌ ProductRepo: Failed to parse search result ${doc.id}: $e', name: 'ProductRepo');
                return null;
              }
            })
            .where((product) => product != null)
            .cast<ProductModel>()
            .toList();
            
        log('✅ ProductRepo: Successfully processed ${productList.length} search results from prefix search', name: 'ProductRepo');
        return productList;
      }

      // If prefix search didn't return enough results, do a broader search
      log('🔍 ProductRepo: Prefix search insufficient, doing broader search...', name: 'ProductRepo');
      
      // Get all active products and filter them
      final allProductsQuery = _db
          .collection('product_details')
          .limit(1000); // Get more products for filtering

      final allProductsSnapshot = await allProductsQuery.get();
      
      log('📊 ProductRepo: Broader search returned ${allProductsSnapshot.docs.length} documents', name: 'ProductRepo');

      // Filter products that contain the query anywhere in the name (case insensitive)
      final filteredProducts = allProductsSnapshot.docs
          .map((doc) {
            try {
              final product = ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
              return product;
            } catch (e) {
              log('❌ ProductRepo: Failed to parse product ${doc.id}: $e', name: 'ProductRepo');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<ProductModel>()
          .where((product) => 
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();

      // Sort by relevance (exact matches first, then starts with, then contains)
      filteredProducts.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final queryLower = query.toLowerCase();
        
        // Exact match gets highest priority
        if (aName == queryLower && bName != queryLower) return -1;
        if (bName == queryLower && aName != queryLower) return 1;
        
        // Starts with gets second priority
        if (aName.startsWith(queryLower) && !bName.startsWith(queryLower)) return -1;
        if (bName.startsWith(queryLower) && !aName.startsWith(queryLower)) return 1;
        
        // Then by length (shorter names first)
        return aName.length.compareTo(bName.length);
      });

      // Apply pagination
      final startIndex = offset;
      final endIndex = (startIndex + limit).clamp(0, filteredProducts.length);
      final paginatedProducts = filteredProducts.sublist(
        startIndex.clamp(0, filteredProducts.length),
        endIndex
      );
          
      log('✅ ProductRepo: Successfully processed ${paginatedProducts.length} search results from broader search', name: 'ProductRepo');
      return paginatedProducts;
    });
  }

  Future<ProductModel> getProductById(String id) async {
    return safeCall(() async {
      final doc = await _db.collection('product_details').doc(id).get();
      if (!doc.exists) {
        throw 'Product not found';
      }

      // All membership/quantity flags are handled by ProductCacheService
      return ProductModel.fromFirestore(doc);
    });
  }

  /// Get product by SKU ID - searches through all products to find one containing the SKU
  Future<ProductModel?> getProductBySKUId(String skuId) async {
    return safeCall(() async {
      if (skuId.isEmpty) return null;

      final querySnapshot = await _db.collection('product_details').get();

      for (final doc in querySnapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        
        // Check if this product contains the SKU
        final hasSKU = product.productSkus.any((sku) => sku.skuId == skuId);
        
        if (hasSKU) {
          return product;
        }
      }

      return null;
    });
  }

  Future<void> addToWishlist(String productId) async {
    safeCall(() async {
      await _db.collection('wishlists').doc(userId).set({
        'userId': userId,
        'products': FieldValue.arrayUnion([productId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    safeCall(() async {
      await _db.collection('wishlists').doc(userId).set({
        'userId': userId,
        'products': FieldValue.arrayRemove([productId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // DEPRECATED: Cart operations moved to CartWishlistService

  Future<List<CartModel>> getCartProducts() async {
    return safeCall(() async {
      final doc = await _db.collection('carts').doc(userId).get();
      if (!doc.exists) return <CartModel>[];
      final data = doc.data() ?? {};
      final itemsRaw = (data['items'] as List<dynamic>? ?? []);

      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => CartItem(
                productId: (m['productId'] ?? '') as String,
                quantity: (m['quantity'] ?? 0) as int,
                addedAt: DateTime.now(),
              ))
          .toList();

      final cart = CartModel(
        userId: userId,
        items: items,
        updatedAt: DateTime.now(),
      );
      return <CartModel>[cart];
    });
  }

  Stream<List<CartModel>> getCartStream() {
    return _db
        .collection('carts')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <CartModel>[];
          final data = doc.data() ?? {};
          final itemsRaw = (data['items'] as List<dynamic>? ?? []);

          final items = itemsRaw
              .whereType<Map<String, dynamic>>()
              .map((m) => CartItem(
                    productId: (m['productId'] ?? '') as String,
                    quantity: (m['quantity'] ?? 0) as int,
                    addedAt: DateTime.now(),
                  ))
              .toList();

          final cart = CartModel(
            userId: userId,
            items: items,
            updatedAt: DateTime.now(),
          );

          return <CartModel>[cart];
        })
        .handleError((error) {
          log("CartStream error -> $error", error: error);
          throw 'Error loading cart items. Please try again';
        });
  }


  // Maybe for future use when pagination is needed
  /// Fetches subcategories for a given category.
  Future<List<String>> fetchSubCategoriesByCategory(String category) async {
    return safeCall(() async {
      final productsSnapshot =
          await _db
              .collection('product_details')
              .where('category', isEqualTo: category)
              .get();

      final subCategories = <String>{};
      for (var doc in productsSnapshot.docs) {
        final subCategory = doc['subCategory'] as String?;
        if (subCategory != null && subCategory.isNotEmpty) {
          subCategories.add(subCategory);
        }
      }

      return subCategories.toList()..sort();
    });
  }
}
