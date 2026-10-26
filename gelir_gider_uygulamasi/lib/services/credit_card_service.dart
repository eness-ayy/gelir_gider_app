import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/services/notification_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class CreditCardService extends GetxService {
  static const String _cardsStorageKey = 'credit_cards_data_v1';
  static const String _installmentsStorageKey = 'credit_card_installments_data_v1';

  late final StorgeService _storage;

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
      final rawCards = _storage.getValue<String>(_cardsStorageKey);
      if (rawCards != null && rawCards.isNotEmpty) {
        final decoded = jsonDecode(rawCards) as List;
        cards.value = decoded
            .map((item) => CreditCardModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Örnek Başlangıç Kartları
        cards.value = [
          CreditCardModel(
            id: 'card_1',
            cardName: 'Garanti Bonus Platinum',
            bankName: 'Garanti BBVA',
            totalLimit: 75000.0,
            cutoffDay: 15,
            dueDay: 25,
            colorHex: '#1E1B4B', // Derin İndigo
            last4Digits: '5824',
          ),
          CreditCardModel(
            id: 'card_2',
            cardName: 'Maximum Kart',
            bankName: 'İş Bankası',
            totalLimit: 50000.0,
            cutoffDay: 8,
            dueDay: 18,
            colorHex: '#0F172A', // Koyu Slate / Titanyum
            last4Digits: '9142',
          ),
        ];
        _saveCards();
      }

      // 2. Taksitli Harcamaları yükle
      final rawInstallments = _storage.getValue<String>(_installmentsStorageKey);
      if (rawInstallments != null && rawInstallments.isNotEmpty) {
        final decoded = jsonDecode(rawInstallments) as List;
        installments.value = decoded
            .map((item) =>
                InstallmentPurchaseModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Örnek Başlangıç Taksitleri (Kullanıcının istediği 4 Taksit)
        final now = DateTime.now();
        installments.value = [
          InstallmentPurchaseModel(
            id: 'inst_1',
            cardId: 'card_1',
            title: 'Dyson V15 Süpürge',
            totalAmount: 24000.0,
            totalInstallments: 6,
            paidInstallments: 2,
            startDate: DateTime(now.year, now.month - 2, 1),
          ),
          InstallmentPurchaseModel(
            id: 'inst_2',
            cardId: 'card_1',
            title: 'Uçak Bileti (İstanbul - Roma)',
            totalAmount: 12000.0,
            totalInstallments: 3,
            paidInstallments: 1,
            startDate: DateTime(now.year, now.month - 1, 5),
          ),
          InstallmentPurchaseModel(
            id: 'inst_3',
            cardId: 'card_2',
            title: 'Beyaz Eşya Paketi',
            totalAmount: 36000.0,
            totalInstallments: 9,
            paidInstallments: 3,
            startDate: DateTime(now.year, now.month - 3, 10),
          ),
          InstallmentPurchaseModel(
            id: 'inst_4',
            cardId: 'card_2',
            title: 'Ofis Koltuğu & Masa',
            totalAmount: 8000.0,
            totalInstallments: 4,
            paidInstallments: 1,
            startDate: DateTime(now.year, now.month - 1, 12),
          ),
        ];
        _saveInstallments();
      }
    } catch (e) {
      debugPrint("Kredi kartı verileri yüklenirken hata: $e");
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
      await _storage.setValue<String>(_cardsStorageKey, jsonEncode(jsonList));
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
          _installmentsStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Taksitler kaydedilirken hata: $e");
    }
  }
}
