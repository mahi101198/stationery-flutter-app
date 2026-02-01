import 'package:get/get.dart';
import 'package:rps_stationery/features/product/controllers/product_detail_controller.dart';
import 'package:rps_stationery/features/shop/controllers/review_controller.dart';

class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductDetailController());
    Get.lazyPut(() => ReviewController());
  }
}
