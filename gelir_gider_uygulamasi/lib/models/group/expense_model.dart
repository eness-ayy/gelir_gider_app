import 'package:cloud_firestore/cloud_firestore.dart';

/// Grup içi ortak harcama veri modeli.
class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitMembers;
  final DateTime date;

  final String? paymentMethod;
  final String? linkedTransactionId;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitMembers,
    required this.date,
    this.paymentMethod,
    this.linkedTransactionId,
  });

  /// Kişi başı düşen pay tutarı
  double get perPersonAmount {
    if (splitMembers.isEmpty || !amount.isFinite || amount <= 0) return 0.0;
    return amount / splitMembers.length;
  }

  /// Firestore dokümanına yazılacak veri haritası
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splitMembers': splitMembers,
      'date': Timestamp.fromDate(date),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (linkedTransactionId != null) 'linkedTransactionId': linkedTransactionId,
    };
  }

  /// Map verisinden null-safe ve num -> double dönüşümü garantili model üretimi
  factory ExpenseModel.fromMap(Map<String, dynamic>? map, {String id = ''}) {
    if (map == null) {
      return ExpenseModel(
        id: id,
        title: '',
        amount: 0.0,
        paidBy: '',
        splitMembers: const [],
        date: DateTime.now(),
      );
    }

    // num -> double tip dönüşümünü güvenli şekilde ele al
    final rawAmount = map['amount'];
    double parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }
    if (!parsedAmount.isFinite || parsedAmount < 0) {
      parsedAmount = 0.0;
    }

    // Ortak olan kişilerin listesini güvenli dönüştür
    final rawSplit = map['splitMembers'];
    final List<String> parsedSplitMembers;
    if (rawSplit is List) {
      parsedSplitMembers = rawSplit
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      parsedSplitMembers = const [];
    }

    // Harcama tarihini güvenli dönüştür (Timestamp, String veya int destekler)
    final rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ExpenseModel(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? ''),
      title: map['title']?.toString().trim() ?? '',
      amount: parsedAmount,
      paidBy: map['paidBy']?.toString().trim() ?? '',
      splitMembers: parsedSplitMembers,
      date: parsedDate,
      paymentMethod: map['paymentMethod']?.toString(),
      linkedTransactionId: map['linkedTransactionId']?.toString(),
    );
  }

  /// Firestore DocumentSnapshot üzerinden null-safe model üretimi
  factory ExpenseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return ExpenseModel.fromMap(data, id: snapshot.id);
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? paidBy,
    List<String>? splitMembers,
    DateTime? date,
    String? paymentMethod,
    String? linkedTransactionId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitMembers: splitMembers ?? this.splitMembers,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, title: $title, amount: $amount, paidBy: $paidBy, splitMembers: $splitMembers, date: $date, paymentMethod: $paymentMethod, linkedTransactionId: $linkedTransactionId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.paidBy == paidBy &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, title, amount, paidBy, date);
}
