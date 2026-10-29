import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/debt_item.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class DebtService extends GetxService {
  static const String _storageKey = 'debt_items_data';
  late final StorgeService _storage;

  String get _scopedStorageKey => _storage.scopedKey(_storageKey);

  final debts = <DebtItem>[].obs;

  Future<DebtService> init() async {
    _storage = Get.find<StorgeService>();
    loadDebts();
    return this;
  }

  void loadDebts() {
    try {
      final raw = _storage.getValue<String>(_scopedStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        debts.value = decoded
            .map((item) => DebtItem.fromJson(item as Map<String, dynamic>))
            .where((d) => d.id != 'debt_1' && d.id != 'debt_2')
            .toList();
      } else {
        debts.clear();
      }
    } catch (e) {
      debugPrint("Borç/Alacak verileri yüklenirken hata: $e");
      debts.clear();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = debts.map((d) => d.toJson()).toList();
      await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Borç/Alacak verileri kaydedilirken hata: $e");
    }
  }

  Future<void> addDebt(DebtItem debt) async {
    debts.add(debt);
    await _saveToStorage();
  }

  Future<void> updateDebt(DebtItem debt) async {
    final index = debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      debts[index] = debt;
      await _saveToStorage();
    }
  }

  Future<void> deleteDebt(String id) async {
    debts.removeWhere((d) => d.id == id);
    await _saveToStorage();
  }

  Future<void> togglePaid(String id) async {
    final index = debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final current = debts[index];
      final newStatus = !current.isPaid;
      debts[index] = current.copyWith(
        isPaid: newStatus,
        paidDate: newStatus ? DateTime.now() : null,
      );
      await _saveToStorage();

      if (newStatus && current.amount > 0) {
        try {
          if (Get.isRegistered<TransactionRepostory>()) {
            final repo = Get.find<TransactionRepostory>();
            final isRec = current.isReceivable;
            await repo.createTransaction(
              Transaction(
                id: '',
                amount: current.amount,
                description: isRec
                    ? "Alacak Tahsilatı (${current.personName})"
                    : "Borç Ödemesi (${current.personName})",
                type: isRec ? 'income' : 'expense',
                date: DateTime.now().toIso8601String(),
                categoryId: isRec ? 'Diğer Gelir' : 'Diğer Gider',
                categoryName: isRec ? 'Diğer Gelir' : 'Diğer Gider',
                categoryIcon: 'account_balance_wallet',
                userId: '',
                paymentMethod: 'cash',
              ),
            );
            if (Get.isRegistered<DashboardController>()) {
              await Get.find<DashboardController>().refreshDashboard();
            }
          }
        } catch (e) {
          debugPrint("Borç/Alacak cüzdana yansıtılırken hata: $e");
        }
      }
    }
  }

  double get totalReceivables => debts
      .where((d) => !d.isPaid && d.isReceivable)
      .fold(0.0, (sum, d) => sum + d.amount);

  double get totalPayables => debts
      .where((d) => !d.isPaid && !d.isReceivable)
      .fold(0.0, (sum, d) => sum + d.amount);

  double get netBalance => totalReceivables - totalPayables;

  int get activeDebtsCount => debts.where((d) => !d.isPaid).length;
}
