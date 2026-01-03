import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/features/auth/screens/signup/signup.dart';

class OnboardingController extends GetxController {

  static OnboardingController get instance => Get.find();

  final pageController = PageController();
  final RxInt currentPageIndex = 0.obs;
  //
  // @override
  // void onReady() {
  //   final ctx = Get.context!;
  //   precacheImage(const AssetImage(ImageString.onBoardingImage1), ctx);
  //   precacheImage(const AssetImage(ImageString.onBoardingImage2), ctx);
  //   precacheImage(const AssetImage(ImageString.onBoardingImage3), ctx);
  // }

  void onPageChanged(int index) => currentPageIndex.value = index;

  void onDotClicked(int index) {
    currentPageIndex.value = index;
    pageController.animateToPage(
        index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void skip() {
    AuthRepository.instance.markOnboardingAsCompleted();
    Get.offAll(() => const SignupScreen());
  }

  void next() {
    if (currentPageIndex.value == 2) {
      AuthRepository.instance.markOnboardingAsCompleted();
      Get.offAll(() => const SignupScreen());
    } else {
      currentPageIndex.value++;
      pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

}


