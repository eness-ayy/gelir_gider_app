import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/currency_service.dart';
import 'package:gelir_gider_uygulamasi/services/firestore_group_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/network_service.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NetworkService>()) {
      Get.put<NetworkService>(NetworkService(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
    Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
    Get.lazyPut<TransactionRepostory>(() => TransactionRepostory(), fenix: true);
    Get.lazyPut<BudgetService>(() => BudgetService(), fenix: true);
    Get.lazyPut<AccountService>(() => AccountService(), fenix: true);
    Get.lazyPut<GroupService>(() => GroupService(), fenix: true);
    Get.lazyPut<CurrencyService>(() => CurrencyService(), fenix: true);
    Get.lazyPut<FirestoreGroupService>(() => FirestoreGroupService(), fenix: true);
    Get.lazyPut<UserSessionController>(() => UserSessionController(), fenix: true);
  }
}


