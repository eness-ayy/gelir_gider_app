import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:get/get.dart';

class CategoryExpenseSummary {
  final String categoryId;
  final String categoryName;
  final String icon;
  final double totalAmount;
  final double percentage;
  final Color color;
  final int transactionCount;

  CategoryExpenseSummary({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.totalAmount,
    required this.percentage,
    required this.color,
    required this.transactionCount,
  });
}

class MonthlyTrendData {
  final String monthLabel;
  final int year;
  final int month;
  final double income;
  final double expense;

  MonthlyTrendData({
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });
}

class ReportsController extends BaseController {
  late final TransactionRepostory _transactionRepository;

  final transactions = <AppTransaction>[].obs;
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final touchedPieIndex = (-1).obs;

  // Modern, göz alıcı ve dengeli renk paleti (Pasta dilimleri için)
  static const List<Color> chartColors = [
    Color(0xFF4361EE), // Kraliyet Mavisi
    Color(0xFFF72585), // Canlı Pembe
    Color(0xFF4CC9F0), // Açık Turkuaz
    Color(0xFFFFB703), // Altın Sarısı
    Color(0xFF7209B7), // Mor
    Color(0xFF06D6A0), // Canlı Yeşil
    Color(0xFFFB8500), // Canlı Turuncu
    Color(0xFF3A0CA3), // Derin İndigo
    Color(0xFFEF476F), // Mercan Kırmızısı
    Color(0xFF118AB2), // Okyanus Mavisi
  ];

  @override
  void onInit() {
    super.onInit();
    _transactionRepository = Get.find<TransactionRepostory>();
    loadData();
  }

  Future<void> loadData() async {
    try {
      setLoading(true);
      final list = await _transactionRepository.getTransactions();
      transactions.value = list;
    } catch (e) {
      showErrorSnackbar(message: "Rapor verileri yüklenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }

  // MARK: - Tarih Navigasyonu
  void previousMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month - 1);
    touchedPieIndex.value = -1;
  }

  void nextMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month + 1);
    touchedPieIndex.value = -1;
  }

  void setMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
    touchedPieIndex.value = -1;
  }

  String get selectedMonthFormatted {
    final dt = selectedMonth.value;
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  // MARK: - Filtrelenmiş Veriler
  List<AppTransaction> get selectedMonthTransactions {
    final target = selectedMonth.value;
    return transactions.where((tr) {
      final pDate = DateTime.tryParse(tr.date);
      if (pDate == null) return false;
      return pDate.year == target.year && pDate.month == target.month;
    }).toList();
  }

  List<AppTransaction> get selectedMonthExpenses {
    return selectedMonthTransactions.where((tr) => tr.type == 'expense').toList();
  }

  List<AppTransaction> get selectedMonthIncomes {
    return selectedMonthTransactions.where((tr) => tr.type == 'income').toList();
  }

  double get totalExpense {
    double sum = 0.0;
    for (var tr in selectedMonthExpenses) {
      sum += double.tryParse(tr.amount) ?? 0.0;
    }
    return sum;
  }

  double get totalIncome {
    double sum = 0.0;
    for (var tr in selectedMonthIncomes) {
      sum += double.tryParse(tr.amount) ?? 0.0;
    }
    return sum;
  }

  double get netBalance => totalIncome - totalExpense;

  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    final rate = ((totalIncome - totalExpense) / totalIncome) * 100;
    return rate;
  }

  // MARK: - Kategori Dağılımı (Pasta / Donut Grafiği İçin)
  List<CategoryExpenseSummary> get expenseCategoriesSummary {
    final expenses = selectedMonthExpenses;
    final total = totalExpense;
    if (expenses.isEmpty || total <= 0) return [];

    final Map<String, List<AppTransaction>> grouped = {};
    for (var tr in expenses) {
      final key = tr.category?.name ?? 'Diğer';
      grouped.putIfAbsent(key, () => []).add(tr);
    }

    final List<CategoryExpenseSummary> list = [];
    int colorIndex = 0;

    grouped.forEach((categoryName, items) {
      double catTotal = 0.0;
      for (var item in items) {
        catTotal += double.tryParse(item.amount) ?? 0.0;
      }

      final percentage = (catTotal / total) * 100;
      final firstItem = items.first;

      list.add(
        CategoryExpenseSummary(
          categoryId: firstItem.categoryId,
          categoryName: categoryName,
          icon: firstItem.category?.icon ?? 'receipt',
          totalAmount: catTotal,
          percentage: percentage,
          color: chartColors[colorIndex % chartColors.length],
          transactionCount: items.length,
        ),
      );

      colorIndex++;
    });

    // En çok harcama yapılandan en aza doğru sırala
    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }

  // En çok harcama yapılan ilk 3 kategori özeti
  List<CategoryExpenseSummary> get top3ExpenseCategories {
    return expenseCategoriesSummary.take(3).toList();
  }

  // MARK: - Son 6 Ay Gelir / Gider Karşılaştırma Trendi (Çubuk Grafiği İçin)
  List<MonthlyTrendData> get last6MonthsTrend {
    const monthNames = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];

    final target = selectedMonth.value;
    final List<MonthlyTrendData> trend = [];

    // Son 6 ayı geriye doğru hesaplayıp kronolojik sıraya koy
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(target.year, target.month - i);
      final year = monthDate.year;
      final month = monthDate.month;

      double income = 0.0;
      double expense = 0.0;

      for (var tr in transactions) {
        final pDate = DateTime.tryParse(tr.date);
        if (pDate != null && pDate.year == year && pDate.month == month) {
          final amt = double.tryParse(tr.amount) ?? 0.0;
          if (tr.type == 'income') {
            income += amt;
          } else {
            expense += amt;
          }
        }
      }

      trend.add(
        MonthlyTrendData(
          monthLabel: monthNames[month - 1],
          year: year,
          month: month,
          income: income,
          expense: expense,
        ),
      );
    }

    return trend;
  }
}
