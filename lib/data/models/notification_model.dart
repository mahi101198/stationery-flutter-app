import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? orderId;
  final String? productId;
  final String? categoryId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.productId,
    this.categoryId,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'orderId': orderId,
      'productId': productId,
      'categoryId': categoryId,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      orderId: data['orderId'],
      productId: data['productId'],
      categoryId: data['categoryId'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from FCM message
  factory NotificationModel.fromFCM({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? productId,
    String? categoryId,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: '', // Will be set when saving to Firestore
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      productId: productId,
      categoryId: categoryId,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
      readAt: null,
    );
  }

  /// Copy with new values
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? orderId,
    String? productId,
    String? categoryId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Mark as read
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Get notification icon based on type
  String get icon {
    switch (type) {
      case 'payment_success':
        return '🎉';
      case 'cod_order_placed':
      case 'wallet_order_placed':
        return '📦';
      case 'order_confirmed':
        return '✅';
      case 'order_shipped':
        return '🚚';
      case 'order_cancelled':
        return '🔴';
      case 'order_update':
        return '📝';
      case 'promotion':
        return '🎊';
      case 'product':
        return '🛍️';
      case 'category':
        return '📂';
      case 'referral':
        return '🎁';
      default:
        return '🔔';
    }
  }

  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
