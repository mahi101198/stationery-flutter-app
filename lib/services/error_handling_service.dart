import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/logging/app_logger.dart';

class ErrorHandlingService extends GetxController {
  static ErrorHandlingService get instance => Get.find();

  /// Handle errors with user-friendly messages and proper logging
  void handleError(dynamic error, {
    String? userMessage,
    bool showSnackBar = true,
    bool reportToCrashlytics = true,
  }) {
    final errorMessage = _parseError(error);
    final displayMessage = userMessage ?? errorMessage.userFriendly;

    // Log the error using the new logging system
    AppLogger.error('Error occurred: ${errorMessage.technical}', tag: 'ErrorHandling', error: error);

    // Check if we're on email verification screen and suppress all errors related to email verification
    final currentRoute = Get.currentRoute;
    final errorString = error.toString().toLowerCase();
    
    // Check if this is an error related to email verification process
    final isAuthError = errorString.contains('auth') || 
                       errorString.contains('authentication') ||
                       errorString.contains('user') ||
                       errorString.contains('reload') ||
                       errorString.contains('refresh');
                       
    final isOnVerificationScreen = currentRoute.contains('verify-email') || 
                                  currentRoute.contains('VerifyEmail') ||
                                  currentRoute.contains('verify_email');
    
    // Suppress all authentication-related error notifications during email verification
    // This prevents odd red notifications when user clicks verification link
    if (isAuthError && isOnVerificationScreen) {
      AppLogger.info('Suppressing authentication error during email verification: ${errorString.substring(0, errorString.length > 100 ? 100 : errorString.length)}', tag: 'ErrorHandling');
      return; // Don't show the error notification
    }

    // Show user-friendly message
    if (showSnackBar) {
      TLoaders.errorSnackBar(
        title: "Oops!",
        message: displayMessage,
      );
    }

    // Report to Crashlytics in production
    if (reportToCrashlytics && !kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        error is Error ? (error as Error).stackTrace : StackTrace.current,
        fatal: false,
        information: [errorMessage.technical],
      );
    }
  }

  /// Handle Firebase Storage permission errors specifically
  void handleFirebaseStorageError(dynamic error, String fileName) {
    AppLogger.error('Firebase Storage Error for $fileName: $error', tag: 'FirebaseStorage', error: error);
    
    if (error.toString().contains('403') || error.toString().contains('permission')) {
      TLoaders.errorSnackBar(
        title: "Access Denied",
        message: "Unable to load image. Please check app permissions or try again later.",
      );
    } else if (error.toString().contains('404')) {
      TLoaders.warningSnackBar(
        title: "Image Not Found",
        message: "The requested image is not available.",
      );
    } else {
      handleError(error, userMessage: "Unable to load image. Please try again.");
    }
  }

  /// Handle network connectivity errors
  void handleNetworkError(dynamic error) {
    log('🌐 Network Error: $error', name: 'NetworkError');
    
    TLoaders.errorSnackBar(
      title: "Connection Issue",
      message: "Please check your internet connection and try again.",
    );
  }

  /// Handle Firebase Firestore permission errors
  void handleFirestoreError(dynamic error, String collection) {
    log('🔥 Firestore Error in $collection: $error', name: 'Firestore');
    
    if (error.toString().contains('permission') || error.toString().contains('7')) {
      TLoaders.errorSnackBar(
        title: "Access Denied",
        message: "You don't have permission to access this data. Please sign in again.",
      );
    } else if (error.toString().contains('unavailable') || error.toString().contains('unreachable')) {
      TLoaders.errorSnackBar(
        title: "Service Unavailable",
        message: "Database is temporarily unavailable. Please try again later.",
      );
    } else if (error.toString().contains('quota') || error.toString().contains('limit')) {
      TLoaders.errorSnackBar(
        title: "Service Limit",
        message: "Database service limit reached. Please try again later.",
      );
    } else {
      handleError(error, userMessage: "Database error. Please try again later.");
    }
  }

  /// Parse error and return both technical and user-friendly messages
  _ErrorMessage _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission') || errorStr.contains('403')) {
      return _ErrorMessage(
        technical: error.toString(),
        userFriendly: "Access denied. Please check permissions.",
      );
    }

    if (errorStr.contains('network') || errorStr.contains('timeout') || errorStr.contains('connection')) {
      return _ErrorMessage(
        technical: error.toString(),
        userFriendly: "Network connection issue. Please check your internet.",
      );
    }

    if (errorStr.contains('firebase') || errorStr.contains('firestore')) {
      return _ErrorMessage(
        technical: error.toString(),
        userFriendly: "Database connection issue. Please try again later.",
      );
    }

    if (errorStr.contains('auth') || errorStr.contains('authentication')) {
      return _ErrorMessage(
        technical: error.toString(),
        userFriendly: "Authentication error. Please sign in again.",
      );
    }

    if (errorStr.contains('format') || errorStr.contains('json')) {
      return _ErrorMessage(
        technical: error.toString(),
        userFriendly: "Data format error. Please contact support if this persists.",
      );
    }

    // Default error message
    return _ErrorMessage(
      technical: error.toString(),
      userFriendly: "Something went wrong. Please try again.",
    );
  }

  /// Show retry dialog for critical errors
  void showRetryDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: "Retry",
      textCancel: "Cancel",
      onConfirm: () {
        Get.back();
        onRetry();
      },
      onCancel: () => Get.back(),
    );
  }

  /// Handle product loading errors with specific actions
  void handleProductLoadingError(dynamic error, VoidCallback onRetry) {
    log('📦 Product Loading Error: $error', name: 'ProductLoading');
    
    if (error.toString().contains('permission')) {
      showRetryDialog(
        title: "Product Access Error",
        message: "Unable to load products due to permission issues. Would you like to retry?",
        onRetry: onRetry,
      );
    } else {
      showRetryDialog(
        title: "Product Loading Failed",
        message: "Unable to load products. Please check your connection and try again.",
        onRetry: onRetry,
      );
    }
  }

  /// Handle order loading errors
  void handleOrderError(dynamic error) {
    log('🛍️ Order Error: $error', name: 'OrderError');
    
    if (error.toString().contains('auth')) {
      TLoaders.errorSnackBar(
        title: "Authentication Required",
        message: "Please sign in to view your orders.",
      );
    } else {
      TLoaders.errorSnackBar(
        title: "Order Loading Failed",
        message: "Unable to load your orders. Please try again.",
      );
    }
  }
}

class _ErrorMessage {
  final String technical;
  final String userFriendly;

  _ErrorMessage({required this.technical, required this.userFriendly});
}
