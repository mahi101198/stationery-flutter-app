import 'dart:developer';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/services/cart_wishlist_service.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/features/checkout/screens/payment_waiting_screen.dart';

class RazorpayPaymentService extends GetxController {
  static RazorpayPaymentService get instance => Get.find();

  final Razorpay _razorpay = Razorpay();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CartWishlistService _cartService = CartWishlistService.instance;
  final ProductCacheService _productService = ProductCacheService.instance;
  final AppSettingsService _appSettings = AppSettingsService.instance;

  // Observable variables
  final RxBool _isProcessingPayment = false.obs;
  final RxString _currentOrderId = ''.obs;
  final RxString _currentPaymentId = ''.obs;
  final RxString _currentRazorpayOrderId = ''.obs;
  final RxDouble _currentTotalOrderAmount = 0.0.obs;

  // Getters for external access
  RxBool get isProcessingPayment => _isProcessingPayment;
  RxString get currentOrderId => _currentOrderId;
  RxString get currentPaymentId => _currentPaymentId;
  RxString get currentRazorpayOrderId => _currentRazorpayOrderId;
  RxDouble get currentTotalOrderAmount => _currentTotalOrderAmount;

  @override
  void onInit() {
    super.onInit();
    _setupRazorpayCallbacks();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  /// Setup Razorpay payment callbacks
  void _setupRazorpayCallbacks() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Prepare order items with full product details
  Future<List<Map<String, dynamic>>> _prepareOrderItems(
    List<CartItem> cartItems, {
    bool isBuyNow = false,
    Map<String, dynamic>? buyNowData,
  }) async {
    try {
      print('🔍 Preparing order items with product details...');
      print('🔍 Is Buy Now: $isBuyNow');
      
      if (isBuyNow && buyNowData != null) {
        // Handle Buy Now flow - product data is already available
        final product = buyNowData['product'];
        final quantity = buyNowData['quantity'] ?? 1;
        final selectedColor = buyNowData['selectedColor'];
        
        print('🔍 Buy Now - Product: ${product.name}, Quantity: $quantity, Color: $selectedColor');
        
        return [{
          'productId': product.productId,
          'quantity': quantity,
          'name': product.name,
          'price': product.price,
          'productImage': product.displayImage,
          'discountPrice': product.price, // Use price as discountPrice since discount is already applied
          if (selectedColor != null) 'selectedColor': selectedColor,
        }];
      } else {
        // Handle regular cart flow
        // Get all product IDs from cart items
        final productIds = cartItems.map((item) => item.productId).toList();
        print('🔍 Fetching product details for IDs: $productIds');
        
        // Fetch product details
        final products = await _productService.getProductsByIds(productIds);
        print('🔍 Fetched ${products.length} products');
        
        // Create order items with full product details
        final orderItems = cartItems.map((cartItem) {
          // Find the corresponding product
          final product = products.firstWhereOrNull((p) => p.productId == cartItem.productId);
          
          if (product != null) {
            print('✅ Found product details for ${cartItem.productId}: ${product.name}, Color: ${cartItem.selectedColor}');
            return {
              'productId': cartItem.productId,
              'quantity': cartItem.quantity,
              'name': product.name,
              'price': product.price,
              'productImage': product.displayImage,
              'discountPrice': product.price, // Use price as discountPrice since discount is already applied
              if (cartItem.selectedColor != null) 'selectedColor': cartItem.selectedColor,
            };
          } else {
            print('⚠️ Product details not found for ${cartItem.productId}, using fallback');
            return {
              'productId': cartItem.productId,
              'quantity': cartItem.quantity,
              'name': 'Product ${cartItem.productId}',
              'price': 0.0,
              'productImage': '',
              'discountPrice': 0.0,
              if (cartItem.selectedColor != null) 'selectedColor': cartItem.selectedColor,
            };
          }
        }).toList();
        
        print('🔍 Prepared ${orderItems.length} order items');
        return orderItems;
      }
    } catch (e) {
      print('❌ Error preparing order items: $e');
      // Fallback to basic items if product fetch fails
      if (isBuyNow && buyNowData != null) {
        final product = buyNowData['product'];
        final quantity = buyNowData['quantity'] ?? 1;
        return [{
          'productId': product.productId,
          'quantity': quantity,
          'name': product.name,
          'price': product.price,
          'productImage': product.displayImage,
          'discountPrice': product.price, // Use price as discountPrice since discount is already applied
        }];
      } else {
        return cartItems.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'name': 'Product ${item.productId}',
          'price': 0.0,
          'productImage': '',
          'discountPrice': 0.0,
        }).toList();
      }
    }
  }

  /// Create order and initiate Razorpay payment
  /// Initiate payment with specific payment mode (razorpay or cod)
  Future<Map<String, dynamic>> initiatePaymentWithMode({
    required List<CartItem> cartItems,
    required UserAddress deliveryAddress,
    required double totalAmount,
    required double subTotal,
    required double discount,
    required double deliveryFee,
    required double walletUsed,
    required double finalPayable,
    String? couponCode,
    bool isBuyNow = false,
    Map<String, dynamic>? buyNowData,
    required String paymentMode, // 'razorpay' or 'cod'
  }) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 INITIATE PAYMENT WITH MODE CALLED');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  - cartItems count: ${cartItems.length}');
      print('  - totalAmount: $totalAmount');
      print('  - couponCode: $couponCode');
      print('  - isBuyNow: $isBuyNow');
      print('  - paymentMode: $paymentMode');
      print('  - deliveryAddress ID: ${deliveryAddress.id}');
      print('🔍 ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = true;
      _currentTotalOrderAmount.value = totalAmount; // Store total order amount for navigation
      
      print('🚀 Initiating $paymentMode payment for amount: $finalPayable');

      // Prepare items for Firebase Function with full product details
      final items = await _prepareOrderItems(cartItems, isBuyNow: isBuyNow, buyNowData: buyNowData);

      print('🔍 Prepared items for Firebase Function:');
      for (int i = 0; i < items.length; i++) {
        print('  Item $i: ${items[i]}');
        print('    - productId: ${items[i]['productId']}');
        print('    - name: ${items[i]['name']}');
        print('    - price: ${items[i]['price']}');
        print('    - productImage: ${items[i]['productImage']}');
        if (items[i].containsKey('selectedColor')) {
          print('    - selectedColor: ${items[i]['selectedColor']} ✅');
        } else {
          print('    - selectedColor: NOT INCLUDED IN PAYLOAD ❌');
        }
      }

      // Prepare delivery address
      final addressData = {
        'id': deliveryAddress.id,
        'name': deliveryAddress.name,
        'phoneNumber': deliveryAddress.phoneNumber ?? deliveryAddress.mobileNumber ?? '',
        'street': '${deliveryAddress.line1}${deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}',
        'city': deliveryAddress.city,
        'state': deliveryAddress.state,
        'postalCode': deliveryAddress.pincode,
        'country': deliveryAddress.country,
        'isDefault': deliveryAddress.isDefault,
        'landmark': deliveryAddress.landmark,
        'email': deliveryAddress.email,
      };

      // Prepare amountSummary object as per backend requirements
      final amountSummary = {
        'subTotal': subTotal,
        'discount': discount,
        'walletUsed': walletUsed,
        'deliveryFee': deliveryFee,
        'finalPayable': finalPayable,
        'totalOrderAmount': totalAmount,
      };

      print('🔍 Prepared address data:');
      print('   $addressData');
      print('🔍 Amount Summary:');
      print('   $amountSummary');

      // Call Firebase Function to create order
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 CALLING FIREBASE FUNCTION: createOrder');
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 Request payload being sent:');
      print('  📦 items: $items');
      print('  💰 amountSummary: $amountSummary');
      print('  💱 currency: INR');
      print('  💳 paymentMode: $paymentMode');
      print('  📍 deliveryAddress: $addressData');
      print('  🎟️ couponCode: $couponCode');
      print('🔍 ════════════════════════════════════════════════════════');
      
      final callable = _functions.httpsCallable('createOrder');
      print('⏳ WAITING FOR FIREBASE FUNCTION RESPONSE...');
      
      final result = await callable.call({
        'items': items,
        'amountSummary': amountSummary,
        'currency': 'INR',
        'paymentMode': paymentMode,
        'deliveryAddress': addressData,
        'couponCode': couponCode,
      });

      print('✅ ════════════════════════════════════════════════════════');
      print('✅ FIREBASE FUNCTION RESPONSE RECEIVED');
      print('✅ ════════════════════════════════════════════════════════');
      final data = Map<String, dynamic>.from(result.data as Map);
      print('📥 COMPLETE RESPONSE DATA FROM CREATE ORDER:');
      print('  success: ${data['success']}');
      print('  orderId: ${data['orderId']}');
      print('  paymentId: ${data['paymentId']}');
      print('  deliveryId: ${data['deliveryId']}');
      print('  paymentMode: ${data['paymentMode']}');
      print('  currency: ${data['currency']}');
      
      // Parse new structured response
      if (data.containsKey('paymentInfo') && data['paymentInfo'] != null) {
        final paymentInfo = Map<String, dynamic>.from(data['paymentInfo'] as Map);
        print('  💳 Payment Info:');
        print('    - gateway: ${paymentInfo['gateway']}');
        print('    - status: ${paymentInfo['status']}');
        print('    - razorpayOrderId: ${paymentInfo['razorpayOrderId']}');
      }
      
      if (data.containsKey('amountBreakdown')) {
        final amountBreakdown = Map<String, dynamic>.from(data['amountBreakdown'] as Map);
        print('  💰 Amount Breakdown:');
        print('    - subTotal: ${amountBreakdown['subTotal']}');
        print('    - discount: ${amountBreakdown['discount']}');
        print('    - deliveryFee: ${amountBreakdown['deliveryFee']}');
        print('    - walletUsed: ${amountBreakdown['walletUsed']}');
        print('    - finalAmount: ${amountBreakdown['finalAmount']}');
        print('    - totalSavings: ${amountBreakdown['totalSavings']}');
      }
      
      if (data.containsKey('walletInfo')) {
        final walletInfo = data['walletInfo'] != null ? Map<String, dynamic>.from(data['walletInfo'] as Map) : null;
        if (walletInfo != null) {
          print('  💰 Wallet Info:');
          print('    - amountUsed: ${walletInfo['amountUsed']}');
          print('    - isPartialPayment: ${walletInfo['isPartialPayment']}');
          print('    - remainingAmount: ${walletInfo['remainingAmount']}');
        }
      }
      
      if (data.containsKey('orderStatus')) {
        final orderStatus = Map<String, dynamic>.from(data['orderStatus'] as Map);
        print('  📊 Order Status:');
        print('    - status: ${orderStatus['status']}');
        print('    - paymentStatus: ${orderStatus['paymentStatus']}');
        print('    - deliveryStatus: ${orderStatus['deliveryStatus']}');
      }
      
      if (data.containsKey('error')) {
        print('  ❌ ERROR FIELD: ${data['error']}');
      }
      print('✅ ════════════════════════════════════════════════════════');
      
      if (data['success'] == true) {
        _currentOrderId.value = data['orderId'];
        _currentPaymentId.value = data['paymentId'];
        
        print('✅ Order created successfully:');
        print('  - orderId: ${_currentOrderId.value}');
        print('  - paymentId: ${_currentPaymentId.value}');
        print('  - paymentMode: $paymentMode');
        
        // For Razorpay and Partial Wallet, open Razorpay checkout
        if (paymentMode == 'razorpay' || paymentMode == 'partial_wallet') {
          // Extract razorpayOrderId from paymentInfo
          if (data.containsKey('paymentInfo') && data['paymentInfo'] != null) {
            final paymentInfo = Map<String, dynamic>.from(data['paymentInfo'] as Map);
            final razorpayOrderId = paymentInfo['razorpayOrderId'];
            
            if (razorpayOrderId == null) {
              throw Exception('Razorpay order ID not found in response');
            }
            
            _currentRazorpayOrderId.value = razorpayOrderId;
            
            // Extract final amount from amountBreakdown
            double amountForRazorpay = finalPayable;
            if (data.containsKey('amountBreakdown') && data['amountBreakdown'] != null) {
              final amountBreakdown = Map<String, dynamic>.from(data['amountBreakdown'] as Map);
              amountForRazorpay = (amountBreakdown['finalAmount'] ?? finalPayable).toDouble();
              print('  💰 Amount for Razorpay UI: ₹$amountForRazorpay (from amountBreakdown.finalAmount)');
            }
            
            // Open Razorpay checkout
            print('🚀 Opening Razorpay checkout UI...');
            await _openRazorpayCheckout(
              razorpayOrderId: razorpayOrderId,
              amount: amountForRazorpay,
            );
          } else {
            throw Exception('PaymentInfo not found in response for Razorpay payment');
          }
        } else {
          // For COD and Wallet, just return the response
          _isProcessingPayment.value = false;
        }
        
        return data;
      } else {
        print('❌ ════════════════════════════════════════════════════════');
        print('❌ FIREBASE FUNCTION RETURNED FAILURE');
        print('❌ ════════════════════════════════════════════════════════');
        print('  Error message: ${data['error'] ?? 'Unknown error'}');
        print('❌ ════════════════════════════════════════════════════════');
        throw Exception('Failed to create order: ${data['error'] ?? 'Unknown error'}');
      }

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR IN INITIATE PAYMENT WITH MODE');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('  Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      _isProcessingPayment.value = false;
      TLoaders.errorSnackBar(
        title: 'Payment Error',
        message: 'Failed to initiate payment. Please try again.',
      );
      rethrow;
    }
  }

  /// Create order - unified method for all payment modes
  Future<Map<String, dynamic>> createOrder({
    required List<CartItem> cartItems,
    required UserAddress deliveryAddress,
    required double totalAmount,
    required double subTotal,
    required double discount,
    required double deliveryFee,
    required double walletUsed,
    required double finalPayable,
    String? couponCode,
    bool isBuyNow = false,
    Map<String, dynamic>? buyNowData,
    required String paymentMode,
  }) async {
    try {
      print('💰 ════════════════════════════════════════════════════════');
      print('💰 CREATE ORDER - UNIFIED METHOD');
      print('💰 ════════════════════════════════════════════════════════');
      print('  - cartItems count: ${cartItems.length}');
      print('  - totalAmount: $totalAmount');
      print('  - subTotal: $subTotal');
      print('  - discount: $discount');
      print('  - deliveryFee: $deliveryFee');
      print('  - walletUsed: $walletUsed');
      print('  - finalPayable: $finalPayable');
      print('  - couponCode: $couponCode');
      print('  - isBuyNow: $isBuyNow');
      print('  - paymentMode: $paymentMode');
      print('  - deliveryAddress ID: ${deliveryAddress.id}');
      print('💰 ════════════════════════════════════════════════════════');
      
      // Prepare items for Firebase Function with full product details
      final items = await _prepareOrderItems(cartItems, isBuyNow: isBuyNow, buyNowData: buyNowData);

      // Prepare delivery address
      final addressData = {
        'id': deliveryAddress.id,
        'name': deliveryAddress.name,
        'phoneNumber': deliveryAddress.phoneNumber ?? deliveryAddress.mobileNumber ?? '',
        'street': '${deliveryAddress.line1}${deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}',
        'city': deliveryAddress.city,
        'state': deliveryAddress.state,
        'postalCode': deliveryAddress.pincode,
        'country': deliveryAddress.country,
        'isDefault': deliveryAddress.isDefault,
        'landmark': deliveryAddress.landmark,
        'email': deliveryAddress.email,
      };

      // Prepare amountSummary object as per backend requirements
      final amountSummary = {
        'subTotal': subTotal,
        'discount': discount,
        'walletUsed': walletUsed,
        'deliveryFee': deliveryFee,
        'finalPayable': finalPayable,
        'totalOrderAmount': totalAmount,
      };

      // Call Firebase Function to create order
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 CALLING FIREBASE FUNCTION: createOrder');
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 Request payload being sent:');
      print('  📦 items: $items');
      print('  💰 amountSummary: $amountSummary');
      print('  💱 currency: INR');
      print('  💳 paymentMode: $paymentMode');
      print('  📍 deliveryAddress: $addressData');
      print('  🎟️ couponCode: $couponCode');
      print('🔍 ════════════════════════════════════════════════════════');
      
      final callable = _functions.httpsCallable('createOrder');
      print('⏳ WAITING FOR FIREBASE FUNCTION RESPONSE...');
      
      final result = await callable.call({
        'items': items,
        'amountSummary': amountSummary,
        'currency': 'INR',
        'paymentMode': paymentMode,
        'deliveryAddress': addressData,
        'couponCode': couponCode,
      });

      print('✅ ════════════════════════════════════════════════════════');
      print('✅ FIREBASE FUNCTION RESPONSE RECEIVED');
      print('✅ ════════════════════════════════════════════════════════');
      final data = Map<String, dynamic>.from(result.data as Map);
      print('📥 COMPLETE RESPONSE DATA FROM CREATE ORDER:');
      print('  success: ${data['success']}');
      print('  orderId: ${data['orderId']}');
      print('  paymentId: ${data['paymentId']}');
      print('  deliveryId: ${data['deliveryId']}');
      print('  paymentMode: ${data['paymentMode']}');
      print('  currency: ${data['currency']}');
      
      // Parse structured response
      if (data.containsKey('paymentInfo')) {
        final paymentInfo = Map<String, dynamic>.from(data['paymentInfo'] as Map);
        print('  💳 Payment Info: gateway=${paymentInfo['gateway']}, status=${paymentInfo['status']}');
        if (paymentInfo['razorpayOrderId'] != null) {
          print('    razorpayOrderId: ${paymentInfo['razorpayOrderId']}');
        }
      }
      
      if (data.containsKey('amountBreakdown')) {
        final amountBreakdown = Map<String, dynamic>.from(data['amountBreakdown'] as Map);
        print('  💰 Amount Breakdown: finalAmount=${amountBreakdown['finalAmount']}, walletUsed=${amountBreakdown['walletUsed']}');
      }
      
      if (data.containsKey('walletInfo') && data['walletInfo'] != null) {
        final walletInfo = Map<String, dynamic>.from(data['walletInfo'] as Map);
        print('  💰 Wallet Info: amountUsed=${walletInfo['amountUsed']}, isPartial=${walletInfo['isPartialPayment']}');
      }
      print('✅ ════════════════════════════════════════════════════════');
      
      if (data['success'] == true) {
        print('✅ Order created successfully:');
        print('  - orderId: ${data['orderId']}');
        print('  - paymentId: ${data['paymentId']}');
        print('  - paymentMode: $paymentMode');
        
        return data;
      } else {
        print('❌ ════════════════════════════════════════════════════════');
        print('❌ FIREBASE FUNCTION RETURNED FAILURE');
        print('❌ ════════════════════════════════════════════════════════');
        print('  Error message: ${data['error'] ?? 'Unknown error'}');
        print('❌ ════════════════════════════════════════════════════════');
        throw Exception('Failed to create order: ${data['error'] ?? 'Unknown error'}');
      }

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR IN CREATE ORDER FOR WALLET');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('  Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Original initiatePayment method (for backward compatibility with Razorpay)
  Future<void> initiatePayment({
    required List<CartItem> cartItems,
    required UserAddress deliveryAddress,
    required double totalAmount,
    String? promoCode,
    bool isBuyNow = false,
    Map<String, dynamic>? buyNowData,
  }) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 INITIATE PAYMENT CALLED');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  - cartItems count: ${cartItems.length}');
      print('  - totalAmount: $totalAmount');
      print('  - promoCode: $promoCode');
      print('  - isBuyNow: $isBuyNow');
      print('  - deliveryAddress ID: ${deliveryAddress.id}');
      print('🔍 ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = true;
      
      print('🚀 Initiating Razorpay payment for amount: $totalAmount');

      // Prepare items for Firebase Function with full product details
      final items = await _prepareOrderItems(cartItems, isBuyNow: isBuyNow, buyNowData: buyNowData);

      print('🔍 Prepared items for Firebase Function:');
      for (int i = 0; i < items.length; i++) {
        print('  Item $i: ${items[i]}');
        print('    - productId: ${items[i]['productId']}');
        print('    - name: ${items[i]['name']}');
        print('    - price: ${items[i]['price']}');
        print('    - productImage: ${items[i]['productImage']}');
        if (items[i].containsKey('selectedColor')) {
          print('    - selectedColor: ${items[i]['selectedColor']} ✅');
        } else {
          print('    - selectedColor: NOT INCLUDED IN PAYLOAD ❌');
        }
      }

      // Prepare delivery address
      final addressData = {
        'id': deliveryAddress.id,                    // Uses addressId from UserAddress
        'name': deliveryAddress.name,                // Uses recepientDetails from UserAddress
        'phoneNumber': deliveryAddress.phoneNumber ?? deliveryAddress.mobileNumber ?? '', // Uses phoneNumber or mobileNumber
        'street': '${deliveryAddress.line1}${deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}', // Combines line1 and line2
        'city': deliveryAddress.city,
        'state': deliveryAddress.state,
        'postalCode': deliveryAddress.pincode,       // Maps pincode to postalCode
        'country': deliveryAddress.country,
        'isDefault': deliveryAddress.isDefault,
        'landmark': deliveryAddress.landmark,       // Additional field
        'email': deliveryAddress.email,              // Additional field
      };

      print('🔍 Prepared address data:');
      print('   $addressData');

      // Call Firebase Function to create order
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 CALLING FIREBASE FUNCTION: createOrder');
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 Request payload being sent:');
      print('  📦 items: $items');
      print('  💰 amount: $totalAmount');
      print('  💱 currency: INR');
      print('  💳 paymentMode: razorpay');
      print('  📍 deliveryAddress: $addressData');
      print('  🎟️ promoCode: $promoCode');
      print('🔍 ════════════════════════════════════════════════════════');
      
      final callable = _functions.httpsCallable('createOrder');
      print('⏳ WAITING FOR FIREBASE FUNCTION RESPONSE...');
      
      final result = await callable.call({
        'items': items,
        'amount': totalAmount,
        'currency': 'INR',
        'paymentMode': 'razorpay',
        'deliveryAddress': addressData,
        'promoCode': promoCode,
      });

      print('✅ ════════════════════════════════════════════════════════');
      print('✅ FIREBASE FUNCTION RESPONSE RECEIVED');
      print('✅ ════════════════════════════════════════════════════════');
      final data = Map<String, dynamic>.from(result.data as Map);
      print('📥 COMPLETE RESPONSE DATA FROM CREATE ORDER:');
      print('  success: ${data['success']}');
      print('  orderId: ${data['orderId']}');
      print('  paymentId: ${data['paymentId']}');
      print('  currency: ${data['currency']}');
      if (data.containsKey('error')) {
        print('  ❌ ERROR FIELD: ${data['error']}');
      }
      print('  📋 FULL RESPONSE JSON:');
      print('     ${data.toString()}');
      print('✅ ════════════════════════════════════════════════════════');
      
      if (data['success'] == true) {
        _currentOrderId.value = data['orderId'];
        _currentPaymentId.value = data['paymentId'];
        
        // Extract razorpayOrderId from paymentInfo (new backend structure)
        String? razorpayOrderId;
        if (data.containsKey('paymentInfo')) {
          final paymentInfo = Map<String, dynamic>.from(data['paymentInfo'] as Map);
          razorpayOrderId = paymentInfo['razorpayOrderId'];
          print('  💳 Extracted razorpayOrderId from paymentInfo: $razorpayOrderId');
        }
        
        if (razorpayOrderId == null) {
          throw Exception('Razorpay order ID not found in response');
        }
        
        _currentRazorpayOrderId.value = razorpayOrderId;

        print('✅ Order created successfully:');
        print('  - orderId: ${_currentOrderId.value}');
        print('  - paymentId: ${_currentPaymentId.value}');
        print('  - razorpayOrderId: ${_currentRazorpayOrderId.value}');
        
        // Extract final amount from amountBreakdown for Razorpay UI
        double amountForRazorpay = totalAmount;
        if (data.containsKey('amountBreakdown')) {
          final amountBreakdown = Map<String, dynamic>.from(data['amountBreakdown'] as Map);
          amountForRazorpay = (amountBreakdown['finalAmount'] ?? totalAmount).toDouble();
          print('  💰 Amount for Razorpay: ₹$amountForRazorpay (from amountBreakdown.finalAmount)');
        }
        
        // Open Razorpay checkout
        print('🔍 Calling _openRazorpayCheckout...');
        await _openRazorpayCheckout(
          razorpayOrderId: _currentRazorpayOrderId.value,
          amount: amountForRazorpay,
        );
      } else {
        print('❌ ════════════════════════════════════════════════════════');
        print('❌ FIREBASE FUNCTION RETURNED FAILURE');
        print('❌ ════════════════════════════════════════════════════════');
        print('  Error message: ${data['error'] ?? 'Unknown error'}');
        print('❌ ════════════════════════════════════════════════════════');
        throw Exception('Failed to create order: ${data['error'] ?? 'Unknown error'}');
      }

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR IN INITIATE PAYMENT');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('  Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      _isProcessingPayment.value = false;
      TLoaders.errorSnackBar(
        title: 'Payment Error',
        message: 'Failed to initiate payment. Please try again.',
      );
    }
  }

  /// Open Razorpay checkout
  Future<void> _openRazorpayCheckout({
    required String razorpayOrderId,
    required double amount,
  }) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 OPEN RAZORPAY CHECKOUT CALLED');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  - razorpayOrderId: $razorpayOrderId');
      print('  - amount: ₹$amount');
      print('  - currentUser UID: ${_auth.currentUser?.uid}');
      print('  - currentUser email: ${_auth.currentUser?.email}');
      print('  - currentUser phone: ${_auth.currentUser?.phoneNumber}');
      print('🔍 ════════════════════════════════════════════════════════');

      // Get Razorpay key from database
      final razorpayKey = _appSettings.razorpayKeyId;
      
      if (razorpayKey.isEmpty) {
        throw Exception('Razorpay key not configured. Please contact support.');
      }

      final options = {
        'key': razorpayKey, // Get from database via AppSettingsService
        'amount': (amount * 100).round(), // Convert to paise
        'currency': 'INR',
        'name': _appSettings.appName,
        'description': 'Order Payment',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': _auth.currentUser?.phoneNumber ?? '',
          'email': _auth.currentUser?.email ?? '',
        },
        'theme': {
          'color': '#FF6B35',
        },
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        // Remove the modal.ondismiss callback as it causes serialization issues
      };

      print('💳 ════════════════════════════════════════════════════════');
      print('💳 SENDING DATA TO RAZORPAY UI');
      print('💳 ════════════════════════════════════════════════════════');
      print('📤 COMPLETE PAYLOAD SENT TO RAZORPAY:');
      print('  KEY: ${options['key']} (from database)');
      print('  AMOUNT (paise): ${options['amount']} (₹${(options['amount'] as int) / 100})');
      print('  CURRENCY: ${options['currency']}');
      print('  MERCHANT NAME: ${options['name']}');
      print('  DESCRIPTION: ${options['description']}');
      print('  ORDER_ID: ${options['order_id']}');
      final prefill = options['prefill'] != null ? Map<String, dynamic>.from(options['prefill'] as Map) : null;
      final theme = options['theme'] != null ? Map<String, dynamic>.from(options['theme'] as Map) : null;
      print('  USER EMAIL: ${prefill?['email']}');
      print('  USER PHONE: ${prefill?['contact']}');
      print('  THEME COLOR: ${theme?['color']}');
      print('  RETRY SETTINGS: ${options['retry']}');
      print('  📋 COMPLETE PAYLOAD JSON:');
      print('     ${options.toString()}');
      print('💳 ════════════════════════════════════════════════════════');
      
      _razorpay.open(options);
      print('✅ Razorpay.open() called - UI should launch now');
      print('⏳ WAITING FOR USER TO COMPLETE PAYMENT IN RAZORPAY UI...');

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR OPENING RAZORPAY CHECKOUT');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('  Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      _isProcessingPayment.value = false;
      TLoaders.errorSnackBar(
        title: 'Payment Error',
        message: 'Failed to open payment gateway. Please try again.',
      );
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ PAYMENT COMPLETED - RAZORPAY RETURNED DATA');
      print('✅ ════════════════════════════════════════════════════════');
      print('📥 DATA RECEIVED FROM RAZORPAY AFTER PAYMENT COMPLETION:');
      print('  💳 RAZORPAY PAYMENT ID: ${response.paymentId}');
      print('  🆔 RAZORPAY ORDER ID: ${response.orderId}');
      print('  ✍️ PAYMENT SIGNATURE: ${response.signature}');
      print('  ');
      print('  ℹ️ What this data means:');
      print('    - User successfully completed payment in Razorpay UI ✅');
      print('    - Razorpay verified payment and returned these IDs ✅');
      print('    - Now Razorpay will call our backend webhook ⏳');
      print('    - We will wait for backend to confirm payment ⏳');
      print('✅ ════════════════════════════════════════════════════════');
      
      print('⏳ ════════════════════════════════════════════════════════');
      print('⏳ STARTING WEBHOOK CONFIRMATION WAIT');
      print('⏳ ════════════════════════════════════════════════════════');
      print('  ℹ️ What is happening right now:');
      print('    1. User paid successfully in Razorpay UI ✅');
      print('    2. Razorpay sent confirmation to our app ✅');
      print('    3. Now Razorpay will call our BACKEND webhook ⏳');
      print('    4. Backend will verify signature and update order status ⏳');
      print('    5. We will poll database to detect the update ⏳');
      print('  ');
      print('  🔍 Monitoring order ID: ${_currentOrderId.value}');
      print('  ⏱️ Will poll every 1 second for up to 30 seconds');
      print('  📊 Order status should change from "processing_payment" to "paid"');
      print('⏳ ════════════════════════════════════════════════════════');
      
      // Show loading screen
      Get.to(
        () => const PaymentWaitingScreen(
          message: 'Payment Successful!',
          subMessage: 'Waiting for backend confirmation...',
        ),
        transition: Transition.fadeIn,
      );
      
      // The webhook will handle the actual order updates
      // We need to wait for webhook confirmation before proceeding
      
      print('🔄 STARTING WEBHOOK CONFIRMATION POLLING...');
      print('🔍 Will check Firestore order status every 1 second');
      
      // Poll for order status update from webhook (max 30 seconds)
      bool orderConfirmed = false;
      int attempts = 0;
      const maxAttempts = 30; // 30 seconds
      
      while (!orderConfirmed && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
        
        print('🔍 [Poll $attempts/$maxAttempts] Checking database if webhook updated order status...');
        orderConfirmed = await isOrderPaid(_currentOrderId.value);
        
        if (orderConfirmed) {
          print('✅ ════════════════════════════════════════════════════════');
          print('✅ WEBHOOK CONFIRMED! BACKEND UPDATED ORDER STATUS');
          print('✅ ════════════════════════════════════════════════════════');
          print('  ℹ️ Complete flow that just happened:');
          print('    1. Razorpay called our backend webhook endpoint ✅');
          print('    2. Backend verified payment signature from Razorpay ✅');
          print('    3. Backend updated Firestore order status to "paid" ✅');
          print('    4. We detected the status change in Firestore ✅');
          print('  ');
          print('  📝 Order ID: ${_currentOrderId.value}');
          print('  ⏱️ Webhook confirmation took: $attempts seconds');
          print('  ✅ Order is now CONFIRMED and PAID in database');
          print('✅ ════════════════════════════════════════════════════════');
          break;
        }
      }
      
      if (!orderConfirmed) {
        print('⚠️ ════════════════════════════════════════════════════════');
        print('⚠️ WEBHOOK CONFIRMATION TIMEOUT (THIS IS OK!)');
        print('⚠️ ════════════════════════════════════════════════════════');
        print('  ℹ️ What this means:');
        print('    - We polled database for $attempts seconds');
        print('    - Backend webhook hasn\'t updated order yet (might be delayed)');
        print('    - BUT: USER PAYMENT WAS SUCCESSFUL ✅');
        print('    - Order will be auto-confirmed by webhook later ✅');
        print('  ');
        print('  🔄 What happens next:');
        print('    1. We show success screen to user RIGHT NOW ✅');
        print('    2. Backend webhook processes in background ⏳');
        print('    3. Order status auto-updates to "paid" when webhook arrives ✅');
        print('    4. User can see order in Order History ✅');
        print('  ');
        print('  📝 NOTE: This timeout is NORMAL, not an error!');
        print('  📝 Payment is complete, webhook is just delayed');
        print('⚠️ ════════════════════════════════════════════════════════');
      }
      
      print('🧹 Clearing user cart after successful payment...');
      // Clear cart after successful payment
      await _cartService.clearCart(_auth.currentUser!.uid);
      print('✅ Cart cleared from database');
      
      print('🚀 Navigating to order success screen...');
      print('  📦 Passing data to success screen:');
      print('     orderId: ${_currentOrderId.value}');
      print('     paymentId: ${response.paymentId}');
      print('     razorpayOrderId: ${_currentRazorpayOrderId.value}');
      print('     signature: ${response.signature}');
      print('     amount: ${_currentTotalOrderAmount.value}');
      print('     webhookConfirmed: $orderConfirmed');
      // Navigate to success screen
      Get.offAllNamed(Routes.orderSuccess, arguments: {
        'orderId': _currentOrderId.value,
        'paymentId': response.paymentId,
        'razorpayOrderId': _currentRazorpayOrderId.value,
        'signature': response.signature,
        'amount': _currentTotalOrderAmount.value,
        'webhookConfirmed': orderConfirmed,
        'paymentMethod': 'razorpay', // Add payment method for Razorpay payments
      });
      print('✅ Navigation to success screen completed');

      // Reset state
      resetPaymentState();
      print('✅ Payment service state reset');

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR IN PAYMENT SUCCESS HANDLER');
      print('❌ ════════════════════════════════════════════════════════');
      print('  ❌ Error: $e');
      print('  ❌ Error type: ${e.runtimeType}');
      print('  ❌ Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Payment successful but there was an error processing your order.',
      );
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ ════════════════════════════════════════════════════════');
    print('❌ PAYMENT ERROR CALLBACK TRIGGERED BY RAZORPAY');
    print('❌ ════════════════════════════════════════════════════════');
    print('📥 Error data received from Razorpay:');
    print('  ❌ Error code: ${response.code}');
    print('  📝 Error message: ${response.message}');
    print('  ℹ️ This means user did NOT complete payment');
    print('❌ ════════════════════════════════════════════════════════');
    
    _isProcessingPayment.value = false;
    print('⏹️ Processing payment flag set to false');
    
    String errorMessage = 'Payment failed. Please try again.';
    String errorTitle = 'Payment Failed';
    
    print('🔍 Analyzing error code to show appropriate message...');
    bool isUserCancellation = false;
    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        errorTitle = 'Network Error';
        print('  🌐 Error type: Network Error - User lost connection');
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMessage = 'Invalid payment options. Please try again.';
        errorTitle = 'Invalid Options';
        print('  ⚙️ Error type: Invalid Options - Config issue');
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'You have cancelled the payment. You can retry anytime.';
        errorTitle = 'Payment Cancelled';
        isUserCancellation = true;
        print('  🚫 Error type: Payment Cancelled by User');
        break;
      case Razorpay.TLS_ERROR:
        errorMessage = 'Security error. Please try again.';
        errorTitle = 'Security Error';
        print('  🔒 Error type: TLS/Security Error');
        break;
      default:
        print('  ❓ Error type: Unknown (code: ${response.code})');
    }

    print('💬 Showing message to user: "$errorMessage"');
    if (isUserCancellation) {
      TLoaders.infoSnackBar(
        title: errorTitle,
        message: errorMessage,
      );
    } else {
      TLoaders.errorSnackBar(
        title: errorTitle,
        message: errorMessage,
      );
    }

    print('🔄 Resetting payment state to allow retry...');
    resetPaymentState();
    print('✅ Payment state reset complete');
    print('📝 User can now try payment again');
    print('❌ ════════════════════════════════════════════════════════');
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 ════════════════════════════════════════════════════════');
    print('💳 EXTERNAL WALLET CALLBACK TRIGGERED');
    print('💳 ════════════════════════════════════════════════════════');
    print('📥 External wallet response:');
    print('  💼 Wallet name: ${response.walletName}');
    print('  ℹ️ User chose to pay via external wallet app');
    print('💳 ════════════════════════════════════════════════════════');
    
    print('💬 Notifying user about wallet selection');
    TLoaders.successSnackBar(
      title: 'External Wallet',
      message: 'You have selected ${response.walletName}',
    );
  }

  /// Reset payment state
  void resetPaymentState() {
    _isProcessingPayment.value = false;
    _currentOrderId.value = '';
    _currentPaymentId.value = '';
    _currentRazorpayOrderId.value = '';
    _currentTotalOrderAmount.value = 0.0;
  }
  
  /// Complete remaining payment for partial wallet order
  Future<Map<String, dynamic>> completeRemainingPayment({
    required String orderId,
    required double remainingAmount,
    required String paymentMethod, // 'razorpay' or 'cod'
  }) async {
    try {
      print('💰 ════════════════════════════════════════════════════════');
      print('💰 COMPLETE REMAINING PAYMENT FOR PARTIAL WALLET ORDER');
      print('💰 ════════════════════════════════════════════════════════');
      print('📦 Order ID: $orderId');
      print('💰 Remaining amount: ₹$remainingAmount');
      print('💳 Payment method: $paymentMethod');
      print('💰 ════════════════════════════════════════════════════════');

      final callable = _functions.httpsCallable('completeRemainingPayment');
      final result = await callable.call({
        'orderId': orderId,
        'remainingAmount': remainingAmount,
        'paymentMethod': paymentMethod,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      
      if (data['success'] == true) {
        print('✅ Remaining payment completed successfully');
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to complete remaining payment');
      }
    } catch (e) {
      print('❌ Error completing remaining payment: $e');
      rethrow;
    }
  }

  /// Clear cart after successful order
  Future<void> clearCart(String userId) async {
    try {
      print('🧹 Clearing cart for user: $userId');
      
      // Delete the entire cart document (correct structure based on CartWishlistService)
      await _firestore
          .collection('carts')
          .doc(userId)
          .delete();
      
      print('✅ Cart cleared: cart document deleted');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }

  /// Listen to order status changes in real-time
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToOrderStatus(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots();
  }

  /// Check if order is paid
  Future<bool> isOrderPaid(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['status'] == 'paid' || data['status'] == 'confirmed';
      }
      return false;
    } catch (e) {
      log('❌ Error checking order status: $e');
      return false;
    }
  }

  /// Get order details
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      log('❌ Error getting order details: $e');
      return null;
    }
  }

  /// Cancel order and process refund
  Future<Map<String, dynamic>?> cancelOrder({
    required String orderId,
    required String cancelReason,
    double? refundAmount,
  }) async {
    try {
      log('🚫 Cancelling order: $orderId');
      log('🚫 Cancel reason: $cancelReason');

      final callable = FirebaseFunctions.instance.httpsCallable('cancelOrder');
      
      final result = await callable.call({
        'orderId': orderId,
        'cancelReason': cancelReason,
        'refundAmount': refundAmount,
      });

      if (result.data != null) {
        final data = Map<String, dynamic>.from(result.data as Map);
        log('✅ Order cancelled successfully: ${data['orderId']}');
        return data;
      }
      
      return null;
    } catch (e) {
      log('❌ Error cancelling order: $e');
      rethrow;
    }
  }
}
