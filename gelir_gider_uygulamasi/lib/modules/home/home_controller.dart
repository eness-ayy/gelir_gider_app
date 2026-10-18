import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

class HomeController extends BaseController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
    if (index == 1 && Get.isRegistered<ReportsController>()) {
      Get.find<ReportsController>().loadData();
    }
  }

  String get pageTitle {
    switch (currentIndex.value) {
      case 1:
        return "İstatistikler & Raporlar";
      case 0:
      default:
        return "Gelir Gider App";
    }
  }

  Future<void> cikisYap() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  void goToTransaction() {
    Get.toNamed(AppRoutes.transaction, arguments: null);
  }

  void goToProfile() {
    Get.toNamed(AppRoutes.profile);
  }
}
