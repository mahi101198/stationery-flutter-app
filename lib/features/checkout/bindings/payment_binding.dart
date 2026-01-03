import 'package:get/get.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/features/checkout/controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize Razorpay payment service
    Get.lazyPut<RazorpayPaymentService>(() => RazorpayPaymentService());
    
    // Initialize payment controller
    Get.lazyPut<PaymentController>(() => PaymentController());
  }
}
