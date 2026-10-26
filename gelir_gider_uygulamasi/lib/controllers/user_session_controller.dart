import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/services/firestore_group_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

/// Kullanıcı oturumu, Firebase anonim kimlik doğrulama ve yerel profil yönetim controller'ı.
class UserSessionController extends BaseController {
  final FirebaseAuth _auth;
  late final StorgeService _storageService;
  late final FirestoreGroupService _firestoreGroupService;

  UserSessionController({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Reaktif Durum Değişkenleri (State)
  // ---------------------------------------------------------------------------

  /// Firebase Auth mevcut kullanıcı nesnesi
  final Rx<User?> firebaseUser = Rx<User?>(null);

  /// Kullanıcının belirlediği takma ad / rumuz (displayName)
  final RxString currentUserName = ''.obs;

  /// Kullanıcının anonim oturumla giriş yapıp yapmadığı
  final RxBool isAnonymous = false.obs;

  /// Arka planda anonim giriş işlemi sürerken true olur
  final RxBool isInitializing = true.obs;

  /// Kullanıcının dahil olduğu tüm grupların listesi (Firestore canlı)
  final RxList<GroupModel> userGroups = <GroupModel>[].obs;

  /// Kullanıcının şu an seçili/aktif grubu
  final Rx<GroupModel?> activeGroup = Rx<GroupModel?>(null);

  // Dinleyiciler ve abonelikler
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<GroupModel>>? _groupsSubscription;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Oturumun açık olup olmadığı
  bool get isLoggedIn => firebaseUser.value != null;

  /// Kullanıcının yerel olarak veya profilinde bir takma adı olup olmadığı
  bool get hasNickname => currentUserName.value.trim().isNotEmpty;

  /// Kullanıcının Firebase UID değeri
  String get uid => firebaseUser.value?.uid ?? '';

  /// Kullanıcının üye olduğu grup sayısı
  int get groupCount => userGroups.length;

  // ---------------------------------------------------------------------------
  // Yaşam Döngüsü (Lifecycle)
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.isRegistered<StorgeService>()
        ? Get.find<StorgeService>()
        : Get.put(StorgeService());

    _firestoreGroupService = Get.isRegistered<FirestoreGroupService>()
        ? Get.find<FirestoreGroupService>()
        : Get.put(FirestoreGroupService());

    _setupAuthListener();
    initSession();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _groupsSubscription?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // 1. OTURUM BAŞLATMA VE YEREL HAFIZA (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// Uygulama ilk açıldığında veya controller başladığında çalışır:
  /// - SharedPreferences'tan kayıtlı rumuzu yükler
  /// - Firebase anonim oturumunu kontrol eder / açar
  /// - Canlı grup dinlemesini başlatır
  Future<void> initSession() async {
    isInitializing.value = true;
    try {
      // 1. Yerel hafızadan (SharedPreferences) takma adı oku
      _loadCachedUserName();

      // Takma ad varsa hemen grupları dinlemeye ve çekmeye başla (Auth'a bağımlı kalmadan!)
      if (currentUserName.value.isNotEmpty) {
        _bindUserGroups(currentUserName.value);
        refreshGroups();
      }

      // 2. Firebase Oturum kontrolü
      User? user = _auth.currentUser;
      if (user != null) {
        firebaseUser.value = user;
        isAnonymous.value = user.isAnonymous;

        // Firebase displayName varsa ve yerel ad boşsa yereli doldur
        if (currentUserName.value.isEmpty &&
            user.displayName != null &&
            user.displayName!.trim().isNotEmpty) {
          currentUserName.value = user.displayName!.trim();
          await _persistUserName(currentUserName.value);
          _bindUserGroups(currentUserName.value);
          refreshGroups();
        }
      }

      // 3. Eğer yerelde bir ad varsa ve Firebase oturumu açıksa profil adını senkronize et
      if (currentUserName.value.isNotEmpty && user != null) {
        await _syncDisplayNameWithFirebase(currentUserName.value);
      }

      // 4. Kullanıcının varsayılan kategorilerini sessizce kontrol et / başlat
      if (user != null) {
        unawaited(
          CategoryService()
              .initializeDefaultCategories(user.uid)
              .catchError((_) {}),
        );
      }
    } catch (e) {
      debugPrint("Oturum başlatılırken hata oluştu: $e");
    } finally {
      isInitializing.value = false;
    }
  }

  /// Yerel hafızadan takma adı yükler
  void _loadCachedUserName() {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null &&
          fbUser.displayName != null &&
          fbUser.displayName!.trim().isNotEmpty) {
        currentUserName.value = fbUser.displayName!.trim();
        return;
      }

      final savedName = _storageService.getValue<String>(
        StorageKeys.groupNickname,
      );
      if (savedName != null && savedName.trim().isNotEmpty) {
        currentUserName.value = savedName.trim();
        return;
      }

      // Yedek senaryo: Eğer Google Auth ile giriş yapılmış kullanıcı varsa onun adını al
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        final appUser = authService.currentUser.value;
        if (appUser != null &&
            appUser.first_name != null &&
            appUser.first_name!.trim().isNotEmpty) {
          currentUserName.value = appUser.first_name!.trim();
        }
      }
    } catch (e) {
      debugPrint("Kayıtlı takma ad okunurken hata: $e");
    }
  }

  /// Takma adı yerel hafızaya (SharedPreferences) yazar
  Future<bool> _persistUserName(String name) async {
    try {
      return await _storageService.setValue<String>(
        StorageKeys.groupNickname,
        name.trim(),
      );
    } catch (e) {
      debugPrint("Takma ad kaydedilirken hata: $e");
      return false;
    }
  }

  /// Dış servislerin (örn. AuthService) kullanıcı adını senkronize edebilmesi için
  Future<bool> persistUserName(String name) async {
    return _persistUserName(name);
  }

  /// Grup dinleyicisini dışarıdan tetiklemek için
  void bindUserGroups(String memberName) {
    _bindUserGroups(memberName);
  }

  // ---------------------------------------------------------------------------
  // 2. FIREBASE ANONİM GİRİŞ (Anonymous Auth)
  // ---------------------------------------------------------------------------

  /// Firebase Auth dinleyicisi
  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      firebaseUser.value = user;
      isAnonymous.value = user?.isAnonymous ?? false;
      if (user != null && currentUserName.value.isNotEmpty) {
        _bindUserGroups(currentUserName.value);
      }
    });
  }

  /// Karmaşık e-posta/şifre istemeden, arka planda anonim oturum açar.
  Future<User?> signInAnonymously() async {
    try {
      setLoading(true);
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      firebaseUser.value = user;
      isAnonymous.value = user?.isAnonymous ?? true;

      if (user != null) {
        await _storageService.remove(StorageKeys.cachedTransactions);
        await _storageService.remove(StorageKeys.cachedCategories);
        await CategoryService().initializeDefaultCategories(user.uid);

        // Eğer kullanıcı adı önceden belirlenmişse displayName alanına uygula
        if (currentUserName.value.isNotEmpty) {
          await _syncDisplayNameWithFirebase(currentUserName.value);
        }
      }

      return user;
    } catch (e) {
      debugPrint("Anonim giriş yapılırken hata: $e");
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Firebase Auth profilindeki displayName alanını günceller
  Future<void> _syncDisplayNameWithFirebase(String name) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.displayName != name) {
        await user.updateDisplayName(name);
        await user.reload();
        firebaseUser.value = _auth.currentUser;
      }
    } catch (e) {
      debugPrint("Firebase profil adı senkronize edilirken hata: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 3. KULLANICI ADI KAYDETME VE PROFİL GÜNCELLEME
  // ---------------------------------------------------------------------------

  /// Kullanıcının takma adını (rumuzunu) belirler veya günceller:
  /// - SharedPreferences'a kaydeder
  /// - Firebase Auth displayName alanını günceller
  /// - Firestore 'users' koleksiyonunda günceller
  /// - AuthService ile yerel profili eşitler
  /// - Grubu/grupları bu isim üzerinden canlı dinlemeye bağlar
  Future<bool> saveUserName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      showErrorSnackbar(message: "Lütfen geçerli bir isim veya rumuz giriniz.");
      return false;
    }

    try {
      setLoading(true);

      // 1. Yerel hafızaya kaydet
      await _persistUserName(cleanName);
      currentUserName.value = cleanName;

      // 2. Firebase oturumu yoksa anonim oturum aç
      if (firebaseUser.value == null) {
        await signInAnonymously();
      }

      // 3. Firebase Auth displayName alanını güncelle
      await _syncDisplayNameWithFirebase(cleanName);

      // 4. Firestore users koleksiyonuna kalıcı olarak yaz
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final parts = cleanName.split(' ');
          final fName = parts.first;
          final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'firstName': fName,
                'lastName': lName,
                'fullName': cleanName,
                'email': user.email,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("saveUserName Firestore yazma hatası: $e");
        }
      }

      // 5. AuthService ile senkronize et
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        final parts = cleanName.split(' ');
        final fName = parts.first;
        final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        final current = authService.currentUser.value;
        final updated = (current ?? AppUser(id: user?.uid, email: user?.email))
            .copyWith(firstName: fName, lastName: lName);
        await authService.saveLocalUser(updated);
      }

      // 6. Bu isimle dahil olunan grupların canlı dinlemesini başlat
      _bindUserGroups(cleanName);

      return true;
    } catch (e) {
      debugPrint("Kullanıcı adı kaydedilirken hata: $e");
      showErrorSnackbar(
        message: "Kullanıcı adı güncellenirken bir hata oluştu.",
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. GRUP DURUM YÖNETİMİ
  // ---------------------------------------------------------------------------

  /// Kullanıcının dahil olduğu grupları Firestore üzerinden canlı olarak dinler
  void _bindUserGroups(String memberName) {
    _groupsSubscription?.cancel();

    if (memberName.trim().isEmpty) {
      userGroups.clear();
      activeGroup.value = null;
      return;
    }

    _groupsSubscription = _firestoreGroupService
        .getGroupsForMember(memberName, userUid: _auth.currentUser?.uid)
        .listen(
          (groups) {
            userGroups.assignAll(groups);

            // Aktif grup seçimi: Eğer aktif grup boşsa ve liste doluysa ilk grubu seç
            if (activeGroup.value == null && groups.isNotEmpty) {
              activeGroup.value = groups.first;
            } else if (activeGroup.value != null) {
              // Mevcut aktif grup güncellenmiş mi kontrol et
              GroupModel? foundGroup;
              for (final g in groups) {
                if (g.id == activeGroup.value!.id) {
                  foundGroup = g;
                  break;
                }
              }
              activeGroup.value =
                  foundGroup ?? (groups.isNotEmpty ? groups.first : null);
            }
          },
          onError: (error) {
            debugPrint("Kullanıcı grupları dinlenirken hata oluştu: $error");
          },
        );
  }

  /// Kullanıcının dahil olduğu grupları doğrudan çekerek listeyi tazeler
  Future<void> refreshGroups() async {
    final name = currentUserName.value.trim();
    final uid = _auth.currentUser?.uid;
    if (name.isEmpty && (uid == null || uid.isEmpty)) return;

    try {
      final fetched = await _firestoreGroupService.fetchGroupsForMember(name, userUid: uid);
      if (fetched.isNotEmpty) {
        userGroups.assignAll(fetched);
        if (activeGroup.value == null) {
          activeGroup.value = fetched.first;
        }
      }
    } catch (e) {
      debugPrint("refreshGroups hatası: $e");
    }
  }

  /// Grubu anında yerel listeye ekler (Optimistic UI update)
  void addGroupLocally(GroupModel newGroup) {
    if (!userGroups.any((g) => g.id == newGroup.id)) {
      userGroups.insert(0, newGroup);
    }
    selectActiveGroup(newGroup);
  }

  /// Aktif seçili grubu değiştirir
  void selectActiveGroup(GroupModel group) {
    activeGroup.value = group;
  }

  // ---------------------------------------------------------------------------
  // 5. FIREBASE E-POSTA & ŞİFRE KİMLİK DOĞRULAMA (Email & Password Auth)
  // ---------------------------------------------------------------------------

  /// Kayıt Ol: createUserWithEmailAndPassword ile hesap açar, displayName günceller
  /// ve SharedPreferences ile currentUserName'e yazar.
  Future<User?> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();

    try {
      setLoading(true);
      final userCredential = await _auth
          .createUserWithEmailAndPassword(email: cleanEmail, password: password)
          .timeout(const Duration(seconds: 30));

      final user = userCredential.user;
      if (user != null) {
        // Önceki kullanıcının olası oturum/token/işlem artıklarını temizle
        await _storageService.remove(StorageKeys.userToken);
        await _storageService.remove(StorageKeys.cachedTransactions);
        await _storageService.remove(StorageKeys.cachedCategories);

        if (Get.isRegistered<DashboardController>()) {
          try {
            final dash = Get.find<DashboardController>();
            dash.myTransaction.clear();
            dash.categories.clear();
            dash.aylikGelir.value = 0.0;
            dash.aylikGider.value = 0.0;
          } catch (_) {}
        }

        // 1. Firebase Auth displayName güncelle
        try {
          await user.updateDisplayName(cleanName);
          await user.reload();
        } catch (e) {
          debugPrint("displayName güncelleme hatası (ihmal edilebilir): $e");
        }
        final refreshedUser = _auth.currentUser;
        firebaseUser.value = refreshedUser;
        isAnonymous.value = false;

        // 2. Takma adı ve profil bilgisini yerel state ve SharedPreferences'a yaz
        currentUserName.value = cleanName;
        await _persistUserName(cleanName);

        final parts = cleanName.split(' ');
        final fName = parts.first;
        final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        // 3. Firestore 'users' koleksiyonuna kalıcı olarak kaydet
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'firstName': fName,
                'lastName': lName,
                'fullName': cleanName,
                'email': user.email ?? cleanEmail,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Kayıtta Firestore profil yazma hatası: $e");
        }

        // 3.1. Varsayılan kategorileri WriteBatch ile hemen oluştur
        try {
          await CategoryService().initializeDefaultCategories(user.uid);
        } catch (e) {
          debugPrint("Kayıtta varsayılan kategorileri oluşturma hatası: $e");
        }

        // 4. AuthService ile senkronize et (Profil sayfası ve cüzdan için)
        if (Get.isRegistered<AuthService>()) {
          final authService = Get.find<AuthService>();
          final appUser = AppUser(
            id: user.uid,
            email: user.email ?? cleanEmail,
            firstName: fName,
            lastName: lName,
          );
          await authService.saveLocalUser(appUser);
        }

        // 5. Grupları dinlemeye başla ve arka planda tazele
        _bindUserGroups(cleanName);
        unawaited(
          refreshGroups().catchError((e) {
            debugPrint("Arka plan grup yenileme hatası: $e");
            return null;
          }),
        );

        // 6. Cüzdan / Dashboard verilerini bu yeni kullanıcı için tazele
        if (Get.isRegistered<DashboardController>()) {
          unawaited(
            Get.find<DashboardController>().refreshDashboard().catchError(
              (_) {},
            ),
          );
        }
      }
      return user;
    } finally {
      setLoading(false);
    }
  }

  /// Giriş Yap: signInWithEmailAndPassword ile oturum açar, Firestore'daki güncel adı çeker ve ayarlar.
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    try {
      setLoading(true);
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: cleanEmail, password: password)
          .timeout(const Duration(seconds: 30));

      final user = userCredential.user;
      if (user != null) {
        // Önceki kullanıcıdan kalan backend token'ı ve eski önbellekleri kaldır
        await _storageService.remove(StorageKeys.userToken);
        await _storageService.remove(StorageKeys.cachedTransactions);
        await _storageService.remove(StorageKeys.cachedCategories);

        if (Get.isRegistered<DashboardController>()) {
          try {
            final dash = Get.find<DashboardController>();
            dash.myTransaction.clear();
            dash.categories.clear();
            dash.aylikGelir.value = 0.0;
            dash.aylikGider.value = 0.0;
          } catch (_) {}
        }

        firebaseUser.value = user;
        isAnonymous.value = false;

        // 1. Firestore'dan güncel kullanıcı profilini çek (isim güncellenmişse kesinlikle Firestore'da vardır)
        String? firestoreFirst;
        String? firestoreLast;
        String? firestorePhoto;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            firestoreFirst = data['firstName'] as String?;
            firestoreLast = data['lastName'] as String?;
            firestorePhoto = data['profilePhoto'] as String?;
          }
        } catch (e) {
          debugPrint("Firestore profil getirme hatası (ihmal edilebilir): $e");
        }

        final firestoreFullName =
            "${firestoreFirst ?? ''} ${firestoreLast ?? ''}".trim();
        final authDisplayName = user.displayName?.trim() ?? '';

        final resolvedFullName = firestoreFullName.isNotEmpty
            ? firestoreFullName
            : (authDisplayName.isNotEmpty
                  ? authDisplayName
                  : cleanEmail.split('@').first);

        currentUserName.value = resolvedFullName;
        await _persistUserName(resolvedFullName);

        // Firebase Auth displayName güncel değilse arka planda eşitle
        if (user.displayName != resolvedFullName &&
            resolvedFullName.isNotEmpty) {
          try {
            await user.updateDisplayName(resolvedFullName);
            await user.reload();
          } catch (_) {}
        }

        // AuthService ile kullanıcıyı senkronize et
        if (Get.isRegistered<AuthService>()) {
          final authService = Get.find<AuthService>();
          final parts = resolvedFullName.split(' ');
          final fName = (firestoreFirst != null && firestoreFirst.isNotEmpty)
              ? firestoreFirst
              : parts.first;
          final lName = (firestoreLast != null)
              ? firestoreLast
              : (parts.length > 1 ? parts.sublist(1).join(' ') : '');
          final appUser = AppUser(
            id: user.uid,
            email: user.email ?? cleanEmail,
            firstName: fName,
            lastName: lName,
            profilePhoto: firestorePhoto,
          );
          await authService.saveLocalUser(appUser);
        }

        _bindUserGroups(resolvedFullName);
        unawaited(
          refreshGroups().catchError((e) {
            debugPrint("Arka plan grup yenileme hatası: $e");
            return null;
          }),
        );

        // Kullanıcının varsayılan kategorilerini sessizce kontrol et / başlat
        unawaited(
          CategoryService()
              .initializeDefaultCategories(user.uid)
              .catchError((_) {}),
        );

        // Cüzdan / Dashboard verilerini bu kullanıcı için tazele
        if (Get.isRegistered<DashboardController>()) {
          unawaited(
            Get.find<DashboardController>().refreshDashboard().catchError(
              (_) {},
            ),
          );
        }
      }
      return user;
    } finally {
      setLoading(false);
    }
  }

  /// Şifre Sıfırlama: E-posta adresine şifre sıfırlama linki gönderir.
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    try {
      setLoading(true);
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } finally {
      setLoading(false);
    }
  }

  /// Google ile Giriş: AuthService üzerinden Google ile oturum açar ve UserSession'a bağlar.
  Future<bool> loginWithGoogle() async {
    try {
      setLoading(true);
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        final appUser = await authService.signInWithGoogle();
        if (appUser != null) {
          if (Get.isRegistered<DashboardController>()) {
            try {
              final dash = Get.find<DashboardController>();
              dash.myTransaction.clear();
              dash.categories.clear();
              dash.aylikGelir.value = 0.0;
              dash.aylikGider.value = 0.0;
            } catch (_) {}
          }

          // Firestore'dan özelleştirilmiş kullanıcı profili var mı kontrol et
          String? firestoreFirst;
          String? firestoreLast;
          String? firestorePhoto;
          final currentUid = _auth.currentUser?.uid ?? appUser.id;
          if (currentUid != null && currentUid.isNotEmpty) {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .get()
                  .timeout(const Duration(seconds: 4));
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                firestoreFirst = data['firstName'] as String?;
                firestoreLast = data['lastName'] as String?;
                firestorePhoto = data['profilePhoto'] as String?;
              }
            } catch (_) {}
          }

          final firestoreFullName =
              "${firestoreFirst ?? ''} ${firestoreLast ?? ''}".trim();
          final defaultName = appUser.fullName.trim().isNotEmpty
              ? appUser.fullName.trim()
              : (appUser.first_name?.trim() ?? 'Kullanıcı');

          final displayName = firestoreFullName.isNotEmpty
              ? firestoreFullName
              : defaultName;

          currentUserName.value = displayName;
          await _persistUserName(displayName);

          // AuthService profilini güncelle
          if (firestoreFirst != null ||
              firestoreLast != null ||
              firestorePhoto != null) {
            final updatedAppUser = appUser.copyWith(
              firstName: firestoreFirst ?? appUser.firstName,
              lastName: firestoreLast ?? appUser.lastName,
              profilePhoto: firestorePhoto ?? appUser.profilePhoto,
            );
            await authService.saveLocalUser(updatedAppUser);
          }

          _bindUserGroups(displayName);
          unawaited(refreshGroups().catchError((_) => null));

          if (_auth.currentUser != null) {
            await _syncDisplayNameWithFirebase(displayName);
          }

          if (currentUid != null && currentUid.isNotEmpty) {
            unawaited(
              CategoryService()
                  .initializeDefaultCategories(currentUid)
                  .catchError((_) {}),
            );
          }

          if (Get.isRegistered<DashboardController>()) {
            unawaited(
              Get.find<DashboardController>().refreshDashboard().catchError(
                (_) {},
              ),
            );
          }

          return true;
        }
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Oturumu kapatır (gerekirse)
  Future<void> signOut() async {
    try {
      _groupsSubscription?.cancel();
      userGroups.clear();
      activeGroup.value = null;
      currentUserName.value = '';
      firebaseUser.value = null;

      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().clearUserSessionData();
      } else {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint("Oturum kapatılırken hata: $e");
    }
  }
}
