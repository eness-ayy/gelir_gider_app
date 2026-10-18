// ignore_for_file: must_call_super
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
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

class FakeCategoryRepository extends CategoryRepository {
  final List<AppCategory> mockCategories;
  FakeCategoryRepository(this.mockCategories);

  @override
  void onInit() {}

  @override
  Future<List<AppCategory>> getCategories() async {
    return mockCategories;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardController controller;
  final now = DateTime.now();

  final t1 = AppTransaction(
    id: '1',
    amount: '1500.00',
    type: 'income',
    description: 'Maaş ödemesi',
    date: DateTime(now.year, now.month, 5).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_income',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Maaş', icon: 'payments', type: 'income'),
  );

  final t2 = AppTransaction(
    id: '2',
    amount: '200.00',
    type: 'expense',
    description: 'Market alışverişi',
    date: DateTime(now.year, now.month, 10).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_market',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Market', icon: 'shopping_cart', type: 'expense'),
  );

  final t3 = AppTransaction(
    id: '3',
    amount: '50.00',
    type: 'expense',
    description: 'Kahve ve tatlı',
    date: DateTime(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      15,
    ).toIso8601String(),
    userId: 'u1',
    categoryId: 'c_cafe',
    createdAt: '',
    updatedAt: '',
    category: Category(name: 'Kafe', icon: 'coffee', type: 'expense'),
  );

  setUp(() {
    Get.reset();
    Get.put<TransactionRepostory>(FakeTransactionRepository([t1, t2, t3]));
    Get.put<CategoryRepository>(FakeCategoryRepository([
      AppCategory(id: 'c_income', name: 'Maaş', type: 'income'),
      AppCategory(id: 'c_market', name: 'Market', type: 'expense'),
      AppCategory(id: 'c_cafe', name: 'Kafe', type: 'expense'),
    ]));

    controller = DashboardController();
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('Initial state has default "this_month" and "all" type', () async {
    // Wait for microtask / async getTransactions to complete
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.selectedType.value, equals('all'));
    expect(controller.selectedDateRange.value, equals('this_month'));
    expect(controller.selectedSort.value, equals('date_desc'));

    // t1 and t2 are in this month, t3 is last month
    expect(controller.filteredTransactions.length, equals(2));
    expect(controller.filteredTransactions.map((t) => t.id), containsAll(['1', '2']));
  });

  test('Filter by type: income only', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.setTypeFilter('income');

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.id, equals('1'));
    expect(result.first.type, equals('income'));
  });

  test('Filter by type: expense only', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.setTypeFilter('expense');

    final result = controller.filteredTransactions;
    expect(result.length, equals(2));
    expect(result.every((t) => t.type == 'expense'), isTrue);
  });

  test('Filter by search query: description', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.searchController.text = 'alışveriş';

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.description, contains('alışveriş'));
  });

  test('Filter by search query with Turkish characters and diacritic tolerance', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');

    // Searching 'maaş' matches 'Maaş ödemesi'
    controller.searchController.text = 'maaş';
    expect(controller.filteredTransactions.length, equals(1));
    expect(controller.filteredTransactions.first.id, equals('1'));

    // Searching 'maas' (without Turkish ş) still matches 'Maaş ödemesi'
    controller.searchController.text = 'maas';
    expect(controller.filteredTransactions.length, equals(1));
    expect(controller.filteredTransactions.first.id, equals('1'));

    // Searching 'alisveris' (without ı and ş) matches 'Market alışverişi'
    controller.searchController.text = 'alisveris';
    expect(controller.filteredTransactions.length, equals(1));
    expect(controller.filteredTransactions.first.id, equals('2'));

    // Searching 'MAAŞ' (uppercase Turkish) matches
    controller.searchController.text = 'MAAŞ';
    expect(controller.filteredTransactions.length, equals(1));
    expect(controller.filteredTransactions.first.id, equals('1'));
  });

  test('Filter by search query: category name', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.searchController.text = 'Kafe';

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.category?.name, equals('Kafe'));
  });

  test('Filter by search query: amount string', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.searchController.text = '1500';

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.id, equals('1'));
  });

  test('Filter by date range: last_month', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('last_month');

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.id, equals('3'));
  });

  test('Filter by category ID', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');
    controller.setCategoryFilter('c_market');

    final result = controller.filteredTransactions;
    expect(result.length, equals(1));
    expect(result.first.categoryId, equals('c_market'));
  });

  test('Sorting: amount_desc and amount_asc', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');

    controller.setSort('amount_desc');
    var result = controller.filteredTransactions;
    expect(result.first.id, equals('1')); // 1500
    expect(result.last.id, equals('3')); // 50

    controller.setSort('amount_asc');
    result = controller.filteredTransactions;
    expect(result.first.id, equals('3')); // 50
    expect(result.last.id, equals('1')); // 1500
  });

  test('Summary totals react to active filters', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.setDateRangeFilter('all');

    // All items: Income: 1500, Expense: 200 + 50 = 250, Balance: 1250
    expect(controller.filteredGelir, equals(1500.0));
    expect(controller.filteredGider, equals(250.0));
    expect(controller.filteredBakiye, equals(1250.0));

    // When filtering by expense only
    controller.setTypeFilter('expense');
    expect(controller.filteredGelir, equals(0.0));
    expect(controller.filteredGider, equals(250.0));
    expect(controller.filteredBakiye, equals(-250.0));
  });

  test('clearFilters resets all filter state', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    controller.searchController.text = 'test';
    controller.setTypeFilter('expense');
    controller.setDateRangeFilter('all');
    controller.setCategoryFilter('c_market');
    controller.setSort('amount_desc');

    expect(controller.hasActiveFilters, isTrue);

    controller.clearFilters();

    expect(controller.searchQuery.value, equals(''));
    expect(controller.searchController.text, equals(''));
    expect(controller.selectedType.value, equals('all'));
    expect(controller.selectedDateRange.value, equals('this_month'));
    expect(controller.selectedCategoryId.value, isNull);
    expect(controller.selectedSort.value, equals('date_desc'));
    expect(controller.hasActiveFilters, isFalse);
  });
}
