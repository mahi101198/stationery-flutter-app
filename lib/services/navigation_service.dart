import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Service to handle Android back navigation properly
class NavigationService extends GetxService {
  static NavigationService get instance => Get.find();
  
  static const platform = MethodChannel('com.devay.rps_stationery/navigation');
  
  @override
  void onInit() {
    super.onInit();
    _setupBackButtonHandler();
  }

  /// Setup back button handler for Android
  void _setupBackButtonHandler() {
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.pop') {
        return _handleBackPress();
      }
      return null;
    });
  }

  /// Handle back press with proper navigation logic
  Future<bool> _handleBackPress() async {
    try {
      // Check if we can pop the current route
      if (Get.currentRoute != '/') {
        Get.back();
        return true;
      }
      
      // If we're at the root, let Android handle it
      await platform.invokeMethod('handleBackPress');
      return true;
    } catch (e) {
      // Fallback to default behavior
      SystemNavigator.pop();
      return true;
    }
  }

  /// Check if we can go back
  bool canGoBack() {
    return Get.currentRoute != '/' && Get.routing.current != '/';
  }

  /// Go back with proper error handling
  void goBack() {
    if (canGoBack()) {
      Get.back();
    } else {
      // Handle root navigation
      _handleBackPress();
    }
  }
}
