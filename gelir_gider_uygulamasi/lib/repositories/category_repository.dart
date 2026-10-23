import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';
import 'package:get/get.dart';

class CategoryRepository extends GetxService {
  late final ApiServices _apiService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final List<AppCategory> defaultCategories = [
    // Gider Kategorileri
    AppCategory(id: 'def_expense_yemek', name: 'Yemek & Mutfak', type: 'expense', icon: 'restaurant'),
    AppCategory(id: 'def_expense_fatura', name: 'Fatura & Aidat', type: 'expense', icon: 'receipt_long'),
    AppCategory(id: 'def_expense_kira', name: 'Kira', type: 'expense', icon: 'home'),
    AppCategory(id: 'def_expense_ulasim', name: 'Ulaşım', type: 'expense', icon: 'directions_bus'),
    AppCategory(id: 'def_expense_alisveris', name: 'Alışveriş', type: 'expense', icon: 'shopping_bag'),
    AppCategory(id: 'def_expense_eglence', name: 'Eğlence', type: 'expense', icon: 'movie'),
    AppCategory(id: 'def_expense_saglik', name: 'Sağlık', type: 'expense', icon: 'local_hospital'),
    AppCategory(id: 'def_expense_diger', name: 'Diğer', type: 'expense', icon: 'category'),

    // Gelir Kategorileri
    AppCategory(id: 'def_income_maas', name: 'Maaş', type: 'income', icon: 'account_balance_wallet'),
    AppCategory(id: 'def_income_ek_gelir', name: 'Ek Gelir', type: 'income', icon: 'trending_up'),
    AppCategory(id: 'def_income_yatirim', name: 'Yatırım', type: 'income', icon: 'show_chart'),
    AppCategory(id: 'def_income_diger', name: 'Diğer', type: 'income', icon: 'attach_money'),
  ];

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiServices>();
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _userCategoriesCollection {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('categories');
  }

  /// Kategorileri sırasıyla:
  /// 1. Firestore 'users/{userId}/categories' altından çeker (boşsa CategoryService ile başlatır).
  /// 2. Eğer Firestore boşsa API'yi dener (Bearer ID Token ile).
  /// 3. API 401 veya hata dönerse varsayılan kategori listesini yükler.
  Future<List<AppCategory>> getCategories() async {
    List<AppCategory> categories = [];

    // 1. Önce Firestore'dan çekmeyi dene
    try {
      final uid = _currentUserId;
      if (uid != null && uid.isNotEmpty) {
        // Eksikse Firestore WriteBatch başlatmasını tetikle
        await CategoryService().initializeDefaultCategories(uid);

        final col = _userCategoriesCollection;
        if (col != null) {
          final snapshot = await col.get().timeout(const Duration(seconds: 4));
          if (snapshot.docs.isNotEmpty) {
            categories = snapshot.docs.map((doc) {
              final data = doc.data();
              final rawType = (data['type'] ?? 'expense').toString().toLowerCase();
              final isInc = rawType == 'income' || rawType == 'gelir';
              return AppCategory(
                id: doc.id,
                name: data['name'] ?? '',
                type: isInc ? 'income' : 'expense',
                icon: data['icon'] ?? 'category',
                isSystem: data['isDefault'] ?? data['is_system'] ?? false,
                userId: uid,
              );
            }).toList();

            debugPrint("[KATEGORİ] Firestore'dan ${categories.length} kategori başarıyla yüklendi.");
            return _deduplicateAndEnsureDefaults(categories);
          }
        }
      }
    } catch (e) {
      debugPrint("[KATEGORİ FIRESTORE] Firestore'dan kategoriler okunurken hata: $e");
    }

    // 2. Harici REST API'yi dene
    try {
      final response = await _apiService.get(ApiConstants.categories);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        categories = list
            .map((item) => AppCategory.fromJson(item as Map<String, dynamic>))
            .where((c) => c.name != null && c.name!.trim().isNotEmpty)
            .toList();

        debugPrint("[KATEGORİ API] Sunucudan ${categories.length} kategori başarıyla alındı.");

        // Firestore'a da arka planda yedekle
        _syncToFirestore(categories);
        return _deduplicateAndEnsureDefaults(categories);
      }
    } catch (e) {
      debugPrint("[KATEGORİ API 401/HATA] Sunucu kategorileri alınamadı (${ApiServices.formatError(e)}), varsayılan kategoriler devreye giriyor.");
    }

    // 3. Her iki servis de başarısız veya boşsa varsayılan kategorileri kullan ve Firestore'a kaydet
    final fallbackList = defaultCategories.map((c) => AppCategory(
      id: c.id,
      name: c.name,
      type: c.type,
      icon: c.icon,
      isSystem: true,
      userId: _currentUserId,
    )).toList();

    _syncToFirestore(fallbackList);
    return fallbackList;
  }

  /// Varsayılan kategorilerin eksiksiz olduğundan ve çift kayıt oluşmadığından emin olur
  List<AppCategory> _deduplicateAndEnsureDefaults(List<AppCategory> sourceList) {
    final result = <AppCategory>[];
    final seen = <String>{};

    for (final c in sourceList) {
      if (c.name == null || c.name!.trim().isEmpty) continue;
      final key = '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase()}';
      if (seen.add(key)) {
        result.add(c);
      }
    }

    // Hem gelir hem gider için en az bir kategori olduğundan emin ol
    final hasExpense = result.any((c) => c.type == 'expense' || c.type == 'gider');
    final hasIncome = result.any((c) => c.type == 'income' || c.type == 'gelir');

    if (!hasExpense) {
      result.addAll(defaultCategories.where((c) => c.type == 'expense'));
    }
    if (!hasIncome) {
      result.addAll(defaultCategories.where((c) => c.type == 'income'));
    }

    return result;
  }

  /// Kategorileri Firestore'a senkronize eder
  Future<void> _syncToFirestore(List<AppCategory> list) async {
    final col = _userCategoriesCollection;
    if (col == null || list.isEmpty) return;

    try {
      for (final cat in list) {
        if (cat.name == null || cat.name!.trim().isEmpty) continue;
        final docId = cat.id ?? 'cat_${cat.name.hashCode.abs()}';
        await col.doc(docId).set({
          'name': cat.name,
          'type': cat.type,
          'icon': cat.icon,
          'is_system': cat.isSystem ?? false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("[KATEGORİ SYNC] Firestore senkronizasyon uyarısı: $e");
    }
  }

  /// Yeni kategori oluşturma (Firestore + Opsiyonel API)
  Future<AppCategory> createCategory(AppCategory category) async {
    final col = _userCategoriesCollection;
    String assignedId = category.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Firestore'a yaz
    if (col != null) {
      try {
        final docRef = await col.add({
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
          'is_system': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        assignedId = docRef.id;
        debugPrint("[KATEGORİ] Firestore'a eklendi: ${category.name} (ID: $assignedId)");
      } catch (e) {
        debugPrint("[KATEGORİ] Firestore ekleme hatası: $e");
      }
    }

    // 2. Harici API'yi de bilgilendirmeyi dene (Hata fırlatmadan)
    try {
      await _apiService.post(
        ApiConstants.categories,
        data: category.toJson(),
      );
    } catch (e) {
      debugPrint("[KATEGORİ API] Harici sunucuya eklenemedi (opsiyonel): $e");
    }

    return AppCategory(
      id: assignedId,
      name: category.name,
      type: category.type,
      icon: category.icon,
      isSystem: false,
      userId: _currentUserId,
    );
  }

  /// Kategori güncelleme
  Future<AppCategory> updateCategory(String id, AppCategory category) async {
    final col = _userCategoriesCollection;

    if (col != null && !id.startsWith('def_')) {
      try {
        await col.doc(id).set({
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("[KATEGORİ] Firestore güncellendi: $id");
      } catch (e) {
        debugPrint("[KATEGORİ] Firestore güncelleme hatası: $e");
      }
    }

    try {
      await _apiService.put(
        '${ApiConstants.categories}/$id',
        data: category.toJson(),
      );
    } catch (_) {}

    return category;
  }

  /// Kategori silme
  Future<bool> deleteCategory(String id) async {
    final col = _userCategoriesCollection;

    if (col != null && !id.startsWith('def_')) {
      try {
        await col.doc(id).delete();
        debugPrint("[KATEGORİ] Firestore'dan silindi: $id");
      } catch (e) {
        debugPrint("[KATEGORİ] Firestore silme hatası: $e");
      }
    }

    try {
      await _apiService.delete('${ApiConstants.categories}/$id');
    } catch (_) {}

    return true;
  }
}
