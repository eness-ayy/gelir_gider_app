import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/set_budget_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/budget_overview_card.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BudgetService budgetService;
  late StorgeService storageService;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    storageService = StorgeService();
    await storageService.init();
    Get.put<StorgeService>(storageService);

    budgetService = Get.put<BudgetService>(BudgetService());
  });

  tearDown(() {
    Get.reset();
  });

  test('setBudget, getBudget and removeBudget work correctly', () async {
    expect(budgetService.getBudget('cat_1'), isNull);

    await budgetService.setBudget('cat_1', 1000.0);
    expect(budgetService.getBudget('cat_1'), equals(1000.0));

    await budgetService.removeBudget('cat_1');
    expect(budgetService.getBudget('cat_1'), isNull);
  });

  test('Category budget level is safe when spending < 80%', () {
    final now = DateTime.now();
    final cat = AppCategory(id: 'cat_ulasim', name: 'Ulaşım', type: 'expense');
    budgetService.budgets['cat_ulasim'] = 1000.0;

    final transactions = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '500.0',
        type: 'expense',
        categoryId: 'cat_ulasim',
        userId: 'user1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: 'Otobüs kartı',
      ),
    ];

    final status = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: transactions,
    );

    expect(status, isNotNull);
    expect(status!.spent, equals(500.0));
    expect(status.remaining, equals(500.0));
    expect(status.percentage, equals(50.0));
    expect(status.level, equals(BudgetStatusLevel.safe));
    expect(status.isExceeded, isFalse);
    expect(status.isWarning, isFalse);
  });

  test('Category budget level is warning (amber) when spending >= 80% and <= 100%', () {
    final now = DateTime.now();
    final cat = AppCategory(id: 'cat_market', name: 'Market', type: 'expense');
    budgetService.budgets['cat_market'] = 1000.0;

    final transactions = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '850.0',
        type: 'expense',
        categoryId: 'cat_market',
        userId: 'user1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: 'Haftalık alışveriş',
      ),
    ];

    final status = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: transactions,
    );

    expect(status, isNotNull);
    expect(status!.spent, equals(850.0));
    expect(status.remaining, equals(150.0));
    expect(status.percentage, equals(85.0));
    expect(status.level, equals(BudgetStatusLevel.warning));
    expect(status.isWarning, isTrue);
    expect(status.isExceeded, isFalse);
    expect(status.statusColor, equals(Colors.amber.shade700));
  });

  test('Category budget level is exceeded (red) when spending > 100%', () {
    final now = DateTime.now();
    final cat = AppCategory(id: 'cat_eglence', name: 'Eğlence', type: 'expense');
    budgetService.budgets['cat_eglence'] = 500.0;

    final transactions = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '600.0',
        type: 'expense',
        categoryId: 'cat_eglence',
        userId: 'user1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: 'Konser bileti',
      ),
    ];

    final status = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: transactions,
    );

    expect(status, isNotNull);
    expect(status!.spent, equals(600.0));
    expect(status.remaining, equals(-100.0));
    expect(status.percentage, equals(120.0));
    expect(status.level, equals(BudgetStatusLevel.exceeded));
    expect(status.isExceeded, isTrue);
    expect(status.statusColor, equals(Colors.redAccent));
  });

  test('additionalAmount simulates live transaction entry correctly', () {
    final now = DateTime.now();
    final cat = AppCategory(id: 'cat_ulasim', name: 'Ulaşım', type: 'expense');
    budgetService.budgets['cat_ulasim'] = 1000.0;

    final existingTransactions = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '750.0',
        type: 'expense',
        categoryId: 'cat_ulasim',
        userId: 'user1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: 'Aylık abonman',
      ),
    ];

    // Henüz 750 TL harcandı (güvenli)
    final initialStatus = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: existingTransactions,
    );
    expect(initialStatus!.level, equals(BudgetStatusLevel.safe));

    // Kullanıcı 100 TL girdiği an %85'e çıkar -> warning
    final warningSimulation = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: existingTransactions,
      additionalAmount: 100.0,
    );
    expect(warningSimulation!.level, equals(BudgetStatusLevel.warning));
    expect(warningSimulation.spent, equals(850.0));

    // Kullanıcı 300 TL girdiği an 1050 TL olur -> exceeded
    final exceedSimulation = budgetService.calculateStatusForCategory(
      category: cat,
      transactions: existingTransactions,
      additionalAmount: 300.0,
    );
    expect(exceedSimulation!.level, equals(BudgetStatusLevel.exceeded));
    expect(exceedSimulation.spent, equals(1050.0));
  });

  test('Budget status is null for income categories', () {
    final now = DateTime.now();
    final catIncome = AppCategory(id: 'cat_maas', name: 'Maaş', type: 'income');
    budgetService.budgets['cat_maas'] = 5000.0;

    final trs = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '5000',
        type: 'income',
        categoryId: 'cat_maas',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
    ];

    final status = budgetService.calculateStatusForCategory(
      category: catIncome,
      transactions: trs,
    );

    expect(status, isNull);
  });

  test('getMonthlyBudgetStatuses sorts by highest spending percentage', () {
    final now = DateTime.now();
    final cat1 = AppCategory(id: 'c1', name: 'Kira', type: 'expense');
    final cat2 = AppCategory(id: 'c2', name: 'Yemek', type: 'expense');
    budgetService.budgets['c1'] = 1000.0;
    budgetService.budgets['c2'] = 1000.0;

    final trs = <AppTransaction>[
      AppTransaction(
        id: '1',
        amount: '200',
        type: 'expense',
        categoryId: 'c1',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
      AppTransaction(
        id: '2',
        amount: '800',
        type: 'expense',
        categoryId: 'c2',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
    ];

    final statuses = budgetService.getMonthlyBudgetStatuses(
      categories: [cat1, cat2],
      transactions: trs,
    );

    expect(statuses.length, equals(2));
    // c2 should come first (80% vs 20%)
    expect(statuses.first.category.id, equals('c2'));
    expect(statuses.first.percentage, equals(80.0));
    expect(statuses.last.category.id, equals('c1'));
    expect(statuses.last.percentage, equals(20.0));
  });

  testWidgets('SetBudgetDialog opens, accepts input and saves without error', (tester) async {
    final cat = AppCategory(id: 'cat_test', name: 'Test Kategori', type: 'expense');

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SetBudgetDialog.show(context, category: cat),
              child: const Text('Bütçe Aç'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Bütçe Aç'));
    await tester.pumpAndSettle();

    expect(find.text('Aylık Bütçe Limiti'), findsOneWidget);
    expect(find.text('Test Kategori'), findsOneWidget);

    // Enter budget limit
    await tester.enterText(find.byType(TextFormField), '1500');
    await tester.pumpAndSettle();

    // Tap Kaydet
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed and budget saved
    expect(find.text('Aylık Bütçe Limiti'), findsNothing);
    expect(budgetService.getBudget('cat_test'), equals(1500.0));
  });

  testWidgets('BudgetOverviewCard displays 2 categories initially and expands downwards when tapped', (tester) async {
    final now = DateTime.now();
    final cat1 = AppCategory(id: 'cat_eglence', name: 'Eğlence', type: 'expense');
    final cat2 = AppCategory(id: 'cat_faturalar', name: 'Faturalar', type: 'expense');
    final cat3 = AppCategory(id: 'cat_market', name: 'Market', type: 'expense');
    await budgetService.setBudget('cat_eglence', 1000.0);
    await budgetService.setBudget('cat_faturalar', 200.0);
    await budgetService.setBudget('cat_market', 300.0);

    final mockController = Get.put<DashboardController>(_MockDashboardController());
    mockController.categories.value = [cat1, cat2, cat3];
    mockController.myTransaction.value = [
      AppTransaction(
        id: '1',
        amount: '500',
        type: 'expense',
        categoryId: 'cat_eglence',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: BudgetOverviewCard(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // İlk 2 kategori görünmeli, 3. kategori gizli olmalı
    expect(find.text('Aylık Bütçe Takibi'), findsOneWidget);
    expect(find.text('Eğlence'), findsOneWidget);
    expect(find.text('Faturalar'), findsOneWidget);
    expect(find.text('Market'), findsNothing);
    expect(find.text('Diğer 1 Kategoriyi Gör'), findsOneWidget);

    // Butona tıklandığında aşağı doğru genişlemeli
    await tester.tap(find.text('Diğer 1 Kategoriyi Gör'));
    await tester.pumpAndSettle();

    // Artık her üç kategori de görünmeli
    expect(find.text('Eğlence'), findsOneWidget);
    expect(find.text('Faturalar'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Daha Az Göster'), findsOneWidget);

    // Tekrar tıklandığında geri daralmalı
    await tester.tap(find.text('Daha Az Göster'));
    await tester.pumpAndSettle();

    expect(find.text('Eğlence'), findsOneWidget);
    expect(find.text('Faturalar'), findsOneWidget);
    expect(find.text('Market'), findsNothing);
    expect(find.text('Diğer 1 Kategoriyi Gör'), findsOneWidget);
  });

  testWidgets('BudgetOverviewCard stays as-is and does not expand if only 1 category exists', (tester) async {
    final now = DateTime.now();
    final cat1 = AppCategory(id: 'cat_eglence', name: 'Eğlence', type: 'expense');
    await budgetService.setBudget('cat_eglence', 1000.0);

    final mockController = Get.put<DashboardController>(_MockDashboardController());
    mockController.categories.value = [cat1];
    mockController.myTransaction.value = [
      AppTransaction(
        id: '1',
        amount: '500',
        type: 'expense',
        categoryId: 'cat_eglence',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: BudgetOverviewCard(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aylık Bütçe Takibi'), findsOneWidget);
    expect(find.text('Eğlence'), findsOneWidget);
    expect(find.text('Diğer 1 Kategoriyi Gör'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

    // Tıklandığında herhangi bir genişleme yapmaz, aynı kalır
    await tester.tap(find.text('Aylık Bütçe Takibi'));
    await tester.pumpAndSettle();

    expect(find.text('Eğlence'), findsOneWidget);
    expect(find.text('Daha Az Göster'), findsNothing);
  });

  testWidgets('BudgetOverviewCard expands inside fixed-height carousel page without errors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final cats = [
      AppCategory(id: 'c1', name: 'Eğlence', type: 'expense'),
      AppCategory(id: 'c2', name: 'Ulaşım', type: 'expense'),
      AppCategory(id: 'c3', name: 'Faturalar', type: 'expense'),
    ];
    await budgetService.setBudget('c1', 1000.0);
    await budgetService.setBudget('c2', 750.0);
    await budgetService.setBudget('c3', 500.0);

    final mockController = Get.put<DashboardController>(_MockDashboardController());
    mockController.categories.value = cats;
    mockController.myTransaction.value = [
      AppTransaction(
        id: '1',
        amount: '500',
        type: 'expense',
        categoryId: 'c1',
        userId: 'u1',
        createdAt: '',
        updatedAt: '',
        date: now.toIso8601String(),
        description: '',
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 280,
              child: PageView(
                children: const [
                  BudgetOverviewCard(
                    fillHeight: true,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diğer 1 Kategoriyi Gör'), findsOneWidget);

    await tester.ensureVisible(find.text('Diğer 1 Kategoriyi Gör'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diğer 1 Kategoriyi Gör'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Daha Az Göster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daha Az Göster'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Diğer 1 Kategoriyi Gör'), findsOneWidget);
  });
}

class _MockDashboardController extends DashboardController {
  @override
  // ignore: must_call_super
  void onInit() {
    // Unit/widget test için repository çağrılarını atla
  }
}

