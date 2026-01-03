import 'package:get/get.dart';
import 'package:rps_stationery/features/category/controllers/streaming_subcategory_products_controller.dart';

class StreamingSubCategoryProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StreamingSubCategoryProductsController>(
      () => StreamingSubCategoryProductsController(),
    );
  }
}
