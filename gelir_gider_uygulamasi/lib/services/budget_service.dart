import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class BudgetService extends GetxService {
  static const String _budgetsStorageKey = "category_budget_limits";

  late StorgeService _storageService;
  final budgets = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorgeService>();
    loadBudgets();
  }

  void loadBudgets() {
    try {
      final jsonString = _storageService.getValue<String>(_budgetsStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final map = <String, double>{};
        decoded.forEach((key, value) {
          final val = double.tryParse(value.toString());
          if (val != null && val > 0) {
            map[key] = val;
          }
        });
        budgets.assignAll(map);
      }
    } catch (e) {
      debugPrint("Bütçe limitleri yüklenirken hata: $e");
    }
  }

  Future<void> _persistBudgets() async {
    try {
      final jsonString = jsonEncode(Map<String, double>.from(budgets));
      await _storageService.setValue<String>(_budgetsStorageKey, jsonString);
    } catch (e) {
      debugPrint("Bütçe limitleri kaydedilirken hata: $e");
    }
  }

  double? getBudget(String categoryId) {
    return budgets[categoryId];
  }

  Future<void> setBudget(String categoryId, double limit) async {
    if (limit <= 0) {
      await removeBudget(categoryId);
      return;
    }
    budgets[categoryId] = limit;
    await _persistBudgets();
  }

  Future<void> removeBudget(String categoryId) async {
    budgets.remove(categoryId);
    await _persistBudgets();
  }

  CategoryBudgetStatus? calculateStatusForCategory({
    required AppCategory category,
    required List<AppTransaction> transactions,
    double additionalAmount = 0.0,
    DateTime? month,
  }) {
    final catId = category.id;
    if (catId == null || catId.isEmpty) return null;

    // Bütçe limiti sadece gider kategorileri için geçerlidir
    final catType = (category.type ?? '').toLowerCase().trim();
    final isExpenseCategory = catType == 'expense' || catType == 'gider';
    if (!isExpenseCategory) return null;

    final limit = getBudget(catId);
    if (limit == null || limit <= 0) return null;

    final targetMonth = month ?? DateTime.now();

    // Seçilen aydaki bu kategoriye ait giderleri topla
    final categoryExpenses = transactions.where((t) {
      final isExpense =
          t.type.toLowerCase() == 'expense' || t.type.toLowerCase() == 'gider';
      if (!isExpense) return false;
      if (t.categoryId != catId) return false;

      final parsedDate = DateTime.tryParse(t.date);
      if (parsedDate == null) return false;

      return parsedDate.year == targetMonth.year &&
          parsedDate.month == targetMonth.month;
    });

    double spent = 0.0;
    for (final tr in categoryExpenses) {
      final cleaned = tr.amount.replaceAll(',', '.').trim();
      final amount = double.tryParse(cleaned) ?? 0.0;
      if (amount.isFinite) {
        spent += amount;
      }
    }

    final effectiveAdditional =
        additionalAmount.isFinite ? additionalAmount : 0.0;
    final totalEffectiveSpent = spent + effectiveAdditional;
    final rawPercentage = (limit > 0) ? (totalEffectiveSpent / limit) * 100.0 : 0.0;
    final percentage = rawPercentage.isFinite ? rawPercentage : 0.0;
    final remaining = (limit - totalEffectiveSpent);

    BudgetStatusLevel level;
    if (percentage > 100.0) {
      level = BudgetStatusLevel.exceeded;
    } else if (percentage >= 80.0) {
      level = BudgetStatusLevel.warning;
    } else {
      level = BudgetStatusLevel.safe;
    }

    return CategoryBudgetStatus(
      category: category,
      limit: limit,
      spent: totalEffectiveSpent,
      remaining: remaining,
      percentage: percentage,
      level: level,
    );
  }

  List<CategoryBudgetStatus> getMonthlyBudgetStatuses({
    required List<AppCategory> categories,
    required List<AppTransaction> transactions,
    DateTime? month,
  }) {
    final result = <CategoryBudgetStatus>[];

    for (final category in categories) {
      final status = calculateStatusForCategory(
        category: category,
        transactions: transactions,
        month: month,
      );
      if (status != null) {
        result.add(status);
      }
    }

    // Harcama oranı en yüksek olanları öne getir (Uyarı ve aşılanlar en başta)
    result.sort((a, b) => b.percentage.compareTo(a.percentage));
    return result;
  }
}
