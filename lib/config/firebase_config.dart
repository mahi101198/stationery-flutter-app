import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Single source of truth for all Firebase configuration
/// This replaces the duplicated data in app_config.dart and provides
/// a centralized way to access Firebase configuration
class FirebaseConfig {
  FirebaseConfig._();

  // ============================================================================
  // PROJECT INFORMATION
  // ============================================================================
  
  /// Firebase project ID
  static const String projectId = 'rps-statationary-jaipur';
  
  /// Firebase project number
  static const String projectNumber = '1090273726787';
  
  /// Application package name
  static const String packageName = 'com.devay.rps_stationery';
  
  /// iOS bundle ID
  static const String iosBundleId = 'com.devay.rpsStationery';

  // ============================================================================
  // API KEYS
  // ============================================================================
  
  /// Android API Key
  static const String androidApiKey = 'AIzaSyDAv8g6j-JEpVRL6sPTUsQjZSlDZ5RSmes';
  
  /// iOS API Key
  static const String iosApiKey = 'AIzaSyCFY4riwGzbtsD_cCBK9Q9nJQzfHvGCBZM';

  // ============================================================================
  // APP IDs
  // ============================================================================
  
  /// Android App ID
  static const String androidAppId = '1:1090273726787:android:5b0827e6ec755af8701ff6';
  
  /// iOS App ID
  static const String iosAppId = '1:1090273726787:ios:a33b579527d4d6bd701ff6';

  // ============================================================================
  // OAUTH CLIENT IDs
  // ============================================================================
  
  /// Android OAuth Client ID (Type 1)
  static const String androidOAuthClientId = '1090273726787-14isc7f8fsqocmbql1u15togrutjijuu.apps.googleusercontent.com';
  
  /// iOS OAuth Client ID (Type 2)
  static const String iosOAuthClientId = '1090273726787-8fcbjdhc14lj0hsdu9e65amrfod6v9it.apps.googleusercontent.com';
  
  /// Web OAuth Client ID (Type 3)
  static const String webOAuthClientId = '1090273726787-o06cvumlg0huf25r4bkd4ji6cfd2sn49.apps.googleusercontent.com';

  // ============================================================================
  // CERTIFICATE FINGERPRINTS
  // ============================================================================
  
  /// SHA-1 fingerprint (with colons) - for Firebase Console
  static const String sha1Fingerprint = '8E:82:41:62:C0:88:9D:27:88:C0:D6:03:DD:87:89:C0:32:E5:98:DA';
  
  /// SHA-256 fingerprint (with colons) - for Firebase Console
  static const String sha256Fingerprint = '06:03:28:4F:33:ED:01:B0:16:E4:7A:D6:55:A9:EB:D4:E4:0D:22:61:1B:0C:26:B5:E4:33:74:B4:11:FC:C5:16';
  
  /// Certificate hash (lowercase, no colons) - for google-services.json
  static const String certificateHash = '8e824162c0889d2788c0d603dd8789c032e598da';

  // ============================================================================
  // FIREBASE OPTIONS GENERATION
  // ============================================================================
  
  /// Generate FirebaseOptions for current platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseConfig has not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'FirebaseConfig has not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'FirebaseConfig has not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseConfig has not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'FirebaseConfig is not supported for this platform.',
        );
    }
  }

  /// Android Firebase configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: projectNumber,
    projectId: projectId,
    databaseURL: 'https://rps-statationary-jaipur-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'rps-statationary-jaipur.firebasestorage.app',
  );

  /// iOS Firebase configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: iosApiKey,
    appId: iosAppId,
    messagingSenderId: projectNumber,
    projectId: projectId,
    databaseURL: 'https://rps-statationary-jaipur-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'rps-statationary-jaipur.firebasestorage.app',
    androidClientId: '1090273726787-7med1jcpttfhn58e3s6evd4lrcbu5fph.apps.googleusercontent.com',
    iosClientId: iosOAuthClientId,
    iosBundleId: iosBundleId,
  );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get the appropriate API key for current platform
  static String get currentApiKey {
    if (kIsWeb) return androidApiKey; // Default to Android for web
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidApiKey;
      case TargetPlatform.iOS:
        return iosApiKey;
      default:
        return androidApiKey;
    }
  }
  
  /// Get the appropriate App ID for current platform
  static String get currentAppId {
    if (kIsWeb) return androidAppId; // Default to Android for web
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidAppId;
      case TargetPlatform.iOS:
        return iosAppId;
      default:
        return androidAppId;
    }
  }
  
  /// Get the appropriate OAuth Client ID for current platform
  static String get currentOAuthClientId {
    if (kIsWeb) return webOAuthClientId;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidOAuthClientId;
      case TargetPlatform.iOS:
        return iosOAuthClientId;
      default:
        return androidOAuthClientId;
    }
  }
}
