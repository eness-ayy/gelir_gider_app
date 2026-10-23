import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1. STANDART VARSAYILAN KATEGORİ LİSTESİ
  /// Tüm kullanıcılar için geçerli olan sabit varsayılan kategoriler
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
      id: 'def_income_diger',
      name: 'Diğer',
      type: 'gelir',
      icon: 'attach_money',
      color: 0xFF00ACC1, // Cyan
      isDefault: true,
    ),

    // -------------------------------------------------------------------------
    // GİDER KATEGORİLERİ
    // -------------------------------------------------------------------------
    CategoryModel(
      id: 'def_expense_yemek',
      name: 'Yemek & Mutfak',
      type: 'gider',
      icon: 'restaurant',
      color: 0xFFFF7043, // Turuncu
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_fatura',
      name: 'Fatura & Aidat',
      type: 'gider',
      icon: 'receipt_long',
      color: 0xFFE53935, // Kırmızı
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_kira',
      name: 'Kira',
      type: 'gider',
      icon: 'home',
      color: 0xFF8E24AA, // Mor
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_ulasim',
      name: 'Ulaşım',
      type: 'gider',
      icon: 'directions_bus',
      color: 0xFF1E88E5, // Mavi
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_alisveris',
      name: 'Alışveriş',
      type: 'gider',
      icon: 'shopping_bag',
      color: 0xFFD81B60, // Pembe
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_eglence',
      name: 'Eğlence',
      type: 'gider',
      icon: 'movie',
      color: 0xFFFB8C00, // Koyu Turuncu
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_saglik',
      name: 'Sağlık',
      type: 'gider',
      icon: 'local_hospital',
      color: 0xFF00897B, // Yeşilimsi
      isDefault: true,
    ),
    CategoryModel(
      id: 'def_expense_diger',
      name: 'Diğer',
      type: 'gider',
      icon: 'category',
      color: 0xFF757575, // Gri
      isDefault: true,
    ),
  ];

  /// Kullanıcının alt koleksiyonu: users/{userId}/categories
  CollectionReference<Map<String, dynamic>> _userCategoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  /// 2. VARSAYILAN KATEGORİ BAŞLATMA VE YÖNETİM METODU
  /// - users/{userId}/categories koleksiyonunu kontrol eder.
  /// - Tamamen boşsa WriteBatch kullanarak tek seferde toplu olarak ekler.
  /// - Zaten kategoriler varsa hiçbir veriyi ezmez ve geçiş yapar.
  Future<void> initializeDefaultCategories(String userId) async {
    if (userId.trim().isEmpty) {
      debugPrint("[CATEGORY_SERVICE UYARI] Geçersiz veya boş userId!");
      return;
    }

    try {
      final colRef = _userCategoriesRef(userId);
      final existingDocs = await colRef.get().timeout(const Duration(seconds: 6));

      // Kullanıcının halihazırda kategorileri varsa mevcut verileri koru
      if (existingDocs.docs.isNotEmpty) {
        debugPrint(
          "[CATEGORY_SERVICE] Kullanıcının ($userId) zaten ${existingDocs.docs.length} kategorisi mevcut. Mevcut veriler korundu.",
        );
        return;
      }

      // Koleksiyon tamamen boş: WriteBatch ile toplu ekle
      debugPrint(
        "[CATEGORY_SERVICE] $userId kullanıcısının kategorisi bulunamadı. ${defaultCategories.length} varsayılan kategori WriteBatch ile yükleniyor...",
      );

      final WriteBatch batch = _firestore.batch();

      for (final cat in defaultCategories) {
        final docRef = colRef.doc(cat.id);
        batch.set(docRef, cat.toMap());
      }

      await batch.commit();

      debugPrint(
        "[CATEGORY_SERVICE BAŞARILI] $userId için ${defaultCategories.length} varsayılan kategori Firestore'a yazıldı.",
      );
    } catch (e) {
      debugPrint("[CATEGORY_SERVICE HATA] Varsayılan kategoriler başlatılamadı: $e");
    }
  }

  /// Kullanıcının kategorilerini canlı dinleyen Stream
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    if (userId.trim().isEmpty) return Stream.value([]);

    return _userCategoriesRef(userId)
        .snapshots()
        .map((snapshot) {
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
    debugPrint("[CATEGORY_SERVICE] Özel kategori eklendi: ${newCat.name} (ID: ${newCat.id})");
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
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
