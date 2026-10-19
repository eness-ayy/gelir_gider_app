import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_form_dialog.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class CategoriesPage extends GetView<CategoriesController> {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // 1. Üst Filtre ve Ekleme Çubuğu (Taşmaya Karşı Korumalı)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterChip("Tümü", 'all', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip("Gelir", 'income', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip("Gider", 'expense', isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => CategoryFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Yeni", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          // 2. İsimsiz / Boş Kategori Temizleme Bildirim Bannerı
          Obx(() {
            if (!controller.hasEmptyCategories) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${controller.emptyCategoriesCount} adet isimsiz kategori var.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmCleanEmpty(context),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text("Hepsini Sil"),
                  ),
                ],
              ),
            );
          }),

          // 2.2. Önerilen Kategoriler Bannerı (Eksik önerilen kategori varsa gösterilir)
          Obx(() {
            if (!controller.hasMissingRecommendedCategories) {
              return const SizedBox.shrink();
            }
            final missingCount =
                controller.missingRecommendedCategories.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Önerilen Kategoriler ($missingCount)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Alışveriş, Kira & Ev, Abonelikler vb.",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => controller.addRecommendedCategories(),
                    icon: const Icon(Icons.add_task_rounded, size: 15),
                    label: const Text("Tümünü Ekle"),
                  ),
                ],
              ),
            );
          }),

          // 3. Kategori Listesi (RefreshIndicator doğrudan ListView sarmalar)
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredCategories;

              return RefreshIndicator(
                onRefresh: controller.loadCategories,
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 54,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                          .withValues(alpha: 0.4)
                                      : AppColors.lightTextSecondary
                                          .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Henüz kategori bulunmuyor",
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Yukarıdaki '+ Yeni' butonundan ekleyebilirsiniz.",
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                            .withValues(alpha: 0.7)
                                        : AppColors.lightTextSecondary
                                            .withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 4, bottom: 80),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final category = list[index];
                          final isIncome =
                              (category.type ?? '').toLowerCase().trim() ==
                                      'income' ||
                                  (category.type ?? '').toLowerCase().trim() ==
                                      'gelir';
                          final isEmptyName = category.name == null ||
                              category.name!.trim().isEmpty;

                          final color = isIncome
                              ? (isDark
                                  ? Colors.greenAccent.shade200
                                  : Colors.green.shade700)
                              : (isDark
                                  ? Colors.redAccent.shade100
                                  : Colors.red.shade700);
                          final bgColor = isIncome
                              ? (isDark
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.green.shade50)
                              : (isDark
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.red.shade50);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isEmptyName
                                    ? Colors.amber.withValues(alpha: 0.4)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                width: isEmptyName ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              onTap: () {
                                CategoryFormDialog.show(
                                  context,
                                  categoryToEdit: category,
                                );
                              },
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  getCategoryIcon(
                                    iconName: category.icon ?? 'receipt',
                                    isSystem: category.isSystem ?? false,
                                    type: category.type ?? 'expense',
                                    categoryName: category.name,
                                  ),
                                  color: color,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isEmptyName
                                          ? "(İsimsiz Kategori)"
                                          : category.name!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: isEmptyName
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        color: isEmptyName
                                            ? Colors.amber.shade700
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isIncome ? "Gelir" : "Gider",
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    tooltip: "Düzenle",
                                    onPressed: () {
                                      CategoryFormDialog.show(
                                        context,
                                        categoryToEdit: category,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: Colors.red.shade400,
                                    ),
                                    tooltip: "Sil",
                                    onPressed: () =>
                                        _confirmDelete(context, category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, bool isDark) {
    return Obx(() {
      final isSelected = controller.selectedFilterType.value == type;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) controller.setFilterType(type);
        },
      );
    });
  }

  void _confirmDelete(BuildContext context, AppCategory category) {
    final catName = category.name?.trim().isNotEmpty == true
        ? '"${category.name}"'
        : 'bu isimsiz kategoriyi';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Kategoriyi Sil"),
        content: Text("$catName silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              if (category.id != null) {
                controller.deleteCategory(category.id!);
              }
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _confirmCleanEmpty(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("İsimsiz Kategorileri Temizle"),
        content: Text(
          "${controller.emptyCategoriesCount} adet isimsiz kategori sistemden kalıcı olarak silinecek. Onaylıyor musunuz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              controller.cleanEmptyCategories();
            },
            child: const Text("Hepsini Sil"),
          ),
        ],
      ),
    );
  }
}
