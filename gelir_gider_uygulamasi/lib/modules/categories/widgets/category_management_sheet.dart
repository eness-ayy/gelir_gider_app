import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_form_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/set_budget_dialog.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class CategoryManagementSheet extends StatelessWidget {
  final String? initialType;

  const CategoryManagementSheet({super.key, this.initialType});

  static Future<void> show(BuildContext context, {String? initialType}) {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController());
    }
    final controller = Get.find<CategoriesController>();
    if (initialType != null && initialType.isNotEmpty) {
      controller.setFilterType(initialType);
    } else {
      controller.setFilterType('all');
    }
    controller.loadCategories();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryManagementSheet(initialType: initialType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoriesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomeColor = isDark ? Colors.greenAccent.shade200 : AppColors.income;
    final expenseColor = isDark ? Colors.redAccent.shade100 : AppColors.expense;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Sürükleme Tutamacı
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Başlık ve Kapat Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kategori Yönetimi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Kategorileri düzenleyin, silin veya yeni ekleyin",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: "Kapat",
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filtre Butonları (Tümü / Gider / Gelir)
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(
                    context: context,
                    label: "Tümü",
                    selected: controller.selectedFilterType.value == 'all',
                    onTap: () => controller.setFilterType('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context: context,
                    label: "Gider",
                    selected: controller.selectedFilterType.value == 'expense',
                    color: expenseColor,
                    icon: Icons.arrow_downward_rounded,
                    onTap: () => controller.setFilterType('expense'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context: context,
                    label: "Gelir",
                    selected: controller.selectedFilterType.value == 'income',
                    color: incomeColor,
                    icon: Icons.arrow_upward_rounded,
                    onTap: () => controller.setFilterType('income'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // İsimsiz / Boş Kategori Uyarısı
          Obx(() {
            if (!controller.hasEmptyCategories) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${controller.emptyCategoriesCount} adet isimsiz kategori bulundu",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.cleanEmptyCategories,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Temizle"),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 16),

          // Kategori Listesi
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredCategories
                  .where((c) => c.name != null && c.name!.trim().isNotEmpty)
                  .toList();

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Bu filtreye ait kategori bulunamadı",
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = list[index];
                  final isExpense = (cat.type ?? '').toLowerCase() == 'expense' ||
                      (cat.type ?? '').toLowerCase() == 'gider';
                  final tintColor = isExpense ? expenseColor : incomeColor;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Kategori İkonu
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: tintColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getCategoryIcon(
                              iconName: cat.icon ?? 'receipt',
                              isSystem: cat.isSystem ?? false,
                              type: cat.type ?? '',
                              categoryName: cat.name,
                            ),
                            color: tintColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Kategori Adı ve Türü
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: tintColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isExpense ? "Gider" : "Gelir",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tintColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isExpense)
                                    Obx(() {
                                      final budget = cat.id != null
                                          ? Get.find<BudgetService>().getBudget(cat.id!)
                                          : null;
                                      if (budget == null || budget <= 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Limit: ${budget.toStringAsFixed(0)} ₺",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // İşlem Butonları (Bütçe, Düzenle & Sil)
                        if (isExpense) ...[
                          IconButton(
                            tooltip: "Bütçe Limiti",
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.speed_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            onPressed: () => SetBudgetDialog.show(
                              context,
                              category: cat,
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                        IconButton(
                          tooltip: "Düzenle",
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => CategoryFormDialog.show(
                            context,
                            categoryToEdit: cat,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          tooltip: "Sil",
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _showDeleteConfirmDialog(
                            context,
                            controller,
                            cat,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // Alt Sabit Aksiyon Butonu (+ Yeni Kategori Ekle)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  final currentFilter = controller.selectedFilterType.value;
                  CategoryFormDialog.show(
                    context,
                    initialType: currentFilter == 'all' ? null : currentFilter,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  "Yeni Kategori Ekle",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? activeColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? activeColor
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    CategoriesController controller,
    AppCategory category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Kategoriyi Sil", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "\"${category.name}\" kategorisini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.",
          style: const TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Vazgeç"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    if (category.id != null && category.id!.isNotEmpty) {
                      await controller.deleteCategory(category.id!);
                    }
                  },
                  child: const Text("Sil"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
