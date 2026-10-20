import 'package:gelir_gider_uygulamasi/modules/extra/extra_controller.dart';
import 'package:get/get.dart';

class ExtraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExtraController>(() => ExtraController());
  }
}
