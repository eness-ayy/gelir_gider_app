import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:get/get.dart';

class TransactionModel {
  final String? id;
  final String title;

  /// TRY karşılığı (= baseAmount). Eski kayıtlarla uyum için korunur.
  final double amount;
  final String type; // 'gelir' | 'gider'
  final String category;
  final DateTime date;
  final String? paymentMethod;
  final String? description;

  /// Para birimi kodu (varsayılan 'TRY')
  final String currency;

  /// İşlem anındaki 1 birim = X TRY kuru (varsayılan 1.0)
  final double exchangeRate;

  /// Kullanıcının girdiği döviz/altın tutarı
  final double originalAmount;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.description,
    this.currency = CurrencyHelper.baseCode,
    this.exchangeRate = 1.0,
    double? originalAmount,
  }) : originalAmount = originalAmount ?? amount;

  /// TRY karşılığı = originalAmount * exchangeRate
  double get baseAmount => amount;

  AppCurrency get currencyEnum => CurrencyHelper.fromCode(currency);

  /// Firestore dokümanından nesne üretme
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Tarih alanını güvenli şekilde parse etme
    DateTime parsedDate;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawType = (data['type'] ?? 'gider').toString().toLowerCase();
    final isIncome = rawType == 'income' || rawType == 'gelir';
    final desc = (data['description'] ?? data['title'] ?? '').toString();
    final cur = AppTransaction.parseCurrencyFields(data);
    final base = (data['baseAmount'] as num?)?.toDouble() ??
        (data['amount'] as num?)?.toDouble() ??
        0.0;

    return TransactionModel(
      id: doc.id,
      title: (data['title'] ?? data['description'] ?? '').toString(),
      amount: base,
      type: isIncome ? 'gelir' : 'gider',
      category: (data['category'] ?? data['categoryName'] ?? 'Diğer').toString(),
      date: parsedDate,
      paymentMethod: data['paymentMethod']?.toString(),
      description: desc,
      currency: cur.currency,
      exchangeRate: cur.rate,
      originalAmount: cur.original,
    );
  }

  /// AppTransaction modelinden TransactionModel'e dönüştürme
  factory TransactionModel.fromAppTransaction(AppTransaction appTrans) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(appTrans.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawType = appTrans.type.toLowerCase();
    final isIncome = rawType == 'income' || rawType == 'gelir';
    final desc = appTrans.description.trim();
    final catName = appTrans.category?.name.trim() ?? 'Diğer';

    final method = appTrans.paymentMethodEnum;
    String paymentMethodLabel = method.title;
    if (method == PaymentMethod.creditCard &&
        Get.isRegistered<CreditCardService>()) {
      final cardService = Get.find<CreditCardService>();
      final cardId = PaymentMethod.extractCreditCardId(appTrans.paymentMethod);
      if (cardId != null) {
        final matched =
            cardService.cards.firstWhereOrNull((c) => c.id == cardId);
        if (matched != null) {
          paymentMethodLabel = "${method.title} (${matched.cardName})";
        }
      } else if (cardService.cards.length == 1) {
        paymentMethodLabel =
            "${method.title} (${cardService.cards.first.cardName})";
      }
    }

    return TransactionModel(
      id: appTrans.id,
      title: desc.isNotEmpty ? desc : catName,
      amount: double.tryParse(appTrans.amount) ?? 0.0,
      type: isIncome ? 'gelir' : 'gider',
      category: catName,
      date: parsedDate,
      paymentMethod: paymentMethodLabel,
      description: desc,
      currency: appTrans.currency,
      exchangeRate: appTrans.exchangeRate,
      originalAmount: appTrans.originalAmount,
    );
  }

  /// Firestore'a kaydetmek üzere Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (description != null) 'description': description,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'originalAmount': originalAmount,
      'baseAmount': baseAmount,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? description,
    String? currency,
    double? exchangeRate,
    double? originalAmount,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }
}
