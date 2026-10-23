import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/set_budget_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MonthlyBudgetLimitsSheet extends StatelessWidget {
  const MonthlyBudgetLimitsSheet({super.key});

  static Future<void> show(BuildContext context) {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController());
    }
    final controller = Get.find<CategoriesController>();
    controller.loadCategories();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MonthlyBudgetLimitsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetService = Get.isRegistered<BudgetService>()
        ? Get.find<BudgetService>()
        : Get.put(BudgetService());

    final categoriesController = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>()
        : Get.put(CategoriesController());

    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Başlık Satırı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.speed_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aylık Limit Belirleme",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Kategori bazlı aylık bütçe ve harcama sınırları",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Kapat",
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Özet Kartı (Toplam Belirlenen Limit)
          Obx(() {
            final budgets = budgetService.budgets;
            // Always access observable properties so Obx is registered
            final _ = budgets.length;

            final allCategories = categoriesController.categories.isNotEmpty
                ? categoriesController.categories
                : CategoryRepository.defaultCategories;

            final expenseCategories = allCategories.where((c) {
              final t = (c.type ?? '').toLowerCase().trim();
              return t == 'expense' || t == 'gider';
            }).toList();

            double totalBudget = 0.0;
            int activeCount = 0;

            for (final cat in expenseCategories) {
              final catId = cat.id;
              if (catId != null && budgets.containsKey(catId)) {
                final b = budgets[catId] ?? 0.0;
                if (b > 0) {
                  totalBudget += b;
                  activeCount++;
                }
              }
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E2A1B), const Color(0xFF1E1E1E)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Toplam Aylık Harcama Limiti",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalBudget > 0
                              ? currencyFormatter.format(totalBudget)
                              : "Henüz Limit Belirlenmedi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: totalBudget > 0
                                ? (isDark
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade900)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      "$activeCount / ${expenseCategories.length}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Kategori Listesi
          Expanded(
            child: Obx(() {
              if (categoriesController.isLoading &&
                  categoriesController.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCategories = categoriesController.categories.isNotEmpty
                  ? categoriesController.categories
                  : CategoryRepository.defaultCategories;

              final expenseCategories = allCategories.where((c) {
                final t = (c.type ?? '').toLowerCase().trim();
                return t == 'expense' || t == 'gider';
              }).toList();

              if (expenseCategories.isEmpty) {
                return const Center(
                  child: Text("Gider kategorisi bulunamadı."),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: expenseCategories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = expenseCategories[index];
                  final catId = category.id ?? '';

                  return Obx(() {
                    final currentLimit = budgetService.budgets[catId];
                    final hasLimit = currentLimit != null && currentLimit > 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasLimit
                              ? (isDark
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.primary.withValues(alpha: 0.3))
                              : (isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasLimit
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            getCategoryIcon(
                              iconName: category.icon ?? 'receipt',
                              isSystem: category.isSystem ?? false,
                              type: category.type ?? '',
                              categoryName: category.name,
                            ),
                            color: hasLimit
                                ? AppColors.primary
                                : (isDark ? Colors.white70 : Colors.black87),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          category.name ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          hasLimit
                              ? "Aylık Limit: ${currencyFormatter.format(currentLimit)}"
                              : "Limit Belirlenmedi",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasLimit
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: hasLimit
                                ? (isDark
                                    ? Colors.greenAccent.shade200
                                    : Colors.green.shade700)
                                : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasLimit)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                tooltip: "Limiti Kaldır",
                                onPressed: () async {
                                  await budgetService.removeBudget(catId);
                                  if (Get.isRegistered<DashboardController>()) {
                                    Get.find<DashboardController>()
                                        .refreshDashboard();
                                  }
                                },
                              ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasLimit
                                    ? (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200)
                                    : AppColors.primary,
                                foregroundColor: hasLimit
                                    ? (isDark
                                        ? Colors.white
                                        : Colors.black87)
                                    : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final changed = await SetBudgetDialog.show(
                                context,
                                category: category,
                              );
                              if (changed == true &&
                                  Get.isRegistered<DashboardController>()) {
                                Get.find<DashboardController>()
                                    .refreshDashboard();
                              }
                            },
                            child: Text(
                              hasLimit ? "Düzenle" : "Limit Belirle",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    ),
  );
}
}
