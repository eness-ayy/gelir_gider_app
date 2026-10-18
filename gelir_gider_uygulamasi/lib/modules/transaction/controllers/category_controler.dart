import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class CategoryController extends BaseController {
  final categoryName = ''.obs;
  final selectedIcon = ''.obs;
  final formKey = GlobalKey<FormState>();
  final categoryType = ''.obs;
  final CategoryRepository categoryRepository = Get.find<CategoryRepository>();

  @override
  void onInit() {
    super.onInit();
    selectedIcon.value = icons.first;
    if (Get.isRegistered<TransactionController>()) {
      categoryType.value =
          Get.find<TransactionController>().transactionType.value;
    } else {
      categoryType.value = 'expense';
    }
  }

  Future<void> createCategory() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    try {
      setLoading(true);
      final eklenecekKategori = AppCategory(
        name: categoryName.value.trim(),
        type: categoryType.value,
        icon: selectedIcon.value,
        isSystem: false,
      );
      final eklenenKategori = await categoryRepository.createCategory(
        eklenecekKategori,
      );
      Get.back(result: eklenenKategori);
      showSuccessSnackbar(message: "Kategori başarıyla eklendi");
    } catch (e) {
      showErrorSnackbar(message: "Kategori eklenirken hata oluştu");
    } finally {
      setLoading(false);
    }
  }
}
