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
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static final List<AppCategory> defaultCategories = [
    // -------------------------------------------------------------------------
    // Gider Kategorileri (Kullanıcının talep ettiği sabit 10 kategori)
    // -------------------------------------------------------------------------
    AppCategory(
      id: 'def_expense_market_gida',
      name: 'Market',
      type: 'expense',
      icon: 'shopping_cart',
      color: 0xFFFF7043,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_yeme_icme',
      name: 'Yemek',
      type: 'expense',
      icon: 'restaurant',
      color: 0xFFFFA726,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_faturalar_abonelikler',
      name: 'Faturalar',
      type: 'expense',
      icon: 'receipt_long',
      color: 0xFF42A5F5,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_ulasim_yakit',
      name: 'Ulaşım',
      type: 'expense',
      icon: 'directions_car',
      color: 0xFF26A69A,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_ev_yasam',
      name: 'Ev ve Kira',
      type: 'expense',
      icon: 'home',
      color: 0xFF7E57C2,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_giyim_aksesuar',
      name: 'Giyim',
      type: 'expense',
      icon: 'checkroom',
      color: 0xFFEC407A,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_saglik_bakim',
      name: 'Sağlık & Bakım',
      type: 'expense',
      icon: 'local_hospital',
      color: 0xFFEF5350,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_eglence_hobi',
      name: 'Eğlence',
      type: 'expense',
      icon: 'sports_esports',
      color: 0xFFAB47BC,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_egitim_gelisim',
      name: 'Eğitim',
      type: 'expense',
      icon: 'school',
      color: 0xFF5C6BC0,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_expense_diger_harcamalar',
      name: 'Diğer Harcamalar',
      type: 'expense',
      icon: 'more_horiz',
      color: 0xFF78909C,
      isSystem: true,
    ),

    // -------------------------------------------------------------------------
    // Gelir Kategorileri
    // -------------------------------------------------------------------------
    AppCategory(
      id: 'def_income_maas',
      name: 'Maaş',
      type: 'income',
      icon: 'account_balance_wallet',
      color: 0xFF2E7D32,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_income_ek_gelir',
      name: 'Ek Gelir',
      type: 'income',
      icon: 'trending_up',
      color: 0xFF43A047,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_income_yatirim',
      name: 'Yatırım',
      type: 'income',
      icon: 'show_chart',
      color: 0xFF00897B,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_income_hediye',
      name: 'Hediye',
      type: 'income',
      icon: 'card_giftcard',
      color: 0xFFF57C00,
      isSystem: true,
    ),
    AppCategory(
      id: 'def_income_diger',
      name: 'Diğer',
      type: 'income',
      icon: 'attach_money',
      color: 0xFF00ACC1,
      isSystem: true,
    ),
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
  /// 1. Firestore 'users/{userId}/categories' altından çeker.
  ///    CategoryService.initializeDefaultCategories ile sabit kategorilerin eksiksiz olduğunu garantiler.
  /// 2. Hata veya çevrimdışı durumda sabit varsayılan kategori listesini döner.
  Future<List<AppCategory>> getCategories() async {
    List<AppCategory> categories = [];

    // 1. Önce Firestore'dan çekmeyi dene
    try {
      final uid = _currentUserId;
      if (uid != null && uid.isNotEmpty) {
        // Eksikse Firestore WriteBatch başlatmasını tetikle ve eski kategorileri temizle
        await CategoryService().initializeDefaultCategories(uid);

        final col = _userCategoriesCollection;
        if (col != null) {
          final snapshot = await col.get().timeout(const Duration(seconds: 4));
          if (snapshot.docs.isNotEmpty) {
            categories = snapshot.docs.map((doc) {
              final data = doc.data();
              final rawType = (data['type'] ?? 'expense')
                  .toString()
                  .toLowerCase();
              final isInc = rawType == 'income' || rawType == 'gelir';
              int? parsedColor;
              final rawColor = data['color'];
              if (rawColor is int) {
                parsedColor = rawColor;
              } else if (rawColor is String) {
                parsedColor =
                    int.tryParse(rawColor) ??
                    int.tryParse(rawColor.replaceAll('#', '0xFF'));
              }

              return AppCategory(
                id: doc.id,
                name: data['name'] ?? '',
                type: isInc ? 'income' : 'expense',
                icon: data['icon'] ?? 'category',
                color: parsedColor,
                isSystem: data['isDefault'] ?? data['is_system'] ?? false,
                userId: uid,
              );
            }).toList();

            debugPrint(
              "[KATEGORİ] Firestore'dan ${categories.length} kategori başarıyla yüklendi.",
            );
            return _deduplicateAndEnsureDefaults(categories);
          }
        }
      }
    } catch (e) {
      debugPrint(
        "[KATEGORİ FIRESTORE] Firestore'dan kategoriler okunurken hata: $e",
      );
    }

    // 2. Çevrimdışı / İlk açılış veya hata durumu: Sabit kanonik kategorileri dön
    final fallbackList = defaultCategories
        .map(
          (c) => AppCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            icon: c.icon,
            color: c.color,
            isSystem: true,
            userId: _currentUserId,
          ),
        )
        .toList();

    return fallbackList;
  }

  /// Varsayılan kategorilerin eksiksiz olduğunu, asla bozulmadığını ve
  /// kullanıcının özel kategorileriyle birlikte doğru sırada sunulduğunu garanti eder.
  List<AppCategory> _deduplicateAndEnsureDefaults(
    List<AppCategory> sourceList,
  ) {
    final result = <AppCategory>[];
    final seen = <String>{};

    // 1. Önce kanonik varsayılan kategorileri ekle (her zaman en başta ve eksiksiz)
    for (final def in defaultCategories) {
      final key =
          '${TurkishStringHelper.normalizeForSearch(def.name ?? "")}_${(def.type ?? "").toLowerCase()}';
      seen.add(key);

      // Firestore'da varsa eşleşen ID'yi al, yoksa varsayılan ID'yi ata
      final match = sourceList.firstWhereOrNull(
        (c) =>
            c.id == def.id ||
            TurkishStringHelper.normalizeForSearch(c.name ?? "") ==
                TurkishStringHelper.normalizeForSearch(def.name ?? ""),
      );

      result.add(
        AppCategory(
          id: match?.id ?? def.id,
          name: def.name,
          type: def.type,
          icon: def.icon,
          color: def.color,
          isSystem: true,
          userId: _currentUserId,
        ),
      );
    }

    // 2. Kullanıcının oluşturduğu özel kategorileri ekle (eski default kategorileri atla)
    for (final c in sourceList) {
      if (c.name == null || c.name!.trim().isEmpty) continue;
      // Eski sistem kategorilerini (def_expense_yemek vb.) eliyoruz
      if (c.isSystem == true || (c.id != null && c.id!.startsWith('def_'))) {
        continue;
      }
      final key =
          '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase()}';
      if (seen.add(key)) {
        result.add(c);
      }
    }

    return result;
  }

  /// Yeni kategori oluşturma (Firestore + Opsiyonel API)
  Future<AppCategory> createCategory(AppCategory category) async {
    final col = _userCategoriesCollection;
    String assignedId =
        category.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}';

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
        debugPrint(
          "[KATEGORİ] Firestore'a eklendi: ${category.name} (ID: $assignedId)",
        );
      } catch (e) {
        debugPrint("[KATEGORİ] Firestore ekleme hatası: $e");
      }
    }

    // 2. Harici API'yi de bilgilendirmeyi dene (Hata fırlatmadan)
    try {
      await _apiService.post(ApiConstants.categories, data: category.toJson());
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
