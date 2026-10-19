import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExpenseDonutChart extends GetView<ReportsController> {
  const ExpenseDonutChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

    return Obx(() {
      final categories = controller.expenseCategoriesSummary;
      final totalExpense = controller.totalExpense;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.donut_large_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Gider Dağılımı",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    controller.selectedMonthFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (categories.isEmpty || totalExpense <= 0) ...[
                // Boş Durum
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 54,
                          color: isDark
                              ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                              : AppColors.lightTextSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Bu ay için henüz gider kaydı yok",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Donut Grafiği (Ortasında Toplam Tutar ile)
                SizedBox(
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                controller.touchedPieIndex.value = -1;
                                return;
                              }
                              controller.touchedPieIndex.value = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 60,
                          sections: List.generate(categories.length, (i) {
                            final isTouched = i == controller.touchedPieIndex.value;
                            final fontSize = isTouched ? 14.0 : 11.0;
                            final radius = isTouched ? 36.0 : 28.0;
                            final item = categories[i];

                            return PieChartSectionData(
                              color: item.color,
                              value: item.totalAmount,
                              title: item.percentage >= 5
                                  ? '%${item.percentage.toStringAsFixed(0)}'
                                  : '',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),

                      // Donut Merkezindeki Toplam Harcama Bilgisi
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Toplam Gider",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(totalExpense),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Kategori Lejantı ve Yüzdelik Dağılım Listesi
                const Divider(height: 1),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16, indent: 44),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final isHighlighted =
                        index == controller.touchedPieIndex.value;

                    return InkWell(
                      onTap: () {
                        if (controller.touchedPieIndex.value == index) {
                          controller.touchedPieIndex.value = -1;
                        } else {
                          controller.touchedPieIndex.value = index;
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? item.color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Renk İndikatörü ve İkon
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getCategoryIcon(
                                  iconName: item.icon,
                                  isSystem: true,
                                  type: 'expense',
                                  categoryName: item.categoryName,
                                ),
                                size: 16,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Kategori Adı ve İşlem Sayısı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.categoryName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isHighlighted
                                          ? item.color
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                  Text(
                                    "${item.transactionCount} işlem",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
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
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "%${item.percentage.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      color: item.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
