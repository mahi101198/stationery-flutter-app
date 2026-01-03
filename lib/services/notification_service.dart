import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/services/delivery_confirmation_service.dart';
import 'package:rps_stationery/services/notification_storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final GetStorage _storage = GetStorage();
  
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationPermissionKey = 'notification_permission';

  static Future<void> initialize() async {
    try {
      print('📱 NotificationService: Starting initialization...');
      // Request notification permissions
      print('📱 NotificationService: Requesting permissions...');
      await _requestPermissions();

      // Initialize local notifications
      print('📱 NotificationService: Initializing local notifications...');
      await _initializeLocalNotifications();

      // Configure FCM
      print('📱 NotificationService: Configuring FCM...');
      await _configureFCM();

      // Get and store FCM token
      print('📱 NotificationService: Getting FCM token...');
      await _getFCMToken();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    print('🔐 ════════════════════════════════════════════════════════');
    print('🔐 REQUESTING NOTIFICATION PERMISSIONS');
    print('🔐 ════════════════════════════════════════════════════════');
    
    // Request FCM permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Request system notification permission
    final Permission permission = Permission.notification;
    final PermissionStatus permissionStatus = await permission.request();

    bool isGranted = settings.authorizationStatus == AuthorizationStatus.authorized &&
                    permissionStatus == PermissionStatus.granted;
    
    _storage.write(_notificationPermissionKey, isGranted);
    
    print('  FCM Authorization Status: ${settings.authorizationStatus}');
    print('  FCM Alert: ${settings.alert}');
    print('  FCM Badge: ${settings.badge}');
    print('  FCM Sound: ${settings.sound}');
    print('  System Permission: $permissionStatus');
    print('  Overall Permission Granted: $isGranted');
    
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ FCM Permission DENIED - Notifications will NOT work!');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM Permission GRANTED - Notifications should work!');
    } else {
      print('⚠️ FCM Permission Status: ${settings.authorizationStatus}');
    }
    
    print('🔐 ════════════════════════════════════════════════════════');
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'orders',  // ✅ Must match backend channelId
      'Order Updates',
      description: 'Notifications about your order status',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel promoChannel = AndroidNotificationChannel(
      'promotions',
      'Promotions & Offers',
      description: 'Special offers and promotional notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(promoChannel);
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  static Future<void> _configureFCM() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message when app is launched from notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _getFCMToken() async {
    try {
      print('🔑 ════════════════════════════════════════════════════════');
      print('🔑 GETTING FCM TOKEN');
      print('🔑 ════════════════════════════════════════════════════════');
      
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _storage.write(_fcmTokenKey, token);
        print('✅ FCM Token Generated: ${token.substring(0, 30)}...');
        print('✅ Token Length: ${token.length} characters');
        print('✅ Token Stored Locally: ${_storage.read(_fcmTokenKey) != null}');
        
        // Send token to server for user-specific notifications
        _sendTokenToServer(token);
      } else {
        print('❌ FCM Token is NULL! Check Firebase configuration');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      print('🔄 FCM Token Refreshed: ${token.substring(0, 30)}...');
      _storage.write(_fcmTokenKey, token);
      _sendTokenToServer(token);
    });
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      print('📤 Sending FCM token to server: ${token.substring(0, 20)}...');
      
      // Save FCM token to Firestore if user is authenticated
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        final userId = auth.currentUser!.uid;
        
        // Use set with merge to avoid errors if document doesn't exist yet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('✅ FCM token saved to Firestore for user: $userId');
      } else {
        print('⚠️ User not authenticated, FCM token saved locally only');
      }
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
      // Don't rethrow - FCM token update should not break the app
    }
  }

  /// Update FCM token for logged in user (call this after login)
  static Future<void> updateFCMTokenForUser() async {
    try {
      print('🔄 Updating FCM token for logged in user...');
      
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        print('⚠️ No user logged in, skipping FCM token update');
        return;
      }
      
      // Get current FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
        _storage.write(_fcmTokenKey, token);
        print('✅ FCM token updated for logged in user');
      } else {
        print('⚠️ Could not get FCM token');
      }
    } catch (e) {
      print('❌ Error updating FCM token for user: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📥 ════════════════════════════════════════════════════════');
    print('📥 RECEIVED FOREGROUND FCM MESSAGE');
    print('📥 ════════════════════════════════════════════════════════');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');
    print('  From: ${message.from}');
    print('  Message ID: ${message.messageId}');
    print('  Sent Time: ${message.sentTime}');
    print('📥 ════════════════════════════════════════════════════════');
    
    // Store notification in database
    await storeNotificationFromMessage(message);
    
    // Handle delivery confirmation messages immediately when app is in foreground
    final messageType = message.data['type'] as String?;
    if (messageType == 'order_confirmation') {
      print('🚚 Handling delivery confirmation in foreground');
      try {
        final deliveryService = Get.find<DeliveryConfirmationService>();
        deliveryService.handleDeliveryConfirmationFromNotification(message.data);
        // Don't show system notification for delivery confirmations in foreground
        // as we're showing the popup directly
        return;
      } catch (e) {
        print('❌ Error handling delivery confirmation in foreground: $e');
        // Fallback to showing system notification
      }
    }
    
    // Show local notification when app is in foreground for other message types
    // Note: This will show in system tray even when app is open
    await showNotification(message);
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.data}');
    
    // Navigate to appropriate screen based on notification data
    _navigateBasedOnNotification(message);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      Map<String, dynamic> data = json.decode(response.payload!);
      _navigateFromPayload(data);
    }
  }

  static void _navigateBasedOnNotification(RemoteMessage message) {
    final data = message.data;
    _navigateFromPayload(data);
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;  // Backend sends 'orderId' not 'targetId'
    final targetId = data['targetId'] as String?;
    
    switch (type) {
      // Order-related notifications from backend
      case 'payment_success':
      case 'cod_order_placed':
      case 'wallet_order_placed':
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_cancelled':
      case 'order_update':
        // Backend sends 'orderId' in data
        if (orderId != null) {
          Get.toNamed(Routes.orderDetails, arguments: {'orderId': orderId});
        } else if (targetId != null) {
          Get.toNamed(Routes.orderDetails, arguments: {'orderId': targetId});
        } else {
          Get.toNamed(Routes.order);
        }
        break;
      case 'order_confirmation':
        // Handle delivery confirmation notification
        if (orderId != null) {
          // Import and use the delivery confirmation service
          try {
            final deliveryService = Get.find<DeliveryConfirmationService>();
            deliveryService.handleDeliveryConfirmationFromNotification(data);
          } catch (e) {
            print('❌ Error handling delivery confirmation: $e');
            // Fallback to order details page
            Get.toNamed(Routes.orderDetails, arguments: {'orderId': orderId});
          }
        } else {
          Get.toNamed(Routes.order);
        }
        break;
      case 'product':
        if (targetId != null) {
          Get.toNamed(Routes.productDetail, arguments: targetId);
        }
        break;
      case 'category':
        if (targetId != null) {
          Get.toNamed(Routes.category, arguments: {'categoryId': targetId});
        }
        break;
      case 'promotion':
        Get.toNamed(Routes.promotions);
        break;
      case 'referral':
        Get.toNamed(Routes.profileReferrals);
        break;
      default:
        Get.toNamed(Routes.notification);
    }
  }

  /// Store notification from FCM message
  static Future<void> storeNotificationFromMessage(RemoteMessage message) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user == null) {
        print('⚠️ No user logged in, cannot store notification');
        return;
      }

      final notification = message.notification;
      final data = message.data;
      
      if (notification == null) {
        print('⚠️ No notification payload, skipping storage');
        return;
      }

      await NotificationStorageService.storeFromFCM(
        userId: user.uid,
        type: data['type'] ?? 'general',
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        orderId: data['orderId'],
        productId: data['productId'],
        categoryId: data['categoryId'],
        data: data,
      );

      print('✅ Notification stored in database');
    } catch (e) {
      print('❌ Error storing notification: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    try {
      print('🔔 ════════════════════════════════════════════════════════');
      print('🔔 SHOWING LOCAL NOTIFICATION');
      print('🔔 ════════════════════════════════════════════════════════');
      
      final notification = message.notification;
      final data = message.data;
      
      if (notification == null) {
        print('⚠️ No notification payload in message, skipping...');
        return;
      }
      
      final String type = data['type'] ?? 'general';
      final String channelId = _getChannelId(type);
      
      print('  Notification Type: $type');
      print('  Channel ID: $channelId');
      print('  Title: ${notification.title}');
      print('  Body: ${notification.body}');
      
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: _getImportance(channelId),
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        // largeIcon: data['imageUrl'] != null 
        //   ? DrawableResourceAndroidBitmap('ic_notification')
        //   : null,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = message.hashCode;
      print('  Notification ID: $notificationId');
      print('  Platform Details: $platformDetails');
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        notification.title,
        notification.body,
        platformDetails,
        payload: json.encode(data),
      );
      
      print('✅ Local notification displayed successfully with ID: $notificationId');
      print('🔔 ════════════════════════════════════════════════════════');
    } catch (e) {
      print('❌ Error showing notification: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  static String _getChannelId(String? type) {
    switch (type) {
      // Order-related notifications (from backend)
      case 'payment_success':
      case 'cod_order_placed':
      case 'wallet_order_placed':
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_cancelled':
      case 'order_update':
      case 'order_confirmation':  // ✅ Added delivery confirmation
        return 'orders';  // ✅ Must match backend channelId
      case 'promotion':
        return 'promotions';
      default:
        return 'general';
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'orders':  // ✅ Updated to match new channel ID
        return 'Order Updates';
      case 'promotions':
        return 'Promotions & Offers';
      default:
        return 'General Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'orders':  // ✅ Updated to match new channel ID
        return 'Notifications about your order status';
      case 'promotions':
        return 'Special offers and promotional notifications';
      default:
        return 'General app notifications';
    }
  }

  static Importance _getImportance(String channelId) {
    switch (channelId) {
      case 'orders':  // ✅ Updated to match new channel ID
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  // Public methods for app usage
  static String? get fcmToken => _storage.read(_fcmTokenKey);
  
  static bool get hasNotificationPermission => 
      _storage.read(_notificationPermissionKey) ?? false;

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('🔔 Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('🔕 Unsubscribed from topic: $topic');
  }

  static Future<void> clearAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> clearNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Test FCM notification display (for debugging)
  static Future<void> testNotificationDisplay() async {
    try {
      print('🧪 Testing notification display...');
      
      final testMessage = RemoteMessage(
        data: {
          'type': 'test',
          'orderId': 'TEST_123',
        },
        notification: RemoteNotification(
          title: '🧪 Test Notification',
          body: 'This tests if notifications appear in system tray when app is open',
        ),
        messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        from: 'test',
        sentTime: DateTime.now(),
      );

      await showNotification(testMessage);
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error testing notification: $e');
    }
  }
}
