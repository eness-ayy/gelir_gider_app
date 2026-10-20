import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/savings_goal.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class SavingsService extends GetxService {
  static const String _storageKey = 'savings_goals_data';
  late final StorgeService _storage;

  final goals = <SavingsGoal>[].obs;

  Future<SavingsService> init() async {
    _storage = Get.find<StorgeService>();
    loadGoals();
    return this;
  }

  void loadGoals() {
    try {
      final raw = _storage.getValue<String>(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        goals.value = decoded
            .map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // İlk kullanım için örnek başlangıç hedefleri
        goals.value = [
          SavingsGoal(
            id: 'goal_1',
            title: 'Tatil Kumbarası',
            targetAmount: 20000,
            savedAmount: 9500,
            targetDate: DateTime.now().add(const Duration(days: 90)),
            category: 'Tatil & Seyahat',
            colorValue: 0xFF3B82F6,
          ),
          SavingsGoal(
            id: 'goal_2',
            title: 'Yeni Telefon',
            targetAmount: 30000,
            savedAmount: 5000,
            targetDate: DateTime.now().add(const Duration(days: 180)),
            category: 'Teknoloji',
            colorValue: 0xFF10B981,
          ),
        ];
        _saveToStorage();
      }
    } catch (e) {
      debugPrint("Birikim hedefleri yüklenirken hata: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = goals.map((g) => g.toJson()).toList();
      await _storage.setValue<String>(_storageKey, jsonEncode(jsonList));
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

  Future<void> depositMoney(String id, double amount) async {
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
    }
  }

  Future<void> withdrawMoney(String id, double amount) async {
    final index = goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final g = goals[index];
      final newSaved = (g.savedAmount - amount).clamp(0.0, double.infinity);
      goals[index] = g.copyWith(
        savedAmount: newSaved,
        isCompleted: newSaved >= g.targetAmount,
      );
      await _saveToStorage();
    }
  }

  int get activeGoalsCount => goals.where((g) => !g.isCompleted).length;
  double get totalSavedAmount =>
      goals.fold(0.0, (sum, g) => sum + g.savedAmount);
  double get totalTargetAmount =>
      goals.fold(0.0, (sum, g) => sum + g.targetAmount);
}
