import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class TransactionRepostory extends GetxService {
  late final ApiServices _apiServices;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StorgeService get _storageService => Get.isRegistered<StorgeService>()
      ? Get.find<StorgeService>()
      : Get.put(StorgeService());

  @override
  void onInit() {
    super.onInit();
    _apiServices = Get.find<ApiServices>();
  }

  /// Aktif Firebase kullanıcısının UID'si
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Kullanıcının alt koleksiyonu: users/{userId}/transactions
  CollectionReference<Map<String, dynamic>>? get _transactionsCollection {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  /// Aktif kullanıcının kimliğini (e-posta veya uid) güvenli bir depolama anahtarına dönüştürür.
  String get _activeUserKey {
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      return uid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }

    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      if (user?.email != null && user!.email!.trim().isNotEmpty) {
        return user.email!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      }
      if (user?.id != null && user!.id!.trim().isNotEmpty) {
        return user.id!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      }
    }
    return 'guest_user';
  }

  String get _transactionsStorageKey =>
      '${StorageKeys.cachedTransactions}_$_activeUserKey';

  /// Aktif kullanıcının yerel hafızasındaki (cache) son işlemlerini getirir.
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
      debugPrint("[CACHE] Önbellekten işlemler okunurken hata: $e");
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
      debugPrint("[CACHE] Önbelleğe işlemler kaydedilirken hata: $e");
    }
  }

  /// Kullanıcının işlemlerini çeker (Önce Firestore -> Sonra REST API -> Yerel Cache)
  Future<List<AppTransaction>> getTransactions() async {
    // 1. Doğrudan Firestore'dan çekmeyi dene
    final col = _transactionsCollection;
    if (col != null) {
      try {
        debugPrint("[FIRESTORE TRANSACTIONS] İşlemler Firestore'dan çekiliyor...");
        final snapshot = await col.orderBy('date', descending: true).get();
        if (snapshot.docs.isNotEmpty) {
          final transactions = snapshot.docs.map((doc) {
            final data = doc.data();

            // Tarih dönüşümü
            DateTime parsedDate;
            final rawDate = data['date'];
            if (rawDate is Timestamp) {
              parsedDate = rawDate.toDate();
            } else if (rawDate is String) {
              parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
            } else {
              parsedDate = DateTime.now();
            }

            final catId = (data['categoryId'] ?? data['category'] ?? '').toString();
            String catName = (data['categoryName'] ?? '').toString().trim();
            String catIcon = (data['categoryIcon'] ?? '').toString().trim();
            final desc = (data['title'] ?? data['description'] ?? '').toString().trim();

            final isMistakenDesc = desc.isNotEmpty &&
                catName == desc &&
                desc != 'Gelir İşlemi' &&
                desc != 'Gider İşlemi';

            if (catName.isEmpty || isMistakenDesc || catName == 'İsimsiz Kategori') {
              final found = CategoryService.defaultCategories.firstWhereOrNull(
                (c) =>
                    c.id == catId ||
                    c.name.toLowerCase() == catId.toLowerCase(),
              );
              if (found != null) {
                catName = found.name;
                catIcon = found.icon;
              } else {
                final foundRepo = CategoryRepository.defaultCategories.firstWhereOrNull(
                  (c) =>
                      c.id == catId ||
                      (c.name != null &&
                          c.name!.toLowerCase() == catId.toLowerCase()),
                );
                if (foundRepo != null && foundRepo.name != null) {
                  catName = foundRepo.name!;
                  catIcon = foundRepo.icon ?? 'category';
                } else if (catId.isNotEmpty &&
                    !catId.startsWith('def_') &&
                    !catId.startsWith('cat_') &&
                    catId != desc) {
                  catName = catId;
                } else {
                  catName = (data['type'] == 'income' || data['type'] == 'gelir')
                      ? 'Diğer Gelir'
                      : 'Diğer Gider';
                }
              }
            }

            final categoryObj = Category(
              name: catName,
              icon: catIcon.isNotEmpty ? catIcon : 'category',
              type: data['type'] ?? 'expense',
            );

            return AppTransaction(
              id: doc.id,
              amount: (data['amount'] ?? 0.0).toString(),
              type: data['type'] ?? 'expense',
              description: data['title'] ?? data['description'] ?? '',
              date: parsedDate.toIso8601String(),
              categoryId: catId,
              category: categoryObj,
              userId: _currentUserId ?? _activeUserKey,
              paymentMethod: data['paymentMethod'] ?? 'cash',
              createdAt: parsedDate.toIso8601String(),
              updatedAt: parsedDate.toIso8601String(),
            );
          }).toList();

          debugPrint("[FIRESTORE TRANSACTIONS] Firestore'dan ${transactions.length} işlem başarıyla yüklendi.");
          await saveCachedTransactions(transactions);
          return transactions;
        }
      } catch (e) {
        debugPrint("[FIRESTORE TRANSACTIONS HATA] Firestore getTransactions hatası: $e");
      }
    }

    // 2. REST API dene
    final token = _storageService.getValue<String>(StorageKeys.userToken);
    if (token != null && token.trim().isNotEmpty) {
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
        debugPrint("[API TRANSACTIONS] REST API üzerinden işlemler alınamadı: $e");
      }
    }

    // 3. Yerel önbellekten dön
    return getCachedTransactions();
  }

  /// Yeni işlem oluşturur ve Firestore'a (users/{userId}/transactions) kaydeder
  Future<AppTransaction> createTransaction(Transaction transaction) async {
    final now = DateTime.tryParse(transaction.date ?? '') ?? DateTime.now();
    final nowIso = now.toIso8601String();
    String docId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final col = _transactionsCollection;

    // Kategori adını ve ikonunu akıllıca tespit et
    String categoryName = transaction.categoryName?.trim() ?? '';
    String categoryIcon = transaction.categoryIcon?.trim() ?? '';
    final desc = transaction.description?.trim() ?? '';
    final catId = transaction.categoryId ?? '';

    final isMistakenDesc = desc.isNotEmpty &&
        categoryName == desc &&
        desc != 'Gelir İşlemi' &&
        desc != 'Gider İşlemi';

    if (categoryName.isEmpty || isMistakenDesc || categoryName == 'İsimsiz Kategori') {
      final foundDef = CategoryService.defaultCategories.firstWhereOrNull(
        (c) => c.id == catId || c.name.toLowerCase() == catId.toLowerCase(),
      );
      if (foundDef != null) {
        categoryName = foundDef.name;
        categoryIcon = foundDef.icon;
      } else {
        final foundRepo = CategoryRepository.defaultCategories.firstWhereOrNull(
          (c) =>
              c.id == catId ||
              (c.name != null &&
                  c.name!.toLowerCase() == catId.toLowerCase()),
        );
        if (foundRepo != null && foundRepo.name != null) {
          categoryName = foundRepo.name!;
          categoryIcon = foundRepo.icon ?? 'category';
        } else if (catId.isNotEmpty &&
            !catId.startsWith('def_') &&
            !catId.startsWith('cat_') &&
            catId != desc) {
          categoryName = catId;
        } else {
          categoryName = (transaction.type == 'income' || transaction.type == 'gelir')
              ? 'Diğer Gelir'
              : 'Diğer Gider';
        }
      }
    }

    if (categoryIcon.isEmpty) categoryIcon = 'category';

    final categoryObj = Category(
      name: categoryName,
      icon: categoryIcon,
      type: transaction.type ?? 'expense',
    );

    // 1. FIRESTORE'A YAZ
    if (col != null) {
      try {
        debugPrint("[FIRESTORE TRANSACTIONS] İşlem ekleniyor: Açıklama='${transaction.description}', Tutar=${transaction.amount} ₺, Kategori='$categoryName'");
        
        final docRef = await col.add({
          'title': transaction.description ?? categoryName,
          'description': transaction.description ?? categoryName,
          'amount': transaction.amount ?? 0.0,
          'type': transaction.type ?? 'expense',
          'categoryId': catId,
          'category': categoryName,
          'categoryName': categoryName,
          'categoryIcon': categoryIcon,
          'paymentMethod': transaction.paymentMethod ?? 'cash',
          'date': Timestamp.fromDate(now),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        docId = docRef.id;
        debugPrint("[FIRESTORE TRANSACTIONS BAŞARILI] İşlem Firestore'a kaydedildi! Doküman ID: $docId, Kategori: $categoryName");
      } catch (e) {
        debugPrint("[FIRESTORE TRANSACTIONS HATA] Firestore'a kayıt yapılamadı: $e");
      }
    } else {
      debugPrint("[FIRESTORE TRANSACTIONS UYARI] Kullanıcı oturumu açık değil (_transactionsCollection null). Yerel kayıt yapılıyor.");
    }

    // 2. Harici API varsa arka planda senkronize etmeyi dene
    final token = _storageService.getValue<String>(StorageKeys.userToken);
    if (token != null && token.trim().isNotEmpty) {
      try {
        await _apiServices.post(
          ApiConstants.transactions,
          data: transaction.toJson(),
        );
      } catch (e) {
        debugPrint("[API TRANSACTIONS] REST API senkronizasyon uyarısı: $e");
      }
    }

    // 3. Yerel önbelleğe ekle
    final created = AppTransaction(
      id: docId,
      amount: (transaction.amount ?? 0.0).toString(),
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? nowIso,
      userId: transaction.userId ?? _activeUserKey,
      categoryId: catId,
      category: categoryObj,
      createdAt: nowIso,
      updatedAt: nowIso,
      paymentMethod: transaction.paymentMethod,
    );

    final cached = getCachedTransactions();
    cached.insert(0, created);
    await saveCachedTransactions(cached);

    return created;
  }

  /// İşlem güncelleme (Firestore + Local)
  Future<AppTransaction> updateTransaction(
      String id, Transaction transaction) async {
    final now = DateTime.tryParse(transaction.date ?? '') ?? DateTime.now();
    final nowIso = now.toIso8601String();

    String categoryName = transaction.categoryName?.trim() ?? '';
    String categoryIcon = transaction.categoryIcon?.trim() ?? '';
    final desc = transaction.description?.trim() ?? '';
    final catId = transaction.categoryId ?? '';

    final isMistakenDesc = desc.isNotEmpty &&
        categoryName == desc &&
        desc != 'Gelir İşlemi' &&
        desc != 'Gider İşlemi';

    if (categoryName.isEmpty || isMistakenDesc || categoryName == 'İsimsiz Kategori') {
      final foundDef = CategoryService.defaultCategories.firstWhereOrNull(
        (c) => c.id == catId || c.name.toLowerCase() == catId.toLowerCase(),
      );
      if (foundDef != null) {
        categoryName = foundDef.name;
        categoryIcon = foundDef.icon;
      } else {
        final foundRepo = CategoryRepository.defaultCategories.firstWhereOrNull(
          (c) =>
              c.id == catId ||
              (c.name != null &&
                  c.name!.toLowerCase() == catId.toLowerCase()),
        );
        if (foundRepo != null && foundRepo.name != null) {
          categoryName = foundRepo.name!;
          categoryIcon = foundRepo.icon ?? 'category';
        } else if (catId.isNotEmpty &&
            !catId.startsWith('def_') &&
            !catId.startsWith('cat_') &&
            catId != desc) {
          categoryName = catId;
        } else {
          categoryName = (transaction.type == 'income' || transaction.type == 'gelir')
              ? 'Diğer Gelir'
              : 'Diğer Gider';
        }
      }
    }

    if (categoryIcon.isEmpty) categoryIcon = 'category';

    final categoryObj = Category(
      name: categoryName,
      icon: categoryIcon,
      type: transaction.type ?? 'expense',
    );

    final col = _transactionsCollection;
    if (col != null && !id.startsWith('local_')) {
      try {
        await col.doc(id).set({
          'title': transaction.description ?? categoryName,
          'description': transaction.description ?? categoryName,
          'amount': transaction.amount ?? 0.0,
          'type': transaction.type ?? 'expense',
          'categoryId': catId,
          'category': categoryName,
          'categoryName': categoryName,
          'categoryIcon': categoryIcon,
          'paymentMethod': transaction.paymentMethod ?? 'cash',
          'date': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("[FIRESTORE TRANSACTIONS] İşlem güncellendi: $id");
      } catch (e) {
        debugPrint("[FIRESTORE TRANSACTIONS HATA] Güncelleme hatası: $e");
      }
    }

    // Yerel önbellekte güncelle
    final updated = AppTransaction(
      id: id,
      amount: (transaction.amount ?? 0.0).toString(),
      type: transaction.type ?? 'expense',
      description: transaction.description ?? '',
      date: transaction.date ?? nowIso,
      userId: transaction.userId ?? _activeUserKey,
      categoryId: catId,
      category: categoryObj,
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

  /// İşlem silme (Firestore + Local)
  Future<bool> deleteTransaction(String id) async {
    final col = _transactionsCollection;
    if (col != null && !id.startsWith('local_')) {
      try {
        await col.doc(id).delete();
        debugPrint("[FIRESTORE TRANSACTIONS] İşlem Firestore'dan silindi: $id");
      } catch (e) {
        debugPrint("[FIRESTORE TRANSACTIONS HATA] Silme hatası: $e");
      }
    }

    // Yerel önbellekten sil
    final cached = getCachedTransactions();
    cached.removeWhere((t) => t.id == id);
    await saveCachedTransactions(cached);
    return true;
  }
}

// İsimlendirme uyumluluğu
typedef TransactionRepository = TransactionRepostory;
