import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'network_service.dart';
import 'firestore_config_service.dart';

/// Service to handle automatic sync between cache and Firestore
class CacheSyncService extends GetxService {
  static CacheSyncService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  NetworkService get _networkService => NetworkService.instance;
  FirestoreConfigService get _firestoreConfig => FirestoreConfigService.instance;

  // Track sync status
  var isSyncing = false.obs;
  var lastSyncTime = DateTime.now().obs;
  var pendingWrites = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupNetworkListener();
  }

  /// Listen for network changes and trigger sync
  void _setupNetworkListener() {
    ever(_networkService.isConnected, (isConnected) {
      if (isConnected && !isSyncing.value) {
        log('📡 Network restored - triggering automatic sync', name: 'CacheSyncService');
        _autoSync();
      }
    });
  }

  /// Automatic sync when network is available
  Future<void> _autoSync() async {
    if (isSyncing.value) return;

    try {
      isSyncing.value = true;
      log('🔄 Starting automatic sync...', name: 'CacheSyncService');

      // Wait for any pending writes to complete
      await _firestoreConfig.waitForPendingWrites();
      
      // Update sync time
      lastSyncTime.value = DateTime.now();
      
      log('✅ Automatic sync completed', name: 'CacheSyncService');
    } catch (e) {
      log('❌ Auto sync failed: $e', name: 'CacheSyncService');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Manual sync trigger
  Future<void> forcSync() async {
    log('🔄 Manual sync triggered', name: 'CacheSyncService');
    await _autoSync();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'isSyncing': isSyncing.value,
      'lastSyncTime': lastSyncTime.value,
      'pendingWrites': pendingWrites.value,
      'cacheSize': '~${(100).toStringAsFixed(0)}MB max', // Our configured cache size
    };
  }

  /// Clear cache (for testing or storage management)
  Future<void> clearCache() async {
    try {
      log('🗑️ Clearing Firestore cache...', name: 'CacheSyncService');
      await _firestoreConfig.clearCache();
      log('✅ Cache cleared successfully', name: 'CacheSyncService');
    } catch (e) {
      log('❌ Error clearing cache: $e', name: 'CacheSyncService');
    }
  }

  /// Check if data needs sync
  Future<bool> needsSync() async {
    try {
      // Check if there are pending writes
      final snapshot = await _firestore.collection('_syncCheck').limit(1).get();
      return snapshot.metadata.hasPendingWrites;
    } catch (e) {
      return false;
    }
  }
}
