class GroupSettlement {
  final String fromParticipantId;
  final String toParticipantId;
  final double amount;
  final bool isPaid;

  const GroupSettlement({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amount,
    this.isPaid = false,
  });

  /// Bu transferi grup içinde benzersiz tanımlayan anahtar
  String get key => '${fromParticipantId}_$toParticipantId';

  GroupSettlement copyWith({
    String? fromParticipantId,
    String? toParticipantId,
    double? amount,
    bool? isPaid,
  }) {
    return GroupSettlement(
      fromParticipantId: fromParticipantId ?? this.fromParticipantId,
      toParticipantId: toParticipantId ?? this.toParticipantId,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  factory GroupSettlement.fromJson(Map<String, dynamic> json) {
    return GroupSettlement(
      fromParticipantId: json['fromParticipantId']?.toString() ?? '',
      toParticipantId: json['toParticipantId']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
      isPaid: json['isPaid'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'fromParticipantId': fromParticipantId,
        'toParticipantId': toParticipantId,
        'amount': amount,
        'isPaid': isPaid,
      };
}
