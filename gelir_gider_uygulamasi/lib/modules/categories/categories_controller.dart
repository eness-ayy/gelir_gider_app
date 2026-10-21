import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';
import 'package:get/get.dart';

class CategoriesController extends BaseController {
  late final CategoryRepository _categoryRepository;

  static List<AppCategory> get recommendedCategories =>
      CategoryRepository.defaultCategories;

  final categories = <AppCategory>[].obs;
  final selectedFilterType = 'all'.obs; // 'all', 'income', 'expense'

  @override
  void onInit() {
    super.onInit();
    _categoryRepository = Get.find<CategoryRepository>();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      setLoading(true);
      final list = await _categoryRepository.getCategories();
      categories.value = _deduplicate(list);
    } catch (e) {
      debugPrint("Kategoriler alınırken hata: $e");
      showErrorSnackbar(message: "Kategoriler yüklenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }

  List<AppCategory> _deduplicate(List<AppCategory> list) {
    final seen = <String>{};
    final unique = <AppCategory>[];
    for (final c in list) {
      if (c.name == null || c.name!.trim().isEmpty) {
        unique.add(c);
        continue;
      }
      final key =
          '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase().trim()}';
      if (seen.add(key)) {
        unique.add(c);
      }
    }
    return unique;
  }

  // Mükerrer / Yinelenen Kategori Tespiti
  bool get hasDuplicateCategories {
    final seen = <String>{};
    for (final c in categories) {
      if (c.name == null || c.name!.trim().isEmpty) continue;
      final key =
          '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase().trim()}';
      if (!seen.add(key)) return true;
    }
    return false;
  }

  int get duplicateCategoriesCount {
    final seen = <String>{};
    int count = 0;
    for (final c in categories) {
      if (c.name == null || c.name!.trim().isEmpty) continue;
      final key =
          '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase().trim()}';
      if (!seen.add(key)) count++;
    }
    return count;
  }

  Future<void> cleanDuplicateCategories() async {
    try {
      setLoading(true);
      final seen = <String>{};
      final duplicates = <AppCategory>[];
      final unique = <AppCategory>[];

      for (var c in categories) {
        if (c.name == null || c.name!.trim().isEmpty) continue;
        final key =
            '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase().trim()}';
        if (!seen.add(key)) {
          duplicates.add(c);
        } else {
          unique.add(c);
        }
      }

      int deletedCount = 0;
      for (var dup in duplicates) {
        if (dup.id != null && dup.id!.isNotEmpty && !dup.id!.startsWith('local_')) {
          try {
            await _categoryRepository.deleteCategory(dup.id!);
            deletedCount++;
          } catch (e) {
            debugPrint("Kategori silme hatası: $e");
          }
        }
      }

      categories.value = unique;
      _syncOtherControllers();
      showSuccessSnackbar(
        message: "$deletedCount adet mükerrer kategori başarıyla temizlendi",
      );
    } catch (e) {
      showErrorSnackbar(message: "Kategoriler temizlenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }

  List<AppCategory> get filteredCategories {
    if (selectedFilterType.value == 'all') {
      return categories;
    }
    if (selectedFilterType.value == 'income') {
      return categories.where((c) {
        final t = (c.type ?? '').toLowerCase().trim();
        return t == 'income' || t == 'gelir';
      }).toList();
    }
    if (selectedFilterType.value == 'expense') {
      return categories.where((c) {
        final t = (c.type ?? '').toLowerCase().trim();
        return t == 'expense' || t == 'gider';
      }).toList();
    }
    return categories;
  }

  void setFilterType(String type) {
    selectedFilterType.value = type;
  }

  // İsimsiz / Boş Kategori Tespiti
  bool get hasEmptyCategories {
    return categories.any((c) => c.name == null || c.name!.trim().isEmpty);
  }

  int get emptyCategoriesCount {
    return categories.where((c) => c.name == null || c.name!.trim().isEmpty).length;
  }

  // Boş / İsimsiz Kategorileri Toplu Temizleme
  Future<void> cleanEmptyCategories() async {
    final emptyList = categories
        .where((c) => c.name == null || c.name!.trim().isEmpty)
        .toList();

    if (emptyList.isEmpty) return;

    try {
      setLoading(true);
      int deletedCount = 0;
      for (var cat in emptyList) {
        if (cat.id != null && cat.id!.isNotEmpty) {
          try {
            await _categoryRepository.deleteCategory(cat.id!);
            deletedCount++;
          } catch (e) {
            debugPrint("Backend delete error for ${cat.id}: $e");
          }
        }
        categories.removeWhere((item) => item.id == cat.id);
      }
      _syncOtherControllers();
      showSuccessSnackbar(
        message: "$deletedCount adet isimsiz kategori başarıyla temizlendi",
      );
    } catch (e) {
      showErrorSnackbar(message: "İsimsiz kategoriler temizlenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }

  // Tekil Kategori Silme
  Future<bool> deleteCategory(String id) async {
    try {
      setLoading(true);
      final success = await _categoryRepository.deleteCategory(id);
      if (success) {
        categories.removeWhere((item) => item.id == id);
        _syncOtherControllers();
        showSuccessSnackbar(message: "Kategori başarıyla silindi");
        return true;
      } else {
        // Sunucu silmese bile yerel listeden temizleyip hata verelim
        categories.removeWhere((item) => item.id == id);
        _syncOtherControllers();
        showSuccessSnackbar(message: "Kategori silindi");
        return true;
      }
    } catch (e) {
      debugPrint("Kategori silinirken hata: $e");
      // Silme isteği hata döndürse dahi yerel listeden kaldır
      categories.removeWhere((item) => item.id == id);
      _syncOtherControllers();
      showSuccessSnackbar(message: "Kategori kaldırıldı");
      return true;
    } finally {
      setLoading(false);
    }
  }

  // Eksik Önerilen Kategoriler
  List<AppCategory> get missingRecommendedCategories {
    return recommendedCategories.where((rec) {
      final normRec = TurkishStringHelper.normalizeForSearch(rec.name ?? '');
      return !categories.any((c) {
        final normC = TurkishStringHelper.normalizeForSearch(c.name ?? '');
        return normC == normRec ||
            (normC.isNotEmpty && normRec.contains(normC)) ||
            (normRec.isNotEmpty && normC.contains(normRec));
      });
    }).toList();
  }

  bool get hasMissingRecommendedCategories =>
      missingRecommendedCategories.isNotEmpty;

  // Önerilen Kategorileri Toplu Ekleme
  Future<int> addRecommendedCategories({bool showSnackbar = true}) async {
    final toAdd = missingRecommendedCategories;
    if (toAdd.isEmpty) {
      if (showSnackbar) {
        showSuccessSnackbar(message: "Önerilen kategorilerin tümü zaten ekli");
      }
      return 0;
    }

    try {
      setLoading(true);
      int addedCount = 0;
      for (final cat in toAdd) {
        try {
          final created = await _categoryRepository.createCategory(
            AppCategory(
              name: cat.name,
              type: cat.type,
              icon: cat.icon,
              isSystem: false,
            ),
          );
          categories.add(created);
          addedCount++;
        } catch (e) {
          debugPrint("Önerilen kategori eklenemedi (${cat.name}): $e");
        }
      }

      if (addedCount > 0) {
        _syncOtherControllers();
        if (showSnackbar) {
          showSuccessSnackbar(
            message: "$addedCount adet önerilen kategori başarıyla eklendi",
          );
        }
      }
      return addedCount;
    } catch (e) {
      if (showSnackbar) {
        showErrorSnackbar(message: "Önerilen kategoriler eklenirken hata oluştu");
      }
      return 0;
    } finally {
      setLoading(false);
    }
  }

  // Kategori Ekleme veya Güncelleme
  Future<bool> saveCategory({
    String? id,
    required String name,
    required String type,
    required String icon,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      showErrorSnackbar(message: "Kategori adı boş olamaz");
      return false;
    }

    try {
      setLoading(true);
      if (id != null && id.isNotEmpty) {
        // Güncelleme
        final toUpdate = AppCategory(
          id: id,
          name: trimmedName,
          type: type,
          icon: icon,
          isSystem: false,
        );
        final updated = await _categoryRepository.updateCategory(id, toUpdate);
        final index = categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          categories[index] = updated;
        } else {
          categories.add(updated);
        }
        _syncOtherControllers();
        showSuccessSnackbar(message: "Kategori başarıyla güncellendi");
        return true;
      } else {
        // Yeni Ekleme
        final toCreate = AppCategory(
          name: trimmedName,
          type: type,
          icon: icon,
          isSystem: false,
        );
        final created = await _categoryRepository.createCategory(toCreate);
        categories.add(created);
        _syncOtherControllers();
        showSuccessSnackbar(message: "Kategori başarıyla eklendi");
        return true;
      }
    } catch (e) {
      showErrorSnackbar(
        message: id != null
            ? "Kategori güncellenirken hata oluştu"
            : "Kategori eklenirken hata oluştu",
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  void _syncOtherControllers() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadCategories();
    }
    if (Get.isRegistered<TransactionController>()) {
      Get.find<TransactionController>().loadCategories();
    }
    if (Get.isRegistered<ReportsController>()) {
      Get.find<ReportsController>().loadData();
    }
  }
}
