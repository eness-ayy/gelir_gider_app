import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class TransactionRepostory extends GetxService {
  late final ApiServices _apiServices;
  StorgeService get _storageService => Get.isRegistered<StorgeService>()
      ? Get.find<StorgeService>()
      : Get.put(StorgeService());

  @override
  void onInit() {
    super.onInit();
    _apiServices = Get.find<ApiServices>();
  }

  /// Yerel hafızadaki (cache) son başarılı işlemleri getirir
  List<AppTransaction> getCachedTransactions() {
    try {
      final raw =
          _storageService.getValue<String>(StorageKeys.cachedTransactions);
      if (raw == null || raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) =>
              AppTransaction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Önbellekten işlemler okunurken hata: $e");
      return [];
    }
  }

  /// İşlemleri yerel hafızaya kaydeder
  Future<void> saveCachedTransactions(
      List<AppTransaction> transactions) async {
    try {
      final encoded =
          jsonEncode(transactions.map((t) => t.toJson()).toList());
      await _storageService.setValue<String>(
          StorageKeys.cachedTransactions, encoded);
    } catch (e) {
      debugPrint("Önbelleğe işlemler kaydedilirken hata: $e");
    }
  }

  Future<List<AppTransaction>> getTransactions() async {
    try {
      final response = await _apiServices.get(ApiConstants.transactions);
      if (response.statusCode == 200) {
        var gelenList = response.data['transactions'] as List;
        final transactions = gelenList
            .map((transaction) => AppTransaction.fromJson(transaction))
            .toList();
        await saveCachedTransactions(transactions);
        return transactions;
      }
    } catch (e) {
      debugPrint("İşlemler sunucudan çekilirken hata: $e");
      final cached = getCachedTransactions();
      if (cached.isNotEmpty) {
        debugPrint(
            "Sunucuya ulaşılamadı veya sunucu uyanıyor, önbellekteki ${cached.length} işlem kullanılıyor.");
        return cached;
      }
      rethrow;
    }
    throw Exception("İşlemler getirilirken hata oluştu");
  }

  Future<AppTransaction> createTransaction(Transaction transaction) async {
    final response = await _apiServices.post(
      ApiConstants.transactions,
      data: transaction.toJson(),
    );
    if (response.statusCode == 201) {
      AppTransaction created;
      if (response.data is Map<String, dynamic> &&
          response.data['transaction'] != null) {
        created = AppTransaction.fromJson(response.data['transaction']);
      } else {
        created = AppTransaction.fromJson(response.data);
      }

      // Önbelleği güncelle
      final cached = getCachedTransactions();
      cached.insert(0, created);
      await saveCachedTransactions(cached);

      return created;
    }
    throw Exception("İşlem oluşturulurken hata oluştu");
  }

  Future<AppTransaction> updateTransaction(
      String id, Transaction transaction) async {
    final response = await _apiServices.put(
      '${ApiConstants.transactions}/$id',
      data: transaction.toJson(),
    );
    if (response.statusCode == 200) {
      AppTransaction updated;
      if (response.data is Map<String, dynamic> &&
          response.data['transaction'] != null) {
        updated = AppTransaction.fromJson(response.data['transaction']);
      } else {
        updated = AppTransaction.fromJson(response.data);
      }

      // Önbelleği güncelle
      final cached = getCachedTransactions();
      final index = cached.indexWhere((t) => t.id == id);
      if (index != -1) {
        cached[index] = updated;
        await saveCachedTransactions(cached);
      }

      return updated;
    }
    throw Exception("İşlem güncellenirken hata oluştu");
  }

  Future<bool> deleteTransaction(String id) async {
    final response = await _apiServices.delete(
      '${ApiConstants.transactions}/$id',
    );
    if (response.statusCode == 200) {
      // Önbelleği güncelle
      final cached = getCachedTransactions();
      cached.removeWhere((t) => t.id == id);
      await saveCachedTransactions(cached);
      return true;
    }
    throw Exception("İşlem silinirken hata oluştu");
  }
}

// İsimlendirme uyumluluğu için
typedef TransactionRepository = TransactionRepostory;
