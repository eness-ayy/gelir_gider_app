import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
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
      final list = categories.where((c) => c.type == type).toList();
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
        (c) => c.id == selectedCategoryId.value && c.type == transactionType.value,
      );
      if (!isValidSelection) {
        final list = categories
            .where((c) => c.type == transactionType.value)
            .toList();
        if (list.isNotEmpty && list.first.id != null) {
          selectedCategoryId.value = list.first.id!;
        } else {
          selectedCategoryId.value = "";
        }
      }
    } catch (e) {
      showErrorSnackbar(message: e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveTransaction() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      setLoading(true);
      final double amountValue = double.tryParse(amountController.text) ?? 0.0;
      final transaction = Transaction(
        id: editingTransactionId ?? '',
        amount: amountValue,
        description: descriptionController.text.trim(),
        type: transactionType.value,
        date: date.value.toIso8601String(),
        categoryId: selectedCategoryId.value,
        userId: '',
        paymentMethod: selectedPaymentMethod.value.key,
      );

      if (isEditing.value && (editingTransactionId?.isNotEmpty ?? false)) {
        await _transactionRepostory.updateTransaction(
          editingTransactionId!,
          transaction,
        );
        await _accountService.setPaymentMethod(
          editingTransactionId!,
          selectedPaymentMethod.value.key,
        );
        showSuccessSnackbar(message: "İşlem başarıyla güncellendi");
      } else {
        final created = await _transactionRepostory.createTransaction(transaction);
        final targetId = created.id.isNotEmpty ? created.id : (editingTransactionId ?? '');
        if (targetId.isNotEmpty) {
          await _accountService.setPaymentMethod(
            targetId,
            selectedPaymentMethod.value.key,
          );
        }
        showSuccessSnackbar(message: "İşlem başarıyla oluşturuldu");
      }

      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      clearForm();
    } catch (e) {
      showErrorSnackbar(
        message: isEditing.value
            ? "İşlem güncellenirken hata oluştu"
            : "İşlem eklenirken hata oluştu",
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
    if (newCategory.type == transactionType.value &&
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
