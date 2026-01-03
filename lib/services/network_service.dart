import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Service to check and monitor network connectivity
class NetworkService extends GetxService {
  static NetworkService get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  
  var isConnected = false.obs;
  var connectionType = ConnectivityResult.none.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      log('❌ Error checking connectivity: $e', name: 'NetworkService');
    }
  }

  /// Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Take the first non-none connection type or none if all are none
    final result = results.firstWhere(
      (element) => element != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    
    connectionType.value = result;
    isConnected.value = result != ConnectivityResult.none;
    
    log('📡 Network status: ${result.name}, Connected: ${isConnected.value}', 
        name: 'NetworkService');
  }

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      // First check connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.every((result) => result == ConnectivityResult.none)) {
        return false;
      }

      // Try to ping a reliable server
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        log('✅ Internet connection verified', name: 'NetworkService');
        return true;
      }
      
      return false;
    } catch (e) {
      log('❌ Internet connection check failed: $e', name: 'NetworkService');
      return false;
    }
  }

  /// Check if device can reach Firebase servers
  Future<bool> canReachFirebase() async {
    try {
      // Try to reach Firebase servers
      final results = await Future.wait([
        InternetAddress.lookup('firestore.googleapis.com'),
        InternetAddress.lookup('firebase.googleapis.com'),
      ]).timeout(const Duration(seconds: 10));
      
      bool canReach = results.every(
        (result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty,
      );
      
      log(canReach 
          ? '✅ Firebase servers reachable' 
          : '❌ Firebase servers unreachable', 
          name: 'NetworkService');
      
      return canReach;
    } catch (e) {
      log('❌ Firebase connectivity check failed: $e', name: 'NetworkService');
      return false;
    }
  }

  /// Get connection type as string
  String get connectionTypeString {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }

  /// Check if we're on a metered connection (mobile data)
  bool get isOnMeteredConnection {
    return connectionType.value == ConnectivityResult.mobile;
  }

  /// Wait for internet connection to be available
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      if (await hasInternetConnection()) {
        return true;
      }
      
      await Future.delayed(const Duration(seconds: 2));
    }
    
    return false;
  }
}
