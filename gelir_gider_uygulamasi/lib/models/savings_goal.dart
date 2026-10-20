class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final String? category;
  final int? colorValue;
  final bool isCompleted;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.targetDate,
    this.category,
    this.colorValue,
    this.isCompleted = false,
  });

  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    final rem = targetAmount - savedAmount;
    return rem > 0 ? rem : 0.0;
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    String? category,
    int? colorValue,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate?.toIso8601String(),
      'category': category,
      'colorValue': colorValue,
      'isCompleted': isCompleted,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      category: json['category'] as String?,
      colorValue: json['colorValue'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
