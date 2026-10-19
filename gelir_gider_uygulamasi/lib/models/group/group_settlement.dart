class GroupSettlement {
  final String fromParticipantId;
  final String toParticipantId;
  final double amount;

  const GroupSettlement({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amount,
  });

  factory GroupSettlement.fromJson(Map<String, dynamic> json) {
    return GroupSettlement(
      fromParticipantId: json['fromParticipantId']?.toString() ?? '',
      toParticipantId: json['toParticipantId']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromParticipantId': fromParticipantId,
        'toParticipantId': toParticipantId,
        'amount': amount,
      };
}
