import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_management_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/set_budget_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class BudgetOverviewCard extends StatefulWidget {
  const BudgetOverviewCard({super.key});

  @override
  State<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<BudgetOverviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final budgetService = Get.find<BudgetService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final statuses = budgetService.getMonthlyBudgetStatuses(
        categories: controller.categories,
        transactions: controller.myTransaction,
      );

      if (statuses.isEmpty) {
        return _buildEmptyBudgetPromo(context, isDark);
      }

      final hasMultiple = statuses.length > 1;
      final exceededCount = statuses.where((s) => s.isExceeded).length;
      final warningCount = statuses.where((s) => s.isWarning).length;

      // Varsayılan olarak sadece 1 kategori gösterilir, tıklandığında genişler
      final displayedStatuses = (!_isExpanded || !hasMultiple)
          ? [statuses.first]
          : statuses;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tıklanabilir Üst Başlık (Birden fazla kategori varsa açılır/kapanır)
            InkWell(
              onTap: hasMultiple
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Aylık Bütçe Takibi",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasMultiple) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${statuses.length}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (exceededCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$exceededCount Aşım!",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (warningCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$warningCount Kritik",
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (hasMultiple) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: "Bütçeleri Yönet",
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => CategoryManagementSheet.show(context),
                    ),
                  ],
                ),
              ),
            ),

            // Kategori Bütçe İlerleme Çubukları (AnimatedSize ile akıcı genişleme)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedStatuses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final status = displayedStatuses[index];
                        return _buildBudgetItem(
                          context,
                          status,
                          isDark,
                          isExpanded: _isExpanded,
                          hasMultiple: hasMultiple,
                        );
                      },
                    ),
                    if (hasMultiple) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isExpanded
                                    ? "Daha Az Göster"
                                    : "Diğer ${statuses.length - 1} Kategoriyi Gör",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBudgetItem(
    BuildContext context,
    CategoryBudgetStatus status,
    bool isDark, {
    required bool isExpanded,
    required bool hasMultiple,
  }) {
    final cat = status.category;
    final statusColor = status.statusColor;

    // Kapalıyken ve birden çok kategori varken tıklanırsa genişlet; açıkken veya tek kategoriyse bütçe düzenleme aç
    final onTap = (hasMultiple && !isExpanded)
        ? () => setState(() => _isExpanded = true)
        : () => SetBudgetDialog.show(context, category: cat);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İsim, Harcanan / Limit ve Yüzde
            Row(
              children: [
                Icon(
                  getCategoryIcon(
                    iconName: cat.icon ?? 'receipt',
                    isSystem: cat.isSystem ?? false,
                    type: cat.type ?? '',
                  ),
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cat.name ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${status.spent.toStringAsFixed(0)} ₺ / ${status.limit.toStringAsFixed(0)} ₺",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status.isExceeded
                        ? Colors.redAccent
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "%${status.percentage.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // İlerleme Çubuğu (Progress Bar)
            // Limit %80'e ulaştığında sarı, %100'ü aştığında kırmızı renk uyarısı
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.progressRatio,
                minHeight: 7,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 4),

            // Durum / Kalan Metni
            Row(
              children: [
                if (status.isExceeded) ...[
                  const Icon(Icons.error_outline_rounded,
                      size: 12, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    "Limit ${(status.spent - status.limit).toStringAsFixed(0)} ₺ aşıldı!",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (status.isWarning) ...[
                  Icon(Icons.warning_amber_rounded,
                      size: 12, color: Colors.amber.shade800),
                  const SizedBox(width: 4),
                  Text(
                    "Kalan: ${status.remaining.toStringAsFixed(0)} ₺ (Limit dolmak üzere)",
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    "Kalan Bütçe: ${status.remaining.toStringAsFixed(0)} ₺",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBudgetPromo(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.5)
            : Colors.blue.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aylık Bütçe Sınırı Belirleyin",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "%80 ve %100 limit uyarılarıyla harcamalarınızı kontrol edin",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => CategoryManagementSheet.show(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            child: const Text("+ Tanımla"),
          ),
        ],
      ),
    );
  }
}
