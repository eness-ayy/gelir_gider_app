import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/widgets/guest_feature_dialog.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/debt_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExtraController extends BaseController {
  SavingsService? get _savingsService =>
      Get.isRegistered<SavingsService>() ? Get.find<SavingsService>() : null;
  DebtService? get _debtService =>
      Get.isRegistered<DebtService>() ? Get.find<DebtService>() : null;
  RecurringService? get _recurringService =>
      Get.isRegistered<RecurringService>()
          ? Get.find<RecurringService>()
          : null;
  GroupService? get _groupService =>
      Get.isRegistered<GroupService>() ? Get.find<GroupService>() : null;
  CreditCardService? get _creditCardService =>
      Get.isRegistered<CreditCardService>()
          ? Get.find<CreditCardService>()
          : null;

  // Reaktif Sekme / Navigasyon İndeksi
  final rxNavIndex = 0.obs;

  // Misafir (Anonim) Kullanıcı Durumu
  final RxBool isGuest = false.obs;

  /// Testler veya harici denetimler için misafir durumunu zorlama alanı
  bool? debugIsGuest;

  @override
  void onInit() {
    super.onInit();
    checkGuestStatus();
  }

  /// Kullanıcının misafir (anonim) olup olmadığını belirler ve dinler
  void checkGuestStatus() {
    if (debugIsGuest != null) {
      isGuest.value = debugIsGuest!;
      return;
    }

    try {
      if (Get.isRegistered<UserSessionController>()) {
        final session = Get.find<UserSessionController>();
        isGuest.value = session.isAnonymous.value || !session.isLoggedIn;
        ever(session.isAnonymous, (val) {
          if (debugIsGuest == null) {
            isGuest.value = val || !session.isLoggedIn;
          }
        });
        ever(session.firebaseUser, (user) {
          if (debugIsGuest == null) {
            isGuest.value = user == null || user.isAnonymous;
          }
        });
        return;
      }

      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        isGuest.value = user == null || user.isAnonymous;
        FirebaseAuth.instance.authStateChanges().listen((user) {
          if (debugIsGuest == null) {
            isGuest.value = user == null || user.isAnonymous;
          }
        });
      }
    } catch (_) {
      isGuest.value = false;
    }
  }

  // 1. Gruplar & Ortak Harcamalar Dinamik Verileri
  int get activeGroupCount => _groupService?.groups.length ?? 0;
  String get groupBadgeText => "$activeGroupCount Grup";

  // 2. Birikim Hedefleri (Kumbara) Dinamik Verileri
  int get activeSavingsCount => _savingsService?.activeGoalsCount ?? 0;
  double get totalSavingsAmount => _savingsService?.totalSavedAmount ?? 0.0;
  double get targetSavingsAmount => _savingsService?.totalTargetAmount ?? 0.0;

  // 2. Borç & Alacak Takibi Dinamik Verileri
  double get netDebtBalance => _debtService?.netBalance ?? 0.0;
  double get totalReceivables => _debtService?.totalReceivables ?? 0.0;
  double get totalPayables => _debtService?.totalPayables ?? 0.0;
  int get activeDebtsCount => _debtService?.activeDebtsCount ?? 0;

  // 3. Tekrarlayan İşlemler & Abonelikler Dinamik Verileri
  int get upcomingRecurringCount => _recurringService?.activeCount ?? 0;
  double get monthlyRecurringTotal => _recurringService?.monthlyTotal ?? 0.0;

  // 4. Kredi Kartları & Taksitler Dinamik Verileri
  int get activeInstallmentCount =>
      _creditCardService?.activeInstallmentCount ?? 0;
  int get creditCardExpenseCount =>
      _creditCardService?.allCreditCardTransactions.length ?? 0;
  String get creditCardBadgeText {
    final instCount = activeInstallmentCount;
    final txCount = creditCardExpenseCount;
    if (instCount > 0 && txCount > 0) {
      return "$txCount Harcama • $instCount Taksit";
    }
    if (txCount > 0) {
      return "$txCount Harcama";
    }
    return "$instCount Taksit";
  }

  // Formatlı Görsel Metin Getter'ları
  String get savingsBadgeText => "$activeSavingsCount Aktif";

  String get netDebtBadgeText {
    final val = netDebtBalance;
    final formatter = NumberFormat("#,##0", "tr_TR");
    final prefix = val >= 0 ? "+₺" : "-₺";
    return "$prefix${formatter.format(val.abs())}";
  }

  String get recurringBadgeText => "$upcomingRecurringCount Yaklaşan";

  // Yönlendirme Metodları

  /// 1. Grup Harcamaları: Misafir kullanıcılar erişemez, bilgilendirme çıkar
  void goToGroups({BuildContext? context}) {
    if (isGuest.value) {
      showGuestNotice(
        featureName: "Grup Harcamaları",
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFF2563EB),
        description:
            "Grup harcamalarını ortaklaşa kullanabilmek için lütfen giriş yapın veya ücretsiz hesap oluşturun.",
        context: context,
      );
      return;
    }
    Get.toNamed(AppRoutes.groups);
  }

  /// 2. Ortak Hesap: Misafir kullanıcılar erişemez, bilgilendirme çıkar
  void goToSharedBudget({BuildContext? context}) {
    if (isGuest.value) {
      showGuestNotice(
        featureName: "Ortak Hesap",
        icon: Icons.cottage_rounded,
        accentColor: const Color(0xFF0D9488),
        description:
            "Ortak bütçe ve kasa tutabilmek için lütfen giriş yapın veya ücretsiz hesap oluşturun.",
        context: context,
      );
      return;
    }
    Get.toNamed(AppRoutes.sharedBudget);
  }

  void goToSavingsGoals() {
    Get.toNamed(AppRoutes.savingsGoals);
  }

  void goToDebts() {
    Get.toNamed(AppRoutes.debts);
  }

  void goToRecurringTransactions() {
    Get.toNamed(AppRoutes.recurringTransactions);
  }

  void goToCreditCards() {
    Get.toNamed(AppRoutes.creditCards);
  }

  /// Misafir kısıtlama bilgilendirme diyaloğunu gösterir
  void showGuestNotice({
    required String featureName,
    required IconData icon,
    required Color accentColor,
    required String description,
    BuildContext? context,
  }) {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      GuestFeatureDialog.show(
        ctx,
        title: "$featureName Özelliği",
        featureName: featureName,
        description: description,
        icon: icon,
        accentColor: accentColor,
      );
    }
  }

  /// Özet verileri yenileme
  Future<void> refreshSummaryData() async {
    checkGuestStatus();
    _savingsService?.loadGoals();
    _debtService?.loadDebts();
    _recurringService?.loadItems();
    _groupService?.loadGroups();
    _creditCardService?.loadData();
  }
}
