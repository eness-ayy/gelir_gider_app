import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
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

      // 2. Firebase Anonim Giriş kontrolü
      User? user = _auth.currentUser;
      if (user == null) {
        user = await signInAnonymously();
      } else {
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
    } catch (e) {
      debugPrint("Oturum başlatılırken hata oluştu: $e");
    } finally {
      isInitializing.value = false;
    }
  }

  /// Yerel hafızadan takma adı yükler
  void _loadCachedUserName() {
    try {
      final savedName =
          _storageService.getValue<String>(StorageKeys.groupNickname);
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

      // Eğer kullanıcı adı önceden belirlenmişse displayName alanına uygula
      if (user != null && currentUserName.value.isNotEmpty) {
        await _syncDisplayNameWithFirebase(currentUserName.value);
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

      // 4. Bu isimle dahil olunan grupların canlı dinlemesini başlat
      _bindUserGroups(cleanName);

      return true;
    } catch (e) {
      debugPrint("Kullanıcı adı kaydedilirken hata: $e");
      showErrorSnackbar(message: "Kullanıcı adı güncellenirken bir hata oluştu.");
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
        .getGroupsForMember(memberName)
        .listen((groups) {
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
        activeGroup.value = foundGroup ?? (groups.isNotEmpty ? groups.first : null);
      }
    }, onError: (error) {
      debugPrint("Kullanıcı grupları dinlenirken hata oluştu: $error");
    });
  }

  /// Kullanıcının dahil olduğu grupları doğrudan çekerek listeyi tazeler
  Future<void> refreshGroups() async {
    final name = currentUserName.value.trim();
    if (name.isEmpty) return;

    try {
      final fetched = await _firestoreGroupService.fetchGroupsForMember(name);
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

  /// Oturumu kapatır (gerekirse)
  Future<void> signOut() async {
    try {
      _groupsSubscription?.cancel();
      await _auth.signOut();
      firebaseUser.value = null;
      userGroups.clear();
      activeGroup.value = null;
    } catch (e) {
      debugPrint("Oturum kapatılırken hata: $e");
    }
  }
}

/// İsimlendirme esnekliği ve kolay erişim için takma ad (alias)
typedef AuthController = UserSessionController;
