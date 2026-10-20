import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/debt_item.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class DebtService extends GetxService {
  static const String _storageKey = 'debt_items_data';
  late final StorgeService _storage;

  final debts = <DebtItem>[].obs;

  Future<DebtService> init() async {
    _storage = Get.find<StorgeService>();
    loadDebts();
    return this;
  }

  void loadDebts() {
    try {
      final raw = _storage.getValue<String>(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        debts.value = decoded
            .map((item) => DebtItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // İlk kullanım için örnek başlangıç borç/alacak kayıtları (+₺1.500 net)
        debts.value = [
          DebtItem(
            id: 'debt_1',
            personName: 'Ahmet Yılmaz',
            type: 'receivable',
            amount: 2500,
            dueDate: DateTime.now().add(const Duration(days: 15)),
            notes: 'Ortak tatil harcaması payı',
            isPaid: false,
          ),
          DebtItem(
            id: 'debt_2',
            personName: 'Mehmet Demir',
            type: 'payable',
            amount: 1000,
            dueDate: DateTime.now().add(const Duration(days: 5)),
            notes: 'Kitap ve kırtasiye borcu',
            isPaid: false,
          ),
        ];
        _saveToStorage();
      }
    } catch (e) {
      debugPrint("Borç/Alacak verileri yüklenirken hata: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = debts.map((d) => d.toJson()).toList();
      await _storage.setValue<String>(_storageKey, jsonEncode(jsonList));
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
