import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends GetxController {
  late final StorgeService _storgeService;
  late final ApiServices _apiServices;
  late final GoogleSignIn _googleSignIn;

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);

  Future<AuthService> init() async {
    _storgeService = Get.find<StorgeService>();
    _apiServices = Get.find<ApiServices>();
    _googleSignIn = GoogleSignIn(
      serverClientId: ApiConstants.serverClient,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
    loadCachedUser();
    return this;
  }

  void loadCachedUser() {
    try {
      final cachedJson = _storgeService.getValue<String>(StorageKeys.userData);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        currentUser.value = AppUser.fromJson(decoded);
      }
    } catch (e) {
      debugPrint("Kayıtlı kullanıcı yükleme hatası: $e");
    }
  }

  Future<void> saveLocalUser(AppUser user) async {
    currentUser.value = user;
    try {
      await _storgeService.setValue<String>(
        StorageKeys.userData,
        jsonEncode(user.toJson()),
      );
    } catch (e) {
      debugPrint("Kullanıcı kaydetme hatası: $e");
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuthentication = await googleUser.authentication;

      final response = await _apiServices.post(
        ApiConstants.login,
        data: {'idToken': googleAuthentication.idToken},
      );

      if (response.statusCode == 200) {
        await _storgeService.setValue<String>(
          StorageKeys.userToken,
          response.data['token'],
        );

        final user = AppUser.fromJson(response.data['user']);
        // Kullanıcı giriş yaptığında ilk önce eskisi gibi sadece isminin baş harfi olsun
        final userWithInitialOnly = user.copyWith(clearPhoto: true);
        await saveLocalUser(userWithInitialOnly);
        return userWithInitialOnly;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Google sign in hatası: $e");
      currentUser.value = null;
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storgeService.remove(StorageKeys.userToken);
      await _storgeService.remove(StorageKeys.userData);
      currentUser.value = null;
    } catch (e) {
      debugPrint("Çıkış yapılırken hata oluştu: $e");
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? profilePhoto,
    bool clearPhoto = false,
  }) async {
    final current = currentUser.value ?? AppUser();
    final updated = current.copyWith(
      firstName: firstName ?? current.firstName,
      lastName: lastName ?? current.lastName,
      email: email ?? current.email,
      profilePhoto: profilePhoto,
      clearPhoto: clearPhoto,
    );

    // 1. Önce yerel veriyi ve UI durumunu anında güncelle
    await saveLocalUser(updated);

    // 2. Ardından sunucuya senkronize etmeyi dene
    try {
      final response = await _apiServices.put(
        ApiConstants.profile,
        data: {
          'first_name': updated.firstName,
          'last_name': updated.lastName,
          'email': updated.email,
          'profile_photo': updated.profilePhoto,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final serverUser = AppUser.fromJson(
          data is Map<String, dynamic>
              ? (data['user'] is Map<String, dynamic>
                  ? data['user']
                  : data)
              : updated.toJson(),
        );
        await saveLocalUser(serverUser);
      }
    } catch (e) {
      debugPrint("Sunucu profil güncelleme hatası (yerel değişiklikler korundu): $e");
    }

    return true;
  }

  Future<AppUser?> getProfile() async {
    try {
      final response = await _apiServices.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final user = AppUser.fromJson(response.data);
        await saveLocalUser(user);
        return currentUser.value;
      }
      return null;
    } catch (e) {
      debugPrint("get profile error: $e");
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = _storgeService.getValue<String>(StorageKeys.userToken);
      if (token == null) {
        currentUser.value = null;
        return false;
      }
      final response = await getProfile();
      if (response != null) {
        currentUser.value = response;
        return true;
      }
      return false;
    } catch (e) {
      await _storgeService.remove(StorageKeys.userToken);
      currentUser.value = null;
      return false;
    }
  }
}
