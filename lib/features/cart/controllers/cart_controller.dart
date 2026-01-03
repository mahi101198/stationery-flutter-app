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
      AppLogger.debug('Cannot start cart listener: No user logged in', tag: 'CartController');
      return;
    }
    
    // Cancel existing subscription before creating new one
    _cartSubscription?.cancel();
    
    AppLogger.debug('Starting cart listener for user: $_currentUserId', tag: 'CartController');
    
    // Listen to cart changes in real-time
    _cartSubscription = _cartService.getCartStream(_currentUserId!).listen(
      (cart) {
        if (cart != null) {
          AppLogger.debug('Cart updated: ${cart.items.length} items', tag: 'CartController');
          cartItems.assignAll(cart.items);
          _loadProductDetails();
        } else {
          AppLogger.debug('Cart is empty or deleted', tag: 'CartController');
          cartItems.clear();
          cartProducts.clear();
          calculateTotal();
        }
      },
      onError: (error) {
        AppLogger.logErrorWithContext('CartStream', error, StackTrace.current);
        // Silently handle error - no user notification in production
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
      
      final productIds = cartItems.map((item) => item.productId).toList();
      
      // Check if we have all products loaded
      final currentProductIds = cartProducts.map((p) => p.productId).toSet();
      final requestedProductIds = productIds.toSet();
      final missingProductIds = requestedProductIds.difference(currentProductIds);
      
      AppLogger.debug(
        'Loading products - Current: ${currentProductIds.length}, Requested: ${requestedProductIds.length}, Missing: ${missingProductIds.length}',
        tag: 'CartController');
      
      // If all products are loaded and count matches (no new items), just recalculate total
      if (missingProductIds.isEmpty && 
          currentProductIds.length == requestedProductIds.length && 
          !showLoading) {
        AppLogger.debug('All products already loaded, skipping fetch', tag: 'CartController');
        calculateTotal();
        return;
      }
      
      // Fetch all products to ensure consistency
      AppLogger.debug('Fetching ${productIds.length} products from service', tag: 'CartController');
      final products = await _productService.getProductsByIds(productIds);
      AppLogger.debug('Fetched ${products.length} products successfully', tag: 'CartController');
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

  Future<void> addToCart(String productId, int quantity, {String? selectedColor}) async {
    try {
      if (_currentUserId == null) {
        AppLogger.error('Add to cart failed: No user logged in', tag: 'CART');
        return;
      }
      
      if (productId.isEmpty) {
        AppLogger.error('Add to cart failed: Empty product ID', tag: 'CART');
        return;
      }
      
      if (quantity <= 0) {
        AppLogger.error('Add to cart failed: Invalid quantity $quantity', tag: 'CART');
        return;
      }
      
      AppLogger.logCartOperation('addToCart', productId: productId, quantity: quantity);
      
      await executeWithLoading(
        'addToCart',
        () async {
          await _cartService.addToCart(
            userId: _currentUserId!, 
            productId: productId, 
            quantity: quantity,
            selectedColor: selectedColor,
          );
        },
        loadingMessage: 'Adding to cart...',
      );
      
      // Removed notification for better UX - cart addition is indicated by UI changes
    } catch (e) {
      AppLogger.logErrorWithContext('addToCart', e, StackTrace.current);
      // Silently handle error - no user notification in production
    }
  }

  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    // Store original quantity for rollback
    final originalItem = cartItems.firstWhereOrNull((item) => item.productId == productId);
    final originalQuantity = originalItem?.quantity ?? 0;
    
    try {
      if (_currentUserId == null) {
        AppLogger.error('Update cart failed: No user logged in', tag: 'CART');
        return;
      }
      
      if (productId.isEmpty) {
        AppLogger.error('Update cart failed: Empty product ID', tag: 'CART');
        return;
      }
      
      // Get product details for validation
      final product = cartProducts.firstWhereOrNull((p) => p.productId == productId);
      if (product == null) {
        AppLogger.error('Update cart failed: Product details not found', tag: 'CART');
        return;
      }
      
      // Validate quantity before optimistic update silently
      if (quantity > 0) {
        // Check stock availability silently
        if (quantity > product.stock) {
          AppLogger.warning('Stock limit: Only ${product.stock} available for $productId', tag: 'CART');
          return;
        }
        
        // Check max quantity per user silently
        if (quantity > product.maxQuantityPerUser) {
          AppLogger.warning('Quantity limit: Max ${product.maxQuantityPerUser} for $productId', tag: 'CART');
          return;
        }
      }
      
      AppLogger.logCartOperation('updateCartItemQuantity', productId: productId, quantity: quantity);
      
      // Mark item as updating
      updatingItems[productId] = true;
      
      // Optimistic update: Update the UI immediately before the server responds
      final itemIndex = cartItems.indexWhere((item) => item.productId == productId);
      if (itemIndex != -1) {
        if (quantity <= 0) {
          // Remove item optimistically
          cartItems.removeAt(itemIndex);
        } else {
          // Update quantity optimistically
          final updatedItem = cartItems[itemIndex].copyWith(quantity: quantity);
          cartItems[itemIndex] = updatedItem;
        }
        calculateTotal();
      }
      
      // Update cart item quantity on the server
      // The stream will sync if there are any differences
      if (quantity <= 0) {
        await _cartService.removeFromCart(userId: _currentUserId!, productId: productId);
      } else {
        await _cartService.updateCartItemQuantity(
          userId: _currentUserId!, 
          productId: productId, 
          quantity: quantity,
        );
      }
      
      // Remove from updating items
      updatingItems.remove(productId);
    } catch (e) {
      updatingItems.remove(productId);
      AppLogger.logErrorWithContext('updateCartItemQuantity', e, StackTrace.current);
      
      // Rollback optimistic update on error
      if (originalItem != null) {
        final itemIndex = cartItems.indexWhere((item) => item.productId == productId);
        if (itemIndex != -1) {
          cartItems[itemIndex] = originalItem;
        } else if (originalQuantity > 0) {
          // Item was removed optimistically, add it back
          cartItems.add(originalItem);
        }
        calculateTotal();
      }
      
      AppLogger.logErrorWithContext('updateCartItemQuantity', e, StackTrace.current);
      // Silently handle error - no user notification in production
    }
  }

  void calculateTotal() {
    total.value = 0.0;
    
    for (final cartItem in cartItems) {
      final product = cartProducts.firstWhereOrNull(
        (p) => p.productId == cartItem.productId,
      );
      
      if (product != null && product.price > 0) {
        final price = product.hasDiscount 
            ? product.price 
            : product.price;
        total.value += price * cartItem.quantity;
      } else {
        // Log missing product for debugging
            // Log missing product for debugging
            // AppLogger.warning('Product not found for cart item: ${cartItem.productId}', tag: 'CartController');
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
  ProductModel? getProductForCartItem(String productId) {
    return cartProducts.firstWhereOrNull((p) => p.productId == productId);
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
