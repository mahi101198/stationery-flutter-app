import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rps_stationery/data/services/cart_wishlist_service.dart';
import 'package:rps_stationery/data/services/product_service.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/loading/loading_state_manager.dart';
import 'package:rps_stationery/utils/logging/app_logger.dart';

/// Cart Controller
/// NOTE: All productId references in cart items now refer to SKU IDs in the new architecture.
/// Cart items are identified by their SKU ID (e.g., "NB-BLUE-P1") rather than
/// product ID, allowing different variants to be tracked separately.
class CartController extends GetxController {
  static CartController get instance {
    try {
      return Get.find<CartController>();
    } catch (_) {
      return Get.put(CartController());
    }
  }

  var isLoading = false.obs;
  var cartItems = <CartItem>[].obs;
  var cartProducts = <ProductModel>[].obs;
  var total = 0.0.obs;
  
  // Track which cart items are currently being updated
  var updatingItems = <String, bool>{}.obs;

  // Services
  late final CartWishlistService _cartService;
  late final ProductService _productService;
  
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  StreamSubscription<CartModel?>? _cartSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    startListeningToCart();
  }
  
  void _initializeServices() {
    try {
      _cartService = Get.find<CartWishlistService>();
      _productService = Get.find<ProductService>();
    } catch (e) {
      // Fallback if services are not yet available
      _cartService = CartWishlistService.instance;
      _productService = ProductService.instance;
    }
  }
  
  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }

  void startListeningToCart() {
    if (_currentUserId == null) {
      print('⚠️ Cannot start cart listener: No user logged in');
      AppLogger.debug('Cannot start cart listener: No user logged in', tag: 'CartController');
      return;
    }
    
    // Cancel existing subscription before creating new one
    _cartSubscription?.cancel();
    
    print('🔊 ════════════════════════════════════════════════════════');
    print('🔊 STARTING CART LISTENER');
    print('🔊 User ID: $_currentUserId');
    print('🔊 ════════════════════════════════════════════════════════');
    AppLogger.debug('Starting cart listener for user: $_currentUserId', tag: 'CartController');
    
    // Listen to cart changes in real-time
    _cartSubscription = _cartService.getCartStream(_currentUserId!).listen(
      (cart) {
        if (cart != null) {
          print('✅ Cart stream update: ${cart.items.length} items');
          AppLogger.debug('Cart updated: ${cart.items.length} items', tag: 'CartController');
          cartItems.assignAll(cart.items);
          _loadProductDetails();
        } else {
          print('ℹ️ Cart is empty');
          AppLogger.debug('Cart is empty or deleted', tag: 'CartController');
          cartItems.clear();
          cartProducts.clear();
          calculateTotal();
        }
      },
      onError: (error) {
        print('❌ Cart stream error: $error');
        AppLogger.logErrorWithContext('CartStream', error, StackTrace.current);
        // Try to reconnect after error
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentUserId != null) {
            startListeningToCart();
          }
        });
      },
      cancelOnError: false, // Keep subscription alive even after errors
    );
  }
  
  /// Restart cart listener (useful for debugging or recovering from errors)
  void restartCartListener() {
    AppLogger.debug('Restarting cart listener...', tag: 'CartController');
    startListeningToCart();
  }
  
  Future<void> _loadProductDetails({bool showLoading = false}) async {
    if (cartItems.isEmpty) {
      AppLogger.debug('Cart items empty, clearing products', tag: 'CartController');
      cartProducts.clear();
      calculateTotal();
      return;
    }
    
    try {
      // Only show loading on initial load or explicit refresh, not on quantity updates
      if (showLoading) {
        isLoading.value = true;
      }
      
      // NOTE: productId field now contains SKU IDs (e.g., "NB-BLUE-P1")
      final skuIds = cartItems.map((item) => item.productId).toList();
      
      // Check if we have all products loaded
      final currentProductIds = cartProducts.map((p) => p.productId).toSet();
      
      AppLogger.debug(
        'Loading products for ${skuIds.length} SKUs',
        tag: 'CartController');
      
      // Fetch products by SKU IDs from product_details collection
      AppLogger.debug('Fetching products for ${skuIds.length} SKUs from product_details', tag: 'CartController');
      final products = await _productService.getProductsBySKUIds(skuIds);
      AppLogger.debug('Fetched ${products.length} unique products successfully', tag: 'CartController');
      
      // DEBUG: Log image URLs for each product
      for (final product in products) {
        print('📦 Product loaded: ${product.title}');
        print('   ├─ Product ID: ${product.productId}');
        print('   ├─ Main Image: ${product.media.mainImage}');
        print('   ├─ Display Image: ${product.displayImage}');
        print('   ├─ Gallery Images: ${product.media.galleryImages.length}');
        print('   └─ All Images: ${product.allImages.length}');
      }
      
      cartProducts.assignAll(products);
      calculateTotal();
    } catch (e) {
      AppLogger.logErrorWithContext('_loadProductDetails', e, StackTrace.current);
      // Silently handle error - no user notification in production
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshCart() async {
    try {
      await _loadProductDetails(showLoading: true);
      
      if (cartItems.isNotEmpty) {
        TLoaders.successSnackBar(
          title: "Cart Refreshed",
          message: "Cart is updated with the latest product information.",
        );
      }
    } catch (e) {
      // Silently handle error - log only, no user notification
      AppLogger.logErrorWithContext('refreshCart', e, StackTrace.current);
    }
  }

  /// Refresh cart silently without showing notification
  Future<void> refreshCartSilently() async {
    try {
      await _loadProductDetails(showLoading: true);
    } catch (e) {
      // Silently handle error - log only, no user notification
      AppLogger.logErrorWithContext('refreshCartSilently', e, StackTrace.current);
    }
  }

  Future<void> deleteCartItem(String productId) async {
    try {
      if (_currentUserId == null) {
        AppLogger.error('Delete cart item failed: No user logged in', tag: 'CART');
        return;
      }
      
      if (productId.isEmpty) {
        AppLogger.error('Delete cart item failed: Empty product ID', tag: 'CART');
        return;
      }
      
      // Mark item as updating
      updatingItems[productId] = true;
      
      // Optimistic update: Remove from UI immediately
      cartItems.removeWhere((item) => item.productId == productId);
      calculateTotal();
      
      // Remove cart item from server
      // The stream will sync if there are any differences
      await _cartService.removeFromCart(userId: _currentUserId!, productId: productId);
      // Removed notification for better UX - cart removal is indicated by UI changes
      
      // Remove from updating items
      updatingItems.remove(productId);
    } catch (e) {
      updatingItems.remove(productId);
      AppLogger.logErrorWithContext('deleteCartItem', e, StackTrace.current);
      
      // Revert optimistic update on error by refreshing from stream
      // The stream will automatically sync the correct state
    }
  }

  Future<void> addToCart(String productId, int quantity, {String? selectedColor, ProductModel? productContext}) async {
    print('🛒 ════════════════════════════════════════════════════════');
    print('🛒 CART CONTROLLER - ADD TO CART');
    print('🛒 ════════════════════════════════════════════════════════');
    print('  Product ID (SKU): $productId');
    print('  Quantity: $quantity');
    print('  Selected Color: $selectedColor');
    
    try {
      if (_currentUserId == null) {
        print('❌ No user logged in');
        AppLogger.error('Add to cart failed: No user logged in', tag: 'CART');
        return;
      }
      
      print('✅ User ID: $_currentUserId');
      
      if (productId.isEmpty) {
        print('❌ Empty product ID');
        AppLogger.error('Add to cart failed: Empty product ID', tag: 'CART');
        return;
      }
      
      if (quantity <= 0) {
        print('❌ Invalid quantity: $quantity');
        AppLogger.error('Add to cart failed: Invalid quantity $quantity', tag: 'CART');
        return;
      }
      
      // Validate max per order limit if product context is provided
      if (productContext != null) {
        final sku = productContext.productSkus.firstWhereOrNull((s) => s.skuId == productId);
        if (sku != null && quantity > sku.maxPerOrder) {
          TLoaders.customToast(
            message: "Maximum ${sku.maxPerOrder} units per order for this item.",
          );
          AppLogger.warning('Max per order limit: ${sku.maxPerOrder} for $productId', tag: 'CART');
          return;
        }
      }
      
      print('✅ Validation passed');
      AppLogger.logCartOperation('addToCart', productId: productId, quantity: quantity);
      
      print('🔄 Calling CartService.addToCart...');
      await executeWithLoading(
        'addToCart',
        () async {
          print('  🔹 Inside executeWithLoading callback');
          await _cartService.addToCart(
            userId: _currentUserId!, 
            productId: productId, 
            quantity: quantity,
            selectedColor: selectedColor,
            productContext: productContext,
          );
          print('  ✅ CartService.addToCart completed');
        },
        loadingMessage: 'Adding to cart...',
      );
      
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ CART CONTROLLER - ADD TO CART SUCCESS');
      print('✅ ════════════════════════════════════════════════════════');
      
      // Removed notification for better UX - cart addition is indicated by UI changes
    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ CART CONTROLLER - ADD TO CART ERROR');
      print('❌ Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      AppLogger.logErrorWithContext('addToCart', e, StackTrace.current);
      // Silently handle error - no user notification in production
    }
  }

  Future<void> updateCartItemQuantity(String productId, int quantity, {ProductModel? productContext}) async {
    // Store original quantity for rollback
    final originalItem = cartItems.firstWhereOrNull((item) => item.productId == productId);
    final originalQuantity = originalItem?.quantity ?? 0;
    
    print('🔄 ═══════════════════════════════════════════════════════');
    print('🔄 UPDATING CART ITEM QUANTITY');
    print('🔄 Product ID (SKU): $productId');
    print('🔄 New Quantity: $quantity');
    print('🔄 Original Quantity: $originalQuantity');
    print('🔄 ═══════════════════════════════════════════════════════');
    
    try {
      if (_currentUserId == null) {
        print('❌ No user logged in');
        AppLogger.error('Update cart failed: No user logged in', tag: 'CART');
        return;
      }
      
      if (productId.isEmpty) {
        print('❌ Empty product ID');
        AppLogger.error('Update cart failed: Empty product ID', tag: 'CART');
        return;
      }
      
      // Get product details for validation
      final product = productContext ?? cartProducts.firstWhereOrNull((p) => p.productId == productId);
      
      // Only validate if product is found and quantity > 0
      if (product != null && quantity > 0) {
        // Find the specific SKU for this cart item
        final sku = product.productSkus.firstWhereOrNull((s) => s.skuId == productId);
        
        // Check max per order limit (SKU-level)
        if (sku != null && quantity > sku.maxPerOrder) {
          print('⚠️ Max per order limit reached: ${sku.maxPerOrder}');
          TLoaders.customToast(
            message: "Maximum ${sku.maxPerOrder} units per order for this item.",
          );
          AppLogger.warning('Max per order limit: ${sku.maxPerOrder} for $productId', tag: 'CART');
          return;
        }
        
        // Check stock availability silently
        if (quantity > product.stock) {
          print('⚠️ Stock limit reached: ${product.stock}');
          TLoaders.customToast(
            message: "Only ${product.stock} items available in stock.",
          );
          AppLogger.warning('Stock limit: Only ${product.stock} available for $productId', tag: 'CART');
          return;
        }
        
        // Check max quantity per user silently
        if (quantity > product.maxQuantityPerUser) {
          print('⚠️ User quantity limit reached: ${product.maxQuantityPerUser}');
          TLoaders.customToast(
            message: "Maximum ${product.maxQuantityPerUser} items per user.",
          );
          AppLogger.warning('Quantity limit: Max ${product.maxQuantityPerUser} for $productId', tag: 'CART');
          return;
        }
      }
      
      AppLogger.logCartOperation('updateCartItemQuantity', productId: productId, quantity: quantity);
      
      // Mark item as updating
      updatingItems[productId] = true;
      print('🔄 Marked item as updating');
      
      // Optimistic update: Update the UI immediately before the server responds
      final itemIndex = cartItems.indexWhere((item) => item.productId == productId);
      if (itemIndex != -1) {
        if (quantity <= 0) {
          // Remove item optimistically
          print('➖ Removing item optimistically (quantity <= 0)');
          cartItems.removeAt(itemIndex);
        } else {
          // Update quantity optimistically
          print('🔄 Updating quantity optimistically to $quantity');
          final updatedItem = cartItems[itemIndex].copyWith(quantity: quantity);
          cartItems[itemIndex] = updatedItem;
        }
        calculateTotal();
        print('✅ UI updated optimistically');
      } else {
        print('⚠️ Cart item not found in local state for optimistic update');
      }
      
      // Update cart item quantity on the server
      // The stream will sync if there are any differences
      if (quantity <= 0) {
        print('➖ Removing item from server (quantity <= 0)');
        await _cartService.removeFromCart(userId: _currentUserId!, productId: productId);
        print('✅ Item removed from server');
      } else {
        print('🔄 Updating quantity on server to $quantity');
        await _cartService.updateCartItemQuantity(
          userId: _currentUserId!, 
          productId: productId, 
          quantity: quantity,
          productContext: productContext,
        );
        print('✅ Quantity updated on server');
      }
      
      print('✅ ═══════════════════════════════════════════════════════');
      print('✅ CART QUANTITY UPDATE SUCCESS');
      print('✅ ═══════════════════════════════════════════════════════');
      
    } catch (e) {
      print('❌ ═══════════════════════════════════════════════════════');
      print('❌ CART QUANTITY UPDATE ERROR');
      print('❌ Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ ═══════════════════════════════════════════════════════');
      
      AppLogger.logErrorWithContext('updateCartItemQuantity', e, StackTrace.current);
      
      // Rollback optimistic update on error
      if (originalItem != null) {
        final itemIndex = cartItems.indexWhere((item) => item.productId == productId);
        if (itemIndex != -1) {
          cartItems[itemIndex] = originalItem;
          print('🔄 Rolled back optimistic update to quantity ${originalItem.quantity}');
        } else if (originalQuantity > 0) {
          // Item was removed optimistically, add it back
          cartItems.add(originalItem);
          print('➕ Added back removed item (rollback)');
        }
        calculateTotal();
      }
      
      // Show user-friendly error message
      TLoaders.customToast(
        message: "Failed to update quantity. Please try again.",
      );
      
    } finally {
      // Remove from updating items
      updatingItems.remove(productId);
      print('✅ Removed updating flag for $productId');
    }
  }

  void calculateTotal() {
    total.value = 0.0;
    
    for (final cartItem in cartItems) {
      // Check if cart item has enhanced pricing data (price > 0)
      if (cartItem.price != null && cartItem.price! > 0) {
        // Use enhanced cart pricing directly
        total.value += cartItem.price! * cartItem.quantity;
      } else {
        // Fallback to product lookup for legacy cart items
        final product = cartProducts.firstWhereOrNull(
          (p) => p.productSkus.any((sku) => sku.skuId == cartItem.productId),
        );
        
        if (product != null) {
          // Find the specific SKU within the product
          final sku = product.productSkus.firstWhereOrNull(
            (s) => s.skuId == cartItem.productId,
          );
          
          if (sku != null && sku.price > 0) {
            // Use SKU price for calculation
            total.value += sku.price * cartItem.quantity;
          }
        } else {
          // Log missing product for debugging
          AppLogger.warning('Product not found for SKU: ${cartItem.productId}', tag: 'CartController');
        }
      }
    }
  }

  Future<void> clearCart() async {
    try {
      if (_currentUserId == null) {
        AppLogger.error('Clear cart failed: No user logged in', tag: 'CART');
        return;
      }
      
      await _cartService.clearCart(_currentUserId!);
      // Removed notification for better UX - cart clearing is indicated by UI changes
    } catch (e) {
      AppLogger.logErrorWithContext('clearCart', e, StackTrace.current);
      // Silently handle error - no user notification in production
    }
  }

  /// Clear cart silently without showing notification
  Future<void> clearCartSilently() async {
    try {
      if (_currentUserId == null) {
        AppLogger.error('Clear cart silently failed: No user logged in', tag: 'CART');
        return;
      }
      
      await _cartService.clearCart(_currentUserId!);
    } catch (e) {
      AppLogger.logErrorWithContext('clearCartSilently', e, StackTrace.current);
      // Silently handle error - no user notification in production
    }
  }
  
  // Helper method to get product details for a cart item
  ProductModel? getProductForCartItem(String skuId) {
    // productId in cartItem actually contains SKU ID, not product ID
    // So we need to find the product that contains this SKU
    try {
      final product = cartProducts.firstWhereOrNull((p) {
        final hasSku = p.productSkus.any((sku) => sku.skuId == skuId);
        if (hasSku) {
          print('✅ [getProductForCartItem] Found product for SKU: $skuId');
          print('   Product: ${p.title}');
          print('   Product ID: ${p.productId}');
        }
        return hasSku;
      });
      
      if (product == null) {
        print('⚠️  [getProductForCartItem] No product found for SKU: $skuId');
      }
      
      return product;
    } catch (e) {
      print('❌ [getProductForCartItem] Error finding product for SKU: $skuId, Error: $e');
      return null;
    }
  }
  
  // Helper method to get CartItem by productId
  CartItem? getCartItemByProductId(String productId) {
    return cartItems.firstWhereOrNull((item) => item.productId == productId);
  }
  
  // Helper method to get combined cart data for UI (product + quantity)
  Map<ProductModel, int> get cartItemsWithProducts {
    final Map<ProductModel, int> result = {};
    
    for (final cartItem in cartItems) {
      final product = getProductForCartItem(cartItem.productId);
      if (product != null) {
        result[product] = cartItem.quantity;
      }
    }
    
    return result;
  }
  
  // Helper method to get total items count
  int get totalItemsCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  // Check if a specific item is being updated
  bool isItemUpdating(String productId) => updatingItems[productId] ?? false;
}
