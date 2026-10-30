import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/recurring_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/notification_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class RecurringService extends GetxService {
  static const String _storageKey = 'recurring_transactions_data';
  late final StorgeService _storage;

  String get _scopedStorageKey => _storage.scopedKey(_storageKey);
  bool get _canUseCloud =>
      Firebase.apps.isNotEmpty && _storage.activeUserKey != 'guest_user';

  final items = <RecurringTransaction>[].obs;

  Future<RecurringService> init() async {
    _storage = Get.find<StorgeService>();
    loadItems();
    return this;
  }

  void loadItems() {
    try {
      final raw = _storage.getValue<String>(_scopedStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        items.value = decoded
            .map((item) =>
                RecurringTransaction.fromJson(item as Map<String, dynamic>))
            .where((i) => i.id != 'rec_1' && i.id != 'rec_2' && i.id != 'rec_3')
            .toList();
      } else {
        items.clear();
        unawaited(_restoreFromCloudIfEmpty());
      }
    } catch (e) {
      debugPrint("Tekrarlayan işlemler yüklenirken hata: $e");
      items.clear();
    }
  }

  Future<void> _restoreFromCloudIfEmpty() async {
    if (!_canUseCloud) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_storage.activeUserKey)
          .collection('extra_modules')
          .doc('recurring')
          .get();
      final list = doc.data()?['items'] as List?;
      if (list != null && list.isNotEmpty && items.isEmpty) {
        items.value = list
            .map((e) =>
                RecurringTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final jsonList = items.map((i) => i.toJson()).toList();
        await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = items.map((i) => i.toJson()).toList();
      await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().scheduleRecurringReminders();
      }
      if (_canUseCloud) {
        unawaited(
          FirebaseFirestore.instance
              .collection('users')
              .doc(_storage.activeUserKey)
              .collection('extra_modules')
              .doc('recurring')
              .set({
                'items': jsonList,
                'updatedAt': FieldValue.serverTimestamp(),
              })
              .catchError((_) {}),
        );
      }
    } catch (e) {
      debugPrint("Tekrarlayan işlemler kaydedilirken hata: $e");
    }
  }

  Future<bool> recordPaymentToWallet(
    RecurringTransaction item, {
    String paymentMethod = 'bank_card',
  }) async {
    if (item.amount <= 0 || item.isPaidThisMonth) return false;
    try {
      if (Get.isRegistered<TransactionRepostory>()) {
        final repo = Get.find<TransactionRepostory>();
        await repo.createTransaction(
          Transaction(
            id: '',
            amount: item.amount,
            description: item.title,
            type: 'expense',
            date: DateTime.now().toIso8601String(),
            categoryId: item.category,
            categoryName: item.category,
            categoryIcon: 'event_repeat',
            userId: '',
            paymentMethod: paymentMethod,
          ),
        );
        final idx = items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          items[idx] = items[idx].copyWith(
            lastProcessedPeriod: item.currentPeriodKey,
          );
          await _saveToStorage();
        }
        if (Get.isRegistered<DashboardController>()) {
          await Get.find<DashboardController>().refreshDashboard();
        }
        return true;
      }
    } catch (e) {
      debugPrint("Tekrarlayan ödeme cüzdana işlenirken hata: $e");
    }
    return false;
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
