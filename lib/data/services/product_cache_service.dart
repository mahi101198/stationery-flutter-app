import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/database/app_database.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/models/cart_model.dart' as cart_models;
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/models/product_sku_model.dart';
import 'package:rps_stationery/data/models/delivery_info_model.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift show Value;
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/data/services/cart_wishlist_service.dart';

/// Robust product cache service using Drift database
/// Provides offline-first caching with real-time sync capabilities
///
/// Organized into logical sections:
/// 1. Initialization & Setup
/// 2. Data Loading & Caching
/// 3. Sync Operations
/// 4. Public API Methods
/// 5. Cart Operations
/// 6. Wishlist Operations
/// 7. Utility Methods
class ProductCacheService extends GetxController {
  static ProductCacheService get instance => Get.find();
  // ============================
  // DEPENDENCIES & VARIABLES
  // ============================

  final _firestore = FirebaseFirestore.instance;
  final _localDatabase = AppDatabase.instance;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Authentication - integrated with AuthRepository
  AuthRepository get _authRepo => AuthRepository.instance;
  String get _currentUserId => _authRepo.userId;

  // Reactive State
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> flashSaleProducts = <ProductModel>[].obs;
  final RxList<cart_models.CartModel> cartItems = <cart_models.CartModel>[].obs;
  final RxSet<String> wishlistIds = <String>{}.obs;
  final RxList<ProductModel> wishlistProducts = <ProductModel>[].obs;

  // Loading States
  final RxBool isInitializing = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isRefreshingCart = false.obs;
  final RxBool isOnline = true.obs;

  // Configuration Constants
  static const String _lastSyncKey = 'last_sync';
  static const String _cacheVersionKey = 'cache_version';
  static const int _cacheVersion = 1;
  static const Duration _syncInterval = Duration(minutes: 1);
  static const int _popularLimit = 10;
  static const int _flashSaleLimit = 10;

  // Stream Subscriptions
  StreamSubscription<List<CartItem>>? _cartSubscription;
  StreamSubscription<List<WishlistItem>>? _wishlistSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteCartSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteWishlistSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  // ============================
  // 1. INITIALIZATION & SETUP
  // ============================

  @override
  void onInit() async {
    super.onInit();
    await initializeCache();
  }

  /// Initialize the cache service with all required setup
  Future<void> initializeCache() async {
    try {
      isInitializing.value = true;

      await _setupConnectivityMonitoring();
      await _setupAuthStateMonitoring();
      await _loadCachedDataFromLocal();
      await _setupLocalDatabaseListeners();

      if (await _shouldPerformSync()) {
        await _performFullSync();
      }

      await _setupRemoteFirestoreListeners();
    } catch (e) {
      log('Cache initialization failed: $e');
      await _handleError('Failed to initialize cache', e);
    } finally {
      isInitializing.value = false;
    }
  }

  /// Setup authentication state monitoring
  Future<void> _setupAuthStateMonitoring() async {
    _authStateSubscription = _authRepo.firebaseUser.listen((User? user) async {
      log('ProductCacheService: Auth state changed - ${user?.uid ?? 'null'}');

      if (user == null) {
        // User logged out - clear user-specific data
        await _clearUserSpecificData();
        await _cancelRemoteListeners();
      } else {
        // User logged in - setup user data sync
        await _setupLocalDatabaseListeners();
        await _setupRemoteFirestoreListeners();
        if (isOnline.value) {
          await _syncUserSpecificData();
        }
      }
    });
  }

  /// Clear user-specific data when user logs out
  Future<void> _clearUserSpecificData() async {
    try {
      await _localDatabase.transaction(() async {
        await _localDatabase.delete(_localDatabase.cartItems).go();
        await _localDatabase.delete(_localDatabase.wishlistItems).go();
      });

      // Clear reactive lists
      cartItems.clear();
      wishlistIds.clear();
      wishlistProducts.clear();

      log('User-specific data cleared successfully');
    } catch (e) {
      log('Error clearing user-specific data: $e');
    }
  }

  /// Cancel remote listeners (called when user logs out)
  Future<void> _cancelRemoteListeners() async {
    _remoteCartSubscription?.cancel();
    _remoteWishlistSubscription?.cancel();
    _remoteCartSubscription = null;
    _remoteWishlistSubscription = null;
  }

  /// Setup connectivity monitoring to track online/offline status
  Future<void> _setupConnectivityMonitoring() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    isOnline.value = !result.contains(ConnectivityResult.none);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOnline = isOnline.value;
      isOnline.value = !results.contains(ConnectivityResult.none);

      if (!wasOnline && isOnline.value) {
        // Came back online, sync data
        _performFullSync();
      }
    });
  }

  // ============================
  // 2. DATA LOADING & CACHING
  // ============================

  /// Load cached data from local database and populate reactive lists
  Future<void> _loadCachedDataFromLocal() async {
    try {
      // Load popular products
      final popularQuery =
          _localDatabase.select(_localDatabase.products)
            ..where((p) => p.popularRanking.isSmallerThanValue(_popularLimit))
            ..orderBy([(p) => OrderingTerm.asc(p.popularRanking)])
            ..limit(_popularLimit);

      final popular = await popularQuery.get();
      popularProducts.value =
          popular.map(_convertProductEntityToModel).toList();

      // Load flash sale products
      final flashQuery =
          _localDatabase.select(_localDatabase.products)
            ..where(
              (p) => p.flashSaleRanking.isSmallerThanValue(_flashSaleLimit),
            )
            ..orderBy([(p) => OrderingTerm.asc(p.flashSaleRanking)])
            ..limit(_flashSaleLimit);

      final flash = await flashQuery.get();
      flashSaleProducts.value =
          flash.map(_convertProductEntityToModel).toList();

      // Load wishlist products if user is authenticated
      if (_currentUserId.isNotEmpty) {
        final wishlistItems =
            await _localDatabase.select(_localDatabase.wishlistItems).get();
        await _updateWishlistProductsFromLocalData(wishlistItems);
      }

      log('Cached data loaded successfully');
    } catch (e) {
      log('Error loading cached data: $e');
    }
  }

  /// Setup local database listeners for real-time updates
  Future<void> _setupLocalDatabaseListeners() async {
    if (_currentUserId.isEmpty) return;

    // Cart listener
    _cartSubscription = _localDatabase
        .select(_localDatabase.cartItems)
        .watch()
        .listen((cartItems) async {
          await _updateCartItemsFromLocalData(cartItems);
        });

    // Wishlist listener
    _wishlistSubscription = _localDatabase
        .select(_localDatabase.wishlistItems)
        .watch()
        .listen((wishlistItems) async {
          wishlistIds.assignAll(wishlistItems.map((item) => item.productId));
          await _updateWishlistProductsFromLocalData(wishlistItems);
        });
  }

  /// Setup remote Firestore listeners for real-time sync
  Future<void> _setupRemoteFirestoreListeners() async {
    if (_currentUserId.isEmpty || !isOnline.value) return;

    try {
      // Remote cart listener (new schema: top-level carts/{userId})
      _remoteCartSubscription = _firestore
          .collection('carts')
          .doc(_currentUserId)
          .snapshots()
          .listen((doc) async {
            await _syncCartFromRemoteToLocalDoc(doc);
          }, onError: (error) => log('Remote cart listener error: $error'));

      // Remote wishlist listener (new schema: top-level wishlists/{userId})
      _remoteWishlistSubscription = _firestore
          .collection('wishlists')
          .doc(_currentUserId)
          .snapshots()
          .listen((doc) async {
            await _syncWishlistFromRemoteToLocalDoc(doc);
          }, onError: (error) => log('Remote wishlist listener error: $error'));
    } catch (e) {
      log('Error setting up remote listeners: $e');
    }
  }

  // ============================
  // 3. SYNC OPERATIONS
  // ============================

  /// Check if sync is needed based on last sync time
  Future<bool> _shouldPerformSync() async {
    try {
      final metadata =
          await (_localDatabase.select(_localDatabase.cacheMetadata)
            ..where((m) => m.key.equals(_lastSyncKey))).getSingleOrNull();

      if (metadata == null) return true;

      final lastSync = DateTime.parse(metadata.value);
      return DateTime.now().difference(lastSync) > _syncInterval;
    } catch (e) {
      return true; // Sync if unsure
    }
  }

  /// Perform full sync with remote Firestore
  Future<void> _performFullSync() async {
    if (!isOnline.value || isSyncing.value) return;

    try {
      isSyncing.value = true;
      log('Starting full sync with remote...');

      await Future.wait([
        _syncProductsFromRemoteToLocal(),
        if (_currentUserId.isNotEmpty) _syncUserSpecificData(),
      ]);

      await _updateSyncMetadata();
      log('Full sync completed successfully');
    } catch (e) {
      log('Full sync failed: $e');
      await _handleError('Sync failed', e);
    } finally {
      isSyncing.value = false;
    }
  }

  /// Sync products from Firestore to local database
  Future<void> _syncProductsFromRemoteToLocal() async {
    try {
      final snapshot =
          await _firestore
              .collection('product_details')
              .get();

      await _localDatabase.transaction(() async {
        // Clear existing products
        await _localDatabase.delete(_localDatabase.products).go();

        // Insert new products
        for (final doc in snapshot.docs) {
          await _localDatabase
              .into(_localDatabase.products)
              .insert(
              _convertProductModelToEntity(ProductModel.fromFirestore(doc)),
              );
        }
      });

      await _loadCachedDataFromLocal(); // Refresh reactive lists
    } catch (e) {
      log('Error syncing products: $e');
      rethrow;
    }
  }

  /// Sync user-specific data (cart and wishlist)
  Future<void> _syncUserSpecificData() async {
    await Future.wait([
      _syncRemoteCartToLocalInitially(),
      _syncRemoteWishlistToLocalInitially(),
    ]);
  }

  /// Update cart items from local database changes
  Future<void> _updateCartItemsFromLocalData(List<CartItem> cartItems) async {
    try {
      if (cartItems.isEmpty) {
        this.cartItems.clear();
        return;
      }

      // Build CartModel from local CartItem entities
      final items = cartItems.map((ci) => cart_models.CartItem.minimal(
            productId: ci.productId,
            quantity: ci.quantity,
            addedAt: DateTime.now(),
          )).toList();

      final cartModel = cart_models.CartModel(
        userId: _currentUserId,
        items: items,
        updatedAt: DateTime.now(),
      );

      this.cartItems.value = [cartModel];
    } catch (e) {
      log('Error updating cart from local: $e');
    }
  }

  /// Update wishlist products from local database changes
  Future<void> _updateWishlistProductsFromLocalData(
    List<WishlistItem> wishlistItems,
  ) async {
    try {
      if (wishlistItems.isEmpty) {
        wishlistProducts.clear();
        return;
      }

      final productIds = wishlistItems.map((item) => item.productId).toList();
      final products =
          await (_localDatabase.select(_localDatabase.products)
            ..where((p) => p.id.isIn(productIds))).get();

      final wishlistProductModels =
          products.map(_convertProductEntityToModel).toList();
      wishlistProducts.value = wishlistProductModels;
    } catch (e) {
      log('Error updating wishlist products from local: $e');
    }
  }

  /// Sync cart from remote document to local database (new schema)
  Future<void> _syncCartFromRemoteToLocalDoc(DocumentSnapshot snapshot) async {
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      final items = (data != null && data['items'] is List) ? data['items'] as List : <dynamic>[];

      await _localDatabase.transaction(() async {
        await _localDatabase.delete(_localDatabase.cartItems).go();

        for (final raw in items) {
          if (raw is Map<String, dynamic>) {
            final productId = raw['productId'] as String?;
            final quantity = (raw['quantity'] ?? 0);
            if (productId != null && productId.isNotEmpty) {
              await _localDatabase
                  .into(_localDatabase.cartItems)
                  .insert(
                    CartItemsCompanion.insert(
                      productId: productId,
                      quantity: drift.Value(quantity),
                    ),
                  );
            }
          }
        }
      });
    } catch (e) {
      log('Error syncing cart from remote: $e');
    }
  }

  /// Initial sync of remote cart to local database (new schema)
  Future<void> _syncRemoteCartToLocalInitially() async {
    try {
      final doc = await _firestore.collection('carts').doc(_currentUserId).get();
      await _syncCartFromRemoteToLocalDoc(doc);
    } catch (e) {
      log('Error syncing remote cart to local: $e');
    }
  }

  /// Sync wishlist from remote document to local database (new schema)
  Future<void> _syncWishlistFromRemoteToLocalDoc(DocumentSnapshot snapshot) async {
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      final products = (data != null && data['products'] is List) ? data['products'] as List : <dynamic>[];

      await _localDatabase.transaction(() async {
        await _localDatabase.delete(_localDatabase.wishlistItems).go();

        for (final pid in products) {
          if (pid is String && pid.isNotEmpty) {
            await _localDatabase
                .into(_localDatabase.wishlistItems)
                .insert(
                  WishlistItemsCompanion.insert(productId: pid),
                );
          }
        }
      });
    } catch (e) {
      log('Error syncing wishlist from remote: $e');
    }
  }

  /// Initial sync of remote wishlist to local database (new schema)
  Future<void> _syncRemoteWishlistToLocalInitially() async {
    try {
      final doc = await _firestore.collection('wishlists').doc(_currentUserId).get();
      await _syncWishlistFromRemoteToLocalDoc(doc);
    } catch (e) {
      log('Error syncing remote wishlist to local: $e');
    }
  }

  /// Update sync metadata in local database
  Future<void> _updateSyncMetadata() async {
    await _localDatabase
        .into(_localDatabase.cacheMetadata)
        .insertOnConflictUpdate(
          CacheMetadataCompanion.insert(
            key: _lastSyncKey,
            value: DateTime.now().toIso8601String(),
          ),
        );

    await _localDatabase
        .into(_localDatabase.cacheMetadata)
        .insertOnConflictUpdate(
          CacheMetadataCompanion.insert(
            key: _cacheVersionKey,
            value: _cacheVersion.toString(),
          ),
        );
  }

  // ============================
  // 4. PUBLIC API METHODS
  // ============================

  /// Search products in local cache with comprehensive field matching
  Future<List<ProductModel>> searchProducts(String query) async {
    return await _executeWithErrorHandling(() async {
      final lowerQuery = query.toLowerCase();

      final results =
          await (_localDatabase.select(_localDatabase.products)
                ..where(
                  (p) =>
                      p.name.lower().contains(lowerQuery) |
                      p.description.lower().contains(lowerQuery) |
                      p.category.lower().contains(lowerQuery) |
                      p.subCategory.lower().contains(lowerQuery),
                )
                ..orderBy([
                  // Order by relevance: name matches first, then category, then description
                  (p) => OrderingTerm(
                    expression: p.name.lower().contains(lowerQuery),
                    mode: OrderingMode.desc,
                  ),
                  (p) => OrderingTerm(
                    expression: p.category.lower().contains(lowerQuery),
                    mode: OrderingMode.desc,
                  ),
                  (p) => OrderingTerm.asc(p.name),
                ]))
              .get();

      return results.map(_convertProductEntityToModel).toList();
    });
  }

  /// Get products by category from cache
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    return await _executeWithErrorHandling(() async {
      late List<Product> results;
      
      // If category is "All Products", return all active products
      // Otherwise filter by specific category
      if (category == 'All Products') {
        results = await _localDatabase.select(_localDatabase.products).get();
      } else {
        results = await (_localDatabase.select(_localDatabase.products)
          ..where((p) => p.category.equals(category))).get();
      }

      return results.map(_convertProductEntityToModel).toList();
    });
  }

  /// Get products by IDs from cache, with fallback to remote if not found
  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    return await _executeWithErrorHandling(() async {
      final List<ProductModel> products = [];
      
      print('🔍 getProductsByIds: Received ${productIds.length} IDs (SKU or Product IDs)');
      
      for (final idToFetch in productIds) {
        print('🔍 Fetching product/SKU: $idToFetch');
        
        // Try to fetch directly using the ID (whether it's SKU or product ID)
        final product = await getProductById(idToFetch);
        if (product != null) {
          print('✅ Found: ${product.name} (ID: $idToFetch)');
          products.add(product);
        } else {
          print('⚠️ Product not found for: $idToFetch');
        }
      }
      
      print('✅ getProductsByIds: Successfully fetched ${products.length}/${productIds.length} products');
      return products;
    });
  }

  /// Get product by ID from cache, with fallback to remote if not found
  /// Handles both base product IDs and SKU IDs
  Future<ProductModel?> getProductById(String productId) async {
    return await _executeWithErrorHandling(() async {
      print('🔍 getProductById: Looking for product: $productId');
      
      // First try to get from local cache (handles both base ID and SKU ID)
      final localResult =
          await (_localDatabase.select(_localDatabase.products)
            ..where((p) => p.id.equals(productId))).getSingleOrNull();

      if (localResult != null) {
        print('✅ getProductById: Found in local cache: $productId');
        return _convertProductEntityToModel(localResult);
      }

      // If not found in local cache and we're online, try remote
      if (isOnline.value) {
        try {
          // Try direct lookup first (for base product IDs)
          print('📡 Fetching from Firestore: product_details/$productId');
          var remoteDoc =
              await _firestore.collection('product_details').doc(productId).get();

          // If not found and productId looks like a SKU (contains hyphens), try to extract base product ID
          if (!remoteDoc.exists && productId.contains('-')) {
            print('⚠️ Direct lookup failed for $productId, trying base product ID extraction...');
            
            // Extract base product ID by removing the last part (SKU variant)
            // Examples: 
            //   "stapler-kangaro-hd10d-standard" → "stapler-kangaro-hd10d"
            //   "pen-ball-balaji-20pack" → "pen-ball-balaji"
            //   "scale-infinity-small-4pt8in" → "scale-infinity-small"
            final parts = productId.split('-');
            
            if (parts.length > 1) {
              // Common SKU variant suffixes to remove
              final commonVariants = ['standard', 'premium', 'deluxe', 'basic', 'pro', 'lite'];
              final lastPart = parts.last.toLowerCase();
              
              // Remove last part if it's a common variant OR contains numbers (likely a variant)
              if (commonVariants.contains(lastPart) || lastPart.contains(RegExp(r'\d'))) {
                final baseProductId = parts.sublist(0, parts.length - 1).join('-');
                print('   Trying base product ID: $baseProductId');
                remoteDoc = await _firestore.collection('product_details').doc(baseProductId).get();
              }
            }
          }

          if (remoteDoc.exists) {
            print('✅ Found product document: ${remoteDoc.id}');
            final product = ProductModel.fromFirestore(remoteDoc);

            // If we searched for a SKU, find matching SKU details and update pricing
            if (productId != remoteDoc.id) {
              print('📦 SKU lookup: Finding SKU "$productId" in product_skus array...');
              final matchingSku = product.productSkus.firstWhereOrNull(
                (sku) => sku.skuId == productId
              );
              
              if (matchingSku != null) {
                print('✅ Found matching SKU: ${matchingSku.skuId}');
                print('   Price: ${matchingSku.price}, MRP: ${matchingSku.mrp}');
                // Product model already contains the full product data with all SKUs
                // The order details screen will handle selecting the right SKU
              } else {
                print('⚠️ SKU "$productId" not found in product_skus array');
              }
            }

            // Cache the product locally for future use
            await _localDatabase
                .into(_localDatabase.products)
                .insertOnConflictUpdate(_convertProductModelToEntity(product));

            return product;
          } else {
            print('❌ Product not found in Firestore: $productId');
          }
        } catch (e) {
          log('❌ Error fetching product from remote: $e');
          print('❌ Error fetching product from remote: $e');
        }
      }

      return null; // Product not found in local or remote
    });
  }

  /// Get complete product details by ID from both products and product_details collections
  Future<ProductModel?> getCompleteProductDetails(String productId) async {
    return await _executeWithErrorHandling(() async {
      
      if (!isOnline.value) {
        return await getProductById(productId);
      }

      try {
        // Fetch basic product info from product_details collection
        final productDoc = await _firestore.collection('product_details').doc(productId).get();
        
        if (!productDoc.exists) {
          return null;
        }

        final basicProduct = ProductModel.fromFirestore(productDoc);
        
        // Fetch detailed product info from product_details collection
        final productDetailsDoc = await _firestore
            .collection('product_details')
            .doc(productId)
            .get();

        if (productDetailsDoc.exists) {
          // TODO: Legacy code - needs migration to SKU-based ProductModel
          // The fromMergedData method doesn't exist in the new model
          // For now, return the basic product
          log('⚠️ ProductCacheService: fromMergedData not implemented - returning basic product');
          return basicProduct;
          
          /* LEGACY CODE - COMMENTED OUT
          final detailsData = productDetailsDoc.data()!;
          
          // Merge the detailed information with basic product info using new factory
          final completeProduct = ProductModel.fromMergedData(
            productsData: productDoc.data()!,
            productDetailsData: detailsData,
          );

          
          // Cache the complete product locally for future use
          await _localDatabase
              .into(_localDatabase.products)
              .insertOnConflictUpdate(_convertProductModelToEntity(completeProduct));

          return completeProduct;
          */
        } else {
          return basicProduct;
        }
      } catch (e) {
        // Fallback to basic product info
        return await getProductById(productId);
      }
    });
  }

  /// Get specific wishlist product by ID
  ProductModel? getWishlistProductById(String productId) {
    try {
      return wishlistProducts.firstWhere((product) => product.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Manual refresh of all data - forces sync regardless of time interval
  Future<void> performManualRefresh() async {
    if (!isOnline.value) {
      throw 'No internet connection available';
    }

    await _performFullSync();
  }

  /// Manual refresh of particular product by ID
  Future<void> refreshProductById(String productId) async {
    if (!isOnline.value) {
      return;
    }

    try {
      final remoteDoc =
          await _firestore.collection('product_details').doc(productId).get();

      if (remoteDoc.exists) {
        final product = ProductModel.fromFirestore(remoteDoc);

        // Update local cache
        await _localDatabase
            .into(_localDatabase.products)
            .insertOnConflictUpdate(_convertProductModelToEntity(product));

        log('Product $productId refreshed successfully');
      } else {
        throw 'Product $productId does not exist in remote database';
      }
    } catch (e) {
      log('Error refreshing product $productId: $e');
      // Ignore any errors here, they will be handled in cart
    }
  }

  /// Manual refresh of cart products only - ensures cart items are active and in stock
  /// This should be called before checkout to validate cart contents
  Future<void> refreshCart() async {
    if (!isOnline.value) {
      throw 'You need internet connection for checkout';
    }

    if (_currentUserId.isEmpty) {
      throw 'User not authenticated';
    }

    try {
      isRefreshingCart.value = true;
      log('Refreshing cart products...');

      final currentCartItems = cartItems.toList();
      if (currentCartItems.isEmpty) {
        log('Cart is empty, nothing to refresh');
        return;
      }

      final productIds = currentCartItems.first.items.map((i) => i.productId).toList();

      // Fetch latest product data from remote
      final updatedProducts = <ProductModel>[];

      for (final productId in productIds) {
        await _executeWithErrorHandling(() async {
          final remoteDoc =
              await _firestore.collection('product_details').doc(productId).get();

          if (remoteDoc.exists) {
            final product = ProductModel.fromFirestore(remoteDoc);
            updatedProducts.add(product);

            // Update local cache
            await _localDatabase
                .into(_localDatabase.products)
                .insertOnConflictUpdate(_convertProductModelToEntity(product));
          } else {
            log('Product $productId no longer exists in remote database');
          }
        });
      }

      // Process cart updates based on refreshed product data
      final itemsToRemove = <String>[];
      final quantityAdjustments = <String, int>{};

      final cart = currentCartItems.first;
      for (final cartEntry in cart.items) {
        final updatedProduct = updatedProducts.firstWhereOrNull(
          (p) => p.productId == cartEntry.productId,
        );

        if (updatedProduct != null && updatedProduct.isAvailable) {
          // Product exists, check if quantity needs adjustment
          if (updatedProduct.stock < cartEntry.quantity) {
            if (updatedProduct.stock > 0) {
              // Adjust to available stock silently
              quantityAdjustments[updatedProduct.productId] = updatedProduct.stock;
              log('⚠️ Quantity adjusted for ${updatedProduct.name} to available stock: ${updatedProduct.stock}');
            } else {
              // No stock available, remove from cart silently
              itemsToRemove.add(cartEntry.productId);
              log('⚠️ Product ${updatedProduct.name} out of stock, removed from cart');
            }
          }
          // If quantity is sufficient, no action needed - cart will be updated with fresh product data
        } else {
          // Product no longer exists, remove from cart silently
          itemsToRemove.add(cartEntry.productId);
          log('⚠️ Product ${cartEntry.productId} unavailable, removed from cart');
        }
      }

      // Apply cart modifications using CartWishlistService
      final cartService = Get.find<CartWishlistService>();
      for (final productId in itemsToRemove) {
        await cartService.removeFromCart(
          userId: _currentUserId,
          productId: productId,
        );
      }

      for (final entry in quantityAdjustments.entries) {
        await cartService.updateCartItemQuantity(
          userId: _currentUserId,
          productId: entry.key,
          quantity: entry.value,
        );
      }
    } catch (e) {
      log('Error refreshing cart products: $e');
      TLoaders.errorSnackBar(
        title: 'Cart Refresh Failed',
        message: e.toString(),
      );
      rethrow;
    } finally {
      isRefreshingCart.value = false;
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _executeWithErrorHandling(() async {
      await _localDatabase.transaction(() async {
        await _localDatabase.delete(_localDatabase.products).go();
        await _localDatabase.delete(_localDatabase.cartItems).go();
        await _localDatabase.delete(_localDatabase.wishlistItems).go();
        await _localDatabase.delete(_localDatabase.cacheMetadata).go();
      });

      // Clear reactive lists
      popularProducts.clear();
      flashSaleProducts.clear();
      cartItems.clear();
      wishlistIds.clear();
      wishlistProducts.clear();
    });
  }

  // ============================
  // 5. CART OPERATIONS
  // ============================

  // DEPRECATED: Use CartWishlistService.addToCart() instead

  // DEPRECATED: Use CartWishlistService.removeFromCart() instead

  // DEPRECATED: Use CartWishlistService.updateCartItemQuantity() instead

  // DEPRECATED: Use CartWishlistService.clearCart() instead

  // ============================
  // 6. WISHLIST OPERATIONS
  // ============================

  /// Add item to wishlist with local and remote sync
  Future<void> addItemToWishlist(String productId) async {
    await _executeWithErrorHandling(() async {
      await _localDatabase
          .into(_localDatabase.wishlistItems)
          .insertOnConflictUpdate(
            WishlistItemsCompanion.insert(productId: productId),
          );

      // Sync to remote if online and user is authenticated (new schema)
      if (isOnline.value && _currentUserId.isNotEmpty) {
        await _persistWishlistToRemote();
      }
    });
  }

  /// Remove item from wishlist with local and remote sync
  Future<void> removeItemFromWishlist(String productId) async {
    await _executeWithErrorHandling(() async {
      await (_localDatabase.delete(_localDatabase.wishlistItems)
        ..where((w) => w.productId.equals(productId))).go();

      // Sync to remote if online and user is authenticated (new schema)
      if (isOnline.value && _currentUserId.isNotEmpty) {
        await _persistWishlistToRemote();
      }
    });
  }

  /// Toggle wishlist status for a product
  Future<void> toggleWishlistStatus(String productId) async {
    if (wishlistIds.contains(productId)) {
      await removeItemFromWishlist(productId);
    } else {
      await addItemToWishlist(productId);
    }
  }

  /// Get all wishlist products with full product details
  Future<List<ProductModel>> getWishlistProducts() async {
    return await _executeWithErrorHandling(() async {
      final wishlist =
          await _localDatabase.select(_localDatabase.wishlistItems).get();
      final productIds = wishlist.map((item) => item.productId).toList();

      if (productIds.isEmpty) return <ProductModel>[];

      final products =
          await (_localDatabase.select(_localDatabase.products)
            ..where((p) => p.id.isIn(productIds))).get();

      return products.map(_convertProductEntityToModel).toList();
    });
  }

  // ============================
  // 7. UTILITY METHODS
  // ============================

  /// Persist local cart state to remote Firestore (new schema: carts/{userId})

  /// Persist local wishlist state to remote Firestore (new schema: wishlists/{userId})
  Future<void> _persistWishlistToRemote() async {
    try {
      final localItems = await _localDatabase.select(_localDatabase.wishlistItems).get();
      final now = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('wishlists').doc(_currentUserId).set({
        'userId': _currentUserId,
        'products': localItems.map((w) => w.productId).toList(),
        'updatedAt': now,
      });
    } catch (e) {
      log('Error persisting wishlist to remote: $e');
    }
  }

  /// Convert Product entity to new ProductModel with reactive state
  ProductModel _convertProductEntityToModel(Product product) {
    // Parse discount price if available
    final discount = product.discountPrice != null 
        ? product.price - product.discountPrice! 
        : 0.0;
    
    // Safely parse images JSON
    List<String> imagesList = [];
    try {
      if (product.images.isNotEmpty) {
        final decoded = jsonDecode(product.images);
        if (decoded is List) {
          imagesList = decoded.cast<String>();
        }
      }
    } catch (e) {
      log('Error parsing images JSON: $e');
      imagesList = [];
    }
    
    // Safely parse miniInfo JSON
    List<String> miniInfoList = [];
    try {
      if (product.miniInfo.isNotEmpty) {
        final decoded = jsonDecode(product.miniInfo);
        if (decoded is List) {
          miniInfoList = decoded.cast<String>();
        }
      }
    } catch (e) {
      log('Error parsing miniInfo JSON: $e');
      miniInfoList = [];
    }
    
    // Create a default SKU from legacy data to ensure pricing works
    final defaultSku = ProductSKUModel(
      skuId: '${product.id}_default',
      attributes: const {},
      mrp: product.mrp ?? 0.0,
      price: product.price ?? 0.0,
      availability: product.isActive && product.stock > 0 ? 'in_stock' : 'out_of_stock',
      availableQuantity: product.stock,
      maxPerOrder: 50, // Default limit for legacy products
    );
    
    return ProductModel(
      productId: product.id,
      title: product.name, // Map name to title
      description: product.description ?? '',
      brand: '', // Legacy doesn't have brand
      category: product.category,
      subCategory: '', // Legacy doesn't have subcategory
      media: ProductMediaModel(
        mainImage: imagesList.isNotEmpty ? imagesList.first : '',
        galleryImages: imagesList.length > 1 ? imagesList.sublist(1) : [],
      ),
      variantAttributes: const {}, // Legacy doesn't have variants
      productSkus: [defaultSku], // Create default SKU with pricing data
      overallAvailability: product.isActive && product.stock > 0 ? 'in_stock' : 'out_of_stock',
      contentCards: const [], // Legacy doesn't have content cards
      deliveryInfo: DeliveryInfoModel.empty(),
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  /// Convert new ProductModel to Product entity for database storage
  ProductsCompanion _convertProductModelToEntity(ProductModel product) {
    // Calculate discount price for legacy compatibility
    final discountPrice = product.hasDiscount ? product.price : null;
    
    // Combine primary image with images array for storage
    final allImages = <String>[];
    if (product.image.isNotEmpty) {
      allImages.add(product.image); // Primary image first
    }
    allImages.addAll(product.images); // Then additional images
    
    return ProductsCompanion.insert(
      id: product.productId,
      name: product.name,
      description: product.description ?? '',
      isActive: drift.Value(product.isActive),
      stock: drift.Value(product.stock),
      miniInfo: jsonEncode(product.tags), // Map tags to miniInfo
      images: jsonEncode(allImages), // Include primary image + additional images
      category: product.categoryId, // Map categoryId to legacy category
      subCategory: '', // Legacy field, use empty string
      popularRanking: drift.Value(11), // Default ranking
      categoryRanking: drift.Value(11), // Default ranking
      flashSaleRanking: drift.Value(11), // Default ranking
      mrp: drift.Value(product.mrp), // Store MRP
      price: product.price, // Store selling price
      discount: drift.Value(product.discount), // Store discount percentage
      discountPrice: drift.Value(discountPrice), // Legacy field for backward compatibility
      createdAt: drift.Value(product.createdAt),
      updatedAt: drift.Value(product.updatedAt),
    );
  }

  /// Safe execution wrapper with comprehensive error handling
  Future<T> _executeWithErrorHandling<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException().message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("ProductCacheService error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Handle errors with logging
  Future<void> _handleError(String message, dynamic error) async {
    log('$message: $error');
  }

  /// Get current cache statistics
  Map<String, dynamic> get cacheStats => {
    'popularProductsCount': popularProducts.length,
    'flashSaleProductsCount': flashSaleProducts.length,
    'cartItemsCount': cartItems.length,
    'wishlistItemsCount': wishlistIds.length,
    'wishlistProductsCount': wishlistProducts.length,
    'isOnline': isOnline.value,
    'isInitializing': isInitializing.value,
    'isSyncing': isSyncing.value,
    'isRefreshingCart': isRefreshingCart.value,
    'isAuthenticated': _authRepo.isAuthenticated,
    'currentUserId': _currentUserId,
  };

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    _cartSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _remoteCartSubscription?.cancel();
    _remoteWishlistSubscription?.cancel();
    _authStateSubscription?.cancel();
    // Do NOT close the database - it's a singleton used throughout the app
    // _localDatabase.close(); // REMOVED: This was causing the database re-open error
    super.onClose();
  }
}
