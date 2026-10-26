// ignore_for_file: must_call_super
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class FakeCategoryRepository extends CategoryRepository {
  List<AppCategory> mockCategories;
  FakeCategoryRepository(this.mockCategories);

  @override
  void onInit() {}

  @override
  Future<List<AppCategory>> getCategories() async {
    return List.from(mockCategories);
  }

  @override
  Future<AppCategory> createCategory(AppCategory category) async {
    final created = AppCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: category.name,
      type: category.type,
      icon: category.icon,
      isSystem: category.isSystem,
    );
    mockCategories.add(created);
    return created;
  }

  @override
  Future<AppCategory> updateCategory(String id, AppCategory category) async {
    final idx = mockCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = AppCategory(
        id: id,
        name: category.name,
        type: category.type,
        icon: category.icon,
        isSystem: category.isSystem,
      );
      mockCategories[idx] = updated;
      return updated;
    }
    throw Exception("Not found");
  }

  @override
  Future<bool> deleteCategory(String id) async {
    mockCategories.removeWhere((c) => c.id == id);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoriesController controller;
  late FakeCategoryRepository repo;

  setUp(() {
    Get.reset();
    repo = FakeCategoryRepository([
      AppCategory(
        id: '1',
        name: 'Yatırım Geliri',
        type: 'income',
        icon: 'trending-up',
      ),
      AppCategory(id: '2', name: 'Yemek', type: 'expense', icon: 'restaurant'),
      AppCategory(
        id: '3',
        name: '',
        type: 'expense',
        icon: 'wallet',
      ), // Boş isim
      AppCategory(
        id: '4',
        name: '   ',
        type: 'expense',
        icon: 'wallet',
      ), // Boşluk
      AppCategory(id: '5', name: 'aile', type: 'income', icon: 'cart'),
    ]);
    Get.put<CategoryRepository>(repo);
    controller = CategoriesController();
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('Detects empty categories correctly', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.hasEmptyCategories, isTrue);
    expect(controller.emptyCategoriesCount, equals(2));
  });

  test('cleanEmptyCategories deletes all empty categories', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.categories.length, equals(5));

    await controller.cleanEmptyCategories();

    expect(controller.hasEmptyCategories, isFalse);
    expect(controller.emptyCategoriesCount, equals(0));
    expect(controller.categories.length, equals(3));
    expect(
      controller.categories.map((c) => c.name),
      containsAll(['Yatırım Geliri', 'Yemek', 'aile']),
    );
  });

  test('deleteCategory removes category by id', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final success = await controller.deleteCategory('2'); // Yemek
    expect(success, isTrue);
    expect(controller.categories.any((c) => c.id == '2'), isFalse);
  });

  test('saveCategory creates new category and updates existing', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    // 1. Yeni Kategori Ekle
    final createSuccess = await controller.saveCategory(
      name: 'Kira',
      type: 'expense',
      icon: 'receipt',
    );
    expect(createSuccess, isTrue);
    expect(controller.categories.any((c) => c.name == 'Kira'), isTrue);

    // 2. Kategori Güncelle ('aile' -> 'Aile Destek')
    final updateSuccess = await controller.saveCategory(
      id: '5',
      name: 'Aile Destek',
      type: 'income',
      icon: 'family',
    );
    expect(updateSuccess, isTrue);
    final updated = controller.categories.firstWhere((c) => c.id == '5');
    expect(updated.name, equals('Aile Destek'));
    expect(updated.icon, equals('family'));
  });

  test('saveCategory rejects empty name', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final success = await controller.saveCategory(
      name: '   ',
      type: 'expense',
      icon: 'receipt',
    );
    expect(success, isFalse);
  });

  test('recommended categories detection and batch addition', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.hasMissingRecommendedCategories, isTrue);
    final missingCount = controller.missingRecommendedCategories.length;
    expect(missingCount, greaterThan(0));

    // Toplu ekleme
    final added = await controller.addRecommendedCategories(
      showSnackbar: false,
    );
    expect(added, equals(missingCount));
    expect(controller.hasMissingRecommendedCategories, isFalse);

    // Tüm yeni kategorilerin adları mevcut mu?
    final catNames = controller.categories.map((c) => c.name).toList();
    expect(catNames, contains('Market'));
    expect(catNames, contains('Faturalar'));
    expect(catNames, contains('Ulaşım'));
    expect(catNames, contains('Ev ve Kira'));
    expect(catNames, contains('Giyim'));
    expect(catNames, contains('Sağlık & Bakım'));
    expect(catNames, contains('Eğlence'));
    expect(catNames, contains('Eğitim'));
  });

  test('getCategoryIcon returns appropriate icons for all 8 categories', () {
    // 1. Alışveriş / Giyim
    expect(
      getCategoryIcon(
        iconName: 'shopping-bag',
        isSystem: false,
        type: 'expense',
      ),
      equals(Icons.shopping_bag_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Alışveriş / Giyim',
      ),
      equals(Icons.shopping_bag_rounded),
    );

    // 2. Kira & Ev
    expect(
      getCategoryIcon(iconName: 'home', isSystem: false, type: 'expense'),
      equals(Icons.home_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Kira & Ev',
      ),
      equals(Icons.home_rounded),
    );

    // 3. Abonelikler
    expect(
      getCategoryIcon(iconName: 'autorenew', isSystem: false, type: 'expense'),
      equals(Icons.autorenew_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Abonelikler',
      ),
      equals(Icons.autorenew_rounded),
    );

    // 4. Borç / Kredi
    expect(
      getCategoryIcon(
        iconName: 'credit-card',
        isSystem: false,
        type: 'expense',
      ),
      equals(Icons.credit_card_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Borç / Kredi',
      ),
      equals(Icons.credit_card_rounded),
    );

    // 5. Kişisel Bakım
    expect(
      getCategoryIcon(
        iconName: 'content-cut',
        isSystem: false,
        type: 'expense',
      ),
      equals(Icons.content_cut_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Kişisel Bakım',
      ),
      equals(Icons.content_cut_rounded),
    );

    // 6. Diğer / Çeşitli
    expect(
      getCategoryIcon(iconName: 'more', isSystem: false, type: 'expense'),
      equals(Icons.more_horiz_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'expense',
        categoryName: 'Diğer / Çeşitli',
      ),
      equals(Icons.more_horiz_rounded),
    );

    // 7. Burs / Harçlık
    expect(
      getCategoryIcon(iconName: 'school', isSystem: false, type: 'income'),
      equals(Icons.school_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'income',
        categoryName: 'Burs / Harçlık',
      ),
      equals(Icons.school_rounded),
    );

    // 8. İade / Alacak
    expect(
      getCategoryIcon(
        iconName: 'call-received',
        isSystem: false,
        type: 'income',
      ),
      equals(Icons.call_received_rounded),
    );
    expect(
      getCategoryIcon(
        iconName: 'receipt',
        isSystem: false,
        type: 'income',
        categoryName: 'İade / Alacak',
      ),
      equals(Icons.call_received_rounded),
    );
  });
}
