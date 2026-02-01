import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../../services/firestore_config_service.dart';
import '../../utils/popups/loaders.dart';
import 'product_service.dart';
import 'product_cache_service.dart';

/// Result class for quantity validation
class QuantityValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool isQuantityLimit; // true if error is due to quantity limit, false if stock issue
  final int? adjustedQuantity; // suggested quantity if adjustment is needed
  
  const QuantityValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isQuantityLimit = false,
    this.adjustedQuantity,
  });
  
  factory QuantityValidationResult.success() {
    return const QuantityValidationResult(isValid: true);
  }
  
  factory QuantityValidationResult.stockError(String message, int availableStock) {
    return QuantityValidationResult(
      isValid: false,
      errorMessage: message,
      isQuantityLimit: false,
      adjustedQuantity: availableStock,
    );
  }
  
  factory QuantityValidationResult.quantityLimitError(String message, int maxAllowed) {
    return QuantityValidationResult(
      isValid: false,
      errorMessage: message,
      isQuantityLimit: true,
      adjustedQuantity: maxAllowed,
    );
  }
  
  factory QuantityValidationResult.generalError(String message) {
    return QuantityValidationResult(
      isValid: false,
      errorMessage: message,
      isQuantityLimit: false,
    );
  }
}

/// Cart and Wishlist service following enterprise schema
class CartWishlistService extends GetxController {
  static CartWishlistService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirestoreConfigService get _firestoreConfig => FirestoreConfigService.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _cartsCollection =>
      _firestore.collection('carts');
  CollectionReference<Map<String, dynamic>> get _wishlistsCollection =>
      _firestore.collection('wishlists');

  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // QUANTITY VALIDATION HELPER

  /// Validate quantity limits for a product
  Future<QuantityValidationResult> _validateQuantityLimits({
    required String productId,
    required int requestedQuantity,
    required String userId,
    int currentCartQuantity = 0,
    ProductModel? productContext,
  }) async {
    try {
      // Fetch product details to get maxQuantityPerUser
      ProductModel? product = productContext;
      
      if (product == null) {
        // Try ProductCacheService first (if available)
        if (Get.isRegistered<ProductCacheService>()) {
          try {
            product = await ProductCacheService.instance.getProductById(productId);
          } catch (e) {
            log('⚠️ ProductCacheService failed, falling back to ProductService: $e');
          }
        }
        
        // Fallback to ProductService if cache failed or not available
        if (product == null) {
          product = await ProductService.instance.getProductById(productId);
        }
      }
      
      if (product == null) {
        return QuantityValidationResult.generalError('Product not found');
      }
      
      // Check stock availability
      if (product.stock <= 0) {
        return QuantityValidationResult.stockError('Product is out of stock', 0);
      }
      
      // Calculate total quantity after this operation
      final totalQuantity = currentCartQuantity + requestedQuantity;
      
      // Check if total quantity exceeds stock
      if (totalQuantity > product.stock) {
        return QuantityValidationResult.stockError(
          'Only ${product.stock} items available in stock',
          product.stock - currentCartQuantity,
        );
      }
      
      // Check if total quantity exceeds per-user limit
      if (totalQuantity > product.maxQuantityPerUser) {
        return QuantityValidationResult.quantityLimitError(
          'Maximum ${product.maxQuantityPerUser} items allowed per user',
          product.maxQuantityPerUser - currentCartQuantity,
        );
      }
      
      log('✅ Quantity validation passed for $productId: $totalQuantity/${product.maxQuantityPerUser}');
      return QuantityValidationResult.success();
      
    } catch (e) {
      log('❌ Quantity validation failed: $e');
      return QuantityValidationResult.generalError(e.toString());
    }
  }

  // CART METHODS

  /// Get user cart with offline fallback
  Future<CartModel?> getCart(String userId) async {
    try {
      return await _firestoreConfig.getWithFallback<CartModel?>(
        serverCall: () async {
          final doc = await _cartsCollection.doc(userId).get(const GetOptions(source: Source.server));
          return doc.exists ? CartModel.fromFirestore(doc) : null;
        },
        cacheCall: () async {
          try {
            final doc = await _cartsCollection.doc(userId).get(const GetOptions(source: Source.cache));
            return doc.exists ? CartModel.fromFirestore(doc) : null;
          } catch (_) {
            return null;
          }
        },
        operationName: 'Get Cart',
      );
    } catch (e) {
      log('❌ Error fetching cart: $e');
      throw 'Failed to fetch cart. Please check your internet connection and try again.';
    }
  }

  /// Get current user cart
  Future<CartModel?> getCurrentUserCart() async {
    try {
      if (currentUserId == null) return null;
      return await getCart(currentUserId!);
    } catch (e) {
      log('❌ Error fetching current user cart: $e');
      return null;
    }
  }

  /// Create or update cart
  Future<void> saveCart(CartModel cart) async {
    try {
      print('💾 ════════════════════════════════════════════════════════');
      print('💾 SAVING CART TO FIRESTORE');
      print('💾 ════════════════════════════════════════════════════════');
      print('  User ID: ${cart.userId}');
      print('  Items count: ${cart.items.length}');
      for (var item in cart.items) {
        print('    - ${item.productId} x ${item.quantity}');
      }
      print('  Collection: carts');
      print('  Document ID: ${cart.userId}');
      
      final updatedCart = cart.copyWith(updatedAt: DateTime.now());
      await _cartsCollection.doc(cart.userId).set(updatedCart.toFirestore());
      
      print('✅ Cart saved successfully to Firestore');
      print('💾 ════════════════════════════════════════════════════════');
      log('✅ Cart saved successfully for user: ${cart.userId}');
    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR SAVING CART');
      print('❌ Error: $e');
      print('❌ ════════════════════════════════════════════════════════');
      log('❌ Error saving cart: $e');
      throw 'Failed to save cart. Please try again.';
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
    String? selectedColor,
    ProductModel? productContext,
  }) async {
    print('📦 ════════════════════════════════════════════════════════');
    print('📦 CART SERVICE - ADD TO CART');
    print('📦 ════════════════════════════════════════════════════════');
    print('  Product ID: $productId');
    print('  Quantity: $quantity');
    
    try {
      final cart = await getCart(userId);
      final now = DateTime.now();
      
      print('  Cart fetched: ${cart != null ? "Found (${cart.items.length} items)" : "Null (New Cart)"}');

      // Get current quantity in cart for this product
      int currentCartQuantity = 0;
      if (cart != null) {
        final existingItem = cart.items.firstWhereOrNull(
          (item) => item.productId == productId,
        );
        currentCartQuantity = existingItem?.quantity ?? 0;
      }
      
      print('  Current quantity in cart: $currentCartQuantity');

      // Validate quantity limits before proceeding
      print('🔄 Validating quantity limits...');
      final validationResult = await _validateQuantityLimits(
        productId: productId,
        requestedQuantity: quantity,
        userId: userId,
        currentCartQuantity: currentCartQuantity,
        productContext: productContext,
      );

      // Handle validation result silently - no user notifications in production
      if (!validationResult.isValid) {
        print('❌ Validation failed: ${validationResult.errorMessage}');
        log('⚠️ Add to cart validation failed: ${validationResult.errorMessage}');
        return; // Silently return without showing error to user
      }
      
      print('✅ Validation passed');

      List<CartItem> updatedItems;
      
      if (cart == null) {
        // Create new cart with first item
        updatedItems = [
          CartItem(
            productId: productId,
            quantity: quantity,
            addedAt: now,
            selectedColor: selectedColor,
          ),
        ];
        print('➕ Creating new cart with 1 item');
      } else {
        // Update existing cart
        updatedItems = List.from(cart.items);
        
        // Check if item already exists
        final existingItemIndex = updatedItems.indexWhere(
          (item) => item.productId == productId,
        );
        
        if (existingItemIndex != -1) {
          // Update existing item quantity and color
          updatedItems[existingItemIndex] = updatedItems[existingItemIndex]
              .copyWith(
                quantity: updatedItems[existingItemIndex].quantity + quantity,
                selectedColor: selectedColor,
              );
          print('🔄 Updated existing item quantity');
        } else {
          // Add new item
          updatedItems.add(
            CartItem(
              productId: productId,
              quantity: quantity,
              addedAt: now,
              selectedColor: selectedColor,
            ),
          );
          print('➕ Added new item to existing cart');
        }
      }

      final updatedCart = CartModel(
        userId: userId,
        items: updatedItems,
        updatedAt: now,
      );

      print('🔄 calling saveCart()...');
      await saveCart(updatedCart);
      log('✅ Item added to cart: $productId x$quantity');
      print('📦 CART SERVICE - SUCCESS');
    } catch (e) {
      print('❌ ERROR in CartService.addToCart: $e');
      log('❌ Error adding to cart: $e');
      throw 'Failed to add item to cart. ${e.toString()}';
    }
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
    ProductModel? productContext,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) throw 'Cart not found';

      if (quantity <= 0) {
        await removeFromCart(userId: userId, productId: productId);
        return;
      }

      // Validate quantity limits before updating
      // For update operations, we don't add to existing quantity, we set it directly
      final validationResult = await _validateQuantityLimits(
        productId: productId,
        requestedQuantity: quantity,
        userId: userId,
        currentCartQuantity: 0, // Set to 0 since we're setting absolute quantity
        productContext: productContext,
      );

      // Handle validation result silently - no user notifications in production
      if (!validationResult.isValid) {
        log('⚠️ Update quantity validation failed: ${validationResult.errorMessage}');
        return; // Silently return without showing error to user
      }

      final updatedItems = cart.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await saveCart(updatedCart);
      log('✅ Cart item quantity updated: $productId -> $quantity');
    } catch (e) {
      log('❌ Error updating cart item quantity: $e');
      throw 'Failed to update item quantity. ${e.toString()}';
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return;

      final updatedItems = cart.items
          .where((item) => item.productId != productId)
          .toList();

      if (updatedItems.isEmpty) {
        // Remove cart entirely if empty
        await clearCart(userId);
        return;
      }

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await saveCart(updatedCart);
      log('✅ Item removed from cart: $productId');
    } catch (e) {
      log('❌ Error removing from cart: $e');
      throw 'Failed to remove item from cart. Please try again.';
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    try {
      await _cartsCollection.doc(userId).delete();
      log('✅ Cart cleared for user: $userId');
    } catch (e) {
      log('❌ Error clearing cart: $e');
      throw 'Failed to clear cart. Please try again.';
    }
  }

  /// Get cart stream for real-time updates
  Stream<CartModel?> getCartStream(String userId) {
    try {
      return _cartsCollection.doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          return CartModel.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      log('❌ Error creating cart stream: $e');
      return Stream.value(null);
    }
  }

  /// Get current user cart stream
  Stream<CartModel?> getCurrentUserCartStream() {
    try {
      if (currentUserId == null) return Stream.value(null);
      return getCartStream(currentUserId!);
    } catch (e) {
      log('❌ Error creating current user cart stream: $e');
      return Stream.value(null);
    }
  }

  // WISHLIST METHODS

  /// Get user wishlist
  Future<WishlistModel?> getWishlist(String userId) async {
    try {
      final doc = await _wishlistsCollection.doc(userId).get();
      
      if (doc.exists) {
        return WishlistModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      log('❌ Error fetching wishlist: $e');
      throw 'Failed to fetch wishlist. Please try again.';
    }
  }

  /// Get current user wishlist
  Future<WishlistModel?> getCurrentUserWishlist() async {
    try {
      if (currentUserId == null) return null;
      return await getWishlist(currentUserId!);
    } catch (e) {
      log('❌ Error fetching current user wishlist: $e');
      return null;
    }
  }

  /// Create or update wishlist
  Future<void> saveWishlist(WishlistModel wishlist) async {
    try {
      final updatedWishlist = wishlist.copyWith(updatedAt: DateTime.now());
      await _wishlistsCollection.doc(wishlist.userId).set(updatedWishlist.toFirestore());
      log('✅ Wishlist saved successfully for user: ${wishlist.userId}');
    } catch (e) {
      log('❌ Error saving wishlist: $e');
      throw 'Failed to save wishlist. Please try again.';
    }
  }

  /// Add product to wishlist
  Future<void> addToWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final wishlist = await getWishlist(userId);
      final now = DateTime.now();

      List<String> updatedProducts;
      
      if (wishlist == null) {
        // Create new wishlist with first product
        updatedProducts = [productId];
      } else {
        // Update existing wishlist
        updatedProducts = List.from(wishlist.products);
        
        // Check if product already exists
        if (!updatedProducts.contains(productId)) {
          updatedProducts.add(productId);
        }
      }

      final updatedWishlist = WishlistModel(
        userId: userId,
        products: updatedProducts,
        updatedAt: now,
      );

      await saveWishlist(updatedWishlist);
      log('✅ Product added to wishlist: $productId');
    } catch (e) {
      log('❌ Error adding to wishlist: $e');
      throw 'Failed to add product to wishlist. Please try again.';
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final wishlist = await getWishlist(userId);
      if (wishlist == null) return;

      final updatedProducts = wishlist.products
          .where((id) => id != productId)
          .toList();

      if (updatedProducts.isEmpty) {
        // Remove wishlist entirely if empty
        await clearWishlist(userId);
        return;
      }

      final updatedWishlist = wishlist.copyWith(
        products: updatedProducts,
        updatedAt: DateTime.now(),
      );

      await saveWishlist(updatedWishlist);
      log('✅ Product removed from wishlist: $productId');
    } catch (e) {
      log('❌ Error removing from wishlist: $e');
      throw 'Failed to remove product from wishlist. Please try again.';
    }
  }

  /// Toggle product in wishlist
  Future<void> toggleWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final wishlist = await getWishlist(userId);
      
      if (wishlist == null || !wishlist.containsProduct(productId)) {
        await addToWishlist(userId: userId, productId: productId);
      } else {
        await removeFromWishlist(userId: userId, productId: productId);
      }
    } catch (e) {
      log('❌ Error toggling wishlist: $e');
      throw 'Failed to update wishlist. Please try again.';
    }
  }

  /// Clear entire wishlist
  Future<void> clearWishlist(String userId) async {
    try {
      await _wishlistsCollection.doc(userId).delete();
      log('✅ Wishlist cleared for user: $userId');
    } catch (e) {
      log('❌ Error clearing wishlist: $e');
      throw 'Failed to clear wishlist. Please try again.';
    }
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final wishlist = await getWishlist(userId);
      return wishlist?.containsProduct(productId) ?? false;
    } catch (e) {
      log('❌ Error checking wishlist: $e');
      return false;
    }
  }

  /// Get wishlist stream for real-time updates
  Stream<WishlistModel?> getWishlistStream(String userId) {
    try {
      return _wishlistsCollection.doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          return WishlistModel.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      log('❌ Error creating wishlist stream: $e');
      return Stream.value(null);
    }
  }

  /// Get current user wishlist stream
  Stream<WishlistModel?> getCurrentUserWishlistStream() {
    try {
      if (currentUserId == null) return Stream.value(null);
      return getWishlistStream(currentUserId!);
    } catch (e) {
      log('❌ Error creating current user wishlist stream: $e');
      return Stream.value(null);
    }
  }

  // UTILITY METHODS

  /// Move item from wishlist to cart
  Future<void> moveFromWishlistToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      await addToCart(userId: userId, productId: productId, quantity: quantity);
      await removeFromWishlist(userId: userId, productId: productId);
      log('✅ Product moved from wishlist to cart: $productId');
    } catch (e) {
      log('❌ Error moving from wishlist to cart: $e');
      throw 'Failed to move product to cart. Please try again.';
    }
  }

  /// Get cart and wishlist stats
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final cart = await getCart(userId);
      final wishlist = await getWishlist(userId);

      return {
        'cartItems': cart?.totalItems ?? 0,
        'cartProducts': cart?.items.length ?? 0,
        'wishlistProducts': wishlist?.totalProducts ?? 0,
      };
    } catch (e) {
      log('❌ Error fetching cart/wishlist stats: $e');
      return {
        'cartItems': 0,
        'cartProducts': 0,
        'wishlistProducts': 0,
      };
    }
  }

  @override
  void onReady() {
    super.onReady();
    log('CartWishlistService initialized with enterprise schema');
  }
}
