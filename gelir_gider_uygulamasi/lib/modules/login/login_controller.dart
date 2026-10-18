import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

class LoginController extends BaseController {
  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  Future<void> googleIleGirisYap() async {
    try {
      setLoading(true);
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        showErrorSnackbar(message: "Giriş yapılamadı lütfen tekrar deneyin.");
      }
    } catch (e) {
      debugPrint("Giriş hatası: $e");
      showErrorSnackbar(message: "Giriş yapılırken bir hata oluştu: $e");
    } finally {
      setLoading(false);
    }
  }
}
