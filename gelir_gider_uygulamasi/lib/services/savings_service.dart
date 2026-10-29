import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/savings_goal.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class SavingsService extends GetxService {
  static const String _storageKey = 'savings_goals_data';
  late final StorgeService _storage;

  String get _scopedStorageKey => _storage.scopedKey(_storageKey);

  final goals = <SavingsGoal>[].obs;

  Future<SavingsService> init() async {
    _storage = Get.find<StorgeService>();
    loadGoals();
    return this;
  }

  void loadGoals() {
    try {
      final raw = _storage.getValue<String>(_scopedStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        goals.value = decoded
            .map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>))
            .where((g) => g.id != 'goal_1' && g.id != 'goal_2')
            .toList();
      } else {
        goals.clear();
      }
    } catch (e) {
      debugPrint("Birikim hedefleri yüklenirken hata: $e");
      goals.clear();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = goals.map((g) => g.toJson()).toList();
      await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Birikim hedefleri kaydedilirken hata: $e");
    }
  }

  Future<void> addGoal(SavingsGoal goal) async {
    goals.add(goal);
    await _saveToStorage();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      await _saveToStorage();
    }
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _saveToStorage();
  }

  Future<void> depositMoney(String id, double amount, {String paymentMethod = 'cash'}) async {
    final index = goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final g = goals[index];
      final newSaved = g.savedAmount + amount;
      final isComp = newSaved >= g.targetAmount;
      goals[index] = g.copyWith(
        savedAmount: newSaved,
        isCompleted: isComp,
      );
      await _saveToStorage();
      await _syncWalletForSavings(
        title: "Kumbara Birikimi (${g.title})",
        amount: amount,
        type: 'expense',
        paymentMethod: paymentMethod,
      );
    }
  }

  Future<void> withdrawMoney(String id, double amount, {String paymentMethod = 'cash'}) async {
    final index = goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final g = goals[index];
      final newSaved = (g.savedAmount - amount).clamp(0.0, double.infinity);
      goals[index] = g.copyWith(
        savedAmount: newSaved,
        isCompleted: newSaved >= g.targetAmount,
      );
      await _saveToStorage();
      await _syncWalletForSavings(
        title: "Kumbara Çekimi (${g.title})",
        amount: amount,
        type: 'income',
        paymentMethod: paymentMethod,
      );
    }
  }

  Future<void> _syncWalletForSavings({
    required String title,
    required double amount,
    required String type,
    required String paymentMethod,
  }) async {
    if (amount <= 0) return;
    try {
      if (Get.isRegistered<TransactionRepostory>()) {
        final repo = Get.find<TransactionRepostory>();
        await repo.createTransaction(
          Transaction(
            id: '',
            amount: amount,
            description: title,
            type: type,
            date: DateTime.now().toIso8601String(),
            categoryId: 'Birikim & Yatırım',
            categoryName: 'Birikim & Yatırım',
            categoryIcon: 'savings',
            userId: '',
            paymentMethod: paymentMethod,
          ),
        );
        if (Get.isRegistered<DashboardController>()) {
          await Get.find<DashboardController>().refreshDashboard();
        }
      }
    } catch (e) {
      debugPrint("Kumbara işlemi cüzdana yansıtılırken hata: $e");
    }
  }

  int get activeGoalsCount => goals.where((g) => !g.isCompleted).length;
  double get totalSavedAmount =>
      goals.fold(0.0, (sum, g) => sum + g.savedAmount);
  double get totalTargetAmount =>
      goals.fold(0.0, (sum, g) => sum + g.targetAmount);
}
