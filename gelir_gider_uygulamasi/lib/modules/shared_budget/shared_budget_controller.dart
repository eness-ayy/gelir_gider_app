import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/firestore_group_service.dart';
import 'package:get/get.dart';

/// Ortak Ev & Yurt Bütçesi Lobi Controller'ı
class SharedBudgetController extends BaseController {
  UserSessionController get userSession =>
      Get.isRegistered<UserSessionController>()
          ? Get.find<UserSessionController>()
          : Get.put(UserSessionController());

  FirestoreGroupService get firestoreService =>
      Get.isRegistered<FirestoreGroupService>()
          ? Get.find<FirestoreGroupService>()
          : Get.put(FirestoreGroupService());

  RxList<GroupModel> get userGroups => userSession.userGroups;
  bool get hasNickname => userSession.hasNickname;
  String get currentUserName => userSession.currentUserName.value;

  @override
  void onInit() {
    super.onInit();
    userSession.refreshGroups();
  }

  @override
  void onReady() {
    super.onReady();
    userSession.refreshGroups();
    _checkNicknameOnEntry();
  }

  void _checkNicknameOnEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!userSession.hasNickname) {
        showNicknameSheet(isDismissible: false);
      }
    });
  }

  // ===========================================================================
  // 1. KULLANICI ADI (RUMUZ) İŞLEMLERİ
  // ===========================================================================

  void showNicknameSheet({bool isDismissible = true}) {
    final textController = TextEditingController(text: currentUserName);
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFF0D9488),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserName.isEmpty
                                ? "Ev / Yurt Arkadaşın Seni Tanısın 🎉"
                                : "Rumuzunu Düzenle",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Ortak ev harcamalarında seni temsil edecek bir takma ad seç.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  maxLength: 25,
                  decoration: InputDecoration(
                    labelText: "Takma Adın / Rumuz",
                    hintText: "Örn: Ahmet, Enes, Ev Sahibi",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Lütfen bir takma ad girin.";
                    }
                    if (val.trim().length < 2) {
                      return "En az 2 karakter olmalıdır.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final name = textController.text.trim();
                      Get.back();
                      final success = await userSession.saveUserName(name);
                      if (success) {
                        showSuccessSnackbar(
                          message: "Profil adı '$name' olarak güncellendi.",
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Kaydet ve Devam Et",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: isDismissible,
      enableDrag: isDismissible,
    );
  }

  // ===========================================================================
  // 2. YENİ EV / YURT ODASI OLUŞTURMA
  // ===========================================================================

  void showCreateHouseSheet() {
    if (!hasNickname) {
      showErrorSnackbar(message: "Önce bir takma ad belirlemelisin.");
      showNicknameSheet();
      return;
    }

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cottage_rounded,
                        color: Color(0xFF0D9488),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Yeni Ev / Yurt Odası Kur",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Oda açılacak ve arkadaşların için 6 haneli davet kodu üretilecek.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 35,
                  decoration: InputDecoration(
                    labelText: "Ev / Oda / Daire Adı",
                    hintText: "Örn: Kadıköy Evi, 402 Nolu Yurt Odası",
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Lütfen bir oda veya ev adı girin.";
                    }
                    if (val.trim().length < 3) {
                      return "En az 3 karakter olmalıdır.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final groupName = nameController.text.trim();
                      Get.back();
                      await _createGroup(groupName);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Odayı Oluştur",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Future<void> _createGroup(String groupName) async {
    try {
      setLoading(true);
      final newGroup = await firestoreService.createGroup(
        name: groupName,
        members: [currentUserName],
      );

      userSession.addGroupLocally(newGroup);

      showSuccessSnackbar(
        title: "Ev / Oda Kuruldu! 🏡",
        message:
            "'${newGroup.name}' odası kuruldu. Davet Kodu: ${newGroup.inviteCode}",
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint("Grup oluşturma hatası: $e");
      showErrorSnackbar(message: "Oluşturulurken hata: $e");
    } finally {
      setLoading(false);
    }
  }

  // ===========================================================================
  // 3. KODA GÖRE KATILMA
  // ===========================================================================

  void showJoinHouseSheet() {
    if (!hasNickname) {
      showErrorSnackbar(message: "Önce bir takma ad belirlemelisin.");
      showNicknameSheet();
      return;
    }

    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: Color(0xFF2563EB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Odaya / Eve Katıl",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Ev arkadaşından aldığın 6 haneli davet kodunu gir.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: codeController,
                  autofocus: true,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    labelText: "6 Haneli Davet Kodu",
                    hintText: "ABC123",
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Lütfen davet kodunu girin.";
                    }
                    if (val.trim().length != 6) {
                      return "Davet kodu tam 6 haneli olmalıdır.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final code = codeController.text.trim().toUpperCase();
                      Get.back();
                      await _joinGroup(code);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Odaya Dahil Ol",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Future<void> _joinGroup(String inviteCode) async {
    try {
      setLoading(true);
      final group = await firestoreService.joinGroupByInviteCode(
        inviteCode: inviteCode,
        memberName: currentUserName,
      );

      userSession.addGroupLocally(group);

      showSuccessSnackbar(
        title: "Tebrikler! 🎉",
        message: "'${group.name}' ortak bütçesine başarıyla dahil oldunuz.",
      );
    } catch (e) {
      debugPrint("Gruba katılma hatası: $e");
      showErrorSnackbar(
        message: e
            .toString()
            .replaceAll("Exception: ", "")
            .replaceAll("StateError: ", ""),
      );
    } finally {
      setLoading(false);
    }
  }

  // ===========================================================================
  // 4. DİĞER AKSİYONLAR
  // ===========================================================================

  void copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showSuccessSnackbar(
      title: "Kopyalandı 📋",
      message: "Davet kodu ($code) panoya kopyalandı.",
      duration: const Duration(seconds: 2),
    );
  }

  void openGroupDetail(GroupModel group) {
    userSession.selectActiveGroup(group);
    Get.toNamed(AppRoutes.sharedBudgetDetail, arguments: group.id);
  }
}
