import 'package:gelir_gider_uygulamasi/modules/shared_budget/detail/shared_budget_detail_controller.dart';
import 'package:get/get.dart';

class SharedBudgetDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SharedBudgetDetailController>(
        () => SharedBudgetDetailController());
  }
}
