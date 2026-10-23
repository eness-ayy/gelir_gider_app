import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
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
  final formKey = GlobalKey<FormState>();
  final date = DateTime.now().obs;

  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  final enteredAmount = 0.0.obs;

  final isEditing = false.obs;
  String? editingTransactionId;

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

    amountController.addListener(() {
      final text = amountController.text.replaceAll(',', '.').trim();
      enteredAmount.value = double.tryParse(text) ?? 0.0;
    });

    // Düzenleme modu kontrolü
    if (Get.arguments != null && Get.arguments is AppTransaction) {
      final tr = Get.arguments as AppTransaction;
      isEditing.value = true;
      editingTransactionId = tr.id;
      amountController.text = tr.amount;
      descriptionController.text = tr.description;
      transactionType.value = tr.type.isNotEmpty ? tr.type : "expense";
      selectedCategoryId.value = tr.categoryId;
      if (tr.paymentMethod != null && tr.paymentMethod!.isNotEmpty) {
        selectedPaymentMethod.value = PaymentMethod.fromKey(tr.paymentMethod);
      } else {
        selectedPaymentMethod.value = _accountService.getPaymentMethod(tr.id);
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
    super.onClose();
  }

  Future<void> loadCategories() async {
    setLoading(true);
    try {
      final result = await _categoryRepository.getCategories();
      categories.value = result;

      // Kategori seçili değilse veya geçersizleştiyse türe ait ilk kategoriyi seç
      final isValidSelection = categories.any(
        (c) => c.id == selectedCategoryId.value && isTypeMatch(c.type, transactionType.value),
      );
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

    final double amountValue = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    ) ?? 0.0;

    if (amountValue <= 0) {
      showErrorSnackbar(message: "Lütfen 0'dan büyük geçerli bir tutar giriniz.");
      return;
    }

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

      final transaction = Transaction(
        id: editingTransactionId ?? '',
        amount: amountValue,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : (transactionType.value == 'income' ? 'Gelir İşlemi' : 'Gider İşlemi'),
        type: transactionType.value,
        date: date.value.toIso8601String(),
        categoryId: selectedCategoryId.value,
        categoryName: finalCatName,
        categoryIcon: finalCatIcon,
        userId: '',
        paymentMethod: selectedPaymentMethod.value.key,
      );

      final wasEditing = isEditing.value;

      if (wasEditing && (editingTransactionId?.isNotEmpty ?? false)) {
        await _transactionRepostory.updateTransaction(
          editingTransactionId!,
          transaction,
        );
        await _accountService.setPaymentMethod(
          editingTransactionId!,
          selectedPaymentMethod.value.key,
        );
      } else {
        final created = await _transactionRepostory.createTransaction(transaction);
        final targetId = created.id.isNotEmpty ? created.id : (editingTransactionId ?? '');
        if (targetId.isNotEmpty) {
          await _accountService.setPaymentMethod(
            targetId,
            selectedPaymentMethod.value.key,
          );
        }
      }

      // Formu sıfırla
      clearForm();

      // HomeController'da Cüzdan sekmesini (index 0) seç
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().currentIndex.value = 0;
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
    selectedCategoryId.value = "";
    enteredAmount.value = 0.0;
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
      additionalAmount: enteredAmount.value,
    );
  }
}
