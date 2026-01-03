// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:rps_stationery/config/firebase_config.dart';
// import 'package:rps_stationery/services/database_service.dart';
// import 'package:rps_stationery/services/firebase_init_service.dart';
// import 'package:rps_stationery/services/notification_service.dart';
// import 'package:rps_stationery/services/delivery_confirmation_service.dart';
// import 'package:rps_stationery/services/app_check_service.dart';
// import 'package:rps_stationery/services/firestore_config_service.dart';
// import 'package:rps_stationery/services/network_service.dart';
// import 'package:rps_stationery/services/cache_sync_service.dart';
// import 'package:rps_stationery/services/app_settings_service.dart';
// import 'package:rps_stationery/utils/helpers/firebase_storage_helper.dart';
// import 'app.dart';
// import 'data/repositories/auth/auth_repository.dart';

// // Top-level function to handle background messages
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
  
//   print('📥 ════════════════════════════════════════════════════════');
//   print('📥 BACKGROUND FCM MESSAGE RECEIVED');
//   print('📥 ════════════════════════════════════════════════════════');
//   print('  Title: ${message.notification?.title}');
//   print('  Body: ${message.notification?.body}');
//   print('  Data: ${message.data}');
//   print('  Message ID: ${message.messageId}');
//   print('📥 ════════════════════════════════════════════════════════');
  
//   // Store notification in database
//   await NotificationService.storeNotificationFromMessage(message);
  
//   // Handle the background message here
//   await NotificationService.showNotification(message);
  
//   print('✅ Background message handled successfully');
// }

// Future<void> main() async {
//   print('🚀 Main: Starting app initialization...');
  
  
//   // Widget binding - updated layouts
//   print('🔧 Main: Initializing WidgetsFlutterBinding...');
//   final binding = WidgetsFlutterBinding.ensureInitialized();
//   print('✅ Main: WidgetsFlutterBinding initialized');

//   // Get storage
//   print('💾 Main: Initializing GetStorage...');
//   await GetStorage.init();
//   print('✅ Main: GetStorage initialized successfully');

//   // Await splash screen
//   print('🖼️ Main: Preserving splash screen...');
//   FlutterNativeSplash.preserve(widgetsBinding: binding);
//   print('✅ Main: Splash screen preserved');

//   // Initialize Firebase
//   print('🔥 Main: Initializing Firebase...');
//   await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
//   print('✅ Main: Firebase initialized successfully');

//   // Initialize Auth Repository
//   print('🔐 Main: Initializing Auth Repository...');
//   Get.put(AuthRepository());
//   print('✅ Main: Auth Repository initialized');

//   // Configure Firebase Storage
//   print('📁 Main: Configuring Firebase Storage...');
//   FirebaseStorageHelper.configureFirebaseStorage();
//   print('✅ Main: Firebase Storage configured');

//   // Initialize Firebase App Check with debug token support
//   print('🔒 Main: Initializing Firebase App Check...');
//   await AppCheckService.initialize();
//   print('✅ Main: Firebase App Check initialized');

//   // Initialize Firebase Crashlytics and keep console stack traces
//   print('🐛 Main: Setting up Firebase Crashlytics...');
//   FlutterError.onError = (errorDetails) {
//     // Filter out image loading errors - they're non-fatal
//     final isImageError = errorDetails.exception.toString().contains('NetworkImageLoadException') ||
//                          errorDetails.exception.toString().contains('HTTP request failed');
    
//     if (isImageError) {
//       // Log image errors but don't treat as fatal
//       print('⚠️ Image loading error (non-fatal): ${errorDetails.exception}');
//       FirebaseCrashlytics.instance.recordError(errorDetails.exception, errorDetails.stack, fatal: false);
//     } else {
//       // Always dump to console for local debugging
//       FlutterError.dumpErrorToConsole(errorDetails);
//       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//     }
//   };
//   // Pass all uncaught asynchronous errors to Crashlytics
//   PlatformDispatcher.instance.onError = (error, stack) {
//     // Filter out image loading errors
//     final isImageError = error.toString().contains('NetworkImageLoadException') ||
//                          error.toString().contains('HTTP request failed');
    
//     if (isImageError) {
//       // Log image errors but don't treat as fatal
//       print('⚠️ Async image loading error (non-fatal): $error');
//       FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
//       return true; // Mark as handled
//     }
    
//     // Also print async errors locally
//     FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: error, stack: stack));
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//   print('✅ Main: Firebase Crashlytics configured with image error filtering');


//   // Initialize Firebase Analytics
//   print('📈 Main: Enabling Firebase Analytics...');
//   FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
//   print('✅ Main: Firebase Analytics enabled');

//   // Initialize FCM background message handler
//   print('🔔 Main: Setting up FCM background message handler...');
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   print('✅ Main: FCM background message handler configured');

//   // Initialize Notification Service
//   print('📱 Main: Initializing Notification Service...');
//   await NotificationService.initialize();
//   print('✅ Main: Notification Service initialized');

//   // Initialize Delivery Confirmation Service
//   print('🚚 Main: Initializing Delivery Confirmation Service...');
//   Get.put(DeliveryConfirmationService());
//   print('✅ Main: Delivery Confirmation Service initialized');

//   // Initialize Network monitoring service
//   print('🌐 Main: Initializing Network Service...');
//   Get.put(NetworkService());
//   print('✅ Main: Network Service initialized');

//   // Initialize Firestore configuration (offline persistence, cache, etc.)
//   print('🗄️ Main: Initializing Firestore configuration...');
//   final firestoreConfig = Get.put(FirestoreConfigService());
//   await firestoreConfig.initialize();
//   print('✅ Main: Firestore configuration initialized');

//   // Initialize App Settings Service (loads all app constants from Firestore)
//   print('⚙️ Main: Initializing App Settings Service...');
//   final appSettingsService = Get.put(AppSettingsService());
//   await appSettingsService.init();
//   print('✅ Main: App Settings Service initialized');

//   // Initialize cache sync service for automatic data synchronization
//   print('🔄 Main: Initializing Cache Sync Service...');
//   Get.put(CacheSyncService());
//   print('✅ Main: Cache Sync Service initialized');

//   // Initialize FirebaseInitService to ensure authentication readiness
//   print('🔐 Main: Initializing Firebase Init Service...');
//   final firebaseInitService = Get.put(FirebaseInitService());
//   await firebaseInitService.initialize();
//   print('✅ Main: Firebase Init Service initialized');
  
//   // Initialize DatabaseService (only on native platforms)
//   if (!kIsWeb) {
//     print('💾 Main: Initializing Database Service (native platform)...');
//     final databaseService = Get.put(DatabaseService());
//     await databaseService.initialize();
//     print('✅ Main: Database Service initialized');
//   } else {
//     print('🌐 Main: Skipping Database Service (web platform)');
//   }

  
//   print('🎉 Main: All initialization completed successfully!');
//   print('🏃 Main: Starting app execution...');
  
//   runApp(const Root());
// }

// class Root extends StatefulWidget {
//   const Root({super.key});

//   @override
//   _RootState createState() => _RootState();
// }

// class _RootState extends State<Root> {
//   @override
//   void initState() {
//     super.initState();
//     print('🌱 Root: Root widget initialized');
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     print('🔄 Root: Starting app initialization...');
    
//     // Wait for the authentication state to be determined
//     print('🔐 Root: Waiting for authentication state...');
//     await Get.find<AuthRepository>().onReady;
//     print('✅ Root: Authentication state determined');
    
//     // Remove the splash screen after the first frame is rendered
//     print('🖼️ Root: Removing splash screen...');
//     FlutterNativeSplash.remove();
//     print('✅ Root: Splash screen removed');
    
//     print('🎉 Root: App initialization completed!');
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('🏗️ Root: Building app widget...');
//     return const App();
//   }
// }




import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:rps_stationery/services/database_service.dart';
import 'package:rps_stationery/services/firebase_init_service.dart';
import 'package:rps_stationery/services/notification_service.dart';
import 'package:rps_stationery/services/delivery_confirmation_service.dart';
import 'package:rps_stationery/services/app_check_service.dart';
import 'package:rps_stationery/services/firestore_config_service.dart';
import 'package:rps_stationery/services/network_service.dart';
import 'package:rps_stationery/services/cache_sync_service.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/utils/helpers/firebase_storage_helper.dart';

import 'app.dart';
import 'data/repositories/auth/auth_repository.dart';

/// ─────────────────────────────────────────────────────────────
/// Background FCM handler (SEPARATE ISOLATE)
/// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  await NotificationService.storeNotificationFromMessage(message);
  await NotificationService.showNotification(message);
}

/// ─────────────────────────────────────────────────────────────
/// MAIN ENTRY POINT
/// ─────────────────────────────────────────────────────────────
Future<void> main() async {
  print('🚀 Main: Starting app initialization');

  /// 1️⃣ Flutter binding
  final binding = WidgetsFlutterBinding.ensureInitialized();

  /// 2️⃣ Local storage
  await GetStorage.init();

  /// 3️⃣ Preserve splash
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  /// 4️⃣ Firebase (INITIALIZE ONLY ONCE)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  /// 5️⃣ Dependency injection (SYNC ONLY)
  Get.put(AuthRepository());
  Get.put(NetworkService());
  Get.put(DeliveryConfirmationService());

  /// 6️⃣ Firebase helpers
  FirebaseStorageHelper.configureFirebaseStorage();
  await AppCheckService.initialize();

  /// 7️⃣ Crashlytics
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  /// 8️⃣ Analytics
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  /// 9️⃣ Background FCM
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  /// 🔟 Start UI
  print('🏃 Main: Starting UI');
  runApp(const Root());
}

/// ─────────────────────────────────────────────────────────────
/// ROOT WIDGET
/// ─────────────────────────────────────────────────────────────
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    print('🌱 Root: initState');

    _initializeApp();
    _postStartupServices();
  }

  /// Splash + auth readiness
  Future<void> _initializeApp() async {
    print('🔐 Root: Waiting for auth readiness');
    await Get.find<AuthRepository>().onReady;

    FlutterNativeSplash.remove();
    print('✅ Root: Splash removed');
  }

  /// Heavy async services (NON-BLOCKING)
  void _postStartupServices() async {
    print('⚙️ Root: Starting post-startup services');

    NotificationService.initialize();

    final firestoreConfig = Get.put(FirestoreConfigService());
    firestoreConfig.initialize();

    final appSettingsService = Get.put(AppSettingsService());
    appSettingsService.init();

    Get.put(CacheSyncService());

    final firebaseInitService = Get.put(FirebaseInitService());
    firebaseInitService.initialize();

    if (!kIsWeb) {
      final databaseService = Get.put(DatabaseService());
      databaseService.initialize();
    }

    print('✅ Root: Post-startup services triggered');
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
