import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_core/firebase_core.dart';
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
  bool get _canUseCloud =>
      Firebase.apps.isNotEmpty && _storage.activeUserKey != 'guest_user';

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
        unawaited(_restoreFromCloudIfEmpty());
      }
    } catch (e) {
      debugPrint("Borç/Alacak verileri yüklenirken hata: $e");
      debts.clear();
    }
  }

  Future<void> _restoreFromCloudIfEmpty() async {
    if (!_canUseCloud) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_storage.activeUserKey)
          .collection('extra_modules')
          .doc('debts')
          .get();
      final list = doc.data()?['items'] as List?;
      if (list != null && list.isNotEmpty && debts.isEmpty) {
        debts.value = list
            .map((e) => DebtItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final jsonList = debts.map((d) => d.toJson()).toList();
        await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = debts.map((d) => d.toJson()).toList();
      await _storage.setValue<String>(_scopedStorageKey, jsonEncode(jsonList));
      if (_canUseCloud) {
        unawaited(
          FirebaseFirestore.instance
              .collection('users')
              .doc(_storage.activeUserKey)
              .collection('extra_modules')
              .doc('debts')
              .set({
                'items': jsonList,
                'updatedAt': FieldValue.serverTimestamp(),
              })
              .catchError((_) {}),
        );
      }
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

  Future<void> togglePaid(String id, {String? paymentMethod}) async {
    final index = debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final current = debts[index];
      final newStatus = !current.isPaid;
      final effectiveMethod =
          (paymentMethod != null && paymentMethod.isNotEmpty)
              ? paymentMethod
              : current.paymentMethod;

      if (newStatus && current.amount > 0) {
        String? createdTxId;
        try {
          if (Get.isRegistered<TransactionRepostory>()) {
            final repo = Get.find<TransactionRepostory>();
            final isRec = current.isReceivable;
            final created = await repo.createTransaction(
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
                paymentMethod: effectiveMethod,
              ),
            );
            createdTxId = created.id;
            if (Get.isRegistered<DashboardController>()) {
              final dash = Get.find<DashboardController>();
              if (created.id.isNotEmpty) {
                await dash.accountService.setPaymentMethod(
                  created.id,
                  effectiveMethod,
                );
              }
              await dash.refreshDashboard();
            }
          }
        } catch (e) {
          debugPrint("Borç/Alacak cüzdana yansıtılırken hata: $e");
        }
        debts[index] = current.copyWith(
          isPaid: true,
          paidDate: DateTime.now(),
          paymentMethod: effectiveMethod,
          linkedTransactionId: createdTxId,
        );
      } else {
        // Ödendi durumu geri alındığında cüzdandaki bağlı işlemi sil
        final linkedId = current.linkedTransactionId;
        if (linkedId != null && linkedId.isNotEmpty) {
          try {
            if (Get.isRegistered<TransactionRepostory>()) {
              await Get.find<TransactionRepostory>().deleteTransaction(linkedId);
            }
            if (Get.isRegistered<DashboardController>()) {
              final dash = Get.find<DashboardController>();
              dash.myTransaction.removeWhere((t) => t.id == linkedId);
              await dash.accountService.removePaymentMethod(linkedId);
              dash.aylikOzet();
            }
          } catch (e) {
            debugPrint("Bağlı borç işlemi silinirken hata: $e");
          }
        }
        debts[index] = DebtItem(
          id: current.id,
          personName: current.personName,
          type: current.type,
          amount: current.amount,
          dueDate: current.dueDate,
          notes: current.notes,
          isPaid: false,
          paidDate: null,
          paymentMethod: current.paymentMethod,
          linkedTransactionId: null,
        );
      }
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
