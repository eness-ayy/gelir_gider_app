import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class SplashController extends BaseController {
  @override
  void onReady() async {
    super.onReady();
    await waitForServices();
    await checkTokenAndRedirect();
  }

  Future<void> waitForServices() async {
    while (!Get.isRegistered<StorgeService>() ||
        !Get.isRegistered<ApiServices>() ||
        !Get.isRegistered<AuthService>()) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> checkTokenAndRedirect() async {
    final authService = Get.find<AuthService>();
    final isAuthenticated = await authService.isAuthenticated();

    if (isAuthenticated) {
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
