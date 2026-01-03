import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CartService extends GetxService {
  static CartService get instance => Get.find();

  final _cartItems = <String, int>{}.obs;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  Map<String, int> get cartItems => _cartItems;

  @override
  void onInit() {
    super.onInit();
    _startCartListener();
  }

  void _startCartListener() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_cartSubscription != null) {
      _cartSubscription!.cancel();
    }

    _cartSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
          _cartItems.clear();
          for (var doc in snapshot.docs) {
            _cartItems[doc['productId']] = doc['quantity'];
          }
        });
  }

  bool isInCart(String productId) => _cartItems.containsKey(productId);
  int getQuantity(String productId) => _cartItems[productId] ?? 0;

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }
}
