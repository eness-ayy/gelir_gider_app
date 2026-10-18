import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/category_controler.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class AddCategoryDialog extends StatelessWidget {
  const AddCategoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller daha önce varsa onu bulur, yoksa oluşturur (çift init hatasını önler)
    final controller = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    return AlertDialog(
      title: Text(
        "Kategori Ekle",
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                onChanged: (value) => controller.categoryName.value = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori adı boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Kategori İkonu",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  ),
                  key: ValueKey(controller.selectedIcon.value),
                  initialValue: controller.selectedIcon.value.isEmpty
                      ? null
                      : controller.selectedIcon.value,
                  items: icons
                      .map(
                        (icon) => DropdownMenuItem<String>(
                          value: icon,
                          child: Text(icon),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedIcon.value = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Kategori ikonu seçiniz";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Vazgeç"),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : controller.createCategory,
            child: controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Kaydet"),
          ),
        ),
      ],
    );
  }
}