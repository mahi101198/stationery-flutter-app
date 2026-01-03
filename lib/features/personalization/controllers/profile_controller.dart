import 'package:get/get.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final geolocation = false.obs;
  final hdImageQuality = true.obs;

  void toggleGeolocation(bool value) {
    geolocation.value = value;
  }

  void toggleHdImageQuality(bool value) {
    hdImageQuality.value = value;
  }
}
