import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/participant.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class GroupService extends GetxService {
  static const String _storageKey = 'expense_groups_v1';

  StorgeService get _storageService => Get.isRegistered<StorgeService>()
      ? Get.find<StorgeService>()
      : Get.put(StorgeService());

  TransactionRepostory get _transactionRepository =>
      Get.isRegistered<TransactionRepostory>()
      ? Get.find<TransactionRepostory>()
      : Get.put(TransactionRepostory());

  CategoryRepository get _categoryRepository =>
      Get.isRegistered<CategoryRepository>()
      ? Get.find<CategoryRepository>()
      : Get.put(CategoryRepository());

  AccountService get _accountService => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>()
      : Get.put(AccountService());

  final groups = <ExpenseGroup>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  /// Yerel hafızadan grupları yükler
  void loadGroups() {
    try {
      final jsonString = _storageService.getValue<String>(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final list = decoded
            .map((item) => ExpenseGroup.fromJson(item as Map<String, dynamic>))
            .where((g) => g.id != 'sample_group_1')
            .toList();
        groups.assignAll(list);
      } else {
        groups.clear();
      }
    } catch (e) {
      debugPrint("Grup verileri yüklenirken hata: $e");
      groups.clear();
    }
  }

  Future<void> restoreGroups(List<ExpenseGroup> newGroups) async {
    groups.assignAll(newGroups);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final listMap = groups.map((g) => g.toJson()).toList();
      await _storageService.setValue<String>(_storageKey, jsonEncode(listMap));
    } catch (e) {
      debugPrint("Grup verileri kaydedilirken hata: $e");
    }
  }

  String _getCurrentUserName() {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      if (user != null &&
          user.first_name != null &&
          user.first_name!.trim().isNotEmpty) {
        return user.first_name!.trim();
      }
    }
    return 'Ben';
  }

  /// Yeni grup oluştur
  Future<ExpenseGroup> createGroup({
    required String title,
    required List<String> participantNames,
    String? icon,
  }) async {
    final currentUserName = _getCurrentUserName();
    final participants = <Participant>[
      Participant(
        id: 'me_${DateTime.now().millisecondsSinceEpoch}',
        name: currentUserName,
        isCurrentUser: true,
      ),
    ];

    for (var i = 0; i < participantNames.length; i++) {
      final name = participantNames[i].trim();
      if (name.isNotEmpty) {
        participants.add(
          Participant(
            id: 'p_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            isCurrentUser: false,
          ),
        );
      }
    }

    final newGroup = ExpenseGroup(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      participants: participants,
      expenses: [],
      createdAt: DateTime.now(),
      icon: icon,
    );

    groups.insert(0, newGroup);
    await _persist();
    return newGroup;
  }

  /// Grubu sil
  Future<bool> deleteGroup(String groupId) async {
    groups.removeWhere((g) => g.id == groupId);
    await _persist();
    return true;
  }

  /// Gruba yeni katılımcı ekle
  Future<bool> addParticipant(String groupId, String name) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return false;

    final group = groups[index];
    final newParticipant = Participant(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      isCurrentUser: false,
    );

    final updatedParticipants = List<Participant>.from(group.participants)
      ..add(newParticipant);

    groups[index] = group.copyWith(participants: updatedParticipants);
    await _persist();
    return true;
  }

  /// Gruba harcama ekle
  /// Entegrasyon Kuralı:
  /// - Parayı kullanıcı ödediyse (isCurrentUser == true):
  ///   Ana cüzdandan TÜM tutar düşer (Transaction eklenir).
  /// - Parayı başkası ödediyse:
  ///   Cüzdana dokunulmaz, sadece grupta borç olarak kaydedilir.
  Future<GroupExpense> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidById,
    required List<String> splitParticipantIds,
    DateTime? date,
    String? paymentMethod = 'cash',
  }) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      throw Exception("Grup bulunamadı");
    }

    final group = groups[index];
    final payer = group.findParticipant(paidById);
    final isPayerCurrentUser = payer?.isCurrentUser ?? false;

    String? linkedTxId;

    // KURAL: Eğer parayı kullanıcı ödediyse, ana cüzdandan sadece kullanıcının kendi payına düşen tutarı düş
    if (isPayerCurrentUser) {
      try {
        final splitCount = splitParticipantIds.isEmpty
            ? 1
            : splitParticipantIds.length;
        final userShareAmount = double.parse(
          (amount / splitCount).toStringAsFixed(2),
        );
        linkedTxId = await _createWalletTransactionForExpense(
          groupTitle: group.title,
          expenseTitle: title,
          userShareAmount: userShareAmount,
          totalAmount: amount,
          paymentMethod: paymentMethod ?? 'cash',
          date: date ?? DateTime.now(),
        );
      } catch (e) {
        debugPrint(
          "Cüzdana işlem eklenirken hata (grup içi yine de eklenecek): $e",
        );
      }
    }

    final newExpense = GroupExpense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      amount: amount,
      paidById: paidById,
      date: date ?? DateTime.now(),
      splitParticipantIds: splitParticipantIds,
      paymentMethod: paymentMethod,
      linkedTransactionId: linkedTxId,
    );

    final updatedExpenses = List<GroupExpense>.from(group.expenses)
      ..insert(0, newExpense);

    groups[index] = group.copyWith(expenses: updatedExpenses);
    await _persist();
    return newExpense;
  }

  /// Harcamayı sil (eğer cüzdana bağlı işlem varsa cüzdandan da silinir)
  Future<bool> deleteExpense(String groupId, String expenseId) async {
    final gIndex = groups.indexWhere((g) => g.id == groupId);
    if (gIndex == -1) return false;

    final group = groups[gIndex];
    final expIndex = group.expenses.indexWhere((e) => e.id == expenseId);
    if (expIndex == -1) return false;

    final expense = group.expenses[expIndex];

    // Cüzdandaki bağlı işlemi sil
    if (expense.linkedTransactionId != null &&
        expense.linkedTransactionId!.isNotEmpty) {
      try {
        await _transactionRepository.deleteTransaction(
          expense.linkedTransactionId!,
        );
        await _accountService.removePaymentMethod(expense.linkedTransactionId!);
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshDashboard();
        }
      } catch (e) {
        debugPrint("Bağlı cüzdan işlemi silinirken hata: $e");
      }
    }

    final updatedExpenses = List<GroupExpense>.from(group.expenses)
      ..removeAt(expIndex);

    groups[gIndex] = group.copyWith(expenses: updatedExpenses);
    await _persist();
    return true;
  }

  /// Hesaplaşma transferinin "Ödendi" durumunu değiştirir (toggle) ve kaydeder
  Future<bool> toggleSettlementPaid(
    String groupId,
    String settlementKey,
  ) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return false;

    final group = groups[index];
    final updatedKeys = List<String>.from(group.paidSettlementKeys);

    final isNowPaid = !updatedKeys.contains(settlementKey);
    if (isNowPaid) {
      updatedKeys.add(settlementKey);
    } else {
      updatedKeys.remove(settlementKey);
    }

    groups[index] = group.copyWith(paidSettlementKeys: updatedKeys);
    await _persist();
    return isNowPaid;
  }

  /// Cüzdana grup harcaması için işlem kaydı oluşturur (Kullanıcının kendi payı tutarında)
  Future<String?> _createWalletTransactionForExpense({
    required String groupTitle,
    required String expenseTitle,
    required double userShareAmount,
    required double totalAmount,
    required String paymentMethod,
    required DateTime date,
  }) async {
    String categoryId = '';
    try {
      final categories = await _categoryRepository.getCategories();
      final expenseCategories = categories.where((c) => c.type == 'expense');
      if (expenseCategories.isNotEmpty) {
        // Varsa 'Diğer' veya ilk kategori
        final match = expenseCategories.firstWhere(
          (c) => (c.name?.toLowerCase().contains('diğer') ?? false),
          orElse: () => expenseCategories.first,
        );
        categoryId = match.id ?? '';
      }
    } catch (_) {}

    final formattedDesc = (totalAmount - userShareAmount).abs() > 0.01
        ? "[$groupTitle|${totalAmount.toStringAsFixed(2)}] $expenseTitle"
        : "[$groupTitle] $expenseTitle";

    final transaction = Transaction(
      id: '',
      amount: userShareAmount,
      description: formattedDesc,
      type: 'expense',
      date: date.toIso8601String(),
      categoryId: categoryId,
      userId: '',
      paymentMethod: paymentMethod,
    );

    final created = await _transactionRepository.createTransaction(transaction);
    if (created.id.isNotEmpty) {
      await _accountService.setPaymentMethod(created.id, paymentMethod);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      return created.id;
    }
    return null;
  }
}
