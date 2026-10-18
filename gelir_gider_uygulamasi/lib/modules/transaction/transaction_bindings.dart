import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/instance_manager.dart';

class TransactionBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TransactionController());
    Get.lazyPut(() => CategoriesController());
  }
}
