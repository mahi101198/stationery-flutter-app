import 'dart:developer';

import 'package:get/get.dart';

class StartupController extends GetxController {
  static StartupController get instance => Get.find();

  RxBool isInitializing = true.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  /// Initialize app for production
  Future<void> initializeApp() async {
    try {
      isInitializing.value = true;
      
      // App initialization for production
      // All data comes directly from Firestore
      
      log('App initialization completed');
    } catch (e) {
      log('Error during app initialization: $e');
    } finally {
      isInitializing.value = false;
    }
  }
}
