import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';

enum BudgetStatusLevel {
  safe,
  warning,
  exceeded,
}

class CategoryBudgetStatus {
  final AppCategory category;
  final double limit;
  final double spent;
  final double remaining;
  final double percentage;
  final BudgetStatusLevel level;

  const CategoryBudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.level,
  });

  Color get statusColor {
    switch (level) {
      case BudgetStatusLevel.exceeded:
        return Colors.redAccent;
      case BudgetStatusLevel.warning:
        return Colors.amber.shade700;
      case BudgetStatusLevel.safe:
        return const Color(0xFF2E7D32); // Green
    }
  }

  Color get backgroundColor {
    switch (level) {
      case BudgetStatusLevel.exceeded:
        return Colors.red.withValues(alpha: 0.12);
      case BudgetStatusLevel.warning:
        return Colors.amber.withValues(alpha: 0.12);
      case BudgetStatusLevel.safe:
        return Colors.green.withValues(alpha: 0.12);
    }
  }

  String get statusText {
    switch (level) {
      case BudgetStatusLevel.exceeded:
        return "Bütçe Aşıldı!";
      case BudgetStatusLevel.warning:
        return "Limit Yaklaştı (%${percentage.toStringAsFixed(0)})";
      case BudgetStatusLevel.safe:
        return "%${percentage.toStringAsFixed(0)} Kullanıldı";
    }
  }

  double get progressRatio {
    if (limit <= 0) return 0.0;
    final ratio = spent / limit;
    if (!ratio.isFinite) return 0.0;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isExceeded => level == BudgetStatusLevel.exceeded;
  bool get isWarning => level == BudgetStatusLevel.warning;
}
