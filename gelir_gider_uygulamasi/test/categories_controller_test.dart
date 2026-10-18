// ignore_for_file: must_call_super
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
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
      AppCategory(id: '1', name: 'Yatırım Geliri', type: 'income', icon: 'trending-up'),
      AppCategory(id: '2', name: 'Yemek', type: 'expense', icon: 'restaurant'),
      AppCategory(id: '3', name: '', type: 'expense', icon: 'wallet'), // Boş isim
      AppCategory(id: '4', name: '   ', type: 'expense', icon: 'wallet'), // Boşluk
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
    expect(controller.categories.map((c) => c.name), containsAll(['Yatırım Geliri', 'Yemek', 'aile']));
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
}
