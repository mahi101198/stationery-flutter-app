import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class NotificationController extends GetxController {
  // Observable boolean to track notification permission status
  final RxBool hasNotificationPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check permission status when controller initializes
    checkNotificationPermission();
  }

  // Method to check notification permission
  Future<void> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    hasNotificationPermission.value = status.isGranted;
  }

  // Method to request notification permission
  Future<void> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      
      switch (status) {
        case PermissionStatus.granted:
          TLoaders.customToast(message: "Notifications enabled successfully!");
          hasNotificationPermission.value = true;
          break;
        case PermissionStatus.denied:
          TLoaders.customToast(message: "Notification permission denied");
          hasNotificationPermission.value = false;
          break;
        case PermissionStatus.permanentlyDenied:
          TLoaders.customToast(message: "Please enable notifications in settings");
          hasNotificationPermission.value = false;
          // Optionally open app settings
          // await openAppSettings();
          break;
        case PermissionStatus.restricted:
          TLoaders.customToast(message: "Notifications are restricted on this device");
          hasNotificationPermission.value = false;
          break;
        default:
          hasNotificationPermission.value = false;
      }
    } catch (e) {
      TLoaders.customToast(message: "Error requesting notification permission");
      hasNotificationPermission.value = false;
    }
  }
}
