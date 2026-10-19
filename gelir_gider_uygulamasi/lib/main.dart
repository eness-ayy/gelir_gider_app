import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/app_bindings.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. SharedPreferences'ı ayağa kaldır
  final storageService = StorgeService();
  await storageService.init();
  Get.put<StorgeService>(storageService, permanent: true);

  // 2. Dio / Api servisini ayağa kaldır
  final apiServices = ApiServices();
  await apiServices.init();
  Get.put<ApiServices>(apiServices, permanent: true);

  // 3. Auth servisini ayağa kaldır
  final authService = AuthService();
  await authService.init();
  Get.put<AuthService>(authService, permanent: true);

  // 4. Tema servisini ayağa kaldır
  Get.put<ThemeServices>(ThemeServices(), permanent: true);

  // Repositories
  Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
  Get.lazyPut<TransactionRepostory>(() => TransactionRepostory(), fenix: true);

  // 5. Bütçe servisini ayağa kaldır
  Get.put<BudgetService>(BudgetService(), permanent: true);

  // 6. Hesap & Ödeme Yöntemi servisini ayağa kaldır
  Get.put<AccountService>(AccountService(), permanent: true);

  // 7. Grup & Bölüştürme servisini ayağa kaldır
  Get.put<GroupService>(GroupService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gelir Gider Takip',
      debugShowCheckedModeBanner: false,
      getPages: AppPages.pages,
      initialRoute: AppRoutes.INITIAL,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      initialBinding: AppBindings(),
    );
  }
}
