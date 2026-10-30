import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/debt_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
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
      User? fbUser;
      try {
        fbUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        fbUser = null;
      }
      final cachedJson = _storgeService.getValue<String>(StorageKeys.userData);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedUser = AppUser.fromJson(decoded);

        // Eğer Firebase'de oturum açmış kullanıcı varsa ve önbellekteki e-posta ile uyuşmuyorsa,
        // eski kullanıcının verisini ezip güncel Firebase kullanıcısına uyarla
        if (fbUser != null &&
            fbUser.email != null &&
            cachedUser.email != null &&
            cachedUser.email!.trim().toLowerCase() !=
                fbUser.email!.trim().toLowerCase()) {
          final displayName = fbUser.displayName?.trim() ?? '';
          final parts = displayName.split(' ');
          final fName = parts.first;
          final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

          final syncedUser = AppUser(
            id: fbUser.uid,
            email: fbUser.email,
            firstName: fName.isNotEmpty ? fName : fbUser.email!.split('@').first,
            lastName: lName,
          );
          saveLocalUser(syncedUser);
          return;
        }

        currentUser.value = cachedUser;
      } else if (fbUser != null) {
        // Önbellek boş ama Firebase oturumu aktif
        final displayName = fbUser.displayName?.trim() ?? '';
        final parts = displayName.split(' ');
        final fName = parts.first;
        final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final syncedUser = AppUser(
          id: fbUser.uid,
          email: fbUser.email,
          firstName: fName.isNotEmpty ? fName : (fbUser.email?.split('@').first ?? 'Kullanıcı'),
          lastName: lName,
        );
        saveLocalUser(syncedUser);
      }

      if (fbUser != null) {
        unawaited(syncUserFromFirestore());
      }
    } catch (e) {
      debugPrint("Kayıtlı kullanıcı yükleme hatası: $e");
    }
  }

  /// Firestore'daki güncel profil verisini (isim, soyisim, avatar) çekip yerel profil ile senkronize eder
  Future<void> syncUserFromFirestore() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final first = data['firstName'] as String?;
        final last = data['lastName'] as String?;
        final photo = data['profilePhoto'] as String?;
        final email = (data['email'] as String?) ?? fbUser.email;

        final current = currentUser.value;
        final updated = (current ?? AppUser(id: fbUser.uid, email: email)).copyWith(
          firstName: (first != null && first.isNotEmpty) ? first : current?.firstName,
          lastName: (last != null) ? last : current?.lastName,
          profilePhoto: photo,
          email: email,
        );

        await saveLocalUser(updated);

        final fullName = updated.fullName;
        if (Get.isRegistered<UserSessionController>() && fullName.isNotEmpty) {
          final session = Get.find<UserSessionController>();
          session.currentUserName.value = fullName;
          await session.persistUserName(fullName);
        }
      }
    } catch (e) {
      debugPrint("Firestore kullanıcı senkronizasyon hatası (ihmal edilebilir): $e");
    }
  }

  Future<void> saveLocalUser(AppUser user) async {
    currentUser.value = user;
    try {
      await _storgeService.setValue<String>(
        StorageKeys.userData,
        jsonEncode(user.toJson()),
      );
      _reloadUserScopedServices();
    } catch (e) {
      debugPrint("Kullanıcı kaydetme hatası: $e");
    }
  }

  void _reloadUserScopedServices() {
    try {
      if (Get.isRegistered<GroupService>()) {
        Get.find<GroupService>().loadGroups();
      }
      if (Get.isRegistered<SavingsService>()) {
        Get.find<SavingsService>().loadGoals();
      }
      if (Get.isRegistered<DebtService>()) {
        Get.find<DebtService>().loadDebts();
      }
      if (Get.isRegistered<RecurringService>()) {
        Get.find<RecurringService>().loadItems();
      }
      if (Get.isRegistered<CreditCardService>()) {
        Get.find<CreditCardService>().loadData();
      }
      if (Get.isRegistered<BudgetService>()) {
        Get.find<BudgetService>().loadBudgets();
      }
    } catch (_) {}
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      // Önceki olası oturum artıklarını temizle
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

  /// Tüm kullanıcı oturumunu, önbellekleri ve kontrolcü durumlarını sıfırlar.
  Future<void> clearUserSessionData({bool signOutFirebase = true}) async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      if (signOutFirebase) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }

      await _storgeService.remove(StorageKeys.userToken);
      await _storgeService.remove(StorageKeys.userData);
      await _storgeService.remove(StorageKeys.cachedTransactions);
      await _storgeService.remove(StorageKeys.cachedCategories);
      await _storgeService.remove(StorageKeys.groupNickname);

      currentUser.value = null;

      // Dashboard Controller'ı temizle
      if (Get.isRegistered<DashboardController>()) {
        try {
          final dash = Get.find<DashboardController>();
          dash.myTransaction.clear();
          dash.categories.clear();
          dash.aylikGelir.value = 0.0;
          dash.aylikGider.value = 0.0;
        } catch (_) {}
      }

      // UserSession Controller'ı temizle
      if (Get.isRegistered<UserSessionController>()) {
        try {
          final session = Get.find<UserSessionController>();
          session.firebaseUser.value = null;
          session.currentUserName.value = '';
          session.userGroups.clear();
          session.activeGroup.value = null;
        } catch (_) {}
      }

      // Account Service'i temizle
      if (Get.isRegistered<AccountService>()) {
        try {
          final acc = Get.find<AccountService>();
          acc.transactionPaymentMethods.clear();
        } catch (_) {}
      }

      _reloadUserScopedServices();
    } catch (e) {
      debugPrint("Oturum temizleme hatası: $e");
    }
  }

  Future<void> signOut() async {
    await clearUserSessionData(signOutFirebase: true);
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

    final fullName = updated.fullName.isNotEmpty
        ? updated.fullName
        : (updated.firstName ?? '').trim();

    // 2. Firebase Auth profilini (displayName ve photoURL) güncelle
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        if (fullName.isNotEmpty && fbUser.displayName != fullName) {
          await fbUser.updateDisplayName(fullName);
        }
        if (clearPhoto) {
          await fbUser.updatePhotoURL(null);
        } else if (profilePhoto != null && profilePhoto.isNotEmpty) {
          await fbUser.updatePhotoURL(profilePhoto);
        }
        await fbUser.reload();
      }
    } catch (e) {
      debugPrint("Firebase Auth profil güncelleme hatası: $e");
    }

    // 3. Firestore 'users' koleksiyonuna kalıcı olarak kaydet
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fbUser.uid)
            .set({
          'uid': fbUser.uid,
          'email': updated.email ?? fbUser.email,
          'firstName': updated.firstName,
          'lastName': updated.lastName,
          'fullName': fullName,
          'profilePhoto': clearPhoto ? null : (profilePhoto ?? updated.profilePhoto),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Firestore profil kaydetme hatası: $e");
    }

    // 4. UserSessionController ile senkronize et
    if (Get.isRegistered<UserSessionController>() && fullName.isNotEmpty) {
      try {
        final session = Get.find<UserSessionController>();
        session.currentUserName.value = fullName;
        await session.persistUserName(fullName);
        session.bindUserGroups(fullName);
      } catch (e) {
        debugPrint("UserSession profil senkronizasyon hatası: $e");
      }
    }

    // 5. Sunucuya senkronize etmeyi dene
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
      return currentUser.value;
    } catch (e) {
      debugPrint("Profil bilgisi sunucudan alınamadı: ${ApiServices.formatError(e)}");
      return currentUser.value;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && !fbUser.isAnonymous) {
        return true;
      }
      final token = _storgeService.getValue<String>(StorageKeys.userToken);
      if (token == null || token.isEmpty) {
        currentUser.value = null;
        return false;
      }
      if (currentUser.value != null) {
        // Arka planda sunucudan tazelemeyi dene
        getProfile().catchError((_) => currentUser.value);
        return true;
      }
      final response = await getProfile();
      if (response != null) {
        currentUser.value = response;
        return true;
      }
      return token.isNotEmpty;
    } catch (e) {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && !fbUser.isAnonymous) {
        return true;
      }
      final token = _storgeService.getValue<String>(StorageKeys.userToken);
      return token != null && token.isNotEmpty;
    }
  }

  /// Kullanıcı hesabını şifre doğrulaması yaparak, verilerini temizleyip kalıcı olarak siler
  Future<void> deleteAccount({
    required String password,
    String? reason,
    String? note,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Oturum açmış kullanıcı bulunamadı.");
    }

    final hasPasswordProvider =
        user.providerData.any((p) => p.providerId == 'password');

    // 1. E-posta & Şifre sağlayıcısı olan hesaplarda şifre ile kimlik doğrulama (Re-authentication)
    if (hasPasswordProvider) {
      final email = user.email ?? currentUser.value?.email;
      if (email == null || email.isEmpty) {
        throw Exception("Kullanıcı e-posta adresi bulunamadı.");
      }
      try {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw Exception("Girdiğiniz şifre hatalı. Lütfen kontrol ediniz.");
        } else if (e.code == 'user-mismatch') {
          throw Exception("Kullanıcı kimliği uyuşmuyor.");
        } else if (e.code == 'user-not-found') {
          throw Exception("Kullanıcı kaydı bulunamadı.");
        } else if (e.code == 'too-many-requests') {
          throw Exception("Çok fazla başarısız deneme yapıldı. Lütfen biraz bekleyin.");
        }
        throw Exception(e.message ?? "Kimlik doğrulama başarısız oldu.");
      }
    }

    final uid = user.uid;

    // 2. Silme gerekçesini logla
    try {
      await FirebaseFirestore.instance.collection('account_deletion_feedbacks').add({
        'reason': reason ?? 'Belirtilmedi',
        'note': note ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Silme geri bildirimi kaydedilemedi: $e");
    }

    // 3. Firestore'daki kullanıcı verilerini temizle
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      // İşlemleri (transactions) sil
      final transDocs = await userDoc.collection('transactions').get();
      for (final doc in transDocs.docs) {
        await doc.reference.delete();
      }

      // Kategorileri sil
      final catDocs = await userDoc.collection('categories').get();
      for (final doc in catDocs.docs) {
        await doc.reference.delete();
      }

      // Extra modül verilerini (kredi kartları, borçlar, kumbara, sabit ödemeler) sil
      final extraDocs = await userDoc.collection('extra_modules').get();
      for (final doc in extraDocs.docs) {
        await doc.reference.delete();
      }

      // Ana kullanıcı profil dokümanını sil
      await userDoc.delete();
    } catch (e) {
      debugPrint("Firestore kullanıcı verileri temizlenirken hata: $e");
    }

    // 4. Firebase Authentication kullanıcısını sil
    await user.delete();

    // 5. Oturum ve yerel önbellekleri temizle
    await clearUserSessionData(signOutFirebase: false);
  }
}
