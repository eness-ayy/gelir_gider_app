import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/filter_bottom_sheet.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SearchFilterBar extends GetView<DashboardController> {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar + Filter Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: "İşlem, kategori veya tutar ara...",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                            : AppColors.lightTextSecondary.withValues(
                                alpha: 0.7,
                              ),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      suffixIcon: Obx(() {
                        if (controller.searchQuery.value.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: controller.clearSearch,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter BottomSheet Button with Badge
              Obx(() {
                final filterCount = controller.activeFilterCount;
                final hasFilters = filterCount > 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: hasFilters
                            ? AppColors.primary
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasFilters
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: hasFilters
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          size: 22,
                        ),
                        onPressed: () => FilterBottomSheet.show(context),
                      ),
                    ),
                    if (hasFilters)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),

        // 2. Quick Filter Chips Row
        SizedBox(
          height: 38,
          child: Obx(() {
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Type Filter Chips
                _buildQuickChip(
                  label: "Tümü",
                  isSelected: controller.selectedType.value == 'all',
                  onTap: () => controller.setTypeFilter('all'),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Gelir",
                  icon: Icons.arrow_upward_rounded,
                  activeColor: isDark
                      ? Colors.green.shade700
                      : AppColors.income,
                  isSelected: controller.selectedType.value == 'income',
                  onTap: () => controller.setTypeFilter('income'),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Gider",
                  icon: Icons.arrow_downward_rounded,
                  activeColor: isDark ? Colors.red.shade700 : AppColors.expense,
                  isSelected: controller.selectedType.value == 'expense',
                  onTap: () => controller.setTypeFilter('expense'),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                VerticalDivider(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1,
                  indent: 6,
                  endIndent: 6,
                ),
                const SizedBox(width: 10),

                // Quick Payment Method Filter Chips
                _buildQuickChip(
                  label: "Nakit",
                  icon: PaymentMethod.cash.icon,
                  activeColor: PaymentMethod.cash.color,
                  isSelected:
                      controller.selectedAccountFilter.value ==
                      PaymentMethod.cash.key,
                  onTap: () =>
                      controller.setAccountFilter(PaymentMethod.cash.key),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Banka",
                  icon: PaymentMethod.bankCard.icon,
                  activeColor: PaymentMethod.bankCard.color,
                  isSelected:
                      controller.selectedAccountFilter.value ==
                      PaymentMethod.bankCard.key,
                  onTap: () =>
                      controller.setAccountFilter(PaymentMethod.bankCard.key),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Kredi Kartı",
                  icon: PaymentMethod.creditCard.icon,
                  activeColor: PaymentMethod.creditCard.color,
                  isSelected:
                      controller.selectedAccountFilter.value ==
                      PaymentMethod.creditCard.key,
                  onTap: () =>
                      controller.setAccountFilter(PaymentMethod.creditCard.key),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                VerticalDivider(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1,
                  indent: 6,
                  endIndent: 6,
                ),
                const SizedBox(width: 10),

                // Date Filter Chips
                _buildQuickChip(
                  label: "Bu Ay",
                  isSelected:
                      controller.selectedDateRange.value == 'this_month',
                  onTap: () => controller.setDateRangeFilter('this_month'),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Bu Hafta",
                  isSelected: controller.selectedDateRange.value == 'this_week',
                  onTap: () => controller.setDateRangeFilter('this_week'),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Geçen Ay",
                  isSelected:
                      controller.selectedDateRange.value == 'last_month',
                  onTap: () => controller.setDateRangeFilter('last_month'),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickChip(
                  label: "Tüm Zamanlar",
                  isSelected: controller.selectedDateRange.value == 'all',
                  onTap: () => controller.setDateRangeFilter('all'),
                  isDark: isDark,
                ),

                // Active Category Filter Indicator Chip
                if (controller.selectedCategoryId.value != null) ...[
                  const SizedBox(width: 6),
                  _buildRemovableChip(
                    label: _getSelectedCategoryName(controller),
                    icon: Icons.category_outlined,
                    onRemove: () => controller.setCategoryFilter(null),
                    isDark: isDark,
                  ),
                ],

                // Active Custom Date Filter Indicator Chip
                if (controller.selectedDateRange.value == 'custom' &&
                    controller.customStartDate.value != null &&
                    controller.customEndDate.value != null) ...[
                  const SizedBox(width: 6),
                  _buildRemovableChip(
                    label:
                        "${DateFormat('dd.MM').format(controller.customStartDate.value!)} - ${DateFormat('dd.MM').format(controller.customEndDate.value!)}",
                    icon: Icons.date_range_rounded,
                    onRemove: () => controller.setDateRangeFilter('this_month'),
                    isDark: isDark,
                  ),
                ],

                // Active Account Filter Indicator Chip
                if (controller.selectedAccountFilter.value != 'all') ...[
                  const SizedBox(width: 6),
                  _buildRemovableChip(
                    label: PaymentMethod.fromKey(
                      controller.selectedAccountFilter.value,
                    ).title,
                    icon: PaymentMethod.fromKey(
                      controller.selectedAccountFilter.value,
                    ).icon,
                    onRemove: () => controller.setAccountFilter('all'),
                    isDark: isDark,
                  ),
                ],

                // Clear All Filters Chip
                if (controller.hasActiveFilters) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: controller.clearFilters,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Sıfırla",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  String _getSelectedCategoryName(DashboardController controller) {
    final catId = controller.selectedCategoryId.value;
    final cat = controller.categories.firstWhereOrNull((c) => c.id == catId);
    return cat?.name ?? 'Kategori';
  }

  Widget _buildQuickChip({
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor.withValues(alpha: isDark ? 0.3 : 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          border: Border.all(
            color: isSelected
                ? effectiveActiveColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? effectiveActiveColor
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? effectiveActiveColor
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
