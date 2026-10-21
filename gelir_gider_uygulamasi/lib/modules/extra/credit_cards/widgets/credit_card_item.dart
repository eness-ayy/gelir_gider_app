import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreditCardItem extends StatelessWidget {
  final CreditCardModel card;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const CreditCardItem({
    super.key,
    required this.card,
    this.onTap,
    this.margin,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF1E1B4B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CreditCardController>()
        ? Get.find<CreditCardController>()
        : Get.put(CreditCardController());
    final baseColor = _parseColor(card.colorHex);

    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final available = controller.getAvailableLimitForCard(card);
    final daysToCutoff = controller.getDaysUntilCutoff(card);

    return Container(
      width: 330,
      height: 195,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Üst Satır: Banka & Temassız / Çip İkonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        card.bankName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.contactless_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),

                // 2. Orta: Altın Çip & Maskeli Kart Numarası
                Row(
                  children: [
                    // EMV Çip Tasarımı
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 26,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "••••  ••••  ••••  ${card.last4Digits}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. Alt Satır: Kart Adı, Kalan Limit & Kesim Günü
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Kullanılabilir: ${currencyFmt.format(available)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        daysToCutoff == 0
                            ? "Bugün Kesim"
                            : "$daysToCutoff Gün Kaldı",
                        style: TextStyle(
                          color: daysToCutoff <= 3 ? const Color(0xFFF87171) : Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
