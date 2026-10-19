import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'App startup service registration order does not crash or freeze',
    () async {
      final storageService = StorgeService();
      await storageService.init();
      Get.put<StorgeService>(storageService, permanent: true);

      Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
      Get.lazyPut<TransactionRepostory>(
        () => TransactionRepostory(),
        fenix: true,
      );
      Get.put<BudgetService>(BudgetService(), permanent: true);
      Get.put<AccountService>(AccountService(), permanent: true);

      // Initializing GroupService must not throw exception even before runApp
      expect(
        () => Get.put<GroupService>(GroupService(), permanent: true),
        returnsNormally,
      );

      final groupService = Get.find<GroupService>();
      expect(groupService.groups, isNotNull);
    },
  );
}
