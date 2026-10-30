import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
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
  bool get _canUseCloud =>
      Firebase.apps.isNotEmpty && _storage.activeUserKey != 'guest_user';

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

      if (cards.isEmpty && installments.isEmpty) {
        unawaited(_restoreFromCloudIfEmpty());
      }
    } catch (e) {
      debugPrint("Kredi kartı verileri yüklenirken hata: $e");
      cards.clear();
      installments.clear();
    }
  }

  Future<void> _restoreFromCloudIfEmpty() async {
    if (!_canUseCloud) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_storage.activeUserKey)
          .collection('extra_modules')
          .doc('credit_cards')
          .get();
      final data = doc.data();
      if (data == null) return;
      final cloudCards = data['cards'] as List?;
      final cloudInstallments = data['installments'] as List?;
      if (cloudCards != null && cloudCards.isNotEmpty && cards.isEmpty) {
        cards.value = cloudCards
            .map((e) => CreditCardModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        await _storage.setValue<String>(
          _scopedCardsKey,
          jsonEncode(cards.map((c) => c.toJson()).toList()),
        );
      }
      if (cloudInstallments != null &&
          cloudInstallments.isNotEmpty &&
          installments.isEmpty) {
        installments.value = cloudInstallments
            .map(
              (e) => InstallmentPurchaseModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
        await _storage.setValue<String>(
          _scopedInstallmentsKey,
          jsonEncode(installments.map((i) => i.toJson()).toList()),
        );
      }
    } catch (_) {}
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
              paymentMethod: PaymentMethod.buildCreditCardKey(current.cardId),
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

  /// Bir işlemin ham ödeme yöntemi anahtarını (örn. 'credit_card:card_123') çözer.
  String resolveRawPaymentMethod(AppTransaction tr) {
    final txKey = tr.paymentMethod?.trim() ?? '';
    String localKey = '';
    if (Get.isRegistered<DashboardController>()) {
      localKey = Get.find<DashboardController>()
              .accountService
              .transactionPaymentMethods[tr.id]
              ?.trim() ??
          '';
    }
    // Yerel kayıtta kart ID'li spesifik bir anahtar varsa onu tercih et
    if (localKey.startsWith('credit_card:')) return localKey;
    if (txKey.startsWith('credit_card')) return txKey;
    if (localKey.isNotEmpty && (txKey.isEmpty || txKey == 'cash')) {
      return localKey;
    }
    return txKey.isNotEmpty ? txKey : localKey;
  }

  /// Bir kredi kartı harcamasının hangi karta ait olduğunu bulur.
  CreditCardModel? resolveCardForTransaction(AppTransaction tr) {
    if (cards.isEmpty) return null;
    final rawMethod = resolveRawPaymentMethod(tr);
    final txCardId = PaymentMethod.extractCreditCardId(rawMethod);
    if (txCardId != null) {
      final matched = cards.firstWhereOrNull((c) => c.id == txCardId);
      if (matched != null) return matched;
    }
    return cards.first;
  }

  /// Tüm kredi kartı harcamalarını (taksit ödemeleri ve transferler hariç) döndürür.
  List<AppTransaction> get allCreditCardTransactions {
    if (!Get.isRegistered<DashboardController>()) return [];
    try {
      final dash = Get.find<DashboardController>();
      final result = <AppTransaction>[];
      for (final tr in dash.myTransaction) {
        final desc = tr.description.trim();
        if (desc.startsWith('Taksit Ödemesi (')) continue;
        if (desc.startsWith('[TRANSFER:')) continue;

        final rawMethod = resolveRawPaymentMethod(tr);
        if (PaymentMethod.fromKey(rawMethod) == PaymentMethod.creditCard &&
            tr.type.toLowerCase() == 'expense') {
          result.add(tr);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Belirli bir kredi kartına ait harcamaları döndürür.
  List<AppTransaction> getTransactionsForCard(String cardId) {
    final isFirstCard = cards.isNotEmpty && cards.first.id == cardId;
    return allCreditCardTransactions.where((tr) {
      final rawMethod = resolveRawPaymentMethod(tr);
      final txCardId = PaymentMethod.extractCreditCardId(rawMethod);
      if (txCardId == cardId) return true;
      // Kart seçilmeden önce yapılmış veya silinmiş karta ait harcamaları ilk karta bağla
      if ((txCardId == null || !cards.any((c) => c.id == txCardId)) &&
          isFirstCard) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Belirli bir kredi kartına ait tek çekim cüzdan harcamaları (net)
  double getSingleShotSpendForCard(String cardId) {
    if (!Get.isRegistered<DashboardController>()) return 0.0;
    try {
      final dash = Get.find<DashboardController>();
      final isFirstCard = cards.isNotEmpty && cards.first.id == cardId;
      double spend = 0.0;
      for (final tr in dash.myTransaction) {
        final desc = tr.description.trim();
        if (desc.startsWith('Taksit Ödemesi (')) continue;
        final transferMatch =
            RegExp(r'^\[TRANSFER:(.*?):(.*?)\]').firstMatch(desc);
        if (transferMatch != null) {
          final toKey = transferMatch.group(2)?.trim() ?? '';
          if (toKey.startsWith('credit_card')) {
            final targetCardId = PaymentMethod.extractCreditCardId(toKey);
            final hasMatchingCard =
                targetCardId != null && cards.any((c) => c.id == targetCardId);
            if (targetCardId == cardId || (!hasMatchingCard && isFirstCard)) {
              spend -= tr.baseAmount;
            }
          }
          continue;
        }
        final rawMethod = resolveRawPaymentMethod(tr);
        if (PaymentMethod.fromKey(rawMethod) == PaymentMethod.creditCard &&
            tr.type.toLowerCase() == 'expense') {
          final txCardId = PaymentMethod.extractCreditCardId(rawMethod);
          final hasMatchingCard =
              txCardId != null && cards.any((c) => c.id == txCardId);
          if (txCardId == cardId || (!hasMatchingCard && isFirstCard)) {
            spend += tr.baseAmount;
          }
        }
      }
      return spend > 0 ? spend : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Ana cüzdandaki tek çekim kredi kartı harcamaları (Taksit ödemeleri hariç net kart borcu)
  double get walletSingleShotCardSpend {
    if (!Get.isRegistered<DashboardController>()) return 0.0;
    try {
      final dash = Get.find<DashboardController>();
      double spend = 0.0;
      for (final tr in dash.myTransaction) {
        final desc = tr.description.trim();
        if (desc.startsWith('Taksit Ödemesi (')) continue;
        final transferMatch =
            RegExp(r'^\[TRANSFER:(.*?):(.*?)\]').firstMatch(desc);
        if (transferMatch != null) {
          final toKey = transferMatch.group(2)?.trim() ?? '';
          if (toKey.startsWith('credit_card')) {
            spend -= tr.baseAmount;
          }
          continue;
        }
        final rawMethod = resolveRawPaymentMethod(tr);
        if (PaymentMethod.fromKey(rawMethod) == PaymentMethod.creditCard &&
            tr.type.toLowerCase() == 'expense') {
          spend += tr.baseAmount;
        }
      }
      return spend > 0 ? spend : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double get totalUsedLimit {
    double total = 0.0;
    for (final item in installments.where((i) => !i.isCompleted)) {
      total += item.remainingAmount;
    }
    total += walletSingleShotCardSpend;
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
      _syncToCloud();
    } catch (e) {
      debugPrint("Kartlar kaydedilirken hata: $e");
    }
  }

  Future<void> _saveInstallments() async {
    try {
      final jsonList = installments.map((i) => i.toJson()).toList();
      await _storage.setValue<String>(
          _scopedInstallmentsKey, jsonEncode(jsonList));
      _syncToCloud();
    } catch (e) {
      debugPrint("Taksitler kaydedilirken hata: $e");
    }
  }

  void _syncToCloud() {
    if (!_canUseCloud) return;
    unawaited(
      FirebaseFirestore.instance
          .collection('users')
          .doc(_storage.activeUserKey)
          .collection('extra_modules')
          .doc('credit_cards')
          .set({
            'cards': cards.map((c) => c.toJson()).toList(),
            'installments': installments.map((i) => i.toJson()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((_) {}),
    );
  }
}
