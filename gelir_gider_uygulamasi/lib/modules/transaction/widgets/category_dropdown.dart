import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class CategoryDropdown extends GetView<TransactionController> {
  const CategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        // Seçili türe (Gelir / Gider) ait kategorileri filtrele
        var filteredCategories = controller.categories
            .where(
              (cat) =>
                  (cat.name != null && cat.name!.trim().isNotEmpty) &&
                  controller.isTypeMatch(cat.type, controller.transactionType.value),
            )
            .toList();

        // Eğer liste boşsa, varsayılan kategorileri anında devreye sok (Formun takılmasını önle)
        if (filteredCategories.isEmpty) {
          filteredCategories = CategoryRepository.defaultCategories
              .where((c) => controller.isTypeMatch(c.type, controller.transactionType.value))
              .toList();
        }

        // Seçili kategori geçerli mi?
        final hasValidSelection = filteredCategories.any(
          (c) => c.id == controller.selectedCategoryId.value,
        );

        // Geçerli seçim yoksa otomatik ilkini seç
        if (!hasValidSelection && filteredCategories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (filteredCategories.isNotEmpty && filteredCategories.first.id != null) {
              controller.selectedCategoryId.value = filteredCategories.first.id!;
            }
          });
        }

        final selectedValue = hasValidSelection
            ? controller.selectedCategoryId.value
            : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null);

        return DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Kategori",
            border: OutlineInputBorder(),
          ),
          key: ValueKey(
            "${controller.transactionType.value}_$selectedValue",
          ),
          initialValue: selectedValue,
          items: filteredCategories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        getCategoryIcon(
                          iconName: category.icon ?? 'receipt',
                          isSystem: category.isSystem ?? false,
                          type: category.type ?? '',
                          categoryName: category.name,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null && value.isNotEmpty) {
              controller.selectedCategoryId.value = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Lütfen bir kategori seçin";
            }
            return null;
          },
        );
      },
    );
  }
}
