import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();

  final RazorpayPaymentService _razorpayService = RazorpayPaymentService.instance;

  // Observable variables
  final RxString _selectedPaymentMethod = 'razorpay'.obs;
  final RxBool _isProcessingPayment = false.obs;
  final RxString _currentOrderId = ''.obs;

  // Payment method options
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'wallet',
      'name': 'Pay from Wallet',
      'description': 'Pay using your wallet balance',
      'icon': Icons.account_balance_wallet,
      'isAvailable': true,
    },
    {
      'id': 'razorpay',
      'name': 'Online Payment',
      'description': 'Pay securely with Razorpay',
      'icon': Icons.credit_card,
      'isAvailable': true,
    },
    {
      'id': 'cod',
      'name': 'Cash on Delivery',
      'description': 'Pay when your order arrives',
      'icon': Icons.local_shipping,
      'isAvailable': true,
    },
  ];

  // Getters
  String get selectedPaymentMethod => _selectedPaymentMethod.value;
  bool get isProcessingPayment => _isProcessingPayment.value;
  String get currentOrderId => _currentOrderId.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to Razorpay service state changes
    ever(_razorpayService.isProcessingPayment, (bool isProcessing) {
      _isProcessingPayment.value = isProcessing;
    });
  }

  /// Select payment method
  void selectPaymentMethod(String methodId) {
    _selectedPaymentMethod.value = methodId;
    log('💳 Payment method selected: $methodId');
  }

  /// Process payment based on selected method
  Future<void> processPayment({
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
  }) async {
    try {
      print('🔵 ════════════════════════════════════════════════════════');
      print('🔵 PAYMENT CONTROLLER - PROCESS PAYMENT STARTED');
      print('🔵 ════════════════════════════════════════════════════════');
      print('  Selected payment method: ${_selectedPaymentMethod.value}');
      print('  Cart items count: ${cartItems.length}');
      print('  Total amount: ₹$totalAmount');
      print('  Is Buy Now flow: $isBuyNow');
      print('🔵 ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = true;
      print('🔄 Payment processing flag set to TRUE');

      print('🚀 Routing to ${_selectedPaymentMethod.value} payment handler...');

    if (_selectedPaymentMethod.value == 'wallet') {
      print('💰 >>> Entering Full Wallet payment flow...');
      await _processWalletPayment(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
      );
    } else if (_selectedPaymentMethod.value == 'partial_wallet') {
      print('💰 >>> Entering Partial Wallet payment flow...');
      await _processPartialWalletPayment(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
      );
    } else if (_selectedPaymentMethod.value == 'razorpay') {
        print('💳 >>> Entering Razorpay payment flow...');
        await _processRazorpayPayment(
          cartItems: cartItems,
          deliveryAddress: deliveryAddress,
          totalAmount: totalAmount,
          subTotal: subTotal,
          discount: discount,
          deliveryFee: deliveryFee,
          walletUsed: walletUsed,
          finalPayable: finalPayable,
          couponCode: couponCode,
          isBuyNow: isBuyNow,
          buyNowData: buyNowData,
        );
      } else if (_selectedPaymentMethod.value == 'cod') {
        print('💵 >>> Entering COD payment flow...');
        await _processCODPayment(
          cartItems: cartItems,
          deliveryAddress: deliveryAddress,
          totalAmount: totalAmount,
          subTotal: subTotal,
          discount: discount,
          deliveryFee: deliveryFee,
          walletUsed: walletUsed,
          finalPayable: finalPayable,
          couponCode: couponCode,
          isBuyNow: isBuyNow,
          buyNowData: buyNowData,
        );
      } else {
        print('❌ Invalid payment method selected: ${_selectedPaymentMethod.value}');
        throw Exception('Invalid payment method selected');
      }

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ PAYMENT CONTROLLER ERROR');
      print('❌ ════════════════════════════════════════════════════════');
      print('  ❌ Error: $e');
      print('  ❌ Error type: ${e.runtimeType}');
      print('  ❌ Stack trace: ${StackTrace.current}');
      print('❌ ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = false;
      print('⏹️ Processing payment flag set to FALSE');
      
      TLoaders.errorSnackBar(
        title: 'Payment Error',
        message: 'Failed to process payment. Please try again.',
      );
    }
  }

  /// Process Wallet payment
  Future<void> _processWalletPayment({
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
  }) async {
    try {
      print('💰 ════════════════════════════════════════════════════════');
      print('💰 PAYMENT CONTROLLER - WALLET FLOW');
      print('💰 ════════════════════════════════════════════════════════');
      print('  Cart items count: ${cartItems.length}');
      print('  Total amount: ₹$totalAmount');
      print('  Wallet used: ₹$walletUsed');
      print('  Coupon code: $couponCode');
      print('  Is Buy Now: $isBuyNow');
      print('  Delivery address ID: ${deliveryAddress.id}');
      print('💰 ════════════════════════════════════════════════════════');
      
      // Get current user
      final auth = Get.find<AuthRepository>();
      final firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Get user model with wallet balance
      final userService = Get.find<UserService>();
      final currentUser = await userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User data not found');
      }

      // Check wallet balance (validation only, backend handles deduction)
      final userBalance = currentUser.walletBalance;
      print('💰 Current wallet balance: ₹$userBalance');
      
      if (userBalance < walletUsed) {
        throw Exception('Insufficient wallet balance. Available: ₹$userBalance, Required: ₹$walletUsed');
      }

      print('✅ Wallet balance sufficient - Backend will handle deduction');

      // Create order with wallet payment details (backend deducts wallet)
      print('📦 Creating order with wallet payment...');
      final response = await _razorpayService.createOrder(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
        paymentMode: 'wallet',
      );
      
      _currentOrderId.value = response['orderId'];
      
      // Clear cart after successful order placement
      print('🧹 Clearing user cart after wallet payment...');
      await _razorpayService.clearCart(currentUser.uid);
      print('✅ Cart cleared from database');
      
      // Navigate to success screen
      print('🚀 Navigating to order success screen (Wallet)...');
      Get.offAllNamed(Routes.orderSuccess, arguments: {
        'orderId': response['orderId'],
        'paymentMethod': 'wallet',
        'amount': totalAmount, // Pass total order amount, not just wallet amount
      });
      
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ WALLET PAYMENT COMPLETED SUCCESSFULLY');
      print('✅ ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = false;
      
      TLoaders.successSnackBar(
        title: 'Payment Successful',
        message: '₹${walletUsed.toStringAsFixed(2)} deducted from your wallet',
      );
      
    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ WALLET PAYMENT ERROR');
      print('❌ ════════════════════════════════════════════════════════');
      print('  ❌ Error: $e');
      print('  ❌ Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = false;
      
      TLoaders.errorSnackBar(
        title: 'Wallet Payment Failed',
        message: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Process partial wallet payment (wallet + Razorpay for remaining)
  Future<void> _processPartialWalletPayment({
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
  }) async {
    try {
      print('💰 ════════════════════════════════════════════════════════');
      print('💰 PAYMENT CONTROLLER - PARTIAL WALLET FLOW');
      print('💰 ════════════════════════════════════════════════════════');
      print('  Cart items count: ${cartItems.length}');
      print('  Total amount: ₹$totalAmount');
      print('  Wallet used: ₹$walletUsed');
      print('  Final payable (remaining): ₹$finalPayable');
      print('  Coupon code: $couponCode');
      print('  Is Buy Now: $isBuyNow');
      print('  Delivery address ID: ${deliveryAddress.id}');
      print('💰 ════════════════════════════════════════════════════════');
      
      // Get current user
      final auth = Get.find<AuthRepository>();
      final firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Get user model with wallet balance
      final userService = Get.find<UserService>();
      final currentUser = await userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User data not found');
      }

      final walletBalance = currentUser.walletBalance;

      print('💰 Current wallet balance: ₹$walletBalance');
      print('💰 Wallet payment amount: ₹$walletUsed');
      print('💰 Remaining for Razorpay: ₹$finalPayable');

      if (walletBalance < walletUsed) {
        throw Exception('Insufficient wallet balance. Available: ₹$walletBalance, Required: ₹$walletUsed');
      }

      if (walletUsed <= 0) {
        throw Exception('No wallet amount to use for partial payment');
      }

      if (finalPayable <= 0) {
        throw Exception('Use full wallet payment instead of partial payment');
      }

      print('✅ Wallet balance sufficient - Backend will handle deduction & Razorpay order');

      // Create order with partial wallet + Razorpay (backend handles wallet deduction and Razorpay order creation)
      print('📦 Creating order with partial wallet + Razorpay...');
      final response = await _razorpayService.initiatePaymentWithMode(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
        paymentMode: 'partial_wallet',
      );

      _currentOrderId.value = response['orderId'];
      
      // Note: Razorpay UI is already opened by initiatePaymentWithMode
      // Cart will be cleared after successful Razorpay payment in _handlePaymentSuccess
      // No need to navigate here - Razorpay UI is now visible
      
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ PARTIAL WALLET ORDER CREATED & RAZORPAY UI OPENED');
      print('✅ ════════════════════════════════════════════════════════');
      print('  Backend deducted ₹$walletUsed from wallet');
      print('  Razorpay UI opened for remaining ₹$finalPayable');
      print('  Waiting for user to complete Razorpay payment...');
      print('✅ ════════════════════════════════════════════════════════');
      
      // Payment is in progress, don't set to false yet
      // Will be handled by Razorpay callbacks

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ PARTIAL WALLET PAYMENT ERROR');
      print('❌ ════════════════════════════════════════════════════════');
      print('  ❌ Error: $e');
      print('  ❌ Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      
      _isProcessingPayment.value = false;
      
      TLoaders.errorSnackBar(
        title: 'Wallet Payment Failed',
        message: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Process Razorpay payment
  Future<void> _processRazorpayPayment({
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
  }) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 PAYMENT CONTROLLER - RAZORPAY FLOW');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  Cart items count: ${cartItems.length}');
      print('  Total amount: ₹$totalAmount');
      print('  Final payable: ₹$finalPayable');
      print('  Coupon code: $couponCode');
      print('  Is Buy Now: $isBuyNow');
      print('  Delivery address ID: ${deliveryAddress.id}');
      print('🔍 ════════════════════════════════════════════════════════');
      
      print('📞 >>> Calling RazorpayService.initiatePaymentWithMode()...');
      final response = await _razorpayService.initiatePaymentWithMode(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
        paymentMode: 'razorpay',
      );

      _currentOrderId.value = response['orderId'];
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ PAYMENT CONTROLLER - Razorpay UI opened');
      print('  Order ID: ${_currentOrderId.value}');
      print('  Razorpay UI opened for ₹$finalPayable');
      print('  Waiting for user to complete payment...');
      print('✅ ════════════════════════════════════════════════════════');

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ PAYMENT CONTROLLER - Razorpay error');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Process COD payment
  Future<void> _processCODPayment({
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
  }) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 PAYMENT CONTROLLER - COD FLOW');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  Cart items count: ${cartItems.length}');
      print('  Total amount: ₹$totalAmount');
      print('  Final payable: ₹$finalPayable');
      print('  Coupon code: $couponCode');
      print('  Is Buy Now: $isBuyNow');
      print('  Delivery address ID: ${deliveryAddress.id}');
      print('🔍 ════════════════════════════════════════════════════════');
      
      print('📞 >>> Calling Firebase Function with COD mode...');
      
      // Get current user for cart clearing
      final auth = Get.find<AuthRepository>();
      final firebaseUser = auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }
      
      // Call the same createOrder function with COD mode
      final response = await _razorpayService.initiatePaymentWithMode(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: couponCode,
        isBuyNow: isBuyNow,
        buyNowData: buyNowData,
        paymentMode: 'cod',
      );
      
      print('✅ COD order created successfully');
      print('  📝 Order ID: ${response['orderId']}');
      print('  📝 Payment ID: ${response['paymentId']}');
      
      _currentOrderId.value = response['orderId'];
      
      // Clear cart after successful order placement
      print('🧹 Clearing user cart after COD order...');
      await _razorpayService.clearCart(firebaseUser.uid);
      print('✅ Cart cleared from database');
      
      // For COD, navigate directly to success screen (no Razorpay UI needed)
      print('🚀 Navigating to order success screen (COD)...');
      Get.offAllNamed(Routes.orderSuccess, arguments: {
        'orderId': response['orderId'],
        'paymentId': response['paymentId'],
        'amount': totalAmount,
        'paymentMethod': 'cod',
        'webhookConfirmed': true, // COD orders are immediately confirmed
      });
      
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ PAYMENT CONTROLLER - COD flow completed');
      print('  Final order ID: ${_currentOrderId.value}');
      print('✅ ════════════════════════════════════════════════════════');

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ PAYMENT CONTROLLER - COD error');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Listen to order status changes
  Stream<Map<String, dynamic>?> listenToOrderStatus(String orderId) {
    return _razorpayService.listenToOrderStatus(orderId).map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Check if order is paid
  Future<bool> isOrderPaid(String orderId) async {
    return await _razorpayService.isOrderPaid(orderId);
  }

  /// Get order details
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    return await _razorpayService.getOrderDetails(orderId);
  }

  /// Reset payment state
  void resetPaymentState() {
    _isProcessingPayment.value = false;
    _currentOrderId.value = '';
    _razorpayService.resetPaymentState();
  }

  /// Get payment method display info
  Map<String, dynamic> getPaymentMethodInfo(String methodId) {
    return paymentMethods.firstWhere(
      (method) => method['id'] == methodId,
      orElse: () => paymentMethods.first,
    );
  }

  /// Validate payment method availability
  bool isPaymentMethodAvailable(String methodId) {
    final method = paymentMethods.firstWhere(
      (method) => method['id'] == methodId,
      orElse: () => {'isAvailable': false},
    );
    return method['isAvailable'] ?? false;
  }
}
