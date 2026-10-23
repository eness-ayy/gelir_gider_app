import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

class ProfileController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  Rx<AppUser?> get user => _authService.currentUser;

  final isUpdating = false.obs;

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
