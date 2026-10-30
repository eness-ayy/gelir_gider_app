import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:get/get.dart';

class MonthlyInstallmentLoad {
  final String monthName;
  final int year;
  final double amount;
  final double ratio; // 0.0 to 1.0 (en yüksek aya oranla)

  MonthlyInstallmentLoad({
    required this.monthName,
    required this.year,
    required this.amount,
    required this.ratio,
  });
}

class CreditCardController extends BaseController {
  late final CreditCardService _service;

  // Seçili Kart İndeksi (Carousel / PageView için)
  final selectedCardIndex = 0.obs;
  final showOnlySelectedCardTransactions = false.obs;

  // Reaktif Limit Alanları (İstenen RxDouble)
  final usedLimit = 0.0.obs;
  final availableLimit = 0.0.obs;
  final totalLimit = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _service = Get.isRegistered<CreditCardService>()
        ? Get.find<CreditCardService>()
        : Get.put(CreditCardService());

    _recomputeLimits();

    // Kartlar, taksitler veya cüzdan işlemleri değiştikçe limitleri otomatik yeniden hesapla
    ever(_service.cards, (_) => _recomputeLimits());
    ever(_service.installments, (_) => _recomputeLimits());
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      ever(dash.myTransaction, (_) => _recomputeLimits());
      ever(
        dash.accountService.transactionPaymentMethods,
        (_) => _recomputeLimits(),
      );
    }
  }

  void _recomputeLimits() {
    totalLimit.value = _service.totalCardsLimit;
    usedLimit.value = _service.totalUsedLimit;
    availableLimit.value = _service.totalAvailableLimit;
  }

  Future<void> refreshData() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refreshDashboard();
    }
    _recomputeLimits();
  }

  // --- Genel Getter'lar ---
  RxList<CreditCardModel> get cards => _service.cards;
  RxList<InstallmentPurchaseModel> get installments => _service.installments;

  /// Tüm kredi kartı harcamaları (tek çekim)
  List<AppTransaction> get allCreditCardTransactions =>
      _service.allCreditCardTransactions;

  /// Belirli bir karta ait kredi kartı harcamaları
  List<AppTransaction> getTransactionsForCard(String cardId) =>
      _service.getTransactionsForCard(cardId);

  /// Bir harcamanın bağlı olduğu kredi kartı modeli
  CreditCardModel? getCardForTransaction(AppTransaction tr) =>
      _service.resolveCardForTransaction(tr);

  /// Toplam tek çekim kredi kartı borcu
  double get singleShotSpendTotal => _service.walletSingleShotCardSpend;

  /// Toplam kalan taksit yükü
  double get installmentRemainingTotal => activeInstallments.fold<double>(
        0.0,
        (sum, i) => sum + i.remainingAmount,
      );

  /// Belirli bir kartın tek çekim harcama toplamı
  double getSingleShotSpendForCard(String cardId) =>
      _service.getSingleShotSpendForCard(cardId);

  /// Belirli bir kartın kalan taksit toplamı
  double getInstallmentRemainingForCard(String cardId) =>
      getActiveInstallmentsForCard(cardId).fold<double>(
        0.0,
        (sum, i) => sum + i.remainingAmount,
      );

  Future<bool> deleteCreditCardTransaction(String transactionId) async {
    if (!Get.isRegistered<DashboardController>()) return false;
    final deleted = await Get.find<DashboardController>()
        .deleteTransactions(transactionId);
    if (deleted) {
      _recomputeLimits();
    }
    return deleted;
  }

  /// Toplam doluluk yüzdesi (%0 - %100)
  double get overallUtilizationPercentage {
    if (totalLimit.value <= 0) return 0.0;
    final percent = (usedLimit.value / totalLimit.value) * 100;
    return percent.clamp(0.0, 100.0);
  }

  /// Aktif (bitmemiş) tüm taksitler
  List<InstallmentPurchaseModel> get activeInstallments =>
      _service.installments.where((i) => !i.isCompleted).toList();

  /// Seçili kart
  CreditCardModel? get currentSelectedCard {
    if (cards.isEmpty) return null;
    if (selectedCardIndex.value >= cards.length) {
      selectedCardIndex.value = 0;
    }
    return cards[selectedCardIndex.value];
  }

  // --- Karta Özel Hesaplamalar ---
  double getUsedLimitForCard(String cardId) {
    final installmentTotal = _service.installments
        .where((i) => i.cardId == cardId && !i.isCompleted)
        .fold(0.0, (sum, i) => sum + i.remainingAmount);
    return installmentTotal + _service.getSingleShotSpendForCard(cardId);
  }

  double getAvailableLimitForCard(CreditCardModel card) {
    final used = getUsedLimitForCard(card.id);
    return (card.totalLimit - used).clamp(0.0, card.totalLimit);
  }

  double getUtilizationPercentageForCard(CreditCardModel card) {
    if (card.totalLimit <= 0) return 0.0;
    final used = getUsedLimitForCard(card.id);
    return ((used / card.totalLimit) * 100).clamp(0.0, 100.0);
  }

  List<InstallmentPurchaseModel> getActiveInstallmentsForCard(String cardId) {
    return _service.installments
        .where((i) => i.cardId == cardId && !i.isCompleted)
        .toList();
  }

  // --- 2. Hesap Kesim & Son Ödeme Sayaçları ---

  /// Bir sonraki hesap kesim tarihini dinamik hesaplar
  DateTime getNextCutoffDate(CreditCardModel card) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    if (now.day > card.cutoffDay) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    final maxDayInMonth = DateUtils.getDaysInMonth(year, month);
    final day = card.cutoffDay.clamp(1, maxDayInMonth);
    return DateTime(year, month, day);
  }

  /// Hesap kesimine kalan gün sayısı
  int getDaysUntilCutoff(CreditCardModel card) {
    final nextCutoff = getNextCutoffDate(card);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final cleanCutoff =
        DateTime(nextCutoff.year, nextCutoff.month, nextCutoff.day);
    final diff = cleanCutoff.difference(cleanToday).inDays;
    return diff >= 0 ? diff : 0;
  }

  /// Bir sonraki son ödeme tarihini dinamik hesaplar
  DateTime getNextDueDate(CreditCardModel card) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    if (now.day > card.dueDay) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    final maxDayInMonth = DateUtils.getDaysInMonth(year, month);
    final day = card.dueDay.clamp(1, maxDayInMonth);
    return DateTime(year, month, day);
  }

  /// Son ödemeye kalan gün sayısı
  int getDaysUntilDue(CreditCardModel card) {
    final nextDue = getNextDueDate(card);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final cleanDue = DateTime(nextDue.year, nextDue.month, nextDue.day);
    final diff = cleanDue.difference(cleanToday).inDays;
    return diff >= 0 ? diff : 0;
  }

  // --- 3. Gelecek 6 Ayın Taksit Yükü Analizi ---

  /// Önümüzdeki 6 ay için her ay ödenecek taksit yükünü listeler
  List<MonthlyInstallmentLoad> getNext6MonthsLoad() {
    final now = DateTime.now();
    final List<MonthlyInstallmentLoad> result = [];
    double maxAmount = 0.0;
    final List<double> monthlyAmounts = List.filled(6, 0.0);

    final activeItems = activeInstallments;

    for (int monthIndex = 0; monthIndex < 6; monthIndex++) {
      double totalForMonth = 0.0;
      for (final item in activeItems) {
        final remaining = item.remainingInstallments;
        if (monthIndex < remaining) {
          totalForMonth += item.monthlyAmount;
        }
      }
      monthlyAmounts[monthIndex] = totalForMonth;
      if (totalForMonth > maxAmount) {
        maxAmount = totalForMonth;
      }
    }

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    // Aylar ve oranları oluştur
    for (int i = 0; i < 6; i++) {
      final targetMonth = DateTime(now.year, now.month + i, 1);
      final monthName = turkishMonths[targetMonth.month - 1];
      final amount = monthlyAmounts[i];
      final ratio = maxAmount > 0 ? (amount / maxAmount) : 0.0;

      result.add(
        MonthlyInstallmentLoad(
          monthName: monthName,
          year: targetMonth.year,
          amount: amount,
          ratio: ratio,
        ),
      );
    }

    return result;
  }

  // --- 4. Taksit & Kart İşlemleri ---

  /// Taksiti erken kapatma (kalan tüm taksitleri ödeyip tamamlandı işaretler)
  Future<void> closeInstallmentEarly(String id) async {
    await _service.closeInstallmentEarly(id);
    _recomputeLimits();
    Get.snackbar(
      "Taksit Kapatıldı",
      "Kalan tüm taksitler başarıyla kapatıldı.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E1E1E),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  /// Tek taksit ödeme
  Future<void> payNextInstallment(String id) async {
    await _service.payNextInstallment(id);
    _recomputeLimits();
  }

  /// Taksit silme
  Future<void> deleteInstallment(String id) async {
    await _service.deleteInstallment(id);
    _recomputeLimits();
  }

  /// Yeni kart ekleme
  Future<void> addNewCard({
    required String cardName,
    required String bankName,
    required double totalLimit,
    required int cutoffDay,
    required int dueDay,
    required String colorHex,
    String last4Digits = '0000',
  }) async {
    final newCard = CreditCardModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      cardName: cardName.trim(),
      bankName: bankName.trim(),
      totalLimit: totalLimit,
      cutoffDay: cutoffDay,
      dueDay: dueDay,
      colorHex: colorHex,
      last4Digits: last4Digits,
    );

    await _service.addCard(newCard);
    _recomputeLimits();
  }

  /// Mevcut kartı güncelleme
  Future<void> updateExistingCard({
    required String id,
    required String cardName,
    required String bankName,
    required double totalLimit,
    required int cutoffDay,
    required int dueDay,
    required String colorHex,
    String last4Digits = '0000',
  }) async {
    final updated = CreditCardModel(
      id: id,
      cardName: cardName.trim(),
      bankName: bankName.trim(),
      totalLimit: totalLimit,
      cutoffDay: cutoffDay,
      dueDay: dueDay,
      colorHex: colorHex,
      last4Digits: last4Digits,
    );

    await _service.updateCard(updated);
    _recomputeLimits();
  }

  /// Kart silme
  Future<void> deleteCard(String cardId) async {
    await _service.deleteCard(cardId);
    _recomputeLimits();
  }

  /// Yeni taksitli harcama ekleme
  Future<void> addNewInstallment({
    required String cardId,
    required String title,
    required double totalAmount,
    required int totalInstallments,
    DateTime? startDate,
  }) async {
    final newInstallment = InstallmentPurchaseModel(
      id: 'inst_${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId,
      title: title.trim(),
      totalAmount: totalAmount,
      totalInstallments: totalInstallments,
      paidInstallments: 0,
      startDate: startDate ?? DateTime.now(),
    );

    await _service.addInstallment(newInstallment);
    _recomputeLimits();
  }

  CreditCardModel? getCard(String cardId) => _service.getCardById(cardId);
}
