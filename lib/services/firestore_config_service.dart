import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Service to configure Firestore settings including offline persistence
class FirestoreConfigService extends GetxService {
  static FirestoreConfigService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firestore settings
  Future<void> initialize() async {
    try {
      log('Initializing Firestore configuration...', name: 'FirestoreConfig');
      
      // Enable offline persistence for better user experience
      await _enableOfflinePersistence();
      
      // Configure cache settings
      await _configureCacheSettings();
      
      log('✅ Firestore configuration completed successfully', name: 'FirestoreConfig');
    } catch (e) {
      log('❌ Error configuring Firestore: $e', name: 'FirestoreConfig');
      // Don't throw error - app should continue to work
    }
  }

  /// Enable offline persistence
  Future<void> _enableOfflinePersistence() async {
    try {
      // Configure settings only once
      _firestore.settings = Settings(
        cacheSizeBytes: _getOptimalCacheSize(),
        persistenceEnabled: true,
        host: 'firestore.googleapis.com',
        sslEnabled: true,
      );
      
      log('✅ Offline persistence enabled with ${(_getOptimalCacheSize() / 1024 / 1024).round()}MB cache', 
          name: 'FirestoreConfig');
    } catch (e) {
      log('⚠️ Failed to enable persistence: $e', name: 'FirestoreConfig');
      
      // Try minimal settings fallback
      try {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
        );
        log('✅ Basic persistence enabled', name: 'FirestoreConfig');
      } catch (altError) {
        log('❌ Failed to configure persistence: $altError', name: 'FirestoreConfig');
      }
    }
  }

  /// Configure cache settings for better performance
  Future<void> _configureCacheSettings() async {
    // Cache settings are now configured in _enableOfflinePersistence()
    // This method is kept for future extensibility
    log('✅ Cache settings already configured', name: 'FirestoreConfig');
  }

  /// Get optimal cache size based on device capabilities
  int _getOptimalCacheSize() {
    // For mobile apps, we use a smaller, more efficient cache size
    // 40MB is sufficient for most e-commerce apps and reduces memory pressure
    return 40 * 1024 * 1024; // 40MB - optimal for mobile
  }

  /// Check if device is online and can connect to Firestore
  Future<bool> isOnline() async {
    try {
      // Try to read a small document to test connectivity
      final doc = await _firestore
          .collection('app_settings')
          .doc('connection_test')
          .get(const GetOptions(source: Source.server));
      
      return true; // Successfully connected to server
    } catch (e) {
      log('❌ Network connectivity check failed: $e', name: 'FirestoreConfig');
      return false; // No server connection
    }
  }

  /// Get data with fallback to cache when offline
  Future<T?> getWithFallback<T>({
    required Future<T> Function() serverCall,
    required Future<T?> Function() cacheCall,
    String? operationName,
  }) async {
    try {
      // Try server first
      final result = await serverCall();
      log('✅ ${operationName ?? 'Operation'} successful from server', name: 'FirestoreConfig');
      return result;
    } catch (e) {
      log('⚠️ Server call failed for ${operationName ?? 'operation'}: $e', name: 'FirestoreConfig');
      
      try {
        // Fallback to cache
        final cachedResult = await cacheCall();
        if (cachedResult != null) {
          log('✅ ${operationName ?? 'Operation'} successful from cache', name: 'FirestoreConfig');
          return cachedResult;
        }
      } catch (cacheError) {
        log('❌ Cache fallback failed for ${operationName ?? 'operation'}: $cacheError', name: 'FirestoreConfig');
      }
      
      rethrow; // Re-throw original error if both server and cache fail
    }
  }

  /// Wait for pending writes to complete
  Future<void> waitForPendingWrites() async {
    try {
      await _firestore.waitForPendingWrites();
      log('✅ All pending writes completed', name: 'FirestoreConfig');
    } catch (e) {
      log('❌ Error waiting for pending writes: $e', name: 'FirestoreConfig');
    }
  }

  /// Clear Firestore cache (useful for testing)
  Future<void> clearCache() async {
    try {
      await _firestore.clearPersistence();
      log('✅ Firestore cache cleared', name: 'FirestoreConfig');
    } catch (e) {
      log('❌ Error clearing cache: $e', name: 'FirestoreConfig');
    }
  }

  /// Enable/disable network for testing offline scenarios
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
      log('✅ Network enabled', name: 'FirestoreConfig');
    } catch (e) {
      log('❌ Error enabling network: $e', name: 'FirestoreConfig');
    }
  }

  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      log('✅ Network disabled (offline mode)', name: 'FirestoreConfig');
    } catch (e) {
      log('❌ Error disabling network: $e', name: 'FirestoreConfig');
    }
  }
}
