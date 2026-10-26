import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:get/get.dart';

import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';

/// E-posta & Şifre ile kimlik doğrulama, kayıt ve şifre sıfırlama controller'ı
class AuthController extends BaseController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase Auth mevcut kullanıcısını reaktif olarak tutan Rx nesnesi
  final Rx<User?> firebaseUser = Rx<User?>(null);

  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController());

  bool _isNavigating = false;

  // ---------------------------------------------------------------------------
  // Reaktif Durum Değişkenleri
  // ---------------------------------------------------------------------------

  /// 0: Giriş Yap, 1: Kayıt Ol
  final RxInt selectedTab = 0.obs;

  /// Şifre görünürlük durumları
  final RxBool isLoginPasswordHidden = true.obs;
  final RxBool isRegisterPasswordHidden = true.obs;
  final RxBool isRegisterConfirmPasswordHidden = true.obs;

  /// Şifre sıfırlama işlemi yükleniyor mu
  final RxBool isResetLoading = false.obs;

  /// Canlı şifre kriter kontrolleri (Kayıt ekranı)
  final RxBool hasMinLength = false.obs; // En az 8 karakter
  final RxBool hasUpperCase = false.obs; // En az 1 büyük harf [A-Z]
  final RxBool hasNumber = false.obs; // En az 1 rakam [0-9]
  final RxBool hasSpecialChar = false.obs; // En az 1 özel karakter [!@#\$&*~]
  final RxBool isRegisterPasswordFocused = false.obs;

  /// Satır içi (inline) hata yönetimi (Snackbar yerine)
  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString confirmPasswordError = RxnString();
  final RxnString resetEmailError = RxnString();

  void clearEmailError() {
    if (emailError.value != null) emailError.value = null;
    if (passwordError.value == "Girdiğiniz şifre veya e-posta hatalı.") {
      passwordError.value = null;
    }
  }

  void clearPasswordError() {
    if (passwordError.value != null) passwordError.value = null;
    if (emailError.value != null &&
        (emailError.value?.trim().isEmpty ?? false)) {
      emailError.value = null;
    }
  }

  void clearConfirmPasswordError() {
    if (confirmPasswordError.value != null) confirmPasswordError.value = null;
  }

  void clearResetEmailError() {
    if (resetEmailError.value != null) resetEmailError.value = null;
  }

  void clearErrors() {
    emailError.value = null;
    passwordError.value = null;
    confirmPasswordError.value = null;
    resetEmailError.value = null;
  }

  /// Canlı şifre kriter kontrollerini çalıştırır
  void checkPasswordCriteria(String password) {
    hasMinLength.value = password.length >= 8;
    hasUpperCase.value = password.contains(RegExp(r'[A-Z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(
      RegExp(r'[!@#\$&*~_.,;:\-%+?^=(){}|<>[\]/\\]'),
    );

    if (passwordError.value != null) {
      passwordError.value = null;
    }

    if (registerConfirmPasswordController.text.isNotEmpty) {
      if (password != registerConfirmPasswordController.text) {
        confirmPasswordError.value = "Şifreler birbiriyle eşleşmiyor.";
      } else {
        confirmPasswordError.value = null;
      }
    }
  }

  /// Şifre tekrar anlık kontrolü
  void checkConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = null;
      return;
    }
    if (confirmPassword != registerPasswordController.text) {
      confirmPasswordError.value = "Şifreler birbiriyle eşleşmiyor.";
    } else {
      confirmPasswordError.value = null;
    }
  }

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
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();

  // Şifre sıfırlama alanı
  final TextEditingController resetEmailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // 1. GetX standartlarında reaktif akış bağlama
    firebaseUser.bindStream(_auth.authStateChanges());
    // 2. Oturum durumunu dinle (Çıkış yapıldığında veya giriş yapıldığında tetiklenir)
    ever(firebaseUser, _handleAuthStateChanged);
  }

  /// Oturum durumuna göre rotalama kontrolü
  void _handleAuthStateChanged(User? user) {
    if (_isNavigating) return;

    // Splash ekranındayken yönlendirme kontrolünü SplashController üstlenir
    if (Get.currentRoute == AppRoutes.splash || Get.currentRoute.isEmpty) {
      return;
    }

    final isAuth = user != null;

    if (!isAuth) {
      // Oturum kapalı veya kullanıcı çıkış yapmış -> Login ekranına yönlendir
      if (Get.currentRoute != AppRoutes.login &&
          Get.currentRoute != AppRoutes.auth) {
        _isNavigating = true;
        Get.offAllNamed(AppRoutes.login);
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _isNavigating = false,
        );
      }
    } else {
      // Oturum açık -> Kullanıcıyı senkronize et ve Ana Sayfaya (Home) yönlendir
      _syncUserData(user);
      if (Get.currentRoute != AppRoutes.home) {
        _isNavigating = true;
        Get.offAllNamed(AppRoutes.home);
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _isNavigating = false,
        );
      }
    }
  }

  /// Oturum açıldığında yerel kullanıcı ve profil bilgilerini eşitler
  void _syncUserData(User user) {
    try {
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        authService.loadCachedUser();
      }
      if (Get.isRegistered<UserSessionController>()) {
        final session = Get.find<UserSessionController>();
        session.firebaseUser.value = user;
      }
    } catch (e) {
      debugPrint("Kullanıcı veri senkronizasyon hatası: $e");
    }
  }

  /// Kullanıcı oturumunu kapatır; authStateChanges akışı sistemi otomatik Login ekranına yönlendirir
  Future<void> signOut() async {
    try {
      setLoading(true);
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().signOut();
      } else {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint("Çıkış yapma hatası: $e");
    } finally {
      setLoading(false);
    }
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
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

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Lütfen şifrenizi tekrar giriniz.";
    }
    if (value != registerPasswordController.text) {
      return "Şifreler birbiriyle eşleşmiyor.";
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Kimlik Doğrulama İşlemleri
  // ---------------------------------------------------------------------------

  /// 1. E-posta & Şifre ile Giriş Yap (Satır içi hata yönetimi, snackbar yok)
  Future<void> loginWithEmail() async {
    clearErrors();
    if (!(loginFormKey.currentState?.validate() ?? false)) return;

    try {
      setLoading(true);
      final user = await _userSession.loginWithEmail(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );

      if (user != null) {
        // Başarılı giriş sonrası doğrudan Cüzdan sayfasına (/home) yönlendir
        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Giriş FirebaseAuthException: [${e.code}] ${e.message}");
      _mapLoginAuthError(e);
    } on TimeoutException catch (e) {
      debugPrint("Giriş zaman aşımı: $e");
      passwordError.value =
          "İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyiniz.";
    } catch (e) {
      debugPrint("Giriş bilinmeyen hata: $e");
      passwordError.value =
          "Giriş yapılırken bir sorun oluştu. Lütfen bilgilerinizi kontrol ediniz.";
    } finally {
      setLoading(false);
    }
  }

  /// 2. E-posta & Şifre ile Kayıt Ol (Satır içi hata yönetimi & canlı kriter kontrolü)
  Future<void> registerWithEmail() async {
    clearErrors();
    if (!(registerFormKey.currentState?.validate() ?? false)) return;

    // Şifre kuralları kontrolü
    if (!hasMinLength.value ||
        !hasUpperCase.value ||
        !hasNumber.value ||
        !hasSpecialChar.value) {
      passwordError.value = "Lütfen şifre kurallarını eksiksiz tamamlayın.";
      return;
    }

    // Şifre tekrar kontrolü
    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      confirmPasswordError.value = "Şifreler birbiriyle eşleşmiyor.";
      return;
    }

    try {
      setLoading(true);
      final user = await _userSession.registerWithEmail(
        fullName: registerNameController.text.trim(),
        email: registerEmailController.text.trim(),
        password: registerPasswordController.text,
      );

      if (user != null) {
        // Başarılı kayıt sonrası doğrudan Cüzdan sayfasına (/home) yönlendir
        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Kayıt FirebaseAuthException: [${e.code}] ${e.message}");
      _mapRegisterAuthError(e);
    } on TimeoutException catch (e) {
      debugPrint("Kayıt zaman aşımı: $e");
      passwordError.value =
          "İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyiniz.";
    } catch (e) {
      debugPrint("Kayıt bilinmeyen hata: $e");
      passwordError.value =
          "Kayıt olunurken bir sorun oluştu. Lütfen tekrar deneyiniz.";
    } finally {
      setLoading(false);
    }
  }

  /// 3. Şifre Sıfırlama Bağlantısı Gönder (Satır içi hata yönetimi, snackbar yok)
  Future<void> sendPasswordReset() async {
    clearResetEmailError();
    if (!(resetFormKey.currentState?.validate() ?? false)) return;

    try {
      isResetLoading.value = true;
      final email = resetEmailController.text.trim();
      await _userSession.sendPasswordReset(email);

      Get.back(); // Diyaloğu kapat
      resetEmailController.clear();
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Şifre sıfırlama FirebaseAuthException: [${e.code}] ${e.message}",
      );
      _mapResetAuthError(e);
    } catch (e) {
      debugPrint("Şifre sıfırlama hatası: $e");
      resetEmailError.value = "Şifre sıfırlama e-postası gönderilemedi.";
    } finally {
      isResetLoading.value = false;
    }
  }

  /// 4. Google ile Giriş Yap (Mevcut altyapıyı bağla, snackbar yok)
  Future<void> signInWithGoogle() async {
    clearErrors();
    try {
      setLoading(true);
      final success = await _userSession.loginWithGoogle();

      if (success) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      debugPrint("Google login hatası: $e");
      passwordError.value =
          "Google ile giriş yapılamadı. Lütfen tekrar deneyiniz.";
    } finally {
      setLoading(false);
    }
  }

  /// 5. Firebase Anonymous Authentication (Misafir Girişi)
  Future<void> signInAnonymously() async {
    clearErrors();
    try {
      setLoading(true);
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        _syncUserData(user);
        try {
          await CategoryService().initializeDefaultCategories(user.uid);
        } catch (_) {}
        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Misafir girişi FirebaseAuthException: [${e.code}] ${e.message}",
      );
      passwordError.value =
          "Misafir girişi şu anda yapılamıyor. Lütfen tekrar deneyiniz.";
    } catch (e) {
      debugPrint("Misafir girişi hatası: $e");
      passwordError.value = "Misafir girişi sırasında bir sorun oluştu.";
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase Auth Satır İçi Hata Eşlemesi (errorText için)
  // ---------------------------------------------------------------------------

  void _mapLoginAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Hatalı şifre veya e-posta girildiğinde hem e-posta hem şifre kutusu kırmızı olur
        emailError.value = " ";
        passwordError.value = "Girdiğiniz şifre veya e-posta hatalı.";
        break;
      case 'invalid-email':
        emailError.value = "Girdiğiniz e-posta formatı geçersiz.";
        break;
      case 'user-disabled':
        emailError.value =
            "Bu kullanıcı hesabı askıya alınmış veya kapatılmış.";
        break;
      case 'too-many-requests':
        emailError.value = " ";
        passwordError.value =
            "Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.";
        break;
      case 'network-request-failed':
        passwordError.value =
            "İnternet bağlantısı kurulamadı. Ağınızı kontrol ediniz.";
        break;
      case 'operation-not-allowed':
        emailError.value = "E-posta ile giriş yöntemi henüz aktif değil.";
        break;
      default:
        emailError.value = " ";
        passwordError.value =
            e.message ??
            "Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.";
        break;
    }
  }

  void _mapRegisterAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        emailError.value =
            "Bu e-posta adresi zaten kullanımda. Giriş Yap sekmesinden oturum açabilirsiniz.";
        break;
      case 'invalid-email':
        emailError.value = "Girdiğiniz e-posta formatı geçersiz.";
        break;
      case 'weak-password':
        passwordError.value =
            "Şifre çok zayıf. Lütfen şifre kriterlerini karşılayınız.";
        break;
      case 'too-many-requests':
        passwordError.value =
            "Çok fazla istek yapıldı. Lütfen biraz bekleyip tekrar deneyiniz.";
        break;
      case 'network-request-failed':
        passwordError.value =
            "İnternet bağlantısı kurulamadı. Ağınızı kontrol ediniz.";
        break;
      default:
        passwordError.value =
            e.message ??
            "Kayıt işlemi başarısız oldu. Lütfen tekrar deneyiniz.";
        break;
    }
  }

  void _mapResetAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        resetEmailError.value = "Bu e-posta adresine kayıtlı hesap bulunamadı.";
        break;
      case 'invalid-email':
        resetEmailError.value = "Girdiğiniz e-posta formatı geçersiz.";
        break;
      case 'too-many-requests':
        resetEmailError.value =
            "Çok fazla istek yapıldı. Lütfen biraz bekleyip tekrar deneyiniz.";
        break;
      case 'network-request-failed':
        resetEmailError.value =
            "İnternet bağlantısı kurulamadı. Ağınızı kontrol ediniz.";
        break;
      default:
        resetEmailError.value =
            e.message ?? "Şifre sıfırlama e-postası gönderilemedi.";
        break;
    }
  }
}
