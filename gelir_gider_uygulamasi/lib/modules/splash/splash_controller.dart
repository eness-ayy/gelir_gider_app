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
    int attempts = 0;
    while (!Get.isRegistered<StorgeService>() ||
        !Get.isRegistered<ApiServices>() ||
        !Get.isRegistered<AuthService>()) {
      if (attempts++ > 15) break; // Max ~3 seconds
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> checkTokenAndRedirect() async {
    try {
      final authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      if (authService == null) {
        Get.offAllNamed(AppRoutes.LOGIN);
        return;
      }

      // Add a 3 second timeout so a sleeping or slow backend never hangs the splash screen
      final isAuthenticated = await authService
          .isAuthenticated()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        // If timed out, check if token exists locally so user isn't locked out offline
        final storage = Get.isRegistered<StorgeService>() ? Get.find<StorgeService>() : null;
        final token = storage?.getValue<String>(StorageKeys.userToken);
        return token != null && token.isNotEmpty;
      });

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.offAllNamed(AppRoutes.LOGIN);
      }
    } catch (e) {
      // In case of any unhandled error, gracefully proceed to Login
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
