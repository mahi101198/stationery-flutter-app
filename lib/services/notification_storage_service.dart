import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/notification_model.dart';

class NotificationStorageService extends GetxController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list of notifications
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToNotifications();
  }

  /// Listen to notifications for current user
  void _listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      log('⚠️ No user logged in, cannot listen to notifications');
      return;
    }

    log('📱 Starting to listen to notifications for user: ${user.uid}');

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      try {
        final notificationList = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();

        notifications.value = notificationList;
        unreadCount.value = notificationList.where((n) => !n.isRead).length;

        log('📱 Updated notifications: ${notificationList.length} total, ${unreadCount.value} unread');
      } catch (e) {
        log('❌ Error processing notifications: $e');
      }
    }, onError: (error) {
      log('❌ Error listening to notifications: $error');
    });
  }

  /// Store a new notification
  static Future<String?> storeNotification(NotificationModel notification) async {
    try {
      log('💾 Storing notification: ${notification.title}');

      final docRef = await _firestore.collection('notifications').add(notification.toFirestore());
      
      log('✅ Notification stored with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('❌ Error storing notification: $e');
      return null;
    }
  }

  /// Store notification from FCM message
  static Future<String?> storeFromFCM({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? productId,
    String? categoryId,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel.fromFCM(
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      productId: productId,
      categoryId: categoryId,
      data: data,
    );

    return await storeNotification(notification);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      log('✅ Marked notification as read: $notificationId');
    } catch (e) {
      log('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final unreadNotifications = notifications.where((n) => !n.isRead);
      
      for (final notification in unreadNotifications) {
        await _firestore.collection('notifications').doc(notification.id).update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      log('✅ Marked ${unreadNotifications.length} notifications as read');
    } catch (e) {
      log('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      log('✅ Deleted notification: $notificationId');
    } catch (e) {
      log('❌ Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('✅ Deleted ${notifications.docs.length} notifications');
    } catch (e) {
      log('❌ Error deleting all notifications: $e');
    }
  }

  /// Get notifications for current user
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      log('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    isLoading.value = true;
    try {
      final notificationList = await getNotifications();
      notifications.value = notificationList;
      unreadCount.value = notificationList.where((n) => !n.isRead).length;
    } catch (e) {
      log('❌ Error refreshing notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
