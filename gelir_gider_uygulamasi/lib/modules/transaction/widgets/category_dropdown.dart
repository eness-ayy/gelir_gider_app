import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';
import 'package:get/get.dart';

class CategoryDropdown extends GetView<TransactionController> {
  const CategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final filteredCategories = controller.categories
            .where(
              (cat) =>
                  (cat.name != null && cat.name!.trim().isNotEmpty) &&
                  TurkishStringHelper.toLowerCaseTr(cat.type ?? '') ==
                  TurkishStringHelper.toLowerCaseTr(controller.transactionType.value),
            )
            .toList();

        final hasValidSelection = filteredCategories.any(
          (c) => c.id == controller.selectedCategoryId.value,
        );

        return DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Kategori",
            border: OutlineInputBorder(),
          ),
          key: ValueKey(
            "${controller.transactionType.value}_${controller.selectedCategoryId.value}",
          ),
          initialValue:
              hasValidSelection ? controller.selectedCategoryId.value : null,
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
            controller.selectedCategoryId.value = value ?? "";
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
