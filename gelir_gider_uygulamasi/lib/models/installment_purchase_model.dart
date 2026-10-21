class InstallmentPurchaseModel {
  final String id;
  final String cardId;
  final String title;
  final double totalAmount;
  final int totalInstallments;
  final int paidInstallments;
  final DateTime startDate;
  final bool isCompleted;

  InstallmentPurchaseModel({
    required this.id,
    required this.cardId,
    required this.title,
    required this.totalAmount,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.startDate,
    this.isCompleted = false,
  });

  /// Aylık taksit tutarı
  double get monthlyAmount =>
      totalInstallments > 0 ? totalAmount / totalInstallments : 0.0;

  /// Kalan taksit sayısı
  int get remainingInstallments =>
      (totalInstallments - paidInstallments).clamp(0, totalInstallments);

  /// Kalan toplam borç tutarı
  double get remainingAmount => isCompleted ? 0.0 : (monthlyAmount * remainingInstallments);

  /// Ödenme ilerleme oranı (0.0 - 1.0)
  double get progress => totalInstallments > 0
      ? (paidInstallments / totalInstallments).clamp(0.0, 1.0)
      : 1.0;

  InstallmentPurchaseModel copyWith({
    String? id,
    String? cardId,
    String? title,
    double? totalAmount,
    int? totalInstallments,
    int? paidInstallments,
    DateTime? startDate,
    bool? isCompleted,
  }) {
    return InstallmentPurchaseModel(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      startDate: startDate ?? this.startDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'title': title,
      'totalAmount': totalAmount,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'startDate': startDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory InstallmentPurchaseModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPurchaseModel(
      id: json['id'] as String,
      cardId: json['cardId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalInstallments: (json['totalInstallments'] as num?)?.toInt() ?? 1,
      paidInstallments: (json['paidInstallments'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
