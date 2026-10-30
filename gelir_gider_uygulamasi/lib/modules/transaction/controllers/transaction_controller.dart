import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/services/currency_service.dart';
import 'package:gelir_gider_uygulamasi/services/notification_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class TransactionController extends BaseController {
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final TransactionRepostory _transactionRepostory =
      Get.find<TransactionRepostory>();
  AccountService get _accountService => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>()
      : Get.put(AccountService());

  final categories = <AppCategory>[].obs;
  final selectedCategoryId = "".obs;
  final transactionType = "expense".obs;
  final selectedPaymentMethod = PaymentMethod.cash.obs;
  final selectedCreditCardId = RxnString();
  final formKey = GlobalKey<FormState>();

  String get effectivePaymentMethodKey =>
      selectedPaymentMethod.value == PaymentMethod.creditCard
          ? PaymentMethod.buildCreditCardKey(selectedCreditCardId.value)
          : selectedPaymentMethod.value.key;
  final date = DateTime.now().obs;

  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  final enteredAmount = 0.0.obs;

  // MARK: - Çoklu Para Birimi
  final selectedCurrency = AppCurrency.tryCurrency.obs;
  late final TextEditingController rateController;

  /// 1 birim = X TRY (TRY için her zaman 1.0)
  final exchangeRate = 1.0.obs;

  bool get isForeignCurrency => !selectedCurrency.value.isBase;

  /// Girilen tutarın anlık TRY karşılığı (önizleme + bütçe kontrolü)
  double get enteredBaseAmount => isForeignCurrency
      ? CurrencyHelper.toBase(enteredAmount.value, exchangeRate.value)
      : enteredAmount.value;

  static String _lastRateKey(AppCurrency c) => 'last_exchange_rate_${c.code}';

  StorgeService? get _storage =>
      Get.isRegistered<StorgeService>() ? Get.find<StorgeService>() : null;

  final isEditing = false.obs;
  String? editingTransactionId;
  String? _editingCategoryHint;

  /// Kullanıcı kuru elle mi değiştirdi yoksa canlı piyasa kuru mu?
  final isManualRate = false.obs;

  /// Kart içindeki kur düzenleme panelinin açık/kapalı durumu
  final isRateEditingExpanded = false.obs;

  /// Tür karşılaştırma yardımcısı (expense/gider ve income/gelir eşleşmesi)
  bool isTypeMatch(String? catType, String selectedType) {
    if (catType == null) return false;
    final c = catType.toLowerCase().trim();
    final s = selectedType.toLowerCase().trim();
    final isCatExpense = c == 'expense' || c == 'gider';
    final isSelExpense = s == 'expense' || s == 'gider';
    return isCatExpense == isSelExpense;
  }

  @override
  void onInit() {
    super.onInit();
    amountController = TextEditingController();
    descriptionController = TextEditingController();
    rateController = TextEditingController();

    amountController.addListener(() {
      enteredAmount.value =
          CurrencyHelper.parseInput(amountController.text) ?? 0.0;
    });

    rateController.addListener(() {
      if (!isForeignCurrency) return;
      exchangeRate.value = CurrencyHelper.parseInput(rateController.text) ?? 0.0;
    });

    // Düzenleme modu kontrolü
    if (Get.arguments != null && Get.arguments is AppTransaction) {
      final tr = Get.arguments as AppTransaction;
      isEditing.value = true;
      editingTransactionId = tr.id;
      // Döviz/altın işlemlerinde kullanıcının girdiği orijinal tutarı göster
      amountController.text = _formatInput(tr.originalAmountValue);
      selectedCurrency.value = tr.currencyEnum;
      if (tr.isForeignCurrency) {
        exchangeRate.value = tr.exchangeRate;
        rateController.text = _formatInput(tr.exchangeRate);
      }
      final rawDesc = tr.description.trim();
      descriptionController.text =
          (rawDesc == 'Gelir İşlemi' || rawDesc == 'Gider İşlemi')
              ? ''
              : rawDesc;
      transactionType.value = tr.type.isNotEmpty ? tr.type : "expense";
      selectedCategoryId.value = tr.categoryId;
      _editingCategoryHint = tr.category?.name ?? tr.categoryId;
      if (tr.paymentMethod != null && tr.paymentMethod!.isNotEmpty) {
        selectedPaymentMethod.value = PaymentMethod.fromKey(tr.paymentMethod);
        selectedCreditCardId.value =
            PaymentMethod.extractCreditCardId(tr.paymentMethod);
      } else {
        final savedMethodKey = _accountService.transactionPaymentMethods[tr.id];
        selectedPaymentMethod.value = _accountService.getPaymentMethod(tr.id);
        selectedCreditCardId.value =
            PaymentMethod.extractCreditCardId(savedMethodKey);
      }
      final parsedDate = DateTime.tryParse(tr.date);
      if (parsedDate != null) {
        date.value = parsedDate;
      }
    }

    loadCategories();

    // Tür (expense/income) değiştiğinde:
    ever(transactionType, (type) {
      final list = categories.where((c) => isTypeMatch(c.type, type)).toList();
      if (list.isNotEmpty) {
        final isValid = list.any((c) => c.id == selectedCategoryId.value);
        if (!isValid && list.first.id != null) {
          selectedCategoryId.value = list.first.id!;
        }
      } else {
        selectedCategoryId.value = "";
      }

      // Gelir türünde kredi kartı geçerli olmadığı için Banka Kartı'na geç
      if (type == 'income' && selectedPaymentMethod.value == PaymentMethod.creditCard) {
        selectedPaymentMethod.value = PaymentMethod.bankCard;
      }
    });
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    super.onClose();
  }

  /// Input alanına yazılacak sayıyı sade biçimde döndürür (100.0 → "100")
  String _formatInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  CurrencyService get currencyService => Get.isRegistered<CurrencyService>()
      ? Get.find<CurrencyService>()
      : Get.put(CurrencyService());

  /// Para birimi seçimi. TRY dışı birim seçildiğinde canlı kur otomatik doldurulur.
  void selectCurrency(AppCurrency currency) {
    if (selectedCurrency.value == currency) return;
    selectedCurrency.value = currency;
    isRateEditingExpanded.value = false;
    isManualRate.value = false;

    if (currency.isBase) {
      exchangeRate.value = 1.0;
      rateController.clear();
      return;
    }

    // Canlı / önbellekteki güncel kuru otomatik doldur
    final liveRate = currencyService.getRate(currency);
    rateController.text = _formatInput(liveRate);
    exchangeRate.value = liveRate;
  }

  /// Canlı kuru yeniden çekip kutuyu günceller
  Future<void> refreshLiveRate() async {
    if (!isForeignCurrency) return;
    await currencyService.fetchRates(force: true);
    final rate = currencyService.getRate(selectedCurrency.value);
    rateController.text = _formatInput(rate);
    exchangeRate.value = rate;
    isManualRate.value = false;
  }

  /// Kuru tekrar canlı piyasa kuruna sıfırlar
  void resetToLiveRate() {
    if (!isForeignCurrency) return;
    final live = currencyService.getRate(selectedCurrency.value);
    rateController.text = _formatInput(live);
    exchangeRate.value = live;
    isManualRate.value = false;
    isRateEditingExpanded.value = false;
  }

  /// Kur düzenleme alanını aç/kapat
  void toggleRateEditing() {
    isRateEditingExpanded.value = !isRateEditingExpanded.value;
  }

  /// Kur alanı doğrulaması (yalnızca TRY dışı birimlerde)
  String? validateRate(String? value) {
    if (!isForeignCurrency) return null;
    final parsed = CurrencyHelper.parseInput(value);
    if (parsed == null || parsed <= 0) {
      return "Lütfen geçerli bir kur giriniz";
    }
    return null;
  }

  Future<void> loadCategories() async {
    setLoading(true);
    try {
      final result = await _categoryRepository.getCategories();
      categories.value = result;

      // Kategori seçili değilse veya isimle kaydedilmişse önce isimle eşleştirmeyi dene
      bool isValidSelection = categories.any(
        (c) =>
            c.id == selectedCategoryId.value &&
            isTypeMatch(c.type, transactionType.value),
      );
      if (!isValidSelection &&
          (_editingCategoryHint != null ||
              selectedCategoryId.value.isNotEmpty)) {
        final targetName =
            (_editingCategoryHint ?? selectedCategoryId.value)
                .trim()
                .toLowerCase();
        final matchedByName = categories.firstWhereOrNull(
          (c) =>
              isTypeMatch(c.type, transactionType.value) &&
              (c.name?.trim().toLowerCase() == targetName ||
                  c.id?.trim().toLowerCase() == targetName),
        );
        if (matchedByName?.id != null) {
          selectedCategoryId.value = matchedByName!.id!;
          isValidSelection = true;
        }
      }
      if (!isValidSelection) {
        final list = categories
            .where((c) => isTypeMatch(c.type, transactionType.value))
            .toList();
        if (list.isNotEmpty && list.first.id != null) {
          selectedCategoryId.value = list.first.id!;
        } else if (CategoryRepository.defaultCategories.isNotEmpty) {
          final def = CategoryRepository.defaultCategories.firstWhere(
            (c) => isTypeMatch(c.type, transactionType.value),
            orElse: () => CategoryRepository.defaultCategories.first,
          );
          selectedCategoryId.value = def.id ?? 'def_1';
        }
      }
    } catch (e) {
      debugPrint("[TRANSACTION_CONTROLLER] Kategoriler yüklenirken hata: $e");
      // Hata durumunda varsayılanları ata
      categories.value = CategoryRepository.defaultCategories;
      final def = categories.firstWhereOrNull(
        (c) => isTypeMatch(c.type, transactionType.value),
      );
      if (def?.id != null) selectedCategoryId.value = def!.id!;
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveTransaction() async {
    if (isLoading) return;

    // 1. Kategori kontrolü: Eğer kategori seçili değilse otomatik ilk uygun kategoriyi ata
    if (selectedCategoryId.value.isEmpty) {
      final available = categories.where(
        (c) => isTypeMatch(c.type, transactionType.value),
      ).toList();

      if (available.isNotEmpty && available.first.id != null) {
        selectedCategoryId.value = available.first.id!;
      } else {
        selectedCategoryId.value = "Diğer";
      }
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      debugPrint("[TRANSACTION_CONTROLLER] Form validasyonu başarısız oldu.");
      return;
    }

    final double amountValue =
        CurrencyHelper.parseInput(amountController.text) ?? 0.0;

    if (amountValue <= 0) {
      showErrorSnackbar(message: "Lütfen 0'dan büyük geçerli bir tutar giriniz.");
      return;
    }

    final currency = selectedCurrency.value;
    final double rate = currency.isBase
        ? 1.0
        : (CurrencyHelper.parseInput(rateController.text) ?? 0.0);

    if (rate <= 0) {
      showErrorSnackbar(message: "Lütfen ${currency.name} için geçerli bir kur giriniz.");
      return;
    }

    // Hesaplamalarda kullanılacak TRY karşılığı
    final double baseAmount = currency.isBase
        ? amountValue
        : CurrencyHelper.toBase(amountValue, rate);

    try {
      setLoading(true);
      // Seçili kategori adını ve ikonunu tespit et
      final selectedCat = categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value) ??
          CategoryRepository.defaultCategories.firstWhereOrNull((c) => c.id == selectedCategoryId.value);

      final String finalCatName = (selectedCat?.name != null && selectedCat!.name!.trim().isNotEmpty)
          ? selectedCat.name!.trim()
          : (transactionType.value == 'income' ? 'Diğer Gelir' : 'Diğer Gider');

      final String finalCatIcon = (selectedCat?.icon != null && selectedCat!.icon!.trim().isNotEmpty)
          ? selectedCat.icon!.trim()
          : 'category';

      final paymentKey = effectivePaymentMethodKey;

      final transaction = Transaction(
        id: editingTransactionId ?? '',
        amount: baseAmount,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : (transactionType.value == 'income' ? 'Gelir İşlemi' : 'Gider İşlemi'),
        type: transactionType.value,
        date: date.value.toIso8601String(),
        categoryId: selectedCategoryId.value,
        categoryName: finalCatName,
        categoryIcon: finalCatIcon,
        userId: '',
        paymentMethod: paymentKey,
        currency: currency.code,
        exchangeRate: rate,
        originalAmount: amountValue,
      );

      // Bir sonraki girişte önermek için son kuru sakla
      if (!currency.isBase) {
        await _storage?.setValue<double>(_lastRateKey(currency), rate);
      }

      final wasEditing = isEditing.value;

      if (wasEditing && (editingTransactionId?.isNotEmpty ?? false)) {
        await _transactionRepostory.updateTransaction(
          editingTransactionId!,
          transaction,
        );
        await _accountService.setPaymentMethod(
          editingTransactionId!,
          paymentKey,
        );
      } else {
        final created = await _transactionRepostory.createTransaction(transaction);
        final targetId = created.id.isNotEmpty ? created.id : (editingTransactionId ?? '');
        if (targetId.isNotEmpty) {
          await _accountService.setPaymentMethod(
            targetId,
            paymentKey,
          );
        }
      }

      // Bütçe aşımı veya uyarısı kontrolü (Form sıfırlanmadan önce hesaplanır)
      final budgetAlert = liveBudgetStatus;
      final isExpenseType = transactionType.value.toLowerCase() == 'expense';

      // Formu sıfırla
      clearForm();

      // HomeController'da Cüzdan sekmesini (index 0) seç
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().currentIndex.value = 0;
      }

      if (isExpenseType &&
          budgetAlert != null &&
          budgetAlert.level != BudgetStatusLevel.safe &&
          Get.isRegistered<NotificationService>()) {
        final String catDisplayName = (budgetAlert.category.name != null &&
                budgetAlert.category.name!.trim().isNotEmpty)
            ? budgetAlert.category.name!.trim()
            : finalCatName;

        Get.find<NotificationService>().showBudgetAlertNotification(
          categoryName: catDisplayName,
          spentPercent: budgetAlert.percentage,
          limit: budgetAlert.limit,
          currentSpent: budgetAlert.spent,
        );
      }

      // Cüzdan verilerini tazele
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().refreshDashboard();
      }

      // Sayfayı kapatıp Cüzdan sekmesine dön
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      } else {
        Get.offAllNamed(AppRoutes.home);
      }

      showSuccessSnackbar(
        message: wasEditing
            ? "İşlem başarıyla güncellendi"
            : "İşlem başarıyla kaydedildi",
      );
    } catch (e) {
      debugPrint("[TRANSACTION_CONTROLLER HATA] İşlem kaydedilirken hata oluştu: $e");
      showErrorSnackbar(
        message: isEditing.value
            ? "İşlem güncellenirken hata oluştu: $e"
            : "İşlem eklenirken hata oluştu: $e",
      );
    } finally {
      setLoading(false);
    }
  }

  // Geriye dönük uyumluluk
  Future<void> createTransaction() async {
    await saveTransaction();
  }

  void onCategoryAdded(AppCategory newCategory) {
    categories.add(newCategory);
    if (isTypeMatch(newCategory.type, transactionType.value) &&
        (newCategory.id?.isNotEmpty ?? false)) {
      selectedCategoryId.value = newCategory.id!;
    }
  }

  void clearForm() {
    amountController.clear();
    descriptionController.clear();
    date.value = DateTime.now();
    transactionType.value = "expense";
    selectedPaymentMethod.value = PaymentMethod.cash;
    selectedCreditCardId.value = null;
    selectedCategoryId.value = "";
    enteredAmount.value = 0.0;
    selectedCurrency.value = AppCurrency.tryCurrency;
    exchangeRate.value = 1.0;
    rateController.clear();
    isManualRate.value = false;
    isRateEditingExpanded.value = false;
    isEditing.value = false;
    editingTransactionId = null;
  }

  CategoryBudgetStatus? get liveBudgetStatus {
    final type = transactionType.value.toLowerCase();
    final isExpense = type == 'expense' || type == 'gider';
    if (!isExpense) return null;
    if (selectedCategoryId.value.isEmpty) return null;
    if (!Get.isRegistered<BudgetService>()) return null;

    final cat = categories.firstWhereOrNull(
      (c) => c.id == selectedCategoryId.value,
    );
    if (cat == null) return null;

    final budgetService = Get.find<BudgetService>();
    final allTrs = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>().myTransaction
        : <AppTransaction>[];

    return budgetService.calculateStatusForCategory(
      category: cat,
      transactions: allTrs,
      additionalAmount: enteredBaseAmount,
    );
  }
}
