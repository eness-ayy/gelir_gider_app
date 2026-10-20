import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/recurring_transaction.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class RecurringService extends GetxService {
  static const String _storageKey = 'recurring_transactions_data';
  late final StorgeService _storage;

  final items = <RecurringTransaction>[].obs;

  Future<RecurringService> init() async {
    _storage = Get.find<StorgeService>();
    loadItems();
    return this;
  }

  void loadItems() {
    try {
      final raw = _storage.getValue<String>(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        items.value = decoded
            .map((item) =>
                RecurringTransaction.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // İlk kullanım için örnek 3 adet tekrarlayan ödeme
        items.value = [
          RecurringTransaction(
            id: 'rec_1',
            title: 'Netflix Aboneliği',
            amount: 229.99,
            category: 'Abonelikler',
            period: 'monthly',
            paymentDay: 15,
            isActive: true,
          ),
          RecurringTransaction(
            id: 'rec_2',
            title: 'Ev Kirası',
            amount: 15000,
            category: 'Kira & Ev',
            period: 'monthly',
            paymentDay: 1,
            isActive: true,
          ),
          RecurringTransaction(
            id: 'rec_3',
            title: 'Spotify Premium',
            amount: 59.99,
            category: 'Abonelikler',
            period: 'monthly',
            paymentDay: 28,
            isActive: true,
          ),
        ];
        _saveToStorage();
      }
    } catch (e) {
      debugPrint("Tekrarlayan işlemler yüklenirken hata: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = items.map((i) => i.toJson()).toList();
      await _storage.setValue<String>(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Tekrarlayan işlemler kaydedilirken hata: $e");
    }
  }

  Future<void> addItem(RecurringTransaction item) async {
    items.add(item);
    await _saveToStorage();
  }

  Future<void> updateItem(RecurringTransaction item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await _saveToStorage();
    }
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((i) => i.id == id);
    await _saveToStorage();
  }

  Future<void> toggleActive(String id) async {
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = items[index];
      items[index] = current.copyWith(isActive: !current.isActive);
      await _saveToStorage();
    }
  }

  int get activeCount => items.where((i) => i.isActive).length;

  double get monthlyTotal {
    double total = 0.0;
    for (final item in items.where((i) => i.isActive)) {
      if (item.period == 'yearly') {
        total += item.amount / 12;
      } else if (item.period == 'weekly') {
        total += item.amount * 4;
      } else {
        total += item.amount;
      }
    }
    return total;
  }
}
