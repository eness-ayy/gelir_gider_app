// ignore_for_file: must_call_super
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:get/get.dart';

class FakeTransactionRepository extends TransactionRepostory {
  final List<AppTransaction> mockTransactions;
  FakeTransactionRepository(this.mockTransactions);

  @override
  void onInit() {}

  @override
  Future<List<AppTransaction>> getTransactions() async {
    return mockTransactions;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReportsController controller;
  final now = DateTime.now();

  // Test Verileri:
  // Eğitim: 960 TL (Gider)
  // Ulaşım: 40 TL (Gider)
  // Market: 200 TL (Gider)
  // Maaş: 3000 TL (Gelir)
  // Toplam Gider = 1200 TL.
  // Eğitim oranı: (960 / 1200) * 100 = %80
  // Market oranı: (200 / 1200) * 100 = %16.67
  // Ulaşım oranı: (40 / 1200) * 100 = %3.33
  final tEgitim = AppTransaction(
    id: '1',
    amount: '960.00',
    type: 'expense',
    description: 'Kurs ücreti',
    date: DateTime(now.year, now.month, 2).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_egitim',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Eğitim', icon: 'school', type: 'expense'),
  );

  final tUlasim = AppTransaction(
    id: '2',
    amount: '40.00',
    type: 'expense',
    description: 'Metro bileti',
    date: DateTime(now.year, now.month, 5).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_ulasim',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Ulaşım', icon: 'directions_bus', type: 'expense'),
  );

  final tMarket = AppTransaction(
    id: '3',
    amount: '200.00',
    type: 'expense',
    description: 'Haftalık pazar',
    date: DateTime(now.year, now.month, 8).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_market',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Market', icon: 'shopping_cart', type: 'expense'),
  );

  final tMaas = AppTransaction(
    id: '4',
    amount: '3000.00',
    type: 'income',
    description: 'Aylık maaş',
    date: DateTime(now.year, now.month, 1).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_maas',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Maaş', icon: 'payments', type: 'income'),
  );

  // Önceki aya ait işlem (farklı ay testi için)
  final prevMonthYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final tGecenAy = AppTransaction(
    id: '5',
    amount: '500.00',
    type: 'expense',
    description: 'Geçen ay faturası',
    date: DateTime(prevMonthYear, prevMonth, 15).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_fatura',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Fatura', icon: 'receipt', type: 'expense'),
  );

  setUp(() {
    Get.reset();
    Get.put<TransactionRepostory>(
      FakeTransactionRepository([tEgitim, tUlasim, tMarket, tMaas, tGecenAy]),
    );
    controller = ReportsController();
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('Selected month totals and savings calculations are correct', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.totalIncome, equals(3000.0));
    expect(controller.totalExpense, equals(1200.0));
    expect(controller.netBalance, equals(1800.0));

    // Tasarruf Oranı: (3000 - 1200) / 3000 = %60.0
    expect(controller.savingsRate, equals(60.0));
  });

  test('Category expense breakdown groups and sorts by amount correctly', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final breakdown = controller.expenseCategoriesSummary;
    expect(breakdown.length, equals(3));

    // Sıralama kontrolü (en çok harcanandan en aza)
    expect(breakdown[0].categoryName, equals('Eğitim'));
    expect(breakdown[0].totalAmount, equals(960.0));
    expect(breakdown[0].percentage, closeTo(80.0, 0.1));

    expect(breakdown[1].categoryName, equals('Market'));
    expect(breakdown[1].totalAmount, equals(200.0));
    expect(breakdown[1].percentage, closeTo(16.66, 0.1));

    expect(breakdown[2].categoryName, equals('Ulaşım'));
    expect(breakdown[2].totalAmount, equals(40.0));
    expect(breakdown[2].percentage, closeTo(3.33, 0.1));
  });

  test('Top 3 categories returns exactly up to 3 highest expenses', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final top3 = controller.top3ExpenseCategories;
    expect(top3.length, equals(3));
    expect(top3[0].categoryName, equals('Eğitim'));
    expect(top3[1].categoryName, equals('Market'));
    expect(top3[2].categoryName, equals('Ulaşım'));
  });

  test('Month navigation filters data accurately', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Önceki aya geç
    controller.previousMonth();
    expect(controller.totalExpense, equals(500.0));
    expect(controller.totalIncome, equals(0.0));
    expect(controller.expenseCategoriesSummary.length, equals(1));
    expect(controller.expenseCategoriesSummary.first.categoryName, equals('Fatura'));

    // Tekrar bu aya dön
    controller.nextMonth();
    expect(controller.totalExpense, equals(1200.0));
  });

  test('Last 6 months trend produces 6 chronological points', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final trend = controller.last6MonthsTrend;
    expect(trend.length, equals(6));

    // Son eleman seçili ay olmalı
    final currentMonthData = trend.last;
    expect(currentMonthData.year, equals(now.year));
    expect(currentMonthData.month, equals(now.month));
    expect(currentMonthData.income, equals(3000.0));
    expect(currentMonthData.expense, equals(1200.0));
  });
}
