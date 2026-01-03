import 'dart:developer';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:rps_stationery/config/firebase_config.dart';

/// Firebase App Check Service
/// Handles App Check initialization and debug token management
class AppCheckService {
  AppCheckService._();
  
  static final AppCheckService _instance = AppCheckService._();
  static AppCheckService get instance => _instance;
  
  // ============================================================================
  // DEBUG TOKENS
  // ============================================================================
  
  /// App Check debug token for development
  /// This token should be registered in Firebase Console > App Check
  static const String debugToken = '937ae354-d1be-4e1a-b4b3-3ad88a157125';
  
  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  /// Initialize Firebase App Check with proper providers
  static Future<void> initialize() async {
    try {
      // Set debug token for development
      if (kDebugMode && debugToken.isNotEmpty && debugToken != 'YOUR_APP_CHECK_DEBUG_TOKEN_HERE') {
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
        log('🔧 Setting App Check debug token...');
      }
      
      await FirebaseAppCheck.instance.activate(
        // Android providers
        androidProvider: kDebugMode 
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
        
        // iOS providers  
        appleProvider: kDebugMode 
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
          
        // Web provider (if needed)
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
      
      log('✅ Firebase App Check initialized successfully');
      
      // Print debug info in debug mode
      if (kDebugMode) {
        _printDebugInfo();
      }
      
    } catch (e) {
      log('⚠️ Firebase App Check initialization failed: $e');
      log('🔄 App will continue to work without App Check protection');
      // Don't throw error - allow app to continue
    }
  }
  
  // ============================================================================
  // DEBUG HELPERS
  // ============================================================================
  
  /// Print App Check debug information
  static void _printDebugInfo() {
    log('🛡️ Firebase App Check Debug Info:');
    log('   🔧 Debug Mode: $kDebugMode');
    log('   📱 Platform: ${defaultTargetPlatform.name}');
    log('   🔑 Debug Token Set: ${debugToken.isNotEmpty && debugToken != 'YOUR_APP_CHECK_DEBUG_TOKEN_HERE'}');
    
    if (debugToken.isEmpty || debugToken == 'YOUR_APP_CHECK_DEBUG_TOKEN_HERE') {
      log('');
      log('⚠️  WARNING: App Check debug token not configured!');
      log('   This may cause API calls to be rejected during development.');
      log('   Please follow these steps:');
      log('');
      log('   1. Run this command to get your debug token:');
      log('      flutter run --debug');
      log('');
      log('   2. Look for a line like this in the console:');
      log('      "Firebase App Check debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"');
      log('');
      log('   3. Add the token to Firebase Console > App Check > Apps > Debug tokens');
      log('');
      log('   4. Update the debugToken constant in app_check_service.dart');
      log('');
    }
  }
  
  /// Get current App Check token (for debugging)
  static Future<String?> getCurrentToken() async {
    try {
      final result = await FirebaseAppCheck.instance.getToken();
      return result;
    } catch (e) {
      log('Failed to get App Check token: $e');
      return null;
    }
  }
  
  /// Manually set debug token (for development)
  static Future<void> setDebugToken(String token) async {
    try {
      if (kDebugMode) {
        // Note: There's no direct API to set debug token in current SDK version
        // You need to configure it in Firebase Console
        log('🔧 Debug token should be configured in Firebase Console:');
        log('   Token: $token');
        log('   Console: https://console.firebase.google.com/project/${FirebaseConfig.projectId}/appcheck/apps');
      }
    } catch (e) {
      log('Failed to set debug token: $e');
    }
  }
  
  // ============================================================================
  // UTILITIES
  // ============================================================================
  
  /// Check if App Check is properly initialized
  static Future<bool> isInitialized() async {
    try {
      final token = await getCurrentToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate instructions for configuring App Check
  static void printSetupInstructions() {
    log('');
    log('🛡️ Firebase App Check Setup Instructions:');
    log('');
    log('📋 Step 1: Get Debug Token');
    log('   1. Run: flutter run --debug');
    log('   2. Look for App Check debug token in console output');
    log('   3. Copy the token (format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)');
    log('');
    log('📋 Step 2: Register Debug Token in Firebase Console');
    log('   1. Go to: https://console.firebase.google.com/project/${FirebaseConfig.projectId}/appcheck/apps');
    log('   2. Select your Android app (com.devay.rps_stationery)');
    log('   3. Click "Manage debug tokens"');
    log('   4. Add your debug token');
    log('');
    log('📋 Step 3: Update Code');
    log('   1. Update debugToken in lib/services/app_check_service.dart');
    log('   2. Replace "YOUR_APP_CHECK_DEBUG_TOKEN_HERE" with your actual token');
    log('');
    log('📋 Step 4: Enable App Check for Services');
    log('   1. Go to Firebase Console > App Check > APIs');
    log('   2. Enable App Check for:');
    log('      - Cloud Firestore');
    log('      - Realtime Database');
    log('      - Cloud Storage');
    log('      - Cloud Functions');
    log('');
  }
}
