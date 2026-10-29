import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/firestore_group_service.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Oda & Bütçe Paylaşım ve Derin Bağlantı (Deep Link) Servisi.
/// Arkadaş davet linklerini üretir, paylaşır ve gelen linkleri yakalayıp odaya yönlendirir.
class InviteLinkService extends GetxService {
  static const String applicationId = 'com.hesaply.app';
  static const String webJoinUrl = 'https://gelir-gider-app-9ae8f.web.app/join';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$applicationId';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  // Kullanıcı henüz giriş yapmadıysa linkten gelen kodu hafızada saklar
  String? pendingInviteCode;

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  @override
  void onClose() {
    _linkSub?.cancel();
    super.onClose();
  }

  // ===========================================================================
  // 1. LİNK ÜRETİMİ VE PAYLAŞIM
  // ===========================================================================

  /// Web üzerinden yönlendiren evrensel davet linki
  String buildWebInviteLink(String inviteCode, [String? groupName]) {
    final cleanCode = inviteCode.trim().toUpperCase();
    final uri = Uri.parse(webJoinUrl).replace(
      queryParameters: {
        'code': cleanCode,
        if (groupName != null && groupName.isNotEmpty) 'name': groupName,
      },
    );
    return uri.toString();
  }

  /// Doğrudan uygulamayı açan özel şema linki (Örn: hesaply://join?code=XYZ890)
  String buildCustomSchemeLink(String inviteCode) {
    return 'hesaply://join?code=${inviteCode.trim().toUpperCase()}';
  }

  /// WhatsApp, SMS vb. için hazır davet mesajı
  String buildShareMessage({
    required String groupName,
    required String inviteCode,
    String? inviterName,
  }) {
    final link = buildWebInviteLink(inviteCode, groupName);
    final sender = (inviterName != null && inviterName.trim().isNotEmpty)
        ? inviterName.trim()
        : "Arkadaşın";

    return '👋 $sender seni Hesaply uygulamasında "$groupName" ortak bütçe odasına davet etti!\n\n'
        '🔗 Tek tıkla odaya katılmak için:\n'
        '$link\n\n'
        '📲 Uygulama yüklüyse doğrudan odaya katılırsın. '
        'Yüklü değilse link seni Google Play indirme sayfasına yönlendirir.\n\n'
        '(Manuel giriş için Davet Kodu: $inviteCode)';
  }

  /// Odayı arkadaşlarıyla paylaşma diyaloğunu / sayfasını açar
  Future<void> shareGroup(GroupModel group) async {
    String? currentUserName;
    if (Get.isRegistered<AuthService>()) {
      currentUserName = Get.find<AuthService>().currentUser.value?.first_name;
    }
    if ((currentUserName == null || currentUserName.isEmpty) &&
        Get.isRegistered<UserSessionController>()) {
      currentUserName = Get.find<UserSessionController>().currentUserName.value;
    }

    final message = buildShareMessage(
      groupName: group.name,
      inviteCode: group.inviteCode,
      inviterName: currentUserName,
    );

    try {
      await Share.share(
        message,
        subject: 'Hesaply Odasına Davet: ${group.name}',
      );
    } catch (e) {
      debugPrint("Paylaşım hatası: $e");
    }
  }

  // ===========================================================================
  // 2. GELEN DERİN BAĞLANTILARI (DEEP LINK) DİNLEME
  // ===========================================================================

  Future<void> _initDeepLinks() async {
    try {
      // 1. Soğuk açılış (Cold start): Uygulama kapalıyken linke tıklanırsa
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint("İlk link okuma hatası: $e");
    }

    // 2. Sıcak açılış (Warm/Foreground): Uygulama açıkken veya arka plandayken
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleIncomingUri(uri);
      },
      onError: (err) {
        debugPrint("Link dinleme akış hatası: $err");
      },
    );
  }

  void _handleIncomingUri(Uri uri) {
    debugPrint("Gelen Deep Link yakalandı: $uri");

    // hesaply://join?code=... VEYA https://.../join?code=...
    final isCustomScheme = uri.scheme == 'hesaply' && uri.host == 'join';
    final isWebPath = uri.path.contains('/join');

    if (isCustomScheme || isWebPath) {
      final code = uri.queryParameters['code']?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        handleInviteCodeFromLink(code);
      }
    }
  }

  /// Linkten gelen davet kodunu işler
  void handleInviteCodeFromLink(String inviteCode) {
    final cleanCode = inviteCode.trim().toUpperCase();

    // Kullanıcının oturumu var mı kontrol et
    final isAuth = Get.isRegistered<AuthService>() &&
        Get.find<AuthService>().currentUser.value != null;

    if (!isAuth) {
      // Oturum yoksa kodu sakla, kullanıcı giriş yapınca tetikleriz
      pendingInviteCode = cleanCode;
      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          "Davet Kodu Algılandı 📩",
          "Odaya katılmak için lütfen önce giriş yapın.",
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    // Kullanıcı oturum açmışsa odaya katılma onay modalı göster
    showJoinConfirmationDialog(cleanCode);
  }

  /// Kullanıcı oturum açtıktan sonra bekleyen bir davet linki varsa tetiklenir
  void checkPendingInviteAfterLogin() {
    if (pendingInviteCode != null && pendingInviteCode!.isNotEmpty) {
      final code = pendingInviteCode!;
      pendingInviteCode = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        showJoinConfirmationDialog(code);
      });
    }
  }

  /// Kullanıcıya "Bu odaya katılmak istiyor musunuz?" diyalogu sunar
  void showJoinConfirmationDialog(String inviteCode) {
    if (Get.context == null) return;

    final userSession = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController());

    final firestoreService = Get.isRegistered<FirestoreGroupService>()
        ? Get.find<FirestoreGroupService>()
        : Get.put(FirestoreGroupService());

    // Zaten bu odada var mı kontrol et
    final alreadyInGroup = userSession.userGroups.any(
      (g) => g.inviteCode.toUpperCase() == inviteCode.toUpperCase(),
    );

    if (alreadyInGroup) {
      final existingGroup = userSession.userGroups.firstWhere(
        (g) => g.inviteCode.toUpperCase() == inviteCode.toUpperCase(),
      );
      Get.snackbar(
        "Zaten Bu Odadasınız 🏡",
        "'${existingGroup.name}' odasına daha önce katılmışsınız.",
        snackPosition: SnackPosition.TOP,
      );
      userSession.selectActiveGroup(existingGroup);
      Get.toNamed(AppRoutes.sharedBudgetDetail, arguments: existingGroup.id);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.cottage_rounded, color: Color(0xFF0D9488), size: 28),
            SizedBox(width: 10),
            Text(
              "Odaya Katıl",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bir davet bağlantısı üzerinden odaya çağrıldınız.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Davet Kodu:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    inviteCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Bu ortak bütçe odasına dahil olmak istiyor musunuz?",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final memberName = userSession.currentUserName.value.isNotEmpty
                    ? userSession.currentUserName.value
                    : "Ev Arkadaşı";

                final group = await firestoreService.joinGroupByInviteCode(
                  inviteCode: inviteCode,
                  memberName: memberName,
                );

                userSession.addGroupLocally(group);
                userSession.selectActiveGroup(group);

                Get.snackbar(
                  "Tebrikler! 🎉",
                  "'${group.name}' odasına başarıyla katıldınız.",
                  snackPosition: SnackPosition.TOP,
                );

                Get.toNamed(
                  AppRoutes.sharedBudgetDetail,
                  arguments: group.id,
                );
              } catch (e) {
                Get.snackbar(
                  "Katılma Başarısız",
                  e
                      .toString()
                      .replaceAll("Exception: ", "")
                      .replaceAll("StateError: ", ""),
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.shade600,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Hemen Katıl",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

