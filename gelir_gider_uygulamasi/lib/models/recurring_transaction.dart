class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final String? category;
  final String period; // 'monthly', 'weekly', 'yearly'
  final int paymentDay; // Ödeme günü (1-31)
  final DateTime? startDate;
  final bool isActive;
  final String? notes;
  final String? lastProcessedPeriod;
  final String paymentMethod;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    this.category,
    this.period = 'monthly',
    this.paymentDay = 1,
    this.startDate,
    this.isActive = true,
    this.notes,
    this.lastProcessedPeriod,
    this.paymentMethod = 'bank_card',
  });

  /// Mevcut dönem anahtarı (Örn: "2026-10")
  String get currentPeriodKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Bu ay için cüzdana işlenip işlenmediği
  bool get isPaidThisMonth => lastProcessedPeriod == currentPeriodKey;

  /// Bir sonraki ödeme tarihini hesaplar
  DateTime get nextPaymentDate {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, paymentDay);
    if (next.isBefore(now)) {
      next = DateTime(now.year, now.month + 1, paymentDay);
    }
    return next;
  }

  /// Kalan gün sayısı
  int get daysUntilNextPayment {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      nextPaymentDate.year,
      nextPaymentDate.month,
      nextPaymentDate.day,
    );
    return target.difference(today).inDays;
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? period,
    int? paymentDay,
    DateTime? startDate,
    bool? isActive,
    String? notes,
    String? lastProcessedPeriod,
    String? paymentMethod,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      period: period ?? this.period,
      paymentDay: paymentDay ?? this.paymentDay,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      lastProcessedPeriod: lastProcessedPeriod ?? this.lastProcessedPeriod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'period': period,
      'paymentDay': paymentDay,
      'startDate': startDate?.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'lastProcessedPeriod': lastProcessedPeriod,
      'paymentMethod': paymentMethod,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String?,
      period: json['period'] as String? ?? 'monthly',
      paymentDay: json['paymentDay'] as int? ?? 1,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      lastProcessedPeriod: json['lastProcessedPeriod'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'bank_card',
    );
  }
}
