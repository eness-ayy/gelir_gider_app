import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:get/get.dart';

class CategoryRepository extends GetxService {
  late final ApiServices _apiService;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiServices>();
  }

  Future<List<AppCategory>> getCategories() async {
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

      // Yalnızca geçerli ada sahip kategorileri döndür
      return allCategories
          .where((c) => c.name != null && c.name!.trim().isNotEmpty)
          .toList();
    } else {
      throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
    }
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
