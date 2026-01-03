import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rps_stationery/components/ui/delivery_confirmation_popup.dart';

/// Service to handle delivery confirmation functionality
/// Monitors order status changes and triggers confirmation popups
class DeliveryConfirmationService extends GetxService {
  static DeliveryConfirmationService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();
  
  StreamSubscription<QuerySnapshot>? _orderStatusSubscription;
  final Set<String> _processedOrders = <String>{};
  final Set<String> _respondedOrders = <String>{}; // Track orders user has responded to
  
  // Storage keys for persistence
  static const String _respondedOrdersKey = 'responded_delivery_orders';
  
  @override
  void onInit() {
    super.onInit();
    _loadRespondedOrders();
    _initializeService();
  }

  /// Load previously responded orders from storage
  void _loadRespondedOrders() {
    final List<dynamic>? storedOrders = _storage.read(_respondedOrdersKey);
    if (storedOrders != null) {
      _respondedOrders.addAll(storedOrders.cast<String>());
      log('📦 Loaded ${_respondedOrders.length} previously responded orders');
    }
  }

  /// Save responded orders to storage
  void _saveRespondedOrders() {
    _storage.write(_respondedOrdersKey, _respondedOrders.toList());
  }

  void _initializeService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _startOrderStatusListener(user.uid);
        // Check for pending deliveries on app launch
        _checkPendingDeliveries(user.uid);
      } else {
        _stopOrderStatusListener();
      }
    });
  }

  /// Check for pending deliveries when the app launches
  Future<void> _checkPendingDeliveries(String userId) async {
    try {
      final query = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveryConfirmed', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        // Filter out orders that user has already responded to
        final unrespondedOrders = query.docs.where((doc) => 
          !_respondedOrders.contains(doc.id)
        ).toList();
        
        if (unrespondedOrders.isNotEmpty) {
          // Show popup for the most recent unconfirmed delivery that hasn't been responded to
          final mostRecentOrder = unrespondedOrders.first;
          final orderData = mostRecentOrder.data();
          
          log('🚚 Found pending delivery for order: ${mostRecentOrder.id}');
          
          // Add a small delay to ensure the app UI is fully loaded
          await Future.delayed(const Duration(milliseconds: 1500));
          
          _showDeliveryConfirmationPopup(
            orderId: mostRecentOrder.id,
            orderData: orderData,
          );
        } else {
          log('📦 All delivered orders have been responded to');
        }
      } else {
        log('📦 No pending deliveries found');
      }
    } catch (e) {
      log('❌ Error checking pending deliveries: $e');
    }
  }

  void _startOrderStatusListener(String userId) {
    _stopOrderStatusListener(); // Stop any existing listener
    
    _orderStatusSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .where('deliveryConfirmed', isEqualTo: false)
        .snapshots()
        .listen(_handleOrderStatusChange);
  }

  void _stopOrderStatusListener() {
    _orderStatusSubscription?.cancel();
    _orderStatusSubscription = null;
  }

  void _handleOrderStatusChange(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final orderId = change.doc.id;
        final orderData = change.doc.data() as Map<String, dynamic>;
        
        // Only show popup if we haven't processed this order yet AND user hasn't responded to it
        if (!_processedOrders.contains(orderId) && !_respondedOrders.contains(orderId)) {
          _processedOrders.add(orderId);
          log('🚚 New delivery detected for order: $orderId');
          _showDeliveryConfirmationPopup(
            orderId: orderId,
            orderData: orderData,
          );
        } else if (_respondedOrders.contains(orderId)) {
          log('📦 Skipping order $orderId - user already responded');
        }
      }
    }
  }

  void _showDeliveryConfirmationPopup({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) {
    final orderNumber = orderData['orderNumber'] ?? orderId;
    final totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();

    // Ensure the popup appears over any screen with proper overlay configuration
    Get.dialog(
      DeliveryConfirmationPopup(
        orderId: orderId,
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        orderData: orderData, // Pass the complete order data
        onConfirm: () {
          _markOrderAsResponded(orderId);
          _confirmDelivery(orderId);
        },
        onReject: () {
          _markOrderAsResponded(orderId);
          Get.back();
        },
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.7), // Semi-transparent overlay
      useSafeArea: true, // Respect device safe areas
      name: 'delivery_confirmation_$orderId', // Unique identifier for the dialog
      navigatorKey: Get.key, // Use GetX's navigator for global overlay
    );
  }

  /// Mark an order as responded to prevent duplicate popups
  void _markOrderAsResponded(String orderId) {
    _respondedOrders.add(orderId);
    _saveRespondedOrders();
    log('📝 Marked order $orderId as responded');
  }

  Future<void> _confirmDelivery(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryConfirmed': true,
        'deliveryConfirmedAt': FieldValue.serverTimestamp(),
      });

      Get.back(); // Close the dialog
      
      Get.snackbar(
        'Delivery Confirmed',
        'Thank you for confirming your delivery!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to confirm delivery. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  /// Handle delivery confirmation from notification tap
  Future<void> handleDeliveryConfirmationFromNotification(Map<String, dynamic> data) async {
    try {
      final orderId = data['orderId'] as String?;
      if (orderId == null) return;

      // Check if user has already responded to this order
      if (_respondedOrders.contains(orderId)) {
        log('📦 User already responded to order $orderId - skipping popup');
        return;
      }

      // Fetch the complete order data
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data()!;
      
      // Only show if not already confirmed and user hasn't responded
      if (orderData['deliveryConfirmed'] != true) {
        log('🚚 Showing delivery confirmation popup for order: $orderId');
        _showDeliveryConfirmationPopup(
          orderId: orderId,
          orderData: orderData,
        );
      } else {
        log('📦 Order $orderId already confirmed in database');
      }
    } catch (e) {
      log('❌ Error handling delivery confirmation from notification: $e');
    }
  }

  @override
  void onClose() {
    _stopOrderStatusListener();
    super.onClose();
  }
}