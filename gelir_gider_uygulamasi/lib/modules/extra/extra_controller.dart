import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
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
  String get creditCardBadgeText => "$activeInstallmentCount Taksit";

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
  void goToGroups() {
    Get.toNamed(AppRoutes.groups);
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

  /// Özet verileri yenileme
  Future<void> refreshSummaryData() async {
    _savingsService?.loadGoals();
    _debtService?.loadDebts();
    _recurringService?.loadItems();
    _groupService?.loadGroups();
    _creditCardService?.loadData();
  }
}
