import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
    Get.lazyPut<TransactionRepostory>(() => TransactionRepostory(), fenix: true);
    Get.lazyPut<BudgetService>(() => BudgetService(), fenix: true);
    Get.lazyPut<AccountService>(() => AccountService(), fenix: true);
    Get.lazyPut<GroupService>(() => GroupService(), fenix: true);
  }
}
