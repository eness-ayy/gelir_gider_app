import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
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

  /// Aktif kullanıcının kimliğini (e-posta veya uid) güvenli bir depolama anahtarına dönüştürür.
  String get _activeUserKey {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      if (user?.email != null && user!.email!.trim().isNotEmpty) {
        return user.email!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      }
      if (user?.id != null && user!.id!.trim().isNotEmpty) {
        return user.id!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      }
    }

    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      fbUser = null;
    }
    if (fbUser?.email != null && fbUser!.email!.trim().isNotEmpty) {
      return fbUser.email!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }
    if (fbUser?.uid != null && fbUser!.uid.trim().isNotEmpty) {
      return fbUser.uid.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }
    return 'guest_user';
  }

  String get _transactionsStorageKey =>
      '${StorageKeys.cachedTransactions}_$_activeUserKey';

  /// Aktif kullanıcının yerel hafızasındaki (cache) son başarılı işlemlerini getirir.
  List<AppTransaction> getCachedTransactions() {
    try {
      final raw = _storageService.getValue<String>(_transactionsStorageKey);
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

  /// Aktif kullanıcının işlemlerini yerel hafızaya kaydeder.
  Future<void> saveCachedTransactions(
      List<AppTransaction> transactions) async {
    try {
      final encoded =
          jsonEncode(transactions.map((t) => t.toJson()).toList());
      await _storageService.setValue<String>(
          _transactionsStorageKey, encoded);
    } catch (e) {
      debugPrint("Önbelleğe işlemler kaydedilirken hata: $e");
    }
  }

  /// Kullanıcının işlemlerini sunucudan (veya yerel önbellekten) çeker.
  Future<List<AppTransaction>> getTransactions() async {
    final token = _storageService.getValue<String>(StorageKeys.userToken);

    // Eğer backend JWT token'ı yoksa (Firebase e-posta kullanıcısı gibi),
    // doğrudan bu kullanıcının yerel işlemlerini döndür.
    if (token == null || token.trim().isEmpty) {
      return getCachedTransactions();
    }

    try {
      final response = await _apiServices.get(ApiConstants.transactions);
      if (response.statusCode == 200 && response.data != null) {
        var gelenList = response.data['transactions'] as List?;
        if (gelenList != null) {
          final transactions = gelenList
              .map((transaction) => AppTransaction.fromJson(transaction))
              .toList();
          await saveCachedTransactions(transactions);
          return transactions;
        }
      }
    } catch (e) {
      debugPrint("İşlemler sunucudan çekilirken hata: $e");
      final cached = getCachedTransactions();
      return cached;
    }
    return getCachedTransactions();
  }

  Future<AppTransaction> createTransaction(Transaction transaction) async {
    final token = _storageService.getValue<String>(StorageKeys.userToken);

    if (token != null && token.trim().isNotEmpty) {
      try {
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

          final cached = getCachedTransactions();
          cached.insert(0, created);
          await saveCachedTransactions(cached);
          return created;
        }
      } catch (e) {
        debugPrint("Sunucuya işlem kaydedilemedi, yerel kayıt yapılıyor: $e");
      }
    }

    // Yerel olarak oluştur ve bu kullanıcının önbelleğine ekle
    final nowIso = DateTime.now().toIso8601String();
    final localCreated = AppTransaction(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      amount: (transaction.amount ?? 0.0).toString(),
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? nowIso,
      userId: transaction.userId ?? _activeUserKey,
      categoryId: transaction.categoryId ?? '',
      createdAt: nowIso,
      updatedAt: nowIso,
      paymentMethod: transaction.paymentMethod,
    );

    final cached = getCachedTransactions();
    cached.insert(0, localCreated);
    await saveCachedTransactions(cached);
    return localCreated;
  }

  Future<AppTransaction> updateTransaction(
      String id, Transaction transaction) async {
    final token = _storageService.getValue<String>(StorageKeys.userToken);

    if (token != null && token.trim().isNotEmpty && !id.startsWith('local_')) {
      try {
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

          final cached = getCachedTransactions();
          final index = cached.indexWhere((t) => t.id == id);
          if (index != -1) {
            cached[index] = updated;
            await saveCachedTransactions(cached);
          }
          return updated;
        }
      } catch (e) {
        debugPrint("Sunucuda işlem güncellenemedi, yerel güncelleme yapılıyor: $e");
      }
    }

    // Yerel önbellekte güncelle
    final nowIso = DateTime.now().toIso8601String();
    final updated = AppTransaction(
      id: id,
      amount: (transaction.amount ?? 0.0).toString(),
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? nowIso,
      userId: transaction.userId ?? _activeUserKey,
      categoryId: transaction.categoryId ?? '',
      createdAt: nowIso,
      updatedAt: nowIso,
      paymentMethod: transaction.paymentMethod,
    );

    final cached = getCachedTransactions();
    final index = cached.indexWhere((t) => t.id == id);
    if (index != -1) {
      cached[index] = updated;
      await saveCachedTransactions(cached);
    }
    return updated;
  }

  Future<bool> deleteTransaction(String id) async {
    final token = _storageService.getValue<String>(StorageKeys.userToken);

    if (token != null && token.trim().isNotEmpty && !id.startsWith('local_')) {
      try {
        final response = await _apiServices.delete(
          '${ApiConstants.transactions}/$id',
        );
        if (response.statusCode == 200) {
          final cached = getCachedTransactions();
          cached.removeWhere((t) => t.id == id);
          await saveCachedTransactions(cached);
          return true;
        }
      } catch (e) {
        debugPrint("Sunucudan işlem silinemedi, yerel silme yapılıyor: $e");
      }
    }

    // Yerel önbellekten sil
    final cached = getCachedTransactions();
    cached.removeWhere((t) => t.id == id);
    await saveCachedTransactions(cached);
    return true;
  }
}

// İsimlendirme uyumluluğu için
typedef TransactionRepository = TransactionRepostory;
