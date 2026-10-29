import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/notification_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class CreditCardService extends GetxService {
  static const String _cardsStorageKey = 'credit_cards_data_v1';
  static const String _installmentsStorageKey = 'credit_card_installments_data_v1';

  late final StorgeService _storage;

  String get _scopedCardsKey => _storage.scopedKey(_cardsStorageKey);
  String get _scopedInstallmentsKey => _storage.scopedKey(_installmentsStorageKey);

  final cards = <CreditCardModel>[].obs;
  final installments = <InstallmentPurchaseModel>[].obs;

  Future<CreditCardService> init() async {
    _storage = Get.find<StorgeService>();
    loadData();
    return this;
  }

  void loadData() {
    try {
      // 1. Kartları yükle
      final rawCards = _storage.getValue<String>(_scopedCardsKey);
      if (rawCards != null && rawCards.isNotEmpty) {
        final decoded = jsonDecode(rawCards) as List;
        cards.value = decoded
            .map((item) => CreditCardModel.fromJson(item as Map<String, dynamic>))
            .where((c) => c.id != 'card_1' && c.id != 'card_2')
            .toList();
      } else {
        cards.clear();
      }

      // 2. Taksitli Harcamaları yükle
      final rawInstallments = _storage.getValue<String>(_scopedInstallmentsKey);
      if (rawInstallments != null && rawInstallments.isNotEmpty) {
        final decoded = jsonDecode(rawInstallments) as List;
        installments.value = decoded
            .map((item) =>
                InstallmentPurchaseModel.fromJson(item as Map<String, dynamic>))
            .where((i) =>
                i.id != 'inst_1' &&
                i.id != 'inst_2' &&
                i.id != 'inst_3' &&
                i.id != 'inst_4')
            .toList();
      } else {
        installments.clear();
      }
    } catch (e) {
      debugPrint("Kredi kartı verileri yüklenirken hata: $e");
      cards.clear();
      installments.clear();
    }
  }

  // --- Kart İşlemleri ---
  Future<void> addCard(CreditCardModel card) async {
    cards.add(card);
    await _saveCards();
  }

  Future<void> updateCard(CreditCardModel updated) async {
    final index = cards.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      cards[index] = updated;
      await _saveCards();
    }
  }

  Future<void> deleteCard(String cardId) async {
    cards.removeWhere((c) => c.id == cardId);
    installments.removeWhere((i) => i.cardId == cardId);
    await _saveCards();
    await _saveInstallments();
  }

  CreditCardModel? getCardById(String cardId) {
    try {
      return cards.firstWhere((c) => c.id == cardId);
    } catch (_) {
      return null;
    }
  }

  // --- Taksit İşlemleri ---
  Future<void> addInstallment(InstallmentPurchaseModel item) async {
    installments.insert(0, item);
    await _saveInstallments();
  }

  Future<void> updateInstallment(InstallmentPurchaseModel updated) async {
    final index = installments.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      installments[index] = updated;
      await _saveInstallments();
    }
  }

  Future<void> deleteInstallment(String id) async {
    installments.removeWhere((i) => i.id == id);
    await _saveInstallments();
  }

  Future<void> closeInstallmentEarly(String id) async {
    final index = installments.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = installments[index];
      installments[index] = current.copyWith(
        paidInstallments: current.totalInstallments,
        isCompleted: true,
      );
      await _saveInstallments();
    }
  }

  Future<void> payNextInstallment(String id) async {
    final index = installments.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = installments[index];
      final nextPaid = current.paidInstallments + 1;
      final completed = nextPaid >= current.totalInstallments;
      installments[index] = current.copyWith(
        paidInstallments: nextPaid,
        isCompleted: completed,
      );
      await _saveInstallments();

      try {
        if (Get.isRegistered<TransactionRepostory>() &&
            current.monthlyAmount > 0) {
          final repo = Get.find<TransactionRepostory>();
          await repo.createTransaction(
            Transaction(
              id: '',
              amount: current.monthlyAmount,
              description:
                  "Taksit Ödemesi (${current.title} - $nextPaid/${current.totalInstallments})",
              type: 'expense',
              date: DateTime.now().toIso8601String(),
              categoryId: 'Kredi Kartı & Taksit',
              categoryName: 'Kredi Kartı & Taksit',
              categoryIcon: 'credit_card',
              userId: '',
              paymentMethod: 'credit_card',
            ),
          );
          if (Get.isRegistered<DashboardController>()) {
            await Get.find<DashboardController>().refreshDashboard();
          }
        }
      } catch (e) {
        debugPrint("Taksit ödemesi cüzdana işlenirken hata: $e");
      }
    }
  }

  // --- Sayaç ve Özet Getter'ları ---
  int get activeInstallmentCount =>
      installments.where((i) => !i.isCompleted).length;

  double get totalUsedLimit {
    double total = 0.0;
    for (final item in installments.where((i) => !i.isCompleted)) {
      total += item.remainingAmount;
    }
    return total;
  }

  double get totalCardsLimit =>
      cards.fold(0.0, (sum, c) => sum + c.totalLimit);

  double get totalAvailableLimit =>
      (totalCardsLimit - totalUsedLimit).clamp(0.0, double.infinity);

  // --- Kaydetme ---
  Future<void> _saveCards() async {
    try {
      final jsonList = cards.map((c) => c.toJson()).toList();
      await _storage.setValue<String>(_scopedCardsKey, jsonEncode(jsonList));
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().scheduleCreditCardReminders();
      }
    } catch (e) {
      debugPrint("Kartlar kaydedilirken hata: $e");
    }
  }

  Future<void> _saveInstallments() async {
    try {
      final jsonList = installments.map((i) => i.toJson()).toList();
      await _storage.setValue<String>(
          _scopedInstallmentsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Taksitler kaydedilirken hata: $e");
    }
  }
}
