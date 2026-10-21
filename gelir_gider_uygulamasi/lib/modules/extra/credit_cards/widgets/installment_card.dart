import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:intl/intl.dart';

class InstallmentCard extends StatelessWidget {
  final InstallmentPurchaseModel installment;
  final CreditCardModel? card;
  final VoidCallback? onCloseEarly;
  final VoidCallback? onPayNext;
  final VoidCallback? onDelete;

  const InstallmentCard({
    super.key,
    required this.installment,
    this.card,
    this.onCloseEarly,
    this.onPayNext,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Satır: Başlık & Aylık Tutar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installment.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (card != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.credit_card_rounded,
                                size: 12,
                                color: Color(0xFF818CF8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                card!.cardName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "- ${currencyFmt.format(installment.monthlyAmount)} / ay",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF87171), // Yumuşak Kırmızı
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Toplam: ${currencyFmt.format(installment.totalAmount)}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // İlerleme Çubuğu ve Taksit Sayacı (3/6 Taksit)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${installment.paidInstallments}/${installment.totalInstallments} Taksit Ödendi",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  "Kalan: ${currencyFmt.format(installment.remainingAmount)}",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: installment.progress,
                minHeight: 8,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  installment.isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Alt Aksiyon Butonları
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Taksit Öde Butonu
                if (!installment.isCompleted && onPayNext != null)
                  InkWell(
                    onTap: onPayNext,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Taksit Öde (+1)",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Erken Kapat Butonu
                    if (!installment.isCompleted && onCloseEarly != null)
                      TextButton.icon(
                        onPressed: onCloseEarly,
                        icon: const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Color(0xFF818CF8),
                        ),
                        label: const Text(
                          "Erken Kapat",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        splashRadius: 18,
                        tooltip: "Taksiti Sil",
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
