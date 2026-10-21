import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:intl/intl.dart';

class InstallmentLoadChart extends StatelessWidget {
  final List<MonthlyInstallmentLoad> monthlyLoads;

  const InstallmentLoadChart({
    super.key,
    required this.monthlyLoads,
  });

  String _formatCompact(double value) {
    if (value <= 0) return "₺0";
    if (value >= 1000) {
      final k = value / 1000;
      return k == k.roundToDouble()
          ? "₺${k.toInt()}B"
          : "₺${k.toStringAsFixed(1)}B";
    }
    return "₺${value.toInt()}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF818CF8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Gelecek 6 Ayın Taksit Yükü",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                "Tahmini",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Çubuklar Grafiği
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: monthlyLoads.map((month) {
                // Minimum çubuk yüksekliği oranı %8 ki 0 lira olsa bile minik zemin gözüksün
                final heightFactor = (month.ratio * 0.88 + 0.12).clamp(0.12, 1.0);
                final hasAmount = month.amount > 0;

                return Expanded(
                  child: Tooltip(
                    message: "${month.monthName} ${month.year}: ${currencyFmt.format(month.amount)}",
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tutar etiketi
                        Text(
                          _formatCompact(month.amount),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasAmount
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : (isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Çubuk Gövdesi
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: hasAmount ? heightFactor : 0.08,
                            widthFactor: 0.52,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: hasAmount
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF818CF8),
                                          Color(0xFF4F46E5),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                                color: hasAmount
                                    ? null
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade200),
                                boxShadow: hasAmount
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Ay Adı
                        Text(
                          month.monthName.length > 3
                              ? month.monthName.substring(0, 3)
                              : month.monthName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
