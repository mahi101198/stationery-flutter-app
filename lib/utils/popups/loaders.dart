import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

class TLoaders {
  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message, duration = 3}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: Duration(seconds: duration),
        dismissDirection: DismissDirection.vertical,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color:
                HelperFunctions.isDarkMode(Get.context!)
                    ? AppColors.darkerGrey.withValues(alpha: 0.9)
                    : AppColors.grey.withValues(alpha: 0.9),
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(Get.context!).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    if (Get.context == null) {
      return;
    }
    
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      duration: Duration(seconds: duration),
      animationDuration: const Duration(milliseconds: 400),
      icon: const Icon(Iconsax.check, color: AppColors.white),
    );
  }

  static warningSnackBar({required title, message = ''}) {
    if (Get.context == null) {
      return;
    }
    
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.black,
      backgroundColor: const Color.fromARGB(255, 215, 173, 110),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: AppColors.black),
    );
  }

  static infoSnackBar({required title, message = '', duration = 3}) {
    if (Get.context == null) {
      return;
    }
    
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: const Color(0xFF2196F3), // Material Blue
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      animationDuration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.info_circle, color: Colors.white),
    );
  }

  static errorSnackBar({required title, message = ''}) {
    if (Get.context == null) {
      return;
    }
    
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.white,
      backgroundColor: Colors.red.shade600,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: AppColors.white),
    );
  }
}
