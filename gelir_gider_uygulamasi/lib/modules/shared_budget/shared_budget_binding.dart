import 'package:gelir_gider_uygulamasi/modules/shared_budget/shared_budget_controller.dart';
import 'package:get/get.dart';

class SharedBudgetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SharedBudgetController>(() => SharedBudgetController());
  }
}
