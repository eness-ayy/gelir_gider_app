import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final String type; // 'gelir' | 'gider'
  final String category;
  final DateTime date;
  final String? paymentMethod;
  final String? description;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.description,
  });

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

    return TransactionModel(
      id: doc.id,
      title: (data['title'] ?? data['description'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: isIncome ? 'gelir' : 'gider',
      category: (data['category'] ?? data['categoryName'] ?? 'Diğer').toString(),
      date: parsedDate,
      paymentMethod: data['paymentMethod']?.toString(),
      description: desc,
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

    return TransactionModel(
      id: appTrans.id,
      title: desc.isNotEmpty ? desc : catName,
      amount: double.tryParse(appTrans.amount) ?? 0.0,
      type: isIncome ? 'gelir' : 'gider',
      category: catName,
      date: parsedDate,
      paymentMethod: appTrans.paymentMethodEnum.title,
      description: desc,
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
    );
  }
}
