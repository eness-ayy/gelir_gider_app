import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/app_bindings.dart';
import 'package:gelir_gider_uygulamasi/firebase_options.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/debt_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i servislerden önce en başta ayağa kaldırıyoruz
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Tarih ve yerelleştirme verilerini başlat
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('tr', null);

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

  // 8. Ekstra Modül Servisleri: Birikim, Borç/Alacak ve Tekrarlayan Ödemeler
  final savingsService = SavingsService();
  await savingsService.init();
  Get.put<SavingsService>(savingsService, permanent: true);

  final debtService = DebtService();
  await debtService.init();
  Get.put<DebtService>(debtService, permanent: true);

  final recurringService = RecurringService();
  await recurringService.init();
  Get.put<RecurringService>(recurringService, permanent: true);

  final creditCardService = CreditCardService();
  await creditCardService.init();
  Get.put<CreditCardService>(creditCardService, permanent: true);

  // 9. AuthController'ı oturum akışını dinlemesi için kalıcı olarak başlat
  Get.put<AuthController>(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gelir Gider Takip',
      debugShowCheckedModeBanner: false,
      getPages: AppPages.routes,
      // Başlangıç ekranı her zaman Splash olmalıdır (Firebase oturum durumu çözülürken Login kilitlenmesini önler)
      initialRoute: AppRoutes.splash,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      initialBinding: AppBindings(),
    );
  }
}
