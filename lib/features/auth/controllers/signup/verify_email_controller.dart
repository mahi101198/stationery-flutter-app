import 'dart:async';

import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  @override
  void onInit() {
    super.onInit();
    sendVerificationLink();
    setTimerForRedirect();
  }

  // Send verification link
  sendVerificationLink() async {
    try {
      await AuthRepository.instance.sendEmailVerification();
      TLoaders.successSnackBar(title: "Email sent", message: "Please check your inbox and verify your email.");
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    }
  }

  // Set timer for auto redirect
  setTimerForRedirect() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Only refresh user data, don't show errors during email verification wait
        await AuthRepository.instance.refreshUser();
        final user = AuthRepository.instance.currentUser;
        if (user?.emailVerified ?? false) {
          timer.cancel();
          AuthRepository.instance.screenRedirect();
        }
      } catch (e) {
        // Completely suppress all errors during email verification check
        // This prevents any authentication error notifications from appearing
        // while the user is waiting for email verification or clicking verification link
        // Silent handling is intentional for better UX - no odd red notifications
        // Errors here are expected and normal during the verification flow
      }
    });
  }
}
