import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/get.dart';

class BudgetWarningBanner extends GetView<TransactionController> {
  const BudgetWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.liveBudgetStatus;
      if (status == null) return const SizedBox.shrink();

      final statusColor = status.statusColor;
      final entered = controller.enteredAmount.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      IconData statusIcon;
      String statusTitle;
      String statusSubtitle;

      if (entered > 0) {
        if (status.isExceeded) {
          statusIcon = Icons.error_rounded;
          statusTitle = "Bütçe Limiti Aşılacak!";
          final overAmount = (-status.remaining);
          statusSubtitle =
              "Bu harcama ile '${status.category.name}' bütçesi ${overAmount.toStringAsFixed(0)} ₺ aşılacak. (Toplam: ${status.spent.toStringAsFixed(0)} ₺ / Limit: ${status.limit.toStringAsFixed(0)} ₺)";
        } else if (status.isWarning) {
          statusIcon = Icons.warning_amber_rounded;
          statusTitle = "Bütçe Sınırına Yaklaşıldı (%${status.percentage.toStringAsFixed(0)})";
          statusSubtitle =
              "Bu işlem sonrasında kalan bütçeniz ${status.remaining.toStringAsFixed(0)} ₺ olacak.";
        } else {
          statusIcon = Icons.check_circle_outline_rounded;
          statusTitle = "Bütçe Dahilinde (%${status.percentage.toStringAsFixed(0)})";
          statusSubtitle =
              "Bu işlem sonrasında kalan tavan: ${status.remaining.toStringAsFixed(0)} ₺";
        }
      } else {
        if (status.isExceeded) {
          statusIcon = Icons.error_rounded;
          statusTitle = "Bütçe Limiti Aşılmış!";
          statusSubtitle =
              "Bu ay bu kategoride limit ${(status.spent - status.limit).toStringAsFixed(0)} ₺ aşıldı (${status.spent.toStringAsFixed(0)} ₺ / ${status.limit.toStringAsFixed(0)} ₺).";
        } else if (status.isWarning) {
          statusIcon = Icons.warning_amber_rounded;
          statusTitle = "Bütçe %${status.percentage.toStringAsFixed(0)} Doldu";
          statusSubtitle =
              "Bu ayki harcama: ${status.spent.toStringAsFixed(0)} ₺ / ${status.limit.toStringAsFixed(0)} ₺ (Kalan: ${status.remaining.toStringAsFixed(0)} ₺)";
        } else {
          statusIcon = Icons.speed_rounded;
          statusTitle = "Aylık Bütçe: ${status.limit.toStringAsFixed(0)} ₺";
          statusSubtitle =
              "Şu ana kadarki harcama: ${status.spent.toStringAsFixed(0)} ₺ (Kalan: ${status.remaining.toStringAsFixed(0)} ₺)";
        }
      }

      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "%${status.percentage.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusSubtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: status.progressRatio,
                minHeight: 5,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      );
    });
  }
}
