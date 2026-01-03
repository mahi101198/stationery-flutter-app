import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/logging/app_logger.dart';

/// Network connectivity service for monitoring internet connection
class NetworkConnectivityService extends GetxController {
  static NetworkConnectivityService get instance => Get.find();

  // Dependencies
  final Connectivity _connectivity = Connectivity();

  // Reactive state
  final RxBool _isConnected = false.obs;
  final RxString _connectionType = 'none'.obs;
  final RxBool _isOnline = true.obs;

  // Stream subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  bool get isConnected => _isConnected.value;
  String get connectionType => _connectionType.value;
  bool get isOnline => _isOnline.value;

  // Observable getters for UI
  RxBool get isConnectedObs => _isConnected;
  RxString get connectionTypeObs => _connectionType;
  RxBool get isOnlineObs => _isOnline;

  @override
  void onInit() {
    super.onInit();
    _initializeConnectivity();
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      // Check initial connectivity state
      await _checkConnectivity();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          AppLogger.error('Connectivity stream error: $error', tag: 'NetworkConnectivity', error: error);
        },
      );

      AppLogger.info('Network connectivity monitoring initialized', tag: 'NetworkConnectivity');
    } catch (e) {
      AppLogger.error('Failed to initialize connectivity monitoring: $e', tag: 'NetworkConnectivity', error: e);
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectivityState(connectivityResults);
    } catch (e) {
      AppLogger.error('Failed to check connectivity: $e', tag: 'NetworkConnectivity', error: e);
      _isConnected.value = false;
      _connectionType.value = 'unknown';
      _isOnline.value = false;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivityState(results);
  }

  /// Update connectivity state based on results
  void _updateConnectivityState(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) => result != ConnectivityResult.none);
    final connectionType = _getConnectionType(results);

    final wasConnected = _isConnected.value;
    final wasOnline = _isOnline.value;

    _isConnected.value = hasConnection;
    _connectionType.value = connectionType;
    _isOnline.value = hasConnection;

    // Log connectivity changes
    if (wasConnected != hasConnection) {
      AppLogger.logNetworkChange(hasConnection, connectionType);
    }

    // Log if we went offline
    if (wasOnline && !hasConnection) {
      AppLogger.warning('Device went offline', tag: 'NetworkConnectivity');
    }

    // Log if we came back online
    if (!wasOnline && hasConnection) {
      AppLogger.info('Device came back online via $connectionType', tag: 'NetworkConnectivity');
    }
  }

  /// Get connection type from connectivity results
  String _getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return 'wifi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'mobile';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      return 'bluetooth';
    } else if (results.contains(ConnectivityResult.vpn)) {
      return 'vpn';
    } else {
      return 'none';
    }
  }

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      // First check basic connectivity
      if (!isConnected) {
        return false;
      }

      // Additional check could be added here to ping a server
      // For now, we rely on the connectivity plugin
      return isConnected;
    } catch (e) {
      AppLogger.error('Failed to check internet connection: $e', tag: 'NetworkConnectivity', error: e);
      return false;
    }
  }

  /// Wait for internet connection with timeout
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (isConnected) {
      return true;
    }

    AppLogger.info('Waiting for internet connection...', tag: 'NetworkConnectivity');

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _isConnected.listen((connected) {
      if (connected) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Set timeout
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        AppLogger.warning('Timeout waiting for internet connection', tag: 'NetworkConnectivity');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Get connection quality based on connection type
  String getConnectionQuality() {
    switch (connectionType) {
      case 'wifi':
        return 'excellent';
      case 'ethernet':
        return 'excellent';
      case 'mobile':
        return 'good';
      case 'bluetooth':
        return 'fair';
      case 'vpn':
        return 'good';
      default:
        return 'poor';
    }
  }

  /// Check if connection is suitable for data-heavy operations
  bool isConnectionSuitableForHeavyOperations() {
    return connectionType == 'wifi' || connectionType == 'ethernet';
  }

  /// Check if connection is suitable for basic operations
  bool isConnectionSuitableForBasicOperations() {
    return isConnected && connectionType != 'none';
  }

  /// Get user-friendly connection status
  String getConnectionStatusText() {
    if (!isConnected) {
      return 'No Internet Connection';
    }

    switch (connectionType) {
      case 'wifi':
        return 'Connected via WiFi';
      case 'mobile':
        return 'Connected via Mobile Data';
      case 'ethernet':
        return 'Connected via Ethernet';
      case 'bluetooth':
        return 'Connected via Bluetooth';
      case 'vpn':
        return 'Connected via VPN';
      default:
        return 'Connected';
    }
  }

  /// Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    AppLogger.info('Refreshing connectivity status...', tag: 'NetworkConnectivity');
    await _checkConnectivity();
  }

  /// Get connectivity statistics
  Map<String, dynamic> getConnectivityStats() {
    return {
      'isConnected': isConnected,
      'connectionType': connectionType,
      'isOnline': isOnline,
      'connectionQuality': getConnectionQuality(),
      'suitableForHeavyOps': isConnectionSuitableForHeavyOperations(),
      'suitableForBasicOps': isConnectionSuitableForBasicOperations(),
      'statusText': getConnectionStatusText(),
    };
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    AppLogger.info('Network connectivity monitoring stopped', tag: 'NetworkConnectivity');
    super.onClose();
  }
}

/// Extension for easy network checks
extension NetworkConnectivityExtension on GetxController {
  bool get isConnected => NetworkConnectivityService.instance.isConnected;
  bool get isOnline => NetworkConnectivityService.instance.isOnline;
  String get connectionType => NetworkConnectivityService.instance.connectionType;
  
  Future<bool> hasInternetConnection() => NetworkConnectivityService.instance.hasInternetConnection();
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) => 
    NetworkConnectivityService.instance.waitForConnection(timeout: timeout);
}
