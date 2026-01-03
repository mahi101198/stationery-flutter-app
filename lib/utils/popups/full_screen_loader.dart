import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

/// A utility class for managing a full-screen loading dialog.
class FullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  /// This method doesn't return anything.
  ///
  /// Parameters:
  ///   - text: The text to be displayed in the loading dialog.
  static void openLoadingDialog(String text) {
    showDialog(
      context:
          Get.overlayContext!, // Use Get.overlayContext for overlay dialogs
      barrierDismissible:
          false, // The dialog can't be dismissed by tapping outside it
      builder:
          (_) => PopScope(
            canPop: false, // Disable popping with the back button
            child: Container(
              color:
                  HelperFunctions.isDarkMode(Get.context!)
                      ? AppColors.dark.withValues(alpha: 0.7)
                      : AppColors.white.withValues(alpha: 0.7),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 20),
                    Text(
                      text,
                      style: Theme.of(Get.context!).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /// Stop the currently open loading dialog.
  /// This method doesn't return anything.
  static stopLoading() {
    Navigator.of(
      Get.overlayContext!,
    ).pop(); // Close the dialog using the Navigator
  }
}
