import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_settlement.dart';
import 'package:gelir_gider_uygulamasi/models/group/participant.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:get/get.dart';

class GroupDetailController extends BaseController {
  final GroupService _groupService = Get.find<GroupService>();

  late final String groupId;

  // Harcama ekleme / düzenleme form kontrolleri
  final editingExpenseId = RxnString();
  final expenseTitleController = TextEditingController();
  final expenseAmountController = TextEditingController();
  final selectedPayerId = ''.obs;
  final selectedSplitParticipantIds = <String>{}.obs;
  final expenseDate = DateTime.now().obs;
  final selectedPaymentMethod = PaymentMethod.cash.obs;
  final selectedCreditCardId = RxnString();

  String get effectivePaymentMethodKey {
    if (selectedPaymentMethod.value == PaymentMethod.creditCard) {
      String? cardId = selectedCreditCardId.value;
      if ((cardId == null || cardId.isEmpty) &&
          Get.isRegistered<CreditCardService>()) {
        final cards = Get.find<CreditCardService>().cards;
        if (cards.isNotEmpty) {
          cardId = cards.first.id;
        }
      }
      return PaymentMethod.buildCreditCardKey(cardId);
    }
    return selectedPaymentMethod.value.key;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String) {
      groupId = args;
    } else if (args is Map && args['id'] != null) {
      groupId = args['id'].toString();
    } else {
      groupId = '';
    }

    initExpenseForm();
  }

  @override
  void onClose() {
    expenseTitleController.dispose();
    expenseAmountController.dispose();
    super.onClose();
  }

  /// Aktif grup nesnesi
  ExpenseGroup? get group {
    try {
      return _groupService.groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }

  List<Participant> get participants => group?.participants ?? [];
  List<GroupExpense> get expenses => group?.expenses ?? [];
  double get totalExpense => group?.totalExpense ?? 0.0;
  double get userNetBalance => group?.userNetBalance ?? 0.0;
  List<GroupSettlement> get settlements =>
      group?.calculateSettlements() ?? [];

  void initExpenseForm({GroupExpense? expenseToEdit}) {
    if (expenseToEdit != null) {
      editingExpenseId.value = expenseToEdit.id;
      expenseTitleController.text = expenseToEdit.title;
      expenseAmountController.text = expenseToEdit.amount.toStringAsFixed(2);
      expenseDate.value = expenseToEdit.date;
      selectedPayerId.value = expenseToEdit.paidById;
      selectedSplitParticipantIds.assignAll(expenseToEdit.splitParticipantIds);
      selectedPaymentMethod.value =
          PaymentMethod.fromKey(expenseToEdit.paymentMethod);
      selectedCreditCardId.value =
          PaymentMethod.extractCreditCardId(expenseToEdit.paymentMethod);
      return;
    }

    editingExpenseId.value = null;
    expenseTitleController.clear();
    expenseAmountController.clear();
    expenseDate.value = DateTime.now();
    selectedPaymentMethod.value = PaymentMethod.cash;
    selectedCreditCardId.value = null;

    final currentGrp = group;
    if (currentGrp != null && currentGrp.participants.isNotEmpty) {
      // Varsayılan ödeyen: Mevcut kullanıcı (yoksa ilk kişi)
      final me = currentGrp.currentUser;
      selectedPayerId.value = me?.id ?? currentGrp.participants.first.id;

      // Varsayılan paylaşanlar: Tüm katılımcılar
      selectedSplitParticipantIds
          .assignAll(currentGrp.participants.map((p) => p.id));
    }
  }

  void toggleParticipantSplit(String participantId) {
    if (selectedSplitParticipantIds.contains(participantId)) {
      if (selectedSplitParticipantIds.length > 1) {
        selectedSplitParticipantIds.remove(participantId);
      } else {
        showErrorSnackbar(message: "En az bir katılımcı seçili olmalıdır");
      }
    } else {
      selectedSplitParticipantIds.add(participantId);
    }
  }

  void selectAllParticipants() {
    final allIds = participants.map((p) => p.id).toSet();
    selectedSplitParticipantIds.assignAll(allIds);
  }

  Future<void> saveExpense() async {
    final title = expenseTitleController.text.trim();
    if (title.isEmpty) {
      showErrorSnackbar(message: "Lütfen bir harcama başlığı girin");
      return;
    }

    final rawAmount =
        expenseAmountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(rawAmount) ?? 0.0;
    if (amount <= 0) {
      showErrorSnackbar(message: "Lütfen geçerli bir tutar girin");
      return;
    }

    if (selectedPayerId.value.isEmpty) {
      showErrorSnackbar(message: "Lütfen harcamayı yapan kişiyi seçin");
      return;
    }

    if (selectedSplitParticipantIds.isEmpty) {
      showErrorSnackbar(message: "Lütfen harcamayı paylaşacak kişileri seçin");
      return;
    }

    try {
      setLoading(true);
      final editId = editingExpenseId.value;
      if (editId != null && editId.isNotEmpty) {
        await _groupService.updateExpense(
          groupId: groupId,
          expenseId: editId,
          title: title,
          amount: amount,
          paidById: selectedPayerId.value,
          splitParticipantIds: selectedSplitParticipantIds.toList(),
          date: expenseDate.value,
          paymentMethod: effectivePaymentMethodKey,
        );
        Get.back();
        initExpenseForm();
        showSuccessSnackbar(message: "Grup harcaması güncellendi");
      } else {
        await _groupService.addExpense(
          groupId: groupId,
          title: title,
          amount: amount,
          paidById: selectedPayerId.value,
          splitParticipantIds: selectedSplitParticipantIds.toList(),
          date: expenseDate.value,
          paymentMethod: effectivePaymentMethodKey,
        );

        Get.back(); // modal / bottomSheet kapat
        initExpenseForm();
        showSuccessSnackbar(message: "Grup harcaması eklendi");
      }
    } catch (e) {
      showErrorSnackbar(message: "Harcama eklenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _groupService.deleteExpense(groupId, expenseId);
      showSuccessSnackbar(message: "Harcama silindi");
    } catch (e) {
      showErrorSnackbar(message: "Harcama silinirken hata oluştu");
    }
  }

  Future<void> addParticipant(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      await _groupService.addParticipant(groupId, trimmed);
      showSuccessSnackbar(message: "$trimmed gruba eklendi");
    } catch (e) {
      showErrorSnackbar(message: "Katılımcı eklenirken hata oluştu");
    }
  }

  Future<void> toggleSettlementPaid(GroupSettlement settle) async {
    try {
      await _groupService.toggleSettlementPaid(groupId, settle.key);
    } catch (e) {
      showErrorSnackbar(message: "Ödeme durumu güncellenemedi");
    }
  }
}
