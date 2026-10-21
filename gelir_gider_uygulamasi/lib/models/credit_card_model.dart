class CreditCardModel {
  final String id;
  final String cardName;
  final String bankName;
  final double totalLimit;
  final int cutoffDay;
  final int dueDay;
  final String colorHex;
  final String last4Digits;

  CreditCardModel({
    required this.id,
    required this.cardName,
    required this.bankName,
    required this.totalLimit,
    required this.cutoffDay,
    required this.dueDay,
    this.colorHex = '#1E1B4B',
    this.last4Digits = '5824',
  });

  CreditCardModel copyWith({
    String? id,
    String? cardName,
    String? bankName,
    double? totalLimit,
    int? cutoffDay,
    int? dueDay,
    String? colorHex,
    String? last4Digits,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      totalLimit: totalLimit ?? this.totalLimit,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      dueDay: dueDay ?? this.dueDay,
      colorHex: colorHex ?? this.colorHex,
      last4Digits: last4Digits ?? this.last4Digits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardName': cardName,
      'bankName': bankName,
      'totalLimit': totalLimit,
      'cutoffDay': cutoffDay,
      'dueDay': dueDay,
      'colorHex': colorHex,
      'last4Digits': last4Digits,
    };
  }

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      id: json['id'] as String,
      cardName: json['cardName'] as String? ?? 'Kredi Kartı',
      bankName: json['bankName'] as String? ?? 'Banka',
      totalLimit: (json['totalLimit'] as num?)?.toDouble() ?? 0.0,
      cutoffDay: (json['cutoffDay'] as num?)?.toInt() ?? 15,
      dueDay: (json['dueDay'] as num?)?.toInt() ?? 25,
      colorHex: json['colorHex'] as String? ?? '#1E1B4B',
      last4Digits: json['last4Digits'] as String? ?? '5824',
    );
  }
}
