import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/account_balances.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class AccountService extends GetxService {
  static const String _storageKey = "transaction_payment_methods";

  late StorgeService _storageService;
  final RxMap<String, String> transactionPaymentMethods = <String, String>{}.obs;

  String get _scopedKey => _storageService.scopedKey(_storageKey);

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorgeService>();
    loadPaymentMethods();
  }

  void loadPaymentMethods() {
    try {
      String? jsonString = _storageService.getValue<String>(_scopedKey);
      if ((jsonString == null || jsonString.isEmpty) &&
          _storageService.hasKey(_storageKey)) {
        jsonString = _storageService.getValue<String>(_storageKey);
      }
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final map = <String, String>{};
        decoded.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            map[key] = value;
          }
        });
        transactionPaymentMethods.assignAll(map);
      }
    } catch (e) {
      debugPrint("Ödeme yöntemleri yüklenirken hata: $e");
    }
  }

  Future<void> _persistPaymentMethods() async {
    try {
      final jsonString = jsonEncode(Map<String, String>.from(transactionPaymentMethods));
      await _storageService.setValue<String>(_scopedKey, jsonString);
    } catch (e) {
      debugPrint("Ödeme yöntemleri kaydedilirken hata: $e");
    }
  }

  PaymentMethod getPaymentMethod(String transactionId, {PaymentMethod defaultMethod = PaymentMethod.cash}) {
    if (transactionId.isEmpty) return defaultMethod;
    final savedKey = transactionPaymentMethods[transactionId];
    if (savedKey == null || savedKey.isEmpty) return defaultMethod;
    return PaymentMethod.fromKey(savedKey, defaultMethod: defaultMethod);
  }

  Future<void> setPaymentMethod(String transactionId, String paymentMethodKey) async {
    if (transactionId.isEmpty) return;
    transactionPaymentMethods[transactionId] = paymentMethodKey;
    await _persistPaymentMethods();
  }

  Future<void> restorePaymentMethods(Map<String, String> newMethods) async {
    transactionPaymentMethods.assignAll(newMethods);
    await _persistPaymentMethods();
  }

  Future<void> removePaymentMethod(String transactionId) async {
    if (transactionPaymentMethods.containsKey(transactionId)) {
      transactionPaymentMethods.remove(transactionId);
      await _persistPaymentMethods();
    }
  }

  /// Verilen işlem listesi için hesap bakiyelerini hesaplar (Nakit, Banka Kartı, Kredi Kartı)
  AccountBalances calculateBalances(
    List<AppTransaction> transactions, {
    DateTime? month,
    bool onlyCurrentMonth = false,
  }) {
    double cashIncome = 0.0;
    double cashExpense = 0.0;

    double bankIncome = 0.0;
    double bankExpense = 0.0;

    double creditCardExpense = 0.0;
    double creditCardIncome = 0.0;

    for (final tr in transactions) {
      if (onlyCurrentMonth && month != null) {
        final parsedDate = DateTime.tryParse(tr.date);
        if (parsedDate == null ||
            parsedDate.year != month.year ||
            parsedDate.month != month.month) {
          continue;
        }
      }

      final amount = tr.baseAmount;
      if (amount <= 0 || !amount.isFinite) continue;

      // Hesaplar arası transfer / kredi kartı borç ödemesi kontrolü: [TRANSFER:fromKey:toKey]
      final transferMatch =
          RegExp(r'^\[TRANSFER:(.*?):(.*?)\]').firstMatch(tr.description.trim());
      if (transferMatch != null) {
        final fromKey = transferMatch.group(1)?.trim() ?? '';
        final toKey = transferMatch.group(2)?.trim() ?? '';

        if (fromKey == PaymentMethod.cash.key) {
          cashExpense += amount;
        } else if (fromKey == PaymentMethod.bankCard.key) {
          bankExpense += amount;
        }

        if (toKey == PaymentMethod.cash.key) {
          cashIncome += amount;
        } else if (toKey == PaymentMethod.bankCard.key) {
          bankIncome += amount;
        } else if (toKey == PaymentMethod.creditCard.key) {
          creditCardIncome += amount;
        }
        continue;
      }

      // Önce işlemin kendi paymentMethod alanına, yoksa yerel kayıtlı servise bak
      PaymentMethod method;
      if (tr.paymentMethod != null && tr.paymentMethod!.isNotEmpty) {
        method = PaymentMethod.fromKey(tr.paymentMethod);
      } else {
        method = getPaymentMethod(tr.id, defaultMethod: PaymentMethod.cash);
      }

      final isIncome = tr.type.toLowerCase() == 'income' || tr.type.toLowerCase() == 'gelir';

      switch (method) {
        case PaymentMethod.cash:
          if (isIncome) {
            cashIncome += amount;
          } else {
            cashExpense += amount;
          }
          break;
        case PaymentMethod.bankCard:
          if (isIncome) {
            bankIncome += amount;
          } else {
            bankExpense += amount;
          }
          break;
        case PaymentMethod.creditCard:
          if (isIncome) {
            creditCardIncome += amount;
          } else {
            creditCardExpense += amount;
          }
          break;
      }
    }

    final cashBalance = cashIncome - cashExpense;
    final bankBalance = bankIncome - bankExpense;
    final netCreditCardExpense =
        (creditCardExpense - creditCardIncome).clamp(0.0, double.infinity);
    final totalLiquidAssets = cashBalance + bankBalance;

    return AccountBalances(
      cashBalance: cashBalance,
      cashIncome: cashIncome,
      cashExpense: cashExpense,
      bankBalance: bankBalance,
      bankIncome: bankIncome,
      bankExpense: bankExpense,
      creditCardExpense: netCreditCardExpense,
      creditCardIncome: creditCardIncome,
      totalLiquidAssets: totalLiquidAssets,
    );
  }
}
