import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:get/get.dart';

/// E-posta & Şifre ile kimlik doğrulama, kayıt ve şifre sıfırlama controller'ı
class AuthController extends BaseController {
  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
          ? Get.find<UserSessionController>()
          : Get.put(UserSessionController());

  // ---------------------------------------------------------------------------
  // Reaktif Durum Değişkenleri
  // ---------------------------------------------------------------------------

  /// 0: Giriş Yap, 1: Kayıt Ol
  final RxInt selectedTab = 0.obs;

  /// Şifre görünürlük durumları
  final RxBool isLoginPasswordHidden = true.obs;
  final RxBool isRegisterPasswordHidden = true.obs;

  /// Şifre sıfırlama işlemi yükleniyor mu
  final RxBool isResetLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Form Anahtarları ve Metin Denetleyicileri
  // ---------------------------------------------------------------------------

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

  // Giriş Yap alanları
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  // Kayıt Ol alanları
  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();

  // Şifre sıfırlama alanı
  final TextEditingController resetEmailController = TextEditingController();

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Doğrulama Fonksiyonları (Validation)
  // ---------------------------------------------------------------------------

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Lütfen adınızı ve soyadınızı giriniz.";
    }
    if (value.trim().length < 2) {
      return "Ad Soyad en az 2 karakter olmalıdır.";
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Lütfen e-posta adresinizi giriniz.";
    }
    final clean = value.trim();
    if (!GetUtils.isEmail(clean)) {
      return "Lütfen geçerli bir e-posta adresi giriniz.";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Lütfen şifrenizi giriniz.";
    }
    if (value.length < 6) {
      return "Şifre en az 6 karakter olmalıdır.";
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Kimlik Doğrulama İşlemleri
  // ---------------------------------------------------------------------------

  /// 1. E-posta & Şifre ile Giriş Yap
  Future<void> loginWithEmail() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) return;

    try {
      setLoading(true);
      final user = await _userSession.loginWithEmail(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );

      if (user != null) {
        final name = _userSession.currentUserName.value.isNotEmpty
            ? _userSession.currentUserName.value
            : "Kullanıcı";

        Get.snackbar(
          "Giriş Başarılı",
          "Hoş geldiniz, $name!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          duration: const Duration(seconds: 2),
        );

        // Başarılı giriş sonrası doğrudan Cüzdan sayfasına (/home) yönlendir
        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Giriş FirebaseAuthException: [${e.code}] ${e.message}");
      _showFriendlyAuthError(e);
    } on TimeoutException catch (e) {
      debugPrint("Giriş zaman aşımı: $e");
      showErrorSnackbar(
        message:
            "İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyiniz.",
      );
    } catch (e) {
      debugPrint("Giriş bilinmeyen hata: $e");
      showErrorSnackbar(message: "Giriş yapılırken bir sorun oluştu.");
    } finally {
      setLoading(false);
    }
  }

  /// 2. E-posta & Şifre ile Kayıt Ol
  Future<void> registerWithEmail() async {
    if (!(registerFormKey.currentState?.validate() ?? false)) return;

    try {
      setLoading(true);
      final user = await _userSession.registerWithEmail(
        fullName: registerNameController.text.trim(),
        email: registerEmailController.text.trim(),
        password: registerPasswordController.text,
      );

      if (user != null) {
        Get.snackbar(
          "Kayıt Başarılı 🎉",
          "Hesabınız oluşturuldu. Aramıza hoş geldin!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          icon: const Icon(Icons.celebration_rounded, color: Colors.white),
          duration: const Duration(seconds: 2),
        );

        // Başarılı kayıt sonrası doğrudan Cüzdan sayfasına (/home) yönlendir
        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Kayıt FirebaseAuthException: [${e.code}] ${e.message}");
      _showFriendlyAuthError(e);
    } on TimeoutException catch (e) {
      debugPrint("Kayıt zaman aşımı: $e");
      showErrorSnackbar(
        message:
            "İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyiniz.",
      );
    } catch (e) {
      debugPrint("Kayıt bilinmeyen hata: $e");
      showErrorSnackbar(message: "Kayıt olunurken bir sorun oluştu.");
    } finally {
      setLoading(false);
    }
  }

  /// 3. Şifre Sıfırlama Bağlantısı Gönder
  Future<void> sendPasswordReset() async {
    if (!(resetFormKey.currentState?.validate() ?? false)) return;

    try {
      isResetLoading.value = true;
      final email = resetEmailController.text.trim();
      await _userSession.sendPasswordReset(email);

      Get.back(); // Diyaloğu kapat
      resetEmailController.clear();

      Get.snackbar(
        "Sıfırlama Bağlantısı Gönderildi",
        "$email adresine şifre sıfırlama linki gönderildi. Lütfen gelen kutunuzu kontrol edin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      _showFriendlyAuthError(e);
    } catch (e) {
      debugPrint("Şifre sıfırlama hatası: $e");
      showErrorSnackbar(message: "Şifre sıfırlama e-postası gönderilemedi.");
    } finally {
      isResetLoading.value = false;
    }
  }

  /// 4. Google ile Giriş Yap (Mevcut altyapıyı bağla)
  Future<void> signInWithGoogle() async {
    try {
      setLoading(true);
      final success = await _userSession.loginWithGoogle();

      if (success) {
        Get.snackbar(
          "Giriş Başarılı",
          "Google hesabınızla başarıyla giriş yapıldı.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          duration: const Duration(seconds: 2),
        );

        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      debugPrint("Google login hatası: $e");
      showErrorSnackbar(
        message: "Google ile giriş yapılamadı, lütfen tekrar deneyiniz.",
      );
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase Auth Türkçe Hata Eşlemesi
  // ---------------------------------------------------------------------------

  void _showFriendlyAuthError(FirebaseAuthException e) {
    String title = "Giriş Başarısız";
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = "Bu e-posta adresine ait kayıtlı bir kullanıcı bulunamadı.";
        break;
      case 'wrong-password':
        message = "Hatalı şifre girdiniz. Lütfen kontrol edip tekrar deneyin.";
        break;
      case 'invalid-credential':
        message = "E-posta adresi veya şifre hatalı. Lütfen kontrol ediniz.";
        break;
      case 'email-already-in-use':
        title = "Kayıt Yapılamadı";
        message =
            "Bu e-posta adresi zaten kullanımda. Giriş Yap sekmesinden oturum açabilirsiniz.";
        break;
      case 'weak-password':
        title = "Zayıf Şifre";
        message =
            "Şifreniz çok zayıf. Lütfen en az 6 karakterli daha güçlü bir şifre belirleyin.";
        break;
      case 'invalid-email':
        message = "Girdiğiniz e-posta formatı geçersiz.";
        break;
      case 'user-disabled':
        message = "Bu kullanıcı hesabı askıya alınmış veya kapatılmış.";
        break;
      case 'too-many-requests':
        message =
            "Çok fazla başarısız deneme yapıldı. Güvenliğiniz için lütfen biraz bekleyip tekrar deneyin.";
        break;
      case 'network-request-failed':
        message =
            "İnternet bağlantısı kurulamadı. Lütfen ağ bağlantınızı kontrol edip tekrar deneyiniz.";
        break;
      case 'operation-not-allowed':
        message = "E-posta ile giriş yöntemi henüz aktif edilmemiş.";
        break;
      default:
        message = e.message ?? "Bir hata oluştu, lütfen tekrar deneyiniz.";
        break;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.92),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
