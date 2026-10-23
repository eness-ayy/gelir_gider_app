import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IncomeExpenseBarChart extends StatefulWidget {
  const IncomeExpenseBarChart({super.key});

  @override
  State<IncomeExpenseBarChart> createState() => _IncomeExpenseBarChartState();
}

class _IncomeExpenseBarChartState extends State<IncomeExpenseBarChart> {
  final ReportsController controller = Get.find<ReportsController>();
  int? touchedGroupIndex;

  static (double, double) _calculateNiceMaxAndInterval(double maxDataVal) {
    if (maxDataVal <= 0) {
      return (3000.0, 1000.0);
    }

    final targetMax = maxDataVal * 1.15;
    final rawStep = targetMax / 3.0;

    const niceSteps = [
      50.0, 100.0, 200.0, 250.0, 500.0,
      1000.0, 2000.0, 2500.0, 5000.0,
      10000.0, 20000.0, 25000.0, 50000.0,
      100000.0, 200000.0, 250000.0, 500000.0,
      1000000.0, 2000000.0, 2500000.0, 5000000.0,
    ];

    double step = niceSteps.last;
    for (final s in niceSteps) {
      if (s >= rawStep) {
        step = s;
        break;
      }
    }

    final niceMax = (targetMax / step).ceil() * step;
    return (niceMax, step);
  }

  String _formatCompactY(double value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      final valM = value / 1000000;
      return valM % 1 == 0 ? '${valM.toInt()}M' : '${valM.toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      final valK = value / 1000;
      return valK % 1 == 0 ? '${valK.toInt()}K' : '${valK.toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: "₺", decimalDigits: 2);

    // Renk Paleti (Referans görseldeki koyu tema tasarımına tam uyumlu)
    final cardBgColor = isDark ? const Color(0xFF18191E) : Colors.white;
    final rodBgColor = isDark ? const Color(0xFF282932) : const Color(0xFFEEF0F5);
    const incomeColor = Color(0xFF10B981); // Zümrüt Yeşili
    const expenseColor = Color(0xFFFF5449); // Canlı Mercan/Kırmızı
    final gridLineColor = isDark ? const Color(0xFF2C2E38) : Colors.black.withValues(alpha: 0.06);
    final axisTextColor = isDark ? const Color(0xFF717786) : Colors.grey.shade600;

    return Obx(() {
      final trend = controller.last6MonthsTrend;

      // Grafiğin tepe noktasını bulma
      double maxDataVal = 0.0;
      for (var item in trend) {
        maxDataVal = max(maxDataVal, max(item.income, item.expense));
      }

      final (maxY, stepInterval) = _calculateNiceMaxAndInterval(maxDataVal);

      // Aktif ay: dokunulan ay veya son ay (varsayılan)
      final activeIndex = touchedGroupIndex ?? (trend.isNotEmpty ? trend.length - 1 : -1);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        color: cardBgColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Başlık ve Lejant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2838),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFF388AF6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Aylık Gelir vs Gider",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Son 6 ayın finansal karşılaştırması",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8E95A5) : Colors.grey.shade600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Gelir & Gider Lejant Noktaları
                  Row(
                    children: [
                      _buildLegendDot(
                        color: incomeColor,
                        label: "Gelir",
                        textColor: isDark ? const Color(0xFFB0B7C3) : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildLegendDot(
                        color: expenseColor,
                        label: "Gider",
                        textColor: isDark ? const Color(0xFFB0B7C3) : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bar Grafiği Alanı
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (response != null && response.spot != null && event.isInterestedForInteractions) {
                          setState(() {
                            touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                          });
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => isDark ? const Color(0xFF24252B) : Colors.white,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        tooltipMargin: 8,
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipBorder: BorderSide(
                          color: isDark ? const Color(0xFF383A44) : Colors.grey.shade300,
                          width: 1,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = trend[group.x];
                          final isIncome = rodIndex == 0;
                          final amount = isIncome ? item.income : item.expense;
                          final label = isIncome ? "Gelir" : "Gider";
                          final color = isIncome ? incomeColor : expenseColor;

                          return BarTooltipItem(
                            '$label\n',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                            children: [
                              TextSpan(
                                text: currencyFormat.format(amount),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: stepInterval,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            if (value > meta.max) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _formatCompactY(value),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: axisTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trend.length) {
                              return const SizedBox.shrink();
                            }
                            final isCurrent = idx == activeIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                trend[idx].monthLabel,
                                style: TextStyle(
                                  color: isCurrent
                                      ? (isDark ? Colors.white : Colors.black)
                                      : axisTextColor,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: stepInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: gridLineColor,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(trend.length, (index) {
                      final item = trend[index];
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          // Gelir Çubuğu (Yeşil) + Kapsül Arka Plan
                          BarChartRodData(
                            toY: item.income,
                            color: incomeColor,
                            width: 13,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: rodBgColor,
                            ),
                          ),
                          // Gider Çubuğu (Kırmızı/Mercan) + Kapsül Arka Plan
                          BarChartRodData(
                            toY: item.expense,
                            color: expenseColor,
                            width: 13,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: rodBgColor,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLegendDot({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
