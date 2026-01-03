import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/logging/app_logger.dart';

/// Comprehensive loading state management
class LoadingStateManager extends GetxController {
  static LoadingStateManager get instance => Get.find();

  // Loading states for different operations
  final RxMap<String, bool> _loadingStates = <String, bool>{}.obs;
  final RxMap<String, String> _loadingMessages = <String, String>{}.obs;
  final RxMap<String, double> _loadingProgress = <String, double>{}.obs;

  // Global loading state
  final RxBool _isGlobalLoading = false.obs;
  final RxString _globalLoadingMessage = ''.obs;

  // Getters
  bool get isGlobalLoading => _isGlobalLoading.value;
  String get globalLoadingMessage => _globalLoadingMessage.value;
  Map<String, bool> get loadingStates => _loadingStates;
  Map<String, String> get loadingMessages => _loadingMessages;
  Map<String, double> get loadingProgress => _loadingProgress;

  /// Check if a specific operation is loading
  bool isLoading(String operation) => _loadingStates[operation] ?? false;

  /// Get loading message for a specific operation
  String getLoadingMessage(String operation) => _loadingMessages[operation] ?? '';

  /// Get loading progress for a specific operation (0.0 to 1.0)
  double getLoadingProgress(String operation) => _loadingProgress[operation] ?? 0.0;

  /// Start loading for a specific operation
  void startLoading(String operation, {String? message, double? initialProgress}) {
    _loadingStates[operation] = true;
    if (message != null) {
      _loadingMessages[operation] = message;
    }
    if (initialProgress != null) {
      _loadingProgress[operation] = initialProgress.clamp(0.0, 1.0);
    }
    
    AppLogger.debug('Started loading: $operation', tag: 'LoadingState');
  }

  /// Stop loading for a specific operation
  void stopLoading(String operation) {
    _loadingStates[operation] = false;
    _loadingMessages.remove(operation);
    _loadingProgress.remove(operation);
    
    AppLogger.debug('Stopped loading: $operation', tag: 'LoadingState');
  }

  /// Update loading message for a specific operation
  void updateLoadingMessage(String operation, String message) {
    if (_loadingStates[operation] == true) {
      _loadingMessages[operation] = message;
      AppLogger.debug('Updated loading message for $operation: $message', tag: 'LoadingState');
    }
  }

  /// Update loading progress for a specific operation
  void updateLoadingProgress(String operation, double progress) {
    if (_loadingStates[operation] == true) {
      _loadingProgress[operation] = progress.clamp(0.0, 1.0);
      AppLogger.debug('Updated loading progress for $operation: ${(progress * 100).toInt()}%', tag: 'LoadingState');
    }
  }

  /// Start global loading
  void startGlobalLoading({String? message}) {
    _isGlobalLoading.value = true;
    if (message != null) {
      _globalLoadingMessage.value = message;
    }
    
    AppLogger.debug('Started global loading', tag: 'LoadingState');
  }

  /// Stop global loading
  void stopGlobalLoading() {
    _isGlobalLoading.value = false;
    _globalLoadingMessage.value = '';
    
    AppLogger.debug('Stopped global loading', tag: 'LoadingState');
  }

  /// Update global loading message
  void updateGlobalLoadingMessage(String message) {
    if (_isGlobalLoading.value) {
      _globalLoadingMessage.value = message;
      AppLogger.debug('Updated global loading message: $message', tag: 'LoadingState');
    }
  }

  /// Check if any operation is loading
  bool get isAnyLoading => _loadingStates.values.any((loading) => loading) || _isGlobalLoading.value;

  /// Get all currently loading operations
  List<String> get loadingOperations => _loadingStates.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  /// Clear all loading states
  void clearAllLoading() {
    _loadingStates.clear();
    _loadingMessages.clear();
    _loadingProgress.clear();
    _isGlobalLoading.value = false;
    _globalLoadingMessage.value = '';
    
    AppLogger.debug('Cleared all loading states', tag: 'LoadingState');
  }

  /// Execute operation with loading state
  Future<T?> executeWithLoading<T>(
    String operation,
    Future<T> Function() task, {
    String? loadingMessage,
    bool showGlobalLoading = false,
  }) async {
    try {
      if (showGlobalLoading) {
        startGlobalLoading(message: loadingMessage);
      } else {
        startLoading(operation, message: loadingMessage);
      }

      final result = await task();
      
      if (showGlobalLoading) {
        stopGlobalLoading();
      } else {
        stopLoading(operation);
      }

      return result;
    } catch (e) {
      if (showGlobalLoading) {
        stopGlobalLoading();
      } else {
        stopLoading(operation);
      }
      
      AppLogger.error('Operation failed: $operation', tag: 'LoadingState', error: e);
      rethrow;
    }
  }

  /// Execute operation with progress tracking
  Future<T?> executeWithProgress<T>(
    String operation,
    Future<T> Function(ProgressCallback progressCallback) task, {
    String? loadingMessage,
  }) async {
    try {
      startLoading(operation, message: loadingMessage, initialProgress: 0.0);

      final result = await task((progress) {
        updateLoadingProgress(operation, progress);
      });

      stopLoading(operation);
      return result;
    } catch (e) {
      stopLoading(operation);
      AppLogger.error('Operation with progress failed: $operation', tag: 'LoadingState', error: e);
      rethrow;
    }
  }

  /// Get loading state summary
  Map<String, dynamic> getLoadingSummary() {
    return {
      'isGlobalLoading': isGlobalLoading,
      'globalLoadingMessage': globalLoadingMessage,
      'isAnyLoading': isAnyLoading,
      'loadingOperations': loadingOperations,
      'loadingStates': Map.from(_loadingStates),
      'loadingMessages': Map.from(_loadingMessages),
      'loadingProgress': Map.from(_loadingProgress),
    };
  }
}

/// Progress callback type
typedef ProgressCallback = void Function(double progress);

/// Loading state widget
class LoadingStateWidget extends StatelessWidget {
  final String operation;
  final Widget child;
  final Widget? loadingWidget;
  final String? loadingMessage;
  final bool showProgress;

  const LoadingStateWidget({
    super.key,
    required this.operation,
    required this.child,
    this.loadingWidget,
    this.loadingMessage,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoadingStateManager>(
      builder: (loadingManager) {
        final isLoading = loadingManager.isLoading(operation);
        final message = loadingMessage ?? loadingManager.getLoadingMessage(operation);
        final progress = loadingManager.getLoadingProgress(operation);

        if (!isLoading) {
          return child;
        }

        return loadingWidget ?? _buildDefaultLoadingWidget(context, message, progress);
      },
    );
  }

  Widget _buildDefaultLoadingWidget(BuildContext context, String message, double progress) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message.isNotEmpty ? message : 'Loading...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (showProgress && progress > 0) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Global loading overlay
class GlobalLoadingOverlay extends StatelessWidget {
  final Widget child;

  const GlobalLoadingOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoadingStateManager>(
      builder: (loadingManager) {
        return Stack(
          children: [
            child,
            if (loadingManager.isGlobalLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            loadingManager.globalLoadingMessage.isNotEmpty
                                ? loadingManager.globalLoadingMessage
                                : 'Loading...',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Extension for easy loading state management
extension LoadingStateExtension on GetxController {
  LoadingStateManager get loadingManager => LoadingStateManager.instance;

  void startLoading(String operation, {String? message, double? initialProgress}) =>
      loadingManager.startLoading(operation, message: message, initialProgress: initialProgress);

  void stopLoading(String operation) => loadingManager.stopLoading(operation);

  void updateLoadingMessage(String operation, String message) =>
      loadingManager.updateLoadingMessage(operation, message);

  void updateLoadingProgress(String operation, double progress) =>
      loadingManager.updateLoadingProgress(operation, progress);

  bool isLoading(String operation) => loadingManager.isLoading(operation);

  Future<T?> executeWithLoading<T>(
    String operation,
    Future<T> Function() task, {
    String? loadingMessage,
    bool showGlobalLoading = false,
  }) => loadingManager.executeWithLoading(operation, task, loadingMessage: loadingMessage, showGlobalLoading: showGlobalLoading);

  Future<T?> executeWithProgress<T>(
    String operation,
    Future<T> Function(ProgressCallback progressCallback) task, {
    String? loadingMessage,
  }) => loadingManager.executeWithProgress(operation, task, loadingMessage: loadingMessage);
}
