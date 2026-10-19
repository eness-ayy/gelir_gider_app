class GroupExpense {
  final String id;
  final String title;
  final double amount;
  final String paidById;
  final DateTime date;
  final List<String> splitParticipantIds;
  final String? paymentMethod; // Kişisel cüzdandan düşerken kullanılan yöntem ('cash', 'bank_card', 'credit_card')
  final String? linkedTransactionId; // Cüzdana eklenen işlemin ID'si

  const GroupExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.date,
    required this.splitParticipantIds,
    this.paymentMethod,
    this.linkedTransactionId,
  });

  /// Kişi başı düşen tutar
  double get perPersonAmount {
    if (splitParticipantIds.isEmpty) return 0.0;
    return amount / splitParticipantIds.length;
  }

  /// Belirli bir katılımcının bu harcamadaki payı
  double shareOf(String participantId) {
    if (splitParticipantIds.contains(participantId)) {
      return perPersonAmount;
    }
    return 0.0;
  }

  GroupExpense copyWith({
    String? id,
    String? title,
    double? amount,
    String? paidById,
    DateTime? date,
    List<String>? splitParticipantIds,
    String? paymentMethod,
    String? linkedTransactionId,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidById: paidById ?? this.paidById,
      date: date ?? this.date,
      splitParticipantIds: splitParticipantIds ?? this.splitParticipantIds,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    return GroupExpense(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
      paidById: json['paidById']?.toString() ?? '',
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      splitParticipantIds: (json['splitParticipantIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      paymentMethod: json['paymentMethod']?.toString(),
      linkedTransactionId: json['linkedTransactionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'paidById': paidById,
        'date': date.toIso8601String(),
        'splitParticipantIds': splitParticipantIds,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (linkedTransactionId != null)
          'linkedTransactionId': linkedTransactionId,
      };
}
