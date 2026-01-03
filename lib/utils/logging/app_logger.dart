import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Comprehensive logging system for the app
class AppLogger {
  AppLogger._();

  static const String _tag = 'RPS_Stationery';

  /// Log levels
  static const int VERBOSE = 0;
  static const int DEBUG = 1;
  static const int INFO = 2;
  static const int WARNING = 3;
  static const int ERROR = 4;
  static const int FATAL = 5;

  /// Current log level (set to DEBUG in debug mode, INFO in release)
  static int get _currentLogLevel => kDebugMode ? DEBUG : INFO;

  /// Log verbose messages (only in debug mode)
  static void verbose(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= VERBOSE) {
      _log('VERBOSE', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Log debug messages
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= DEBUG) {
      _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info messages
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= INFO) {
      _log('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning messages
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= WARNING) {
      _log('WARNING', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= ERROR) {
      _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
    }

    // Report to Crashlytics in production
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: false,
        information: [message],
      );
    }
  }

  /// Log fatal messages
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_currentLogLevel <= FATAL) {
      _log('FATAL', message, tag: tag, error: error, stackTrace: stackTrace);
    }

    // Report to Crashlytics in production
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: true,
        information: [message],
      );
    }
  }

  /// Internal logging method
  static void _log(String level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$logTag] $message';

    if (kDebugMode) {
      // Use Flutter's developer log in debug mode
      dev.log(
        logMessage,
        name: logTag,
        level: _getLogLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // Use print in release mode (will be filtered by log level)
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Convert string level to int level
  static int _getLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'VERBOSE': return VERBOSE;
      case 'DEBUG': return DEBUG;
      case 'INFO': return INFO;
      case 'WARNING': return WARNING;
      case 'ERROR': return ERROR;
      case 'FATAL': return FATAL;
      default: return INFO;
    }
  }

  /// Log API requests
  static void logApiRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    debug('API Request: $method $url', tag: 'API');
    if (headers != null) {
      debug('Headers: $headers', tag: 'API');
    }
    if (body != null) {
      debug('Body: $body', tag: 'API');
    }
  }

  /// Log API responses
  static void logApiResponse(String method, String url, int statusCode, {dynamic response}) {
    if (statusCode >= 200 && statusCode < 300) {
      info('API Response: $method $url - $statusCode', tag: 'API');
    } else if (statusCode >= 400 && statusCode < 500) {
      warning('API Response: $method $url - $statusCode', tag: 'API');
    } else {
      error('API Response: $method $url - $statusCode', tag: 'API');
    }
    
    if (response != null) {
      debug('Response: $response', tag: 'API');
    }
  }

  /// Log user actions
  static void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    info('User Action: $action', tag: 'USER');
    if (parameters != null) {
      debug('Parameters: $parameters', tag: 'USER');
    }
  }

  /// Log navigation events
  static void logNavigation(String from, String to, {Map<String, dynamic>? arguments}) {
    info('Navigation: $from -> $to', tag: 'NAVIGATION');
    if (arguments != null) {
      debug('Arguments: $arguments', tag: 'NAVIGATION');
    }
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (duration.inMilliseconds > 1000) {
      warning('Slow operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE');
    } else {
      debug('Operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE');
    }
    
    if (metadata != null) {
      debug('Metadata: $metadata', tag: 'PERFORMANCE');
    }
  }

  /// Log database operations
  static void logDatabaseOperation(String operation, String table, {Map<String, dynamic>? data}) {
    debug('Database: $operation on $table', tag: 'DATABASE');
    if (data != null) {
      verbose('Data: $data', tag: 'DATABASE');
    }
  }

  /// Log authentication events
  static void logAuthEvent(String event, {String? userId, Map<String, dynamic>? metadata}) {
    info('Auth Event: $event', tag: 'AUTH');
    if (userId != null) {
      debug('User ID: $userId', tag: 'AUTH');
    }
    if (metadata != null) {
      debug('Metadata: $metadata', tag: 'AUTH');
    }
  }

  /// Log payment events
  static void logPaymentEvent(String event, {String? orderId, double? amount, Map<String, dynamic>? metadata}) {
    info('Payment Event: $event', tag: 'PAYMENT');
    if (orderId != null) {
      debug('Order ID: $orderId', tag: 'PAYMENT');
    }
    if (amount != null) {
      debug('Amount: \$${amount.toStringAsFixed(2)}', tag: 'PAYMENT');
    }
    if (metadata != null) {
      debug('Metadata: $metadata', tag: 'PAYMENT');
    }
  }

  /// Log cart operations
  static void logCartOperation(String operation, {String? productId, int? quantity, Map<String, dynamic>? metadata}) {
    debug('Cart Operation: $operation', tag: 'CART');
    if (productId != null) {
      debug('Product ID: $productId', tag: 'CART');
    }
    if (quantity != null) {
      debug('Quantity: $quantity', tag: 'CART');
    }
    if (metadata != null) {
      debug('Metadata: $metadata', tag: 'CART');
    }
  }

  /// Log error with context
  static void logErrorWithContext(String context, Object error, StackTrace stackTrace, {Map<String, dynamic>? metadata}) {
    AppLogger.error('Error in $context: $error', tag: 'ERROR', error: error, stackTrace: stackTrace);
    if (metadata != null) {
      AppLogger.debug('Context metadata: $metadata', tag: 'ERROR');
    }
  }

  /// Log network connectivity changes
  static void logNetworkChange(bool isConnected, String connectionType) {
    info('Network: ${isConnected ? 'Connected' : 'Disconnected'} via $connectionType', tag: 'NETWORK');
  }

  /// Log memory usage
  static void logMemoryUsage(String context) {
    // This would require platform-specific implementation
    // For now, just log the context
    debug('Memory check: $context', tag: 'MEMORY');
  }

  /// Log app lifecycle events
  static void logAppLifecycle(String event) {
    info('App Lifecycle: $event', tag: 'LIFECYCLE');
  }

  /// Log feature usage
  static void logFeatureUsage(String feature, {Map<String, dynamic>? metadata}) {
    info('Feature Used: $feature', tag: 'FEATURE');
    if (metadata != null) {
      debug('Metadata: $metadata', tag: 'FEATURE');
    }
  }
}

/// Extension for easy logging
extension AppLoggerExtension on Object {
  void logVerbose(String message, {String? tag}) => AppLogger.verbose(message, tag: tag);
  void logDebug(String message, {String? tag}) => AppLogger.debug(message, tag: tag);
  void logInfo(String message, {String? tag}) => AppLogger.info(message, tag: tag);
  void logWarning(String message, {String? tag}) => AppLogger.warning(message, tag: tag);
  void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) => 
    AppLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  void logFatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) => 
    AppLogger.fatal(message, tag: tag, error: error, stackTrace: stackTrace);
}
