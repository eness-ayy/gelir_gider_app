import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TopCategoriesCard extends GetView<ReportsController> {
  const TopCategoriesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

    final rankBadges = [
      {'emoji': '🥇', 'label': '#1', 'color': const Color(0xFFFFD700)},
      {'emoji': '🥈', 'label': '#2', 'color': const Color(0xFFC0C0C0)},
      {'emoji': '🥉', 'label': '#3', 'color': const Color(0xFFCD7F32)},
    ];

    return Obx(() {
      final top3 = controller.top3ExpenseCategories;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "En Çok Harcanan İlk 3",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          "Lider harcama kategorileri",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (top3.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "Bu ay için harcama kaydı bulunamadı",
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top3.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = top3[index];
                    final badge = rankBadges[index];
                    final progress = (item.percentage / 100).clamp(0.0, 1.0);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Derece Rozeti
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (badge['color'] as Color)
                                      .withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  badge['emoji'] as String,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Kategori İkonu
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  getCategoryIcon(
                                    iconName: item.icon,
                                    isSystem: true,
                                    type: 'expense',
                                    categoryName: item.categoryName,
                                  ),
                                  color: item.color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Kategori Adı ve İşlem Sayısı
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "${item.transactionCount} işlem yapıldı",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tutar ve Yüzde
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(item.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "%${item.percentage.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      color: item.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // İlerleme Çubuğu (Progress Bar)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(item.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
