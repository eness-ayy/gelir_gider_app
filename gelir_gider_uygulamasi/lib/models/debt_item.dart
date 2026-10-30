class DebtItem {
  final String id;
  final String personName;
  final String type; // 'receivable' (Alacak) veya 'payable' (Borç)
  final double amount;
  final DateTime? dueDate;
  final String? notes;
  final bool isPaid;
  final DateTime? paidDate;
  final String paymentMethod;
  final String? linkedTransactionId;

  DebtItem({
    required this.id,
    required this.personName,
    required this.type,
    required this.amount,
    this.dueDate,
    this.notes,
    this.isPaid = false,
    this.paidDate,
    this.paymentMethod = 'cash',
    this.linkedTransactionId,
  });

  bool get isReceivable => type == 'receivable' || type == 'alacak';

  DebtItem copyWith({
    String? id,
    String? personName,
    String? type,
    double? amount,
    DateTime? dueDate,
    String? notes,
    bool? isPaid,
    DateTime? paidDate,
    String? paymentMethod,
    String? linkedTransactionId,
  }) {
    return DebtItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'type': type,
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'linkedTransactionId': linkedTransactionId,
    };
  }

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['id'] as String,
      personName: json['personName'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      notes: json['notes'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      paidDate: json['paidDate'] != null
          ? DateTime.tryParse(json['paidDate'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      linkedTransactionId: json['linkedTransactionId'] as String?,
    );
  }
}
