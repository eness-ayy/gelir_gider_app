import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Filtreler & Sıralama",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Transaction Type
              _buildSectionTitle(context, "İşlem Türü", Icons.swap_vert_rounded),
              const SizedBox(height: 8),
              Obx(() => Row(
                    children: [
                      _buildSelectableChip(
                        label: "Tümü",
                        isSelected: controller.selectedType.value == 'all',
                        onTap: () => controller.setTypeFilter('all'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSelectableChip(
                        label: "Gelir",
                        icon: Icons.arrow_upward_rounded,
                        activeColor: isDark ? Colors.green.shade700 : AppColors.income,
                        isSelected: controller.selectedType.value == 'income',
                        onTap: () => controller.setTypeFilter('income'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSelectableChip(
                        label: "Gider",
                        icon: Icons.arrow_downward_rounded,
                        activeColor: isDark ? Colors.red.shade700 : AppColors.expense,
                        isSelected: controller.selectedType.value == 'expense',
                        onTap: () => controller.setTypeFilter('expense'),
                        isDark: isDark,
                      ),
                    ],
                  )),
              const SizedBox(height: 20),

              // 2. Date Range
              _buildSectionTitle(context, "Tarih Aralığı", Icons.calendar_today_rounded),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSelectableChip(
                        label: "Bu Ay",
                        isSelected: controller.selectedDateRange.value == 'this_month',
                        onTap: () => controller.setDateRangeFilter('this_month'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "Bu Hafta",
                        isSelected: controller.selectedDateRange.value == 'this_week',
                        onTap: () => controller.setDateRangeFilter('this_week'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "Geçen Ay",
                        isSelected: controller.selectedDateRange.value == 'last_month',
                        onTap: () => controller.setDateRangeFilter('last_month'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "Tüm Zamanlar",
                        isSelected: controller.selectedDateRange.value == 'all',
                        onTap: () => controller.setDateRangeFilter('all'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: controller.selectedDateRange.value == 'custom' &&
                                controller.customStartDate.value != null &&
                                controller.customEndDate.value != null
                            ? "${DateFormat('dd.MM').format(controller.customStartDate.value!)} - ${DateFormat('dd.MM').format(controller.customEndDate.value!)}"
                            : "Özel Tarih Seç",
                        icon: Icons.date_range_rounded,
                        isSelected: controller.selectedDateRange.value == 'custom',
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: controller.customStartDate.value != null &&
                                    controller.customEndDate.value != null
                                ? DateTimeRange(
                                    start: controller.customStartDate.value!,
                                    end: controller.customEndDate.value!,
                                  )
                                : DateTimeRange(
                                    start: DateTime.now().subtract(const Duration(days: 7)),
                                    end: DateTime.now(),
                                  ),
                          );
                          if (picked != null) {
                            controller.setCustomDateRange(picked.start, picked.end);
                          }
                        },
                        isDark: isDark,
                      ),
                    ],
                  )),
              const SizedBox(height: 20),

              // 3. Category Filter
              _buildSectionTitle(context, "Kategori", Icons.category_rounded),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSelectableChip(
                        label: "Tüm Kategoriler",
                        isSelected: controller.selectedCategoryId.value == null,
                        onTap: () => controller.setCategoryFilter(null),
                        isDark: isDark,
                      ),
                      ...controller.categories.map((cat) {
                        final isSelected = controller.selectedCategoryId.value == cat.id;
                        return _buildSelectableChip(
                          label: cat.name ?? '',
                          icon: getCategoryIcon(
                            iconName: cat.icon ?? 'receipt',
                            isSystem: cat.isSystem ?? true,
                            type: cat.type ?? 'expense',
                          ),
                          isSelected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              controller.setCategoryFilter(null);
                            } else {
                              controller.setCategoryFilter(cat.id);
                            }
                          },
                          isDark: isDark,
                        );
                      }),
                    ],
                  )),
              const SizedBox(height: 20),

              // 4. Sort
              _buildSectionTitle(context, "Sıralama", Icons.sort_rounded),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSelectableChip(
                        label: "En Yeni",
                        icon: Icons.calendar_today_outlined,
                        isSelected: controller.selectedSort.value == 'date_desc',
                        onTap: () => controller.setSort('date_desc'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "En Eski",
                        icon: Icons.history_rounded,
                        isSelected: controller.selectedSort.value == 'date_asc',
                        onTap: () => controller.setSort('date_asc'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "En Yüksek Tutar",
                        icon: Icons.trending_up_rounded,
                        isSelected: controller.selectedSort.value == 'amount_desc',
                        onTap: () => controller.setSort('amount_desc'),
                        isDark: isDark,
                      ),
                      _buildSelectableChip(
                        label: "En Düşük Tutar",
                        icon: Icons.trending_down_rounded,
                        isSelected: controller.selectedSort.value == 'amount_asc',
                        onTap: () => controller.setSort('amount_asc'),
                        isDark: isDark,
                      ),
                    ],
                  )),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        controller.clearFilters();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Filtreleri Temizle"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Uygula"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildSelectableChip({
    required String label,
    IconData? icon,
    Color? activeColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final effectiveActiveColor = activeColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          border: Border.all(
            color: isSelected
                ? effectiveActiveColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? effectiveActiveColor
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? effectiveActiveColor
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
