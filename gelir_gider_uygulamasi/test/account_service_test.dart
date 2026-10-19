// ignore_for_file: must_call_super
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/account_balances_card.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/dashboard_overview_carousel.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/payment_account_selector.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCategoryRepository extends CategoryRepository {
  @override
  void onInit() {}

  @override
  Future<List<AppCategory>> getCategories() async {
    return [
      AppCategory(id: 'cat_1', name: 'Market', icon: 'shopping_cart', type: 'expense'),
      AppCategory(id: 'cat_2', name: 'Maaş', icon: 'payments', type: 'income'),
    ];
  }
}

class MockTransactionRepository extends TransactionRepostory {
  final List<AppTransaction> stored = [];

  @override
  void onInit() {}

  @override
  Future<List<AppTransaction>> getTransactions() async {
    return stored;
  }

  @override
  Future<AppTransaction> createTransaction(Transaction transaction) async {
    final tr = AppTransaction(
      id: 'tr_${stored.length + 1}',
      amount: transaction.amount?.toString() ?? '0',
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? DateTime.now().toIso8601String(),
      userId: 'user_1',
      categoryId: transaction.categoryId ?? 'cat_1',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      paymentMethod: transaction.paymentMethod,
    );
    stored.add(tr);
    return tr;
  }

  @override
  Future<AppTransaction> updateTransaction(String id, Transaction transaction) async {
    final index = stored.indexWhere((t) => t.id == id);
    final updated = AppTransaction(
      id: id,
      amount: transaction.amount?.toString() ?? '0',
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? DateTime.now().toIso8601String(),
      userId: 'user_1',
      categoryId: transaction.categoryId ?? 'cat_1',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      paymentMethod: transaction.paymentMethod,
    );
    if (index != -1) {
      stored[index] = updated;
    }
    return updated;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    stored.removeWhere((t) => t.id == id);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorgeService storageService;
  late AccountService accountService;
  late MockCategoryRepository mockCategoryRepo;
  late MockTransactionRepository mockTransactionRepo;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    storageService = StorgeService();
    await storageService.init();
    Get.put<StorgeService>(storageService);

    accountService = Get.put<AccountService>(AccountService());
    mockCategoryRepo = MockCategoryRepository();
    Get.put<CategoryRepository>(mockCategoryRepo);
    mockTransactionRepo = MockTransactionRepository();
    Get.put<TransactionRepostory>(mockTransactionRepo);
    Get.put<BudgetService>(BudgetService());
  });

  tearDown(() {
    Get.reset();
  });

  group('PaymentMethod enum & helpers', () {
    test('PaymentMethod.fromKey parses turkish and standard keys properly', () {
      expect(PaymentMethod.fromKey('cash'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromKey('nakit'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromKey('cuzdan'), equals(PaymentMethod.cash));

      expect(PaymentMethod.fromKey('bank_card'), equals(PaymentMethod.bankCard));
      expect(PaymentMethod.fromKey('banka'), equals(PaymentMethod.bankCard));
      expect(PaymentMethod.fromKey('banka_karti'), equals(PaymentMethod.bankCard));

      expect(PaymentMethod.fromKey('credit_card'), equals(PaymentMethod.creditCard));
      expect(PaymentMethod.fromKey('kredi'), equals(PaymentMethod.creditCard));
      expect(PaymentMethod.fromKey('kredi_karti'), equals(PaymentMethod.creditCard));

      expect(PaymentMethod.fromKey(null), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromKey('unknown_key'), equals(PaymentMethod.cash));
    });

    test('expenseMethods contains 3 options and incomeMethods contains 2 options', () {
      expect(PaymentMethod.expenseMethods.length, equals(3));
      expect(PaymentMethod.expenseMethods, contains(PaymentMethod.cash));
      expect(PaymentMethod.expenseMethods, contains(PaymentMethod.bankCard));
      expect(PaymentMethod.expenseMethods, contains(PaymentMethod.creditCard));

      expect(PaymentMethod.incomeMethods.length, equals(2));
      expect(PaymentMethod.incomeMethods, contains(PaymentMethod.cash));
      expect(PaymentMethod.incomeMethods, contains(PaymentMethod.bankCard));
      expect(PaymentMethod.incomeMethods, isNot(contains(PaymentMethod.creditCard)));
    });
  });

  group('AccountService storage and calculation', () {
    test('Stores and retrieves transaction payment methods in storage', () async {
      expect(accountService.getPaymentMethod('tr_1'), equals(PaymentMethod.cash));

      await accountService.setPaymentMethod('tr_1', 'bank_card');
      expect(accountService.getPaymentMethod('tr_1'), equals(PaymentMethod.bankCard));

      await accountService.setPaymentMethod('tr_2', 'credit_card');
      expect(accountService.getPaymentMethod('tr_2'), equals(PaymentMethod.creditCard));

      await accountService.removePaymentMethod('tr_1');
      expect(accountService.getPaymentMethod('tr_1'), equals(PaymentMethod.cash));
    });

    test('calculateBalances correctly separates Cash in Pocket vs Money in Bank vs Credit Card', () {
      final transactions = [
        // Nakit gelir: 1000 TL
        AppTransaction(
          id: '1',
          amount: '1000',
          type: 'income',
          description: 'Elden Maaş',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_2',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'cash',
        ),
        // Nakit gider: 250 TL
        AppTransaction(
          id: '2',
          amount: '250',
          type: 'expense',
          description: 'Pazar',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_1',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'cash',
        ),
        // Banka geliri: 15000 TL
        AppTransaction(
          id: '3',
          amount: '15000',
          type: 'income',
          description: 'Banka Maaş',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_2',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'bank_card',
        ),
        // Banka gideri (kart): 3000 TL
        AppTransaction(
          id: '4',
          amount: '3000',
          type: 'expense',
          description: 'Kira',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_1',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'bank_card',
        ),
        // Kredi kartı harcaması: 1200 TL
        AppTransaction(
          id: '5',
          amount: '1200',
          type: 'expense',
          description: 'Elektronik',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_1',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'credit_card',
        ),
      ];

      final balances = accountService.calculateBalances(transactions);

      // Cebimdeki nakit = 1000 - 250 = 750 TL
      expect(balances.cashIncome, equals(1000.0));
      expect(balances.cashExpense, equals(250.0));
      expect(balances.cashBalance, equals(750.0));

      // Bankadaki para = 15000 - 3000 = 12000 TL
      expect(balances.bankIncome, equals(15000.0));
      expect(balances.bankExpense, equals(3000.0));
      expect(balances.bankBalance, equals(12000.0));

      // Kredi kartı harcaması = 1200 TL
      expect(balances.creditCardExpense, equals(1200.0));

      // Toplam hazır likit para = 750 + 12000 = 12750 TL
      expect(balances.totalLiquidAssets, equals(12750.0));
    });
  });

  group('TransactionController payment method logic', () {
    test('Default payment method is cash for expense', () {
      final controller = Get.put(TransactionController());
      expect(controller.selectedPaymentMethod.value, equals(PaymentMethod.cash));
    });

    test('Switching to income automatically switches credit card to bank card', () {
      final controller = Get.put(TransactionController());
      controller.selectedPaymentMethod.value = PaymentMethod.creditCard;

      controller.transactionType.value = 'income';
      expect(controller.selectedPaymentMethod.value, equals(PaymentMethod.bankCard));
    });

    testWidgets('Saving transaction persists selected payment method', (tester) async {
      final controller = Get.put(TransactionController());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: controller.formKey,
              child: TextFormField(
                controller: controller.amountController,
                validator: (v) => null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.amountController.text = '500';
      controller.descriptionController.text = 'Benzin';
      controller.transactionType.value = 'expense';
      controller.selectedCategoryId.value = 'cat_1';
      controller.selectedPaymentMethod.value = PaymentMethod.creditCard;

      await controller.saveTransaction();

      expect(mockTransactionRepo.stored.length, equals(1));
      final saved = mockTransactionRepo.stored.first;
      expect(saved.paymentMethod, equals('credit_card'));
      expect(accountService.getPaymentMethod(saved.id), equals(PaymentMethod.creditCard));
    });
  });

  group('PaymentAccountSelector widget test', () {
    testWidgets('Renders "Hangi hesaptan ödendi?" with 3 options for expense', (tester) async {
      final controller = Get.put(TransactionController());
      controller.transactionType.value = 'expense';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentAccountSelector(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hangi hesaptan ödendi?'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
      expect(find.text('Banka Kartı'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsOneWidget);

      // Tap "Kredi Kartı"
      await tester.tap(find.text('Kredi Kartı'));
      await tester.pumpAndSettle();
      expect(controller.selectedPaymentMethod.value, equals(PaymentMethod.creditCard));

      // Switch to income
      controller.transactionType.value = 'income';
      await tester.pumpAndSettle();

      expect(find.text('Hangi hesaba aktarıldı?'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
      expect(find.text('Banka Kartı'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsNothing);
    });
  });

  group('AccountBalancesCard widget test', () {
    testWidgets('Displays separate balances for Nakit, Banka Kartı and Kredi Kartı', (tester) async {
      mockTransactionRepo.stored.addAll([
        AppTransaction(
          id: '1',
          amount: '800',
          type: 'income',
          description: '',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_2',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'cash',
        ),
        AppTransaction(
          id: '2',
          amount: '5000',
          type: 'income',
          description: '',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_2',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'bank_card',
        ),
        AppTransaction(
          id: '3',
          amount: '450',
          type: 'expense',
          description: '',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_1',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'credit_card',
        ),
      ]);

      final dashboardController = Get.put(DashboardController());
      await dashboardController.getTransactions();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountBalancesCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cüzdan & Hesap Bakiyeleri'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsOneWidget);
      expect(find.textContaining('Toplam Para'), findsOneWidget);

      // Tapping "Nakit" activates account filter
      await tester.tap(find.text('Nakit'));
      await tester.pumpAndSettle();
      expect(dashboardController.selectedAccountFilter.value, equals('cash'));

      // Tapping again clears filter
      await tester.tap(find.text('Nakit'));
      await tester.pumpAndSettle();
      expect(dashboardController.selectedAccountFilter.value, equals('all'));
    });

    testWidgets('AccountBalancesCard renders without overflow on narrow 276px width container', (tester) async {
      tester.view.physicalSize = const Size(356, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockTransactionRepo.stored.add(
        AppTransaction(
          id: '99',
          amount: '2865',
          type: 'income',
          description: '',
          date: '2026-10-18',
          userId: 'u1',
          categoryId: 'cat_2',
          createdAt: '',
          updatedAt: '',
          paymentMethod: 'cash',
        ),
      );

      final dashboardController = Get.put(DashboardController());
      await dashboardController.getTransactions();

      final originalOnError = FlutterError.onError;
      FlutterErrorDetails? caughtDetails;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AccountBalancesCard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(caughtDetails, isNull);
        expect(find.textContaining('Toplam Para'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('DashboardOverviewCarousel displays wallet card initially and swipes to budget overview card', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dashboardController = Get.put(DashboardController());
      await dashboardController.getTransactions();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardOverviewCarousel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // İlk başta Cüzdan & Hesap Bakiyeleri kartı görünmeli
      expect(find.text('Cüzdan & Hesap Bakiyeleri'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);

      // Sola kaydırma (drag left) işlemi yapılarak Aylık Bütçe Takibi sayfasına geçilir
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Artık Aylık Bütçe Takibi kartı görünmeli
      expect(find.text('Aylık Bütçe Takibi'), findsOneWidget);

      // Sağa kaydırma (drag right) işlemi yapılarak tekrar Cüzdan sayfasına dönülür
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Cüzdan & Hesap Bakiyeleri'), findsOneWidget);
    });

    testWidgets('DashboardOverviewCarousel shows ALL budget categories when expanded', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dashboardController = Get.put(DashboardController());
      await dashboardController.getTransactions();
      final names = ['Eğlence', 'Ulaşım', 'Faturalar', 'Market'];
      dashboardController.categories.value = [
        for (var i = 0; i < names.length; i++)
          AppCategory(id: 'b$i', name: names[i], icon: 'receipt', type: 'expense'),
      ];
      final budgetService = Get.find<BudgetService>();
      for (var i = 0; i < names.length; i++) {
        await budgetService.setBudget('b$i', 1000.0 + i);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DashboardOverviewCarousel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Diğer 2 Kategoriyi Gör'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final n in names) {
        expect(find.text(n).hitTestable(), findsOneWidget, reason: '$n görünür olmalı');
      }
      expect(find.text('Daha Az Göster').hitTestable(), findsOneWidget);
    });
  });
}
