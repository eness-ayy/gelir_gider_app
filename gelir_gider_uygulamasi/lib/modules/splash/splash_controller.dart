import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

/// Splash ekranı yaşam döngüsü controller'ı.
/// İlk açılışta Firebase oturumunu doğrular ve kullanıcıyı ilgili sayfaya yönlendirir.
class SplashController extends BaseController {
  @override
  void onReady() {
    super.onReady();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Karşılama ekranının akıcı ve şık görünmesi için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 800));

      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      // Eğer currentUser henüz hazır değilse Firebase'in diskten okumasını bekle (max 2 saniye)
      if (user == null) {
        try {
          user = await auth.authStateChanges().first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
        } catch (e) {
          debugPrint("Splash oturum bekleme zaman aşımı: $e");
          user = auth.currentUser;
        }
      }

      final isAuthenticated = user != null && !user.isAnonymous;

      if (isAuthenticated) {
        // Oturum açık: yerel verileri eşitle ve Ana Sayfa'ya yönlendir
        if (Get.isRegistered<AuthService>()) {
          Get.find<AuthService>().loadCachedUser();
        }
        if (Get.isRegistered<UserSessionController>()) {
          Get.find<UserSessionController>().firebaseUser.value = user;
        }
        Get.offAllNamed(AppRoutes.home);
      } else {
        // Oturum kapalı: Giriş ekranına yönlendir
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint("Splash yönlendirme hatası: $e");
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
