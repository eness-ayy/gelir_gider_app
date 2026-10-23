import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class ProfileController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  Rx<AppUser?> get user => _authService.currentUser;

  final isUpdating = false.obs;
  final isResetting = false.obs;

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
          await storage.remove("transaction_payment_methods");
        }
      } catch (e) {
        debugPrint("[RESET] Yerel önbellek temizlenirken hata: $e");
      }

      // 4. Bütçe ve Ödeme Yöntemi servislerini sıfırla
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
