import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/features/product/controllers/review_controller.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class ProductDetailController extends GetxController {
  static ProductDetailController get instance => Get.find();

  var isLoading = true.obs;
  var isCartUpdating = false.obs;
  var isRefreshing = false.obs;

  var isInWishlist = false.obs;

  var quantity = 1.obs;
  var cartQuantity = 0.obs;
  var selectedColor = ''.obs;

  Rxn<ProductModel> product = Rxn<ProductModel>();
  late ConfettiController confettiController;

  // Get reference to services
  ProductCacheService get _cacheService => ProductCacheService.instance;
  CartController get _cartController {
    try {
      return Get.find<CartController>();
    } catch (_) {
      return Get.put(CartController());
    }
  }
  ReviewController get reviewController {
    try {
      return Get.find<ReviewController>();
    } catch (_) {
      return Get.put(ReviewController());
    }
  }

  @override
  void onInit() {
    confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    startListeners();
    super.onInit();
  }

  void startListeners() {
    final dynamic argument = Get.arguments;
    String? extractedId;
    
    // Handle both direct string and Map arguments
    if (argument is String) {
      extractedId = argument;
    } else if (argument is Map<String, dynamic>) {
      extractedId = argument['productId'] as String?;
    }

    if (extractedId == null || extractedId.isEmpty) {
      TLoaders.errorSnackBar(
        title: "Oh snap!",
        message: "Seems like the product ID got messed up.",
      );

      return;
    } else {
      print('🔍 ProductDetailController: Starting to fetch product with ID: $extractedId');
      fetchProduct(extractedId);
    }

    // Listen to cart changes to update product's cart quantity
    ever(_cartController.cartItems, (cartItems) {
      if (product.value != null) {
        final cartItem = cartItems.firstWhereOrNull(
          (item) => item.productId == product.value!.productId,
        );
        if (cartItem != null) {
          quantity.value = cartItem.quantity;
          cartQuantity.value = cartItem.quantity;
        } else {
          cartQuantity.value = 0;
        }
      }
    });

    // Listen to wishlist changes to update product's wishlist status
    ever(_cacheService.wishlistIds, (wishlistIds) {
      if (product.value != null) {
        isInWishlist.value = wishlistIds.contains(product.value!.productId);
      }
    });
  }

  Future<void> fetchProduct(String id) async {
    try {
      isLoading.value = true;
      print('🔍 ProductDetailController: Fetching product details for: $id');

      // Fetch complete product details from both collections
      final fetchedProduct = await _cacheService.getCompleteProductDetails(id);

      // Update the product
      product.value = fetchedProduct;
      print('✅ ProductDetailController: Product details loaded successfully');

      // Update the quantity and wishlist status from cache service
      if (fetchedProduct != null) {
        // Get cart status from new cart controller
        final cartItem = _cartController.getCartItemByProductId(fetchedProduct.productId);
        if (cartItem != null) {
          quantity.value = cartItem.quantity;
          cartQuantity.value = cartItem.quantity;
        } else {
          cartQuantity.value = 0;
        }
        isInWishlist.value = _cacheService.wishlistIds.contains(fetchedProduct.productId);
        
        // Load reviews for this product
        reviewController.loadProductReviews(fetchedProduct.productId);
        
        // Set default selected color if colors available
        if (fetchedProduct.colors.isNotEmpty) {
          selectedColor.value = fetchedProduct.colors.first;
          print('🎨 Colors found: ${fetchedProduct.colors}');
        } else {
          print('⚠️ No colors found in product');
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }

  void updateCartQuantity() {
    if (product.value == null) return;
    
    final cartItem = _cartController.cartItems.firstWhereOrNull(
      (item) => item.productId == product.value!.productId,
    );
    
    cartQuantity.value = cartItem?.quantity ?? 0;
  }

  void setQuantity(int newQuantity) {
    final maxAllowed = _getMaxAllowedQuantity();
    if (newQuantity <= maxAllowed && newQuantity >= 1) {
      quantity.value = newQuantity;
    }
  }

  int _getMaxAllowedQuantity() {
    if (product.value == null) return 0;
    
    final stockLimit = product.value!.stock;
    final userLimit = product.value!.maxQuantityPerUser;
    
    if (userLimit != null && userLimit > 0) {
      return stockLimit < userLimit ? stockLimit : userLimit;
    }
    
    return stockLimit;
  }

  void incrementQuantity() {
    final maxAllowed = _getMaxAllowedQuantity();
    if (quantity.value < maxAllowed) {
      quantity.value++;
    } else {
      // Show appropriate message based on the limiting factor
      if (product.value?.maxQuantityPerUser != null && 
          quantity.value >= product.value!.maxQuantityPerUser!) {
        TLoaders.warningSnackBar(
          title: "Quantity Limit",
          message: "Maximum ${product.value!.maxQuantityPerUser} items allowed per user.",
        );
      } else if (quantity.value >= maxQuantity) {
        TLoaders.warningSnackBar(
          title: "Stock Limited",
          message: "Only $maxQuantity items available in stock.",
        );
      }
    }
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  Future<void> refreshProduct() async {
    if (product.value == null) return;

    try {
      isRefreshing.value = true;
      print('🔄 ProductDetailController: Refreshing product details for: ${product.value!.productId}');

      // Force refresh from remote to get latest complete product data
      final fetchedProduct = await _cacheService.getCompleteProductDetails(
        product.value!.productId,
      );

      product.value = fetchedProduct;
      print('✅ ProductDetailController: Product details refreshed successfully');
      // Don't update quantity or wishlist when refreshing product
      // This is only for stock or isActive changes in database
    } catch (e) {
      print('❌ ProductDetailController: Error refreshing product: $e');
      TLoaders.errorSnackBar(
        title: e.toString().contains('internet') ? "Network Error" : "Oh snap!",
        message: e.toString(),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> addToCart() async {
    if (product.value == null) return;

    isCartUpdating.value = true;

    try {
      // Refresh product data from remote before adding to cart
      await refreshProduct();

      if (product.value == null) {
        TLoaders.errorSnackBar(
          title: "Product Error",
          message: "Product information could not be loaded.",
        );
        return;
      }

      // Check if product is available
      if (!product.value!.isAvailable) {
        TLoaders.errorSnackBar(
          title: "Product Unavailable",
          message: "This product is currently unavailable.",
        );
        return;
      }

      // Check if product is in stock
      if (product.value!.stock <= 0) {
        TLoaders.errorSnackBar(
          title: "Out of Stock",
          message: "This product is currently out of stock.",
        );
        return;
      }

      // Validate quantity against available stock and user limits
      final maxAllowed = _getMaxAllowedQuantity();
      if (quantity.value > maxAllowed) {
        quantity.value = maxAllowed;
        
        // Show appropriate message based on the limiting factor
        if (product.value!.maxQuantityPerUser != null && 
            maxAllowed == product.value!.maxQuantityPerUser) {
          TLoaders.warningSnackBar(
            title: "Quantity Limit",
            message: "Maximum ${product.value!.maxQuantityPerUser} items allowed per user. Quantity adjusted.",
          );
        } else {
          TLoaders.warningSnackBar(
            title: "Stock Limited",
            message: "Only $maxAllowed items available. Quantity adjusted.",
          );
        }
      }

      final isUpdate = cartQuantity.value > 0 && cartQuantity.value != quantity.value;

      if (isUpdate) {
        // Update existing cart item quantity
        await _cartController.updateCartItemQuantity(product.value!.productId, quantity.value);
      } else {
        // Add new item to cart with selected color
        await _cartController.addToCart(
          product.value!.productId, 
          quantity.value,
          selectedColor: selectedColor.value.isNotEmpty ? selectedColor.value : null,
        );
      }

      // Update cart quantity locally
      cartQuantity.value = quantity.value;

      // Play confetti animation
      confettiController.play();

      // Removed toast notification for better UX - cart addition is indicated by UI changes
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    } finally {
      isCartUpdating.value = false;
    }
  }

  Future<void> toggleWishlist() async {
    if (product.value == null) return;

    try {
      await _cacheService.toggleWishlistStatus(product.value!.productId);
      // Product will be automatically updated through reactive listeners
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    }
  }

  // Helper methods for product state
  bool get canAddToCart {
    return product.value != null &&
        product.value!.isAvailable &&
        product.value!.stock > 0;
  }

  int get maxQuantity {
    return _getMaxAllowedQuantity();
  }

  bool get isOutOfStock {
    return product.value?.stock == 0;
  }

  bool get isInactive {
    return product.value?.isAvailable == false;
  }

  bool get hasQuantityLimit {
    return product.value?.maxQuantityPerUser != null && 
           product.value!.maxQuantityPerUser! > 0;
  }

  String get quantityLimitMessage {
    if (!hasQuantityLimit) return '';
    return 'Max ${product.value!.maxQuantityPerUser} per user';
  }

  // Color selection method
  void selectColor(String color) {
    selectedColor.value = color;
    print('🎨 ProductDetailController: Color selected: $color');
  }

  bool get hasColors {
    return product.value != null && product.value!.colors.isNotEmpty;
  }
}
