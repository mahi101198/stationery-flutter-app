import 'package:cloud_firestore/cloud_firestore.dart';

/// Order status enum
enum OrderStatus {
  pending,
  placed,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returned,
  refunded,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  successful,
  completed,
  failed,
  refunded,
}

/// Payment mode enum
enum PaymentMode {
  cod,
  upi,
  paytm,
  razorpay,
}

/// Payment attempt model
class PaymentAttempt {
  final String paymentId;
  final PaymentStatus status;
  final DateTime timestamp;
  final String? errorMessage;

  const PaymentAttempt({
    required this.paymentId,
    required this.status,
    required this.timestamp,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'errorMessage': errorMessage,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'paymentId': paymentId,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'errorMessage': errorMessage,
    };
  }

  factory PaymentAttempt.fromMap(Map<String, dynamic> data) {
    return PaymentAttempt(
      paymentId: data['paymentId'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      errorMessage: data['errorMessage'],
    );
  }
}

/// Order item model
class OrderItem {
  final String productId;
  final String name;
  final String productImage;
  final double price;
  final double discountPrice;
  final int quantity;
  final double subtotal;
  final double totalPrice;
  final String? selectedColor;  // Selected color option

  const OrderItem({
    required this.productId,
    required this.name,
    required this.productImage,
    required this.price,
    required this.discountPrice,
    required this.quantity,
    required this.subtotal,
    required this.totalPrice,
    this.selectedColor,
  });

  /// Create from Map
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 1).toInt(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      selectedColor: data['selectedColor'] as String?,
      // Note: orderId and orderStatus are ignored (redundant data)
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'productImage': productImage,
      'price': price,
      'discountPrice': discountPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'totalPrice': totalPrice,
      if (selectedColor != null) 'selectedColor': selectedColor,
    };
  }

  /// Copy with method
  OrderItem copyWith({
    String? productId,
    String? name,
    String? productImage,
    double? price,
    double? discountPrice,
    int? quantity,
    double? subtotal,
    double? totalPrice,
    String? selectedColor,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      totalPrice: totalPrice ?? this.totalPrice,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}

/// Delivery address model
class DeliveryAddress {
  final String addressId;
  final String city;
  final String country;
  final String label;
  final String line1;
  final String line2;
  final String pincode;
  final String state;
  final String mobileNumber;              // ✅ User's mobile number
  final String? alternateNumber;          // ✅ Optional alternate number
  final String? landmark;                 // ✅ Optional landmark
  final String? recipientName;            // ✅ Recipient's name for delivery

  const DeliveryAddress({
    required this.addressId,
    required this.city,
    required this.country,
    required this.label,
    required this.line1,
    required this.line2,
    required this.pincode,
    required this.state,
    required this.mobileNumber,           // ✅ Required mobile number
    this.alternateNumber,                 // ✅ Optional alternate number
    this.landmark,                        // ✅ Optional landmark
    this.recipientName,                   // ✅ Optional recipient name
  });

  /// Create from Map
  factory DeliveryAddress.fromMap(Map<String, dynamic> data) {
    return DeliveryAddress(
      addressId: data['addressId'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      label: data['label'] ?? '',
      line1: data['line1'] ?? '',
      line2: data['line2'] ?? '',
      pincode: data['pincode'] ?? '',
      state: data['state'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',        // ✅ User's mobile
      alternateNumber: data['alternateNumber'],        // ✅ Optional alternate
      landmark: data['landmark'],                      // ✅ Optional landmark
      recipientName: data['recipientName'],            // ✅ Optional recipient name
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'city': city,
      'country': country,
      'label': label,
      'line1': line1,
      'line2': line2,
      'pincode': pincode,
      'state': state,
      'mobileNumber': mobileNumber,        // ✅ User's mobile number
      'alternateNumber': alternateNumber,  // ✅ Optional alternate number
      'landmark': landmark,                // ✅ Optional landmark
      'recipientName': recipientName,      // ✅ Optional recipient name
    };
  }
}

/// Order pricing model
class OrderPricing {
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;

  const OrderPricing({
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
  });

  factory OrderPricing.fromMap(Map<String, dynamic> data) {
    return OrderPricing(
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
    };
  }
}

/// Order timestamps model
class OrderTimestamps {
  final DateTime placedAt;
  final DateTime updatedAt;

  const OrderTimestamps({
    required this.placedAt,
    required this.updatedAt,
  });

  factory OrderTimestamps.fromMap(Map<String, dynamic> data) {
    return OrderTimestamps(
      placedAt: (data['placedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placedAt': Timestamp.fromDate(placedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Order model following new three-schema approach
class OrderModel {
  final String orderId;
  final String userId;
  final String status;                   // ✅ Order status (placed, confirmed, etc.)
  final List<OrderItem> items;
  final OrderPricing pricing;            // ✅ Pricing breakdown
  final String? deliveryId;              // ✅ Reference to delivery collection
  final String? paymentId;               // ✅ Reference to payment collection
  final OrderTimestamps timestamps;      // ✅ Order timestamps

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.status,
    required this.items,
    required this.pricing,
    this.deliveryId,                      // ✅ Reference to delivery collection
    this.paymentId,                       // ✅ Reference to payment collection
    required this.timestamps,
  });

  /// Get order status (now directly from status field)
  String get orderStatus => status;

  /// Check if order is delivered
  bool get isDelivered => orderStatus == 'delivered';

  /// Check if user can review products from this order
  bool get canReviewProducts => isDelivered;

  /// Get delivered product IDs that can be reviewed
  List<String> get deliveredProductIds {
    if (!canReviewProducts) return [];
    
    // If order is delivered, all items can be reviewed
    if (statusEnum == OrderStatus.delivered) {
      return items.map((item) => item.productId).toList();
    }
    
    return [];
  }

  /// Get order status as enum
  OrderStatus get statusEnum {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'placed':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  /// Check if order can be cancelled
  bool get canBeCancelled {
    return ['pending', 'placed', 'confirmed'].contains(orderStatus.toLowerCase());
  }

  /// Get formatted order number
  String get formattedOrderNumber {
    if (orderId.isEmpty) return 'N/A';
    return orderId.length > 8 ? orderId.substring(0, 8) : orderId;
  }

  /// Get subtotal (from pricing object)
  double get subtotal => pricing.subtotal;

  /// Get order ID (alias for orderId)
  String get id => orderId;

  // Helper getters for backward compatibility with UI components
  double get totalAmount => pricing.total;
  double get deliveryFee => pricing.deliveryFee;
  double get discountApplied => pricing.discount;
  DateTime get placedAt => timestamps.placedAt;
  DateTime get updatedAt => timestamps.updatedAt;

  /// Get payment status as enum (for backward compatibility)
  PaymentStatus get paymentStatusEnum {
    // Since we don't have payment status in the new schema, return pending
    // This will be handled by the payment collection
    return PaymentStatus.pending;
  }

  /// Get payment mode as enum (for backward compatibility)
  PaymentMode get paymentModeEnum {
    // Since we don't have payment mode in the new schema, return cod
    // This will be handled by the payment collection
    return PaymentMode.cod;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'userId': userId,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'pricing': pricing.toMap(),
      'deliveryId': deliveryId,              // ✅ Reference to delivery collection
      'paymentId': paymentId,                // ✅ Reference to payment collection
      'timestamps': timestamps.toMap(),
    };
  }

  /// Create from Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return OrderModel(
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'placed',
      items: _parseItems(data['items']),
      pricing: OrderPricing.fromMap(data['pricing'] ?? {}),
      deliveryId: data['deliveryId'],              // ✅ Reference to delivery collection
      paymentId: data['paymentId'],                // ✅ Reference to payment collection
      timestamps: OrderTimestamps.fromMap(data['timestamps'] ?? {}),
    );
  }

  /// Copy with method
  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? status,
    List<OrderItem>? items,
    OrderPricing? pricing,
    String? deliveryId,                      // ✅ Reference to delivery collection
    String? paymentId,                       // ✅ Reference to payment collection
    OrderTimestamps? timestamps,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      items: items ?? this.items,
      pricing: pricing ?? this.pricing,
      deliveryId: deliveryId ?? this.deliveryId,              // ✅ Reference to delivery collection
      paymentId: paymentId ?? this.paymentId,                 // ✅ Reference to payment collection
      timestamps: timestamps ?? this.timestamps,
    );
  }

  /// Helper method to parse items
  static List<OrderItem> _parseItems(dynamic itemsData) {
    if (itemsData == null || itemsData is! List) {
      return [];
    }

    return itemsData
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderItem.fromMap(item))
        .toList();
  }





  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId;

  @override
  int get hashCode => orderId.hashCode;

  @override
  String toString() => 'OrderModel(orderId: $orderId, status: $orderStatus)';
}

/// Delivery model for delivery collection
class DeliveryModel {
  final String deliveryId;
  final String orderId;
  final String status;
  final DeliveryAddress address;
  final DeliveryAgent? agent;
  final DeliveryTracking tracking;
  final DeliveryTimestamps timestamps;

  const DeliveryModel({
    required this.deliveryId,
    required this.orderId,
    required this.status,
    required this.address,
    this.agent,
    required this.tracking,
    required this.timestamps,
  });

  /// Create from Firestore document
  factory DeliveryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return DeliveryModel(
      deliveryId: data['deliveryId'] ?? doc.id,
      orderId: data['orderId'] ?? '',
      status: data['status'] ?? 'pending',
      address: DeliveryAddress.fromMap(data['address'] ?? {}),
      agent: data['agent'] != null ? DeliveryAgent.fromMap(data['agent']) : null,
      tracking: DeliveryTracking.fromMap(data['tracking'] ?? {}),
      timestamps: DeliveryTimestamps.fromMap(data['timestamps'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'deliveryId': deliveryId,
      'orderId': orderId,
      'status': status,
      'address': address.toMap(),
      'agent': agent?.toMap(),
      'tracking': tracking.toMap(),
      'timestamps': timestamps.toMap(),
    };
  }
}

/// Delivery agent model
class DeliveryAgent {
  final String? agentId;
  final String? name;
  final String? phone;
  final DeliveryLocation? location;

  const DeliveryAgent({
    this.agentId,
    this.name,
    this.phone,
    this.location,
  });

  factory DeliveryAgent.fromMap(Map<String, dynamic> data) {
    return DeliveryAgent(
      agentId: data['agentId'],
      name: data['name'],
      phone: data['phone'],
      location: data['location'] != null ? DeliveryLocation.fromMap(data['location']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'name': name,
      'phone': phone,
      'location': location?.toMap(),
    };
  }
}

/// Delivery location model
class DeliveryLocation {
  final double lat;
  final double lng;
  final String? address;

  const DeliveryLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  factory DeliveryLocation.fromMap(Map<String, dynamic> data) {
    return DeliveryLocation(
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

/// Delivery tracking model
class DeliveryTracking {
  final String? courier;
  final String? trackingNumber;
  final String status;
  final List<DeliveryUpdate> updates;

  const DeliveryTracking({
    this.courier,
    this.trackingNumber,
    required this.status,
    required this.updates,
  });

  factory DeliveryTracking.fromMap(Map<String, dynamic> data) {
    return DeliveryTracking(
      courier: data['courier'],
      trackingNumber: data['trackingNumber'],
      status: data['status'] ?? 'pending',
      updates: (data['updates'] as List<dynamic>?)
          ?.map((update) => DeliveryUpdate.fromMap(update))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courier': courier,
      'trackingNumber': trackingNumber,
      'status': status,
      'updates': updates.map((update) => update.toMap()).toList(),
    };
  }
}

/// Delivery update model
class DeliveryUpdate {
  final String status;
  final DateTime timestamp;
  final String location;
  final String description;

  const DeliveryUpdate({
    required this.status,
    required this.timestamp,
    required this.location,
    required this.description,
  });

  factory DeliveryUpdate.fromMap(Map<String, dynamic> data) {
    return DeliveryUpdate(
      status: data['status'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'description': description,
    };
  }
}

/// Delivery timestamps model
class DeliveryTimestamps {
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const DeliveryTimestamps({
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory DeliveryTimestamps.fromMap(Map<String, dynamic> data) {
    return DeliveryTimestamps(
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }
}

/// Payment model for payment collection
class PaymentModel {
  final String paymentId;
  final String orderId;
  final String method;
  final String status;
  final double amount;
  final String currency;
  final String? gateway;
  final String? transactionId;
  final List<PaymentAttempt> attempts;
  final List<PaymentRefund> refunds;
  final PaymentTimestamps timestamps;

  const PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.gateway,
    this.transactionId,
    required this.attempts,
    required this.refunds,
    required this.timestamps,
  });

  /// Create from Firestore document
  factory PaymentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return PaymentModel(
      paymentId: data['paymentId'] ?? doc.id,
      orderId: data['orderId'] ?? '',
      method: data['method'] ?? 'cod',
      status: data['status'] ?? 'pending',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'INR',
      gateway: data['gateway'],
      transactionId: data['transactionId'],
      attempts: (data['attempts'] as List<dynamic>?)
          ?.map((attempt) => PaymentAttempt.fromMap(attempt))
          .toList() ?? [],
      refunds: (data['refunds'] as List<dynamic>?)
          ?.map((refund) => PaymentRefund.fromMap(refund))
          .toList() ?? [],
      timestamps: PaymentTimestamps.fromMap(data['timestamps'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'method': method,
      'status': status,
      'amount': amount,
      'currency': currency,
      'gateway': gateway,
      'transactionId': transactionId,
      'attempts': attempts.map((attempt) => attempt.toMap()).toList(),
      'refunds': refunds.map((refund) => refund.toMap()).toList(),
      'timestamps': timestamps.toMap(),
    };
  }
}

/// Payment refund model
class PaymentRefund {
  final String refundId;
  final double amount;
  final String reason;
  final DateTime processedAt;

  const PaymentRefund({
    required this.refundId,
    required this.amount,
    required this.reason,
    required this.processedAt,
  });

  factory PaymentRefund.fromMap(Map<String, dynamic> data) {
    return PaymentRefund(
      refundId: data['refundId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      reason: data['reason'] ?? '',
      processedAt: (data['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'refundId': refundId,
      'amount': amount,
      'reason': reason,
      'processedAt': Timestamp.fromDate(processedAt),
    };
  }
}

/// Payment timestamps model
class PaymentTimestamps {
  final DateTime initiatedAt;
  final DateTime? completedAt;

  const PaymentTimestamps({
    required this.initiatedAt,
    this.completedAt,
  });

  factory PaymentTimestamps.fromMap(Map<String, dynamic> data) {
    return PaymentTimestamps(
      initiatedAt: (data['initiatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
