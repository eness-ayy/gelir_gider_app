import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1. STANDART VE SABİT VARSAYILAN KATEGORİ LİSTESİ
  /// Kullanıcının isteği doğrultusunda asla değişmeyen kanonik kategoriler
  static final List<CategoryModel> defaultCategories = [
    // -------------------------------------------------------------------------
    // GELİR KATEGORİLERİ
    // -------------------------------------------------------------------------
    CategoryModel(
      id: 'def_income_maas',
      name: 'Maaş',
      type: 'gelir',
      icon: 'account_balance_wallet',
      color: 0xFF2E7D32, // Koyu Yeşil
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_income_ek_gelir',
      name: 'Ek Gelir',
      type: 'gelir',
      icon: 'trending_up',
      color: 0xFF43A047, // Yeşil
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_income_yatirim',
      name: 'Yatırım',
      type: 'gelir',
      icon: 'show_chart',
      color: 0xFF00897B, // Teal
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_income_hediye',
      name: 'Hediye',
      type: 'gelir',
      icon: 'card_giftcard',
      color: 0xFFF57C00,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_income_diger',
      name: 'Diğer',
      type: 'gelir',
      icon: 'attach_money',
      color: 0xFF00ACC1, // Cyan
      isDefault: true,
    ),

    // -------------------------------------------------------------------------
    // GİDER KATEGORİLERİ (Kullanıcı tarafından sabitlenen 10 kategori)
    // -------------------------------------------------------------------------
    CategoryModel(
      id: 'def_expense_market_gida',
      name: 'Market',
      type: 'gider',
      icon: 'shopping_cart',
      color: 0xFFFF7043,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_yeme_icme',
      name: 'Yemek',
      type: 'gider',
      icon: 'restaurant',
      color: 0xFFFFA726,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_faturalar_abonelikler',
      name: 'Faturalar',
      type: 'gider',
      icon: 'receipt_long',
      color: 0xFF42A5F5,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_ulasim_yakit',
      name: 'Ulaşım',
      type: 'gider',
      icon: 'directions_car',
      color: 0xFF26A69A,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_ev_yasam',
      name: 'Ev ve Kira',
      type: 'gider',
      icon: 'home',
      color: 0xFF7E57C2,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_giyim_aksesuar',
      name: 'Giyim',
      type: 'gider',
      icon: 'checkroom',
      color: 0xFFEC407A,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_saglik_bakim',
      name: 'Sağlık & Bakım',
      type: 'gider',
      icon: 'local_hospital',
      color: 0xFFEF5350,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_eglence_hobi',
      name: 'Eğlence',
      type: 'gider',
      icon: 'sports_esports',
      color: 0xFFAB47BC,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_egitim_gelisim',
      name: 'Eğitim',
      type: 'gider',
      icon: 'school',
      color: 0xFF5C6BC0,
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_diger_harcamalar',
      name: 'Diğer Harcamalar',
      type: 'gider',
      icon: 'more_horiz',
      color: 0xFF78909C,
      isDefault: true,
    ),
  ];

  /// Kullanıcının alt koleksiyonu: users/{userId}/categories
  CollectionReference<Map<String, dynamic>> _userCategoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  /// 2. VARSAYILAN KATEGORİ BAŞLATMA VE YÖNETİM METODU
  /// - Kullanıcının kategorilerini kontrol eder.
  /// - Kanonik varsayılan kategorilerin (10 gider + 4 gelir) eksiksiz olmasını sağlar.
  /// - Eski / artık kullanılmayan varsayılan kategorileri siler.
  /// - Kullanıcının sonradan eklediği özel kategorilere asla dokunmaz.
  Future<void> initializeDefaultCategories(String userId) async {
    if (userId.trim().isEmpty) {
      debugPrint("[CATEGORY_SERVICE UYARI] Geçersiz veya boş userId!");
      return;
    }

    try {
      final colRef = _userCategoriesRef(userId);
      final existingDocs = await colRef.get().timeout(
        const Duration(seconds: 6),
      );
      final WriteBatch batch = _firestore.batch();
      bool batchHasOperations = false;

      // 1. Mevcut dokümanları indeksle
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> existingById =
          {};
      final Map<String, DocumentSnapshot<Map<String, dynamic>>>
      existingByNameAndType = {};

      for (final doc in existingDocs.docs) {
        existingById[doc.id] = doc;
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final type = (data['type'] ?? 'gider').toString().trim().toLowerCase();
        final normType = (type == 'expense' || type == 'gider')
            ? 'gider'
            : 'gelir';
        if (name.isNotEmpty) {
          existingByNameAndType['${name}_$normType'] = doc;
        }
      }

      // 2. Eski / geçersiz varsayılan kategorileri temizle (Örn: eski 'Yemek & Mutfak', 'Kira', vb.)
      final canonicalIds = defaultCategories.map((c) => c.id).toSet();
      final canonicalNames = defaultCategories
          .map((c) => '${c.name.trim().toLowerCase()}_${c.type}')
          .toSet();

      for (final doc in existingDocs.docs) {
        final data = doc.data();
        final isSystem =
            data['isDefault'] == true ||
            data['is_system'] == true ||
            doc.id.startsWith('def_');
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final type = (data['type'] ?? 'gider').toString().trim().toLowerCase();
        final normType = (type == 'expense' || type == 'gider')
            ? 'gider'
            : 'gelir';
        final key = '${name}_$normType';

        if (isSystem &&
            !canonicalIds.contains(doc.id) &&
            !canonicalNames.contains(key)) {
          batch.delete(doc.reference);
          batchHasOperations = true;
          debugPrint(
            "[CATEGORY_SERVICE] Eski sistem kategorisi temizlendi: ${doc.id} - ${data['name']}",
          );
        }
      }

      // 3. Kanonik varsayılan kategorileri ekle veya güncelle
      for (final cat in defaultCategories) {
        final key = '${cat.name.trim().toLowerCase()}_${cat.type}';
        final existingDoc = existingById[cat.id] ?? existingByNameAndType[key];

        if (existingDoc == null) {
          final docRef = colRef.doc(cat.id);
          batch.set(docRef, cat.toMap());
          batchHasOperations = true;
        } else {
          final data = existingDoc.data() ?? {};
          final currentIcon = data['icon'];
          final currentColor = data['color'];
          final isDefault = data['isDefault'];

          if (currentIcon != cat.icon ||
              currentColor != cat.color ||
              isDefault != true) {
            batch.set(existingDoc.reference, {
              'name': cat.name,
              'type': cat.type,
              'icon': cat.icon,
              'color': cat.color,
              'isDefault': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            batchHasOperations = true;
          }
        }
      }

      if (batchHasOperations) {
        await batch.commit();
        debugPrint(
          "[CATEGORY_SERVICE BAŞARILI] $userId için standart kategoriler güncellendi ve Firestore'a senkronize edildi.",
        );
      }
    } catch (e) {
      debugPrint(
        "[CATEGORY_SERVICE HATA] Varsayılan kategoriler başlatılamadı: $e",
      );
    }
  }

  /// Kullanıcının kategorilerini canlı dinleyen Stream
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    if (userId.trim().isEmpty) return Stream.value([]);

    return _userCategoriesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Kullanıcının kategorilerini tek seferlik liste olarak getirir
  Future<List<CategoryModel>> getCategories(String userId) async {
    if (userId.trim().isEmpty) return defaultCategories;

    try {
      final snapshot = await _userCategoriesRef(userId).get();
      if (snapshot.docs.isEmpty) {
        // Eğer boşsa hemen arka planda varsayılanları oluştur ve varsayılanları dön
        initializeDefaultCategories(userId);
        return defaultCategories;
      }

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("[CATEGORY_SERVICE] getCategories hatası: $e");
      return defaultCategories;
    }
  }

  /// Yeni özel kategori ekleme
  Future<CategoryModel> addCustomCategory(
    String userId, {
    required String name,
    required String type,
    required String icon,
    required int color,
  }) async {
    final colRef = _userCategoriesRef(userId);
    final docRef = colRef.doc();

    final newCat = CategoryModel(
      id: docRef.id,
      name: name.trim(),
      type: type.toLowerCase() == 'income' || type.toLowerCase() == 'gelir'
          ? 'gelir'
          : 'gider',
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(newCat.toMap());
    debugPrint(
      "[CATEGORY_SERVICE] Özel kategori eklendi: ${newCat.name} (ID: ${newCat.id})",
    );
    return newCat;
  }

  /// Kategori güncelleme
  Future<void> updateCategory(String userId, CategoryModel category) async {
    final docRef = _userCategoriesRef(userId).doc(category.id);
    await docRef.set(category.toMap(), SetOptions(merge: true));
    debugPrint("[CATEGORY_SERVICE] Kategori güncellendi: ${category.name}");
  }

  /// Kategori silme
  Future<void> deleteCategory(String userId, String categoryId) async {
    final docRef = _userCategoriesRef(userId).doc(categoryId);
    await docRef.delete();
    debugPrint("[CATEGORY_SERVICE] Kategori silindi: $categoryId");
  }

  /// İkon dizesini Flutter IconData nesnesine çeviren yardımcı fonksiyon
  static IconData getIconData(String iconName) {
    switch (iconName) {
      // Gelir ikonları
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'attach_money':
        return Icons.attach_money;
      case 'school':
        return Icons.school;
      case 'call_received':
      case 'call-received':
        return Icons.call_received;
      case 'card_giftcard':
      case 'card-giftcard':
      case 'gift':
        return Icons.card_giftcard;

      // Gider ikonları
      case 'restaurant':
        return Icons.restaurant;
      case 'receipt_long':
      case 'receipt-long':
      case 'receipt':
        return Icons.receipt_long;
      case 'home':
        return Icons.home;
      case 'directions_bus':
      case 'directions-bus':
        return Icons.directions_bus;
      case 'directions_car':
      case 'directions-car':
      case 'car':
        return Icons.directions_car;
      case 'checkroom':
        return Icons.checkroom;
      case 'sports_esports':
      case 'sports-esports':
      case 'game-controller':
      case 'game_controller':
      case 'games':
        return Icons.sports_esports;
      case 'shopping_bag':
      case 'shopping-bag':
        return Icons.shopping_bag;
      case 'shopping_cart':
      case 'shopping-cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
      case 'local-hospital':
        return Icons.local_hospital;
      case 'autorenew':
        return Icons.autorenew;
      case 'credit_card':
      case 'credit-card':
        return Icons.credit_card;
      case 'content_cut':
      case 'content-cut':
        return Icons.content_cut;
      case 'more':
      case 'more_horiz':
      case 'more-horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
