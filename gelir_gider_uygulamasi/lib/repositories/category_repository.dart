import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';
import 'package:get/get.dart';

class CategoryRepository extends GetxService {
  late final ApiServices _apiService;

  static final List<AppCategory> defaultCategories = [
    // Gider Kategorileri
    AppCategory(name: 'Alışveriş / Giyim', type: 'expense', icon: 'shopping-bag'),
    AppCategory(name: 'Kira & Ev', type: 'expense', icon: 'home'),
    AppCategory(name: 'Abonelikler', type: 'expense', icon: 'autorenew'),
    AppCategory(name: 'Borç / Kredi', type: 'expense', icon: 'credit-card'),
    AppCategory(name: 'Kişisel Bakım', type: 'expense', icon: 'content-cut'),
    AppCategory(name: 'Diğer / Çeşitli', type: 'expense', icon: 'more'),
    // Gelir Kategorileri
    AppCategory(name: 'Burs / Harçlık', type: 'income', icon: 'school'),
    AppCategory(name: 'İade / Alacak', type: 'income', icon: 'call-received'),
  ];

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiServices>();
  }

  Future<List<AppCategory>> getCategories() async {
    List<AppCategory> validCategories = [];

    try {
      final response = await _apiService.get(ApiConstants.categories);

      if (response.statusCode == 200) {
        var gelenVeri = response.data as List;
        final allCategories = gelenVeri
            .map((category) => AppCategory.fromJson(category))
            .toList();

        // İsimsiz / Boş kategorileri tespit et ve arkaplanda sunucudan sil
        final emptyCategories = allCategories
            .where((c) => c.name == null || c.name!.trim().isEmpty)
            .toList();

        if (emptyCategories.isNotEmpty) {
          for (final emptyCat in emptyCategories) {
            if (emptyCat.id != null && emptyCat.id!.isNotEmpty) {
              deleteCategory(emptyCat.id!).catchError((_) => false);
            }
          }
        }

        // Yalnızca geçerli ada sahip kategorileri al ve kopyaları tespit et
        final seenKeys = <String>{};
        final duplicates = <AppCategory>[];

        for (final cat in allCategories) {
          if (cat.name == null || cat.name!.trim().isEmpty) continue;
          final key =
              '${TurkishStringHelper.normalizeForSearch(cat.name ?? "")}_${(cat.type ?? "").toLowerCase().trim()}';
          if (!seenKeys.add(key)) {
            duplicates.add(cat);
          } else {
            validCategories.add(cat);
          }
        }

        // Kopyaları arkaplanda sunucudan temizle
        if (duplicates.isNotEmpty) {
          for (final dup in duplicates) {
            if (dup.id != null &&
                dup.id!.isNotEmpty &&
                !dup.id!.startsWith('local_')) {
              deleteCategory(dup.id!).catchError((_) => false);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Kategoriler sunucudan alınamadı: $e");
    }

    // Eksik önerilen kategorileri tespit et
    final missing = defaultCategories.where((def) {
      final normDef = TurkishStringHelper.normalizeForSearch(def.name ?? '');
      final defType = (def.type ?? '').toLowerCase().trim();
      return !validCategories.any((c) {
        final cType = (c.type ?? '').toLowerCase().trim();
        if (cType != defType) return false;
        final normC = TurkishStringHelper.normalizeForSearch(c.name ?? '');
        return normC == normDef ||
            (normC.isNotEmpty && normDef.contains(normC)) ||
            (normDef.isNotEmpty && normC.contains(normDef));
      });
    }).toList();

    // Eksik olanları sunucuya kaydetmeye çalış ve listeye ekle
    if (missing.isNotEmpty) {
      for (final cat in missing) {
        // Önceden eklenmişse çift ekleme yapma
        final normCat = TurkishStringHelper.normalizeForSearch(cat.name ?? '');
        final catType = (cat.type ?? '').toLowerCase().trim();
        final alreadyExists = validCategories.any((c) {
          final cType = (c.type ?? '').toLowerCase().trim();
          final normC = TurkishStringHelper.normalizeForSearch(c.name ?? '');
          return cType == catType && normC == normCat;
        });

        if (alreadyExists) continue;

        AppCategory? created;
        try {
          created = await createCategory(AppCategory(
            name: cat.name,
            type: cat.type,
            icon: cat.icon,
            isSystem: false,
          ));
        } catch (e) {
          debugPrint("Sunucuya kategori eklenemedi (${cat.name}): $e");
        }

        validCategories.add(created ??
            AppCategory(
              id: 'local_${cat.name.hashCode.abs()}',
              name: cat.name,
              type: cat.type,
              icon: cat.icon,
              isSystem: false,
            ));
      }
    }

    // Son güvenlik filtresi: Listeyi kesin olarak tekilleştir
    final uniqueResult = <AppCategory>[];
    final finalKeys = <String>{};
    for (final c in validCategories) {
      final key =
          '${TurkishStringHelper.normalizeForSearch(c.name ?? "")}_${(c.type ?? "").toLowerCase().trim()}';
      if (finalKeys.add(key)) {
        uniqueResult.add(c);
      }
    }

    return uniqueResult;
  }

  Future<AppCategory> createCategory(AppCategory category) async {
    final response = await _apiService.post(
      ApiConstants.categories,
      data: category.toJson(),
    );
    if (response.statusCode == 201) {
      if (response.data is Map<String, dynamic> && response.data['category'] != null) {
        return AppCategory.fromJson(response.data['category']);
      }
      return AppCategory.fromJson(response.data);
    }
    throw Exception('Kategori eklenirken hata oluştu: ${response.statusCode}');
  }

  Future<AppCategory> updateCategory(String id, AppCategory category) async {
    final response = await _apiService.put(
      '${ApiConstants.categories}/$id',
      data: category.toJson(),
    );
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic> && response.data['category'] != null) {
        return AppCategory.fromJson(response.data['category']);
      }
      return AppCategory.fromJson(response.data);
    }
    throw Exception('Kategori güncellenirken hata oluştu: ${response.statusCode}');
  }

  Future<bool> deleteCategory(String id) async {
    final response = await _apiService.delete(
      '${ApiConstants.categories}/$id',
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    return false;
  }
}
