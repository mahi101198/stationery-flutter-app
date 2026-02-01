import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/features/product/controllers/review_controller.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/models/product_sku_model.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailController extends GetxController {
  static ProductDetailController get instance => Get.find();

  var isLoading = true.obs;
  var isCartUpdating = false.obs;
  var isRefreshing = false.obs;
  var isInWishlist = false.obs;

  var quantity = 1.obs;
  var cartQuantity = 0.obs;
  var hasItemsInCart = false.obs;  // Track if ANY items exist in cart

  // SKU-based state management
  Rxn<ProductSKUModel> selectedSKU = Rxn<ProductSKUModel>();
  RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  Rxn<ProductModel> product = Rxn<ProductModel>();
  late ConfettiController confettiController;

  // Get reference to services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      // Update hasItemsInCart - TRUE if ANY items in cart
      hasItemsInCart.value = cartItems.isNotEmpty;
      
      // Add null safety check before accessing values
      if (product.value != null && selectedSKU.value != null) {
        final cartItem = cartItems.firstWhereOrNull(
          (item) => item.productId == selectedSKU.value!.skuId,
        );
        
        // Schedule update to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cartItem != null) {
            quantity.value = cartItem.quantity;
            cartQuantity.value = cartItem.quantity;
          } else {
            cartQuantity.value = 0;
          }
        });
      }
    });

    // Listen to wishlist changes to update product's wishlist status
    ever(_cacheService.wishlistIds, (wishlistIds) {
      // Add null safety check before accessing value
      if (product.value != null) {
        isInWishlist.value = wishlistIds.contains(product.value!.productId);
      }
    });
  }

  /// Fetch product from product_details collection only
  Future<void> fetchProduct(String id) async {
    try {
      isLoading.value = true;
      print('🔍 ProductDetailController: Fetching product details from product_details collection for: $id');

      // Fetch from product_details collection only
      final productDoc = await _firestore
          .collection('product_details')
          .doc(id)
          .get();

      if (!productDoc.exists) {
        print('❌ ProductDetailController: Product not found in product_details collection');
        product.value = null;
        return;
      }

      // Parse product from product_details
      final fetchedProduct = ProductModel.fromFirestore(productDoc);
      product.value = fetchedProduct;
      print('✅ ProductDetailController: Product details loaded successfully');
      print('   Title: ${fetchedProduct.title}');
      print('   SKUs: ${fetchedProduct.productSkus.length}');
      print('   Variants: ${fetchedProduct.variantAttributes.keys.join(", ")}');

      // Initialize SKU selection
      _initializeSKUSelection();

      // Update wishlist status
      isInWishlist.value = _cacheService.wishlistIds.contains(fetchedProduct.productId);
      
      // Load reviews for this product
      reviewController.loadProductReviews(fetchedProduct.productId);

    } catch (e) {
      print('❌ ProductDetailController: Error fetching product: $e');
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
      product.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize SKU selection based on product variants
  void _initializeSKUSelection() {
    if (product.value == null) return;

    // If only one SKU, auto-select it
    if (product.value!.hasSingleSKU) {
      selectedSKU.value = product.value!.singleSKU;
      selectedAttributes.value = selectedSKU.value!.attributes;
      print('🎯 Auto-selected single SKU: ${selectedSKU.value!.skuId}');
      return;
    }

    // If multiple SKUs, select first available one by default
    final firstAvailableSKU = product.value!.productSkus.firstWhereOrNull(
      (sku) => sku.isAvailable,
    );

    if (firstAvailableSKU != null) {
      selectedSKU.value = firstAvailableSKU;
      selectedAttributes.value = Map<String, String>.from(firstAvailableSKU.attributes);
      print('🎯 Auto-selected first available SKU: ${selectedSKU.value!.skuId}');
    } else {
      // No available SKU, just select the first one to show pricing
      if (product.value!.productSkus.isNotEmpty) {
        selectedSKU.value = product.value!.productSkus.first;
        selectedAttributes.value = Map<String, String>.from(product.value!.productSkus.first.attributes);
        print('⚠️ No available SKUs, selected first SKU for display: ${selectedSKU.value!.skuId}');
      }
    }
  }

  /// Find SKU by selected attributes
  ProductSKUModel? findSKUByAttributes(Map<String, String> attributes) {
    if (product.value == null) return null;

    return product.value!.productSkus.firstWhereOrNull(
      (sku) => mapEquals(sku.attributes, attributes),
    );
  }

  /// Handle attribute selection (e.g., color, size, pack_size)
  void onAttributeSelected(String attributeName, String value) {
    selectedAttributes[attributeName] = value;
    
    // Try to find matching SKU
    final matchingSKU = findSKUByAttributes(selectedAttributes);
    
    if (matchingSKU != null) {
      selectedSKU.value = matchingSKU;
      print('✅ SKU found for selection: ${matchingSKU.skuId}');
      print('   Price: ₹${matchingSKU.price}, MRP: ₹${matchingSKU.mrp}');
      print('   Availability: ${matchingSKU.availability}');
    } else {
      selectedSKU.value = null;
      print('⚠️ No SKU found for attributes: $selectedAttributes');
    }
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }

  void updateCartQuantity() {
    if (selectedSKU.value == null) return;
    
    final cartItem = _cartController.cartItems.firstWhereOrNull(
      (item) => item.productId == selectedSKU.value!.skuId,
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
    if (selectedSKU.value == null) return 0;
    
    // Use SKU's max_per_order limit from purchase_limits
    return selectedSKU.value!.maxPerOrder;
  }

  void incrementQuantity() {
    final maxAllowed = _getMaxAllowedQuantity();
    if (quantity.value < maxAllowed) {
      quantity.value++;
    } else {
      TLoaders.warningSnackBar(
        title: "Purchase Limit Reached",
        message: "Maximum $maxAllowed units per order for this product.",
      );
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

      // Fetch from product_details collection
      final productDoc = await _firestore
          .collection('product_details')
          .doc(product.value!.productId)
          .get();

      if (productDoc.exists) {
        final fetchedProduct = ProductModel.fromFirestore(productDoc);
        product.value = fetchedProduct;
        
        // Re-initialize SKU selection with fresh data
        _initializeSKUSelection();
        
        print('✅ ProductDetailController: Product details refreshed successfully');
      }
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
    print('🛒 ════════════════════════════════════════════════════════');
    print('🛒 ADD TO CART - START');
    print('🛒 ════════════════════════════════════════════════════════');
    
    if (product.value == null) {
      print('❌ Product is null, returning');
      return;
    }

    print('✅ Product: ${product.value!.title}');
    print('✅ Product ID: ${product.value!.productId}');

    // Check if SKU is selected
    if (selectedSKU.value == null) {
      print('❌ No SKU selected');
      TLoaders.errorSnackBar(
        title: "Selection Required",
        message: "Please select all product options before adding to cart.",
      );
      return;
    }

    print('✅ Selected SKU: ${selectedSKU.value!.skuId}');
    print('✅ Quantity: ${quantity.value}');

    isCartUpdating.value = true;
    print('🔄 Cart updating flag set to TRUE');

    try {
      print('🔄 Refreshing product data...');
      // Refresh product data from remote before adding to cart
      await refreshProduct();
      print('✅ Product data refreshed');

      if (selectedSKU.value == null) {
        print('❌ SKU became null after refresh');
        TLoaders.errorSnackBar(
          title: "Product Error",
          message: "Selected product variant is no longer available.",
        );
        return;
      }

      // Check if SKU is available
      if (!selectedSKU.value!.isAvailable) {
        print('❌ SKU not available');
        TLoaders.errorSnackBar(
          title: "Product Unavailable",
          message: "This product variant is currently unavailable.",
        );
        return;
      }

      print('✅ SKU is available');

      // Check if SKU is in stock
      if (selectedSKU.value!.isOutOfStock) {
        print('❌ SKU out of stock');
        TLoaders.errorSnackBar(
          title: "Out of Stock",
          message: "This product variant is currently out of stock.",
        );
        return;
      }

      print('✅ SKU in stock: ${selectedSKU.value!.availableQuantity}');

      // Validate quantity against available stock
      final maxAllowed = _getMaxAllowedQuantity();
      print('📊 Max allowed quantity: $maxAllowed');
      
      if (quantity.value > maxAllowed) {
        print('⚠️ Quantity exceeds max, adjusting to $maxAllowed');
        quantity.value = maxAllowed;
        TLoaders.warningSnackBar(
          title: "Stock Limited",
          message: "Only $maxAllowed items available. Quantity adjusted.",
        );
      }

      final isUpdate = cartQuantity.value > 0 && cartQuantity.value != quantity.value;
      print('📊 Is update: $isUpdate (cartQuantity: ${cartQuantity.value})');

      if (isUpdate) {
        print('🔄 Updating existing cart item...');
        // Update existing cart item quantity
        await _cartController.updateCartItemQuantity(selectedSKU.value!.skuId, quantity.value);
        print('✅ Cart item updated');
      } else {
        print('➕ Adding new item to cart...');
        print('   SKU ID: ${selectedSKU.value!.skuId}');
        print('   Quantity: ${quantity.value}');
        await _cartController.addToCart(
          selectedSKU.value!.skuId, 
          quantity.value,
          productContext: product.value,
        );
        print('✅ Item added to cart');
      }

      // Update cart quantity locally
      cartQuantity.value = quantity.value;
      print('✅ Cart quantity updated locally: ${cartQuantity.value}');

      // Play confetti animation
      confettiController.play();
      print('🎉 Confetti animation triggered');

      print('✅ ════════════════════════════════════════════════════════');
      print('✅ ADD TO CART - SUCCESS');
      print('✅ ════════════════════════════════════════════════════════');

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ADD TO CART - ERROR');
      print('❌ Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    } finally {
      isCartUpdating.value = false;
      print('🔄 Cart updating flag set to FALSE');
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

  /// Buy Now - Add to cart and navigate to checkout
  Future<void> buyNow() async {
    if (product.value == null) return;

    // Check if SKU is selected
    if (selectedSKU.value == null) {
      TLoaders.errorSnackBar(
        title: "Selection Required",
        message: "Please select all product options before proceeding.",
      );
      return;
    }

    isCartUpdating.value = true;

    try {
      // Refresh product data from remote before adding to cart
      await refreshProduct();

      if (selectedSKU.value == null) {
        TLoaders.errorSnackBar(
          title: "Product Error",
          message: "Selected product variant is no longer available.",
        );
        return;
      }

      // Check if SKU is available
      if (!selectedSKU.value!.isAvailable) {
        TLoaders.errorSnackBar(
          title: "Product Unavailable",
          message: "This product variant is currently unavailable.",
        );
        return;
      }

      // Check if SKU is in stock
      if (selectedSKU.value!.isOutOfStock) {
        TLoaders.errorSnackBar(
          title: "Out of Stock",
          message: "This product variant is currently out of stock.",
        );
        return;
      }

      // Validate quantity against available stock
      final maxAllowed = _getMaxAllowedQuantity();
      if (quantity.value > maxAllowed) {
        quantity.value = maxAllowed;
        TLoaders.warningSnackBar(
          title: "Stock Limited",
          message: "Only $maxAllowed items available. Quantity adjusted.",
        );
      }

      // Add to cart
      await _cartController.addToCart(
        selectedSKU.value!.skuId,
        quantity.value,
      );

      // Update cart quantity locally
      cartQuantity.value = quantity.value;

      // Navigate to cart via bottom navigation
      Get.offAllNamed('/bottom-nav', arguments: 'cart');

    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    } finally {
      isCartUpdating.value = false;
    }
  }

  // Helper methods for product state
  bool get canAddToCart {
    return product.value != null &&
        selectedSKU.value != null &&
        selectedSKU.value!.isAvailable;
  }

  int get maxQuantity {
    return _getMaxAllowedQuantity();
  }

  bool get isOutOfStock {
    return selectedSKU.value?.isOutOfStock ?? true;
  }

  bool get isInactive {
    return product.value?.overallAvailability == 'out_of_stock';
  }

  String? get availabilityMessage {
    if (selectedSKU.value == null && selectedAttributes.isNotEmpty) {
      return "This combination is not available";
    }
    
    if (selectedSKU.value?.hasLimitedStock ?? false) {
      return "Limited stock available";
    }
    
    return null;
  }

  // SKU-based pricing getters
  double? get currentPrice => selectedSKU.value?.price;
  double? get currentMRP => selectedSKU.value?.mrp;
  bool get hasDiscount => (currentMRP ?? 0) > (currentPrice ?? 0);
  double get discountPercentage => selectedSKU.value?.discountPercentage ?? 0.0;

  // Variant helpers
  bool get hasVariants => product.value?.hasVariants ?? false;
  bool get hasSingleSKU => product.value?.hasSingleSKU ?? false;
}
