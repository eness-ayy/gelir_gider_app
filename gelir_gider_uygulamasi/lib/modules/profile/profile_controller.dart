import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/debt_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  Rx<AppUser?> get user => _authService.currentUser;

  final isUpdating = false.obs;
  final isResetting = false.obs;
  final isLinking = false.obs;

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? profilePhoto,
    bool clearPhoto = false,
  }) async {
    try {
      isUpdating.value = true;
      final success = await _authService.updateProfile(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        profilePhoto: profilePhoto,
        clearPhoto: clearPhoto,
      );
      if (success) {
        if (!Get.testMode) {
          Get.snackbar(
            "Başarılı",
            "Profil bilgileriniz güncellendi",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.85),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
      }
      return success;
    } catch (e) {
      if (!Get.testMode) {
        Get.snackbar(
          "Hata",
          "Profil güncellenirken bir sorun oluştu: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateProfilePhoto(String? photoUrl, {bool clearPhoto = false}) async {
    try {
      isUpdating.value = true;
      final success = await _authService.updateProfile(
        profilePhoto: photoUrl,
        clearPhoto: clearPhoto,
      );
      if (success) {
        if (!Get.testMode) {
          Get.snackbar(
            "Fotoğraf Güncellendi",
            clearPhoto
                ? "Profil fotoğrafı kaldırıldı"
                : "Profil fotoğrafınız başarıyla güncellendi",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.85),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
      }
      return success;
    } catch (e) {
      if (!Get.testMode) {
        Get.snackbar(
          "Hata",
          "Fotoğraf güncellenirken hata: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Misafir kullanıcının oturumunu Google kimlik bilgisiyle kalıcı hesaba bağlar (linkWithCredential)
  Future<bool> linkWithGoogle() async {
    try {
      isLinking.value = true;
      final User? fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        throw Exception("Aktif bir kullanıcı oturumu bulunamadı.");
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: ApiConstants.serverClient,
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
      );

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı Google oturum açma penceresini kapattı/iptal etti
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await fbUser.linkWithCredential(credential);
      final linkedUser = userCredential.user ?? fbUser;

      final displayName = (linkedUser.displayName != null && linkedUser.displayName!.trim().isNotEmpty)
          ? linkedUser.displayName!.trim()
          : (googleUser.displayName?.trim() ?? '');
      final parts = displayName.split(' ');
      final fName = parts.isNotEmpty ? parts.first : '';
      final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final email = linkedUser.email ?? googleUser.email;

      // 1. Firestore 'users' dokümanını senkronize et
      try {
        await FirebaseFirestore.instance.collection('users').doc(linkedUser.uid).set({
          'uid': linkedUser.uid,
          'email': email,
          'firstName': fName,
          'lastName': lName,
          'fullName': displayName.isNotEmpty ? displayName : "$fName $lName".trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("linkWithGoogle Firestore güncelleme hatası: $e");
      }

      // 2. UserSessionController'ı güncelle
      if (Get.isRegistered<UserSessionController>()) {
        try {
          final session = Get.find<UserSessionController>();
          session.firebaseUser.value = linkedUser;
          session.isAnonymous.value = false;
          final resolvedName = displayName.isNotEmpty ? displayName : "$fName $lName".trim();
          if (resolvedName.isNotEmpty) {
            session.currentUserName.value = resolvedName;
            await session.persistUserName(resolvedName);
            session.bindUserGroups(resolvedName);
          }
        } catch (e) {
          debugPrint("linkWithGoogle UserSession hatası: $e");
        }
      }

      // 3. AuthService yerel kullanıcıyı güncelle
      try {
        final appUser = AppUser(
          id: linkedUser.uid,
          email: email,
          firstName: fName,
          lastName: lName,
        );
        await _authService.saveLocalUser(appUser);
      } catch (e) {
        debugPrint("linkWithGoogle AuthService hatası: $e");
      }

      if (!Get.testMode) {
        Get.snackbar(
          "Tebrikler 🎉",
          "Google hesabınız başarıyla bağlandı! Artık profilinizi dilediğiniz gibi özelleştirebilirsiniz.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("linkWithGoogle FirebaseAuthException: [${e.code}] ${e.message}");
      String message = "Hesap bağlama sırasında bir sorun oluştu.";
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        message = "Bu Google hesabı zaten başka bir kullanıcı tarafından kullanılıyor.";
      } else if (e.code == 'provider-already-linked') {
        message = "Google hesabı zaten mevcut hesabınıza bağlı.";
      } else if (e.code == 'operation-not-allowed') {
        message = "Google ile giriş Firebase üzerinde etkinleştirilmemiş.";
      } else if (e.code == 'network-request-failed') {
        message = "İnternet bağlantınızı kontrol edip tekrar deneyiniz.";
      }

      if (!Get.testMode) {
        Get.snackbar(
          "Bağlantı Hatası",
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        );
      }
      return false;
    } catch (e) {
      debugPrint("linkWithGoogle genel hata: $e");
      if (!Get.testMode) {
        Get.snackbar(
          "Hata",
          "Google ile bağlanırken bir sorun oluştu. Lütfen tekrar deneyiniz.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      return false;
    } finally {
      isLinking.value = false;
    }
  }

  /// Misafir kullanıcının oturumunu E-posta & Şifre bilgisiyle kalıcı hesaba bağlar (linkWithCredential)
  Future<bool> linkWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      isLinking.value = true;
      final User? fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        throw Exception("Aktif bir kullanıcı oturumu bulunamadı.");
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      final userCredential = await fbUser.linkWithCredential(credential);
      final linkedUser = userCredential.user ?? fbUser;

      final cleanName = fullName?.trim() ?? '';
      if (cleanName.isNotEmpty) {
        try {
          await linkedUser.updateDisplayName(cleanName);
          await linkedUser.reload();
        } catch (_) {}
      }

      final updatedFbUser = FirebaseAuth.instance.currentUser ?? linkedUser;
      final displayName = updatedFbUser.displayName ?? cleanName;
      final parts = displayName.trim().split(' ');
      final fName = parts.isNotEmpty ? parts.first : '';
      final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final cleanEmail = updatedFbUser.email ?? email.trim();

      // 1. Firestore 'users' dokümanını senkronize et
      try {
        await FirebaseFirestore.instance.collection('users').doc(updatedFbUser.uid).set({
          'uid': updatedFbUser.uid,
          'email': cleanEmail,
          'firstName': fName,
          'lastName': lName,
          'fullName': displayName.isNotEmpty ? displayName : "$fName $lName".trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("linkWithEmail Firestore güncelleme hatası: $e");
      }

      // 2. UserSessionController'ı güncelle
      if (Get.isRegistered<UserSessionController>()) {
        try {
          final session = Get.find<UserSessionController>();
          session.firebaseUser.value = updatedFbUser;
          session.isAnonymous.value = false;
          final resolvedName = displayName.isNotEmpty ? displayName : "$fName $lName".trim();
          if (resolvedName.isNotEmpty) {
            session.currentUserName.value = resolvedName;
            await session.persistUserName(resolvedName);
            session.bindUserGroups(resolvedName);
          }
        } catch (e) {
          debugPrint("linkWithEmail UserSession hatası: $e");
        }
      }

      // 3. AuthService yerel kullanıcıyı güncelle
      try {
        final appUser = AppUser(
          id: updatedFbUser.uid,
          email: cleanEmail,
          firstName: fName,
          lastName: lName,
        );
        await _authService.saveLocalUser(appUser);
      } catch (e) {
        debugPrint("linkWithEmail AuthService hatası: $e");
      }

      if (!Get.testMode) {
        Get.snackbar(
          "Tebrikler 🎉",
          "E-posta hesabınız başarıyla bağlandı! Artık profilinizi dilediğiniz gibi özelleştirebilirsiniz.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("linkWithEmail FirebaseAuthException: [${e.code}] ${e.message}");
      String message = "Hesap bağlama sırasında bir sorun oluştu.";
      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        message = "Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.";
      } else if (e.code == 'invalid-email') {
        message = "Lütfen geçerli bir e-posta adresi giriniz.";
      } else if (e.code == 'weak-password') {
        message = "Şifre çok zayıf. Lütfen en az 6 karakterli bir şifre belirleyin.";
      } else if (e.code == 'provider-already-linked') {
        message = "Bu e-posta sağlayıcısı zaten hesabınıza bağlı.";
      } else if (e.code == 'operation-not-allowed') {
        message = "E-posta ile kimlik doğrulama Firebase üzerinde etkinleştirilmemiş.";
      }

      if (!Get.testMode) {
        Get.snackbar(
          "Bağlantı Hatası",
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        );
      }
      return false;
    } catch (e) {
      debugPrint("linkWithEmail genel hata: $e");
      if (!Get.testMode) {
        Get.snackbar(
          "Hata",
          "E-posta ile bağlanırken bir sorun oluştu. Lütfen tekrar deneyiniz.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      return false;
    } finally {
      isLinking.value = false;
    }
  }

  /// Kullanıcının tüm gelir, gider ve bütçe verilerini kalıcı olarak sıfırlar
  Future<bool> resetUserData() async {
    try {
      isResetting.value = true;

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        uid = _authService.currentUser.value?.id;
      }

      if (uid == null || uid.isEmpty) {
        throw Exception("Kullanıcı oturumu bulunamadı.");
      }

      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(uid);

      // 1. Firestore 'transactions' alt koleksiyonundaki tüm işlemleri sil
      try {
        final transSnapshot = await userDoc.collection('transactions').get();
        if (transSnapshot.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in transSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint("[RESET] Transactions silinirken hata: $e");
      }

      // 2. Firestore 'categories' alt koleksiyonunu sil ve varsayılanları yeniden yükle
      try {
        final catSnapshot = await userDoc.collection('categories').get();
        if (catSnapshot.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in catSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
        await CategoryService().initializeDefaultCategories(uid);
      } catch (e) {
        debugPrint("[RESET] Categories sıfırlanırken hata: $e");
      }

      // 2.5 Firestore 'extra_modules' alt koleksiyonundaki kredi kartı, borç, kumbara ve sabit ödemeleri sil
      try {
        final extraSnapshot = await userDoc.collection('extra_modules').get();
        if (extraSnapshot.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in extraSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint("[RESET] Extra modüller silinirken hata: $e");
      }

      // 3. Yerel önbellekleri temizle
      try {
        if (Get.isRegistered<StorgeService>()) {
          final storage = Get.find<StorgeService>();
          await storage.remove(StorageKeys.cachedTransactions);
          await storage.remove(StorageKeys.cachedCategories);

          final safeKey = uid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
          await storage.remove('${StorageKeys.cachedTransactions}_$safeKey');
          await storage.remove('${StorageKeys.cachedCategories}_$safeKey');
          await storage.remove("category_budget_limits");
          await storage.remove(storage.scopedKey("category_budget_limits"));
          await storage.remove("transaction_payment_methods");
          await storage.remove(storage.scopedKey("credit_cards_data"));
          await storage.remove(storage.scopedKey("installment_purchases_data"));
          await storage.remove(storage.scopedKey("debts_ledger_data"));
          await storage.remove(storage.scopedKey("savings_goals_data"));
          await storage.remove(storage.scopedKey("recurring_transactions_data"));
          await storage.remove(storage.scopedKey("expense_groups_v1"));
        }
      } catch (e) {
        debugPrint("[RESET] Yerel önbellek temizlenirken hata: $e");
      }

      // 4. Bütçe, Ödeme Yöntemi ve Extra servislerini sıfırla
      if (Get.isRegistered<BudgetService>()) {
        try {
          Get.find<BudgetService>().budgets.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<AccountService>()) {
        try {
          Get.find<AccountService>().transactionPaymentMethods.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<CreditCardService>()) {
        try {
          final cc = Get.find<CreditCardService>();
          cc.cards.clear();
          cc.installments.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<DebtService>()) {
        try {
          Get.find<DebtService>().debts.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<SavingsService>()) {
        try {
          Get.find<SavingsService>().goals.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<RecurringService>()) {
        try {
          Get.find<RecurringService>().items.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<GroupService>()) {
        try {
          Get.find<GroupService>().groups.clear();
        } catch (_) {}
      }

      // 5. Dashboard ve Kategori durumlarını tazele
      if (Get.isRegistered<DashboardController>()) {
        try {
          final dash = Get.find<DashboardController>();
          dash.myTransaction.clear();
          dash.categories.clear();
          dash.aylikGelir.value = 0.0;
          dash.aylikGider.value = 0.0;
          await dash.getTransactions();
          await dash.loadCategories();
        } catch (_) {}
      }

      if (Get.isRegistered<CategoriesController>()) {
        try {
          await Get.find<CategoriesController>().loadCategories();
        } catch (_) {}
      }

      Get.snackbar(
        "Veriler Sıfırlandı",
        "Tüm gelir, gider ve bütçe verileriniz başarıyla sıfırlandı.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      return true;
    } catch (e) {
      debugPrint("[RESET] Veri sıfırlama hatası: $e");
      Get.snackbar(
        "Hata",
        "Veriler sıfırlanırken bir sorun oluştu: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isResetting.value = false;
    }
  }

  Future<void> cikisYap() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount({
    required String password,
    String? reason,
    String? note,
  }) async {
    isUpdating.value = true;
    try {
      await _authService.deleteAccount(
        password: password,
        reason: reason,
        note: note,
      );
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isUpdating.value = false;
    }
  }
}
