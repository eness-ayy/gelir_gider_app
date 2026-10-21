import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/add_installment_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/credit_card_item.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/installment_card.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreditCardDetailView extends StatelessWidget {
  final CreditCardModel? card;

  const CreditCardDetailView({
    super.key,
    this.card,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CreditCardController>()
        ? Get.find<CreditCardController>()
        : Get.put(CreditCardController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    final initialCard = card ?? (Get.arguments as CreditCardModel?);
    if (initialCard == null) {
      return const Scaffold(
        body: Center(child: Text("Kart bilgisi bulunamadı.")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          initialCard.cardName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _confirmDeleteCard(context, controller, initialCard),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: "Kartı Sil",
          ),
        ],
      ),
      body: Obx(() {
        // Kartın güncel taksitlerini al
        final currentCard = controller.cards.firstWhereOrNull((c) => c.id == initialCard.id) ?? initialCard;
        final cardInstallments = controller.getActiveInstallmentsForCard(currentCard.id);

        final used = controller.getUsedLimitForCard(currentCard.id);
        final available = controller.getAvailableLimitForCard(currentCard);
        final percent = controller.getUtilizationPercentageForCard(currentCard);
        final daysCutoff = controller.getDaysUntilCutoff(currentCard);
        final daysDue = controller.getDaysUntilDue(currentCard);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kart Görseli (Ortalanmış ve sabit boyutlu)
              Center(
                child: CreditCardItem(
                  card: currentCard,
                  margin: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 18),

              // 2. Limit & Tarih Durum Kutuları
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    // Kullanılan & Kullanılabilir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kullanılan Limit",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFmt.format(used),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Kalan Limit",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFmt.format(available),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Doluluk Barı
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percent > 80
                              ? Colors.redAccent
                              : (percent > 50 ? Colors.orangeAccent : const Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "%${percent.toStringAsFixed(1)} Doluluk (Limit: ${currencyFmt.format(currentCard.totalLimit)})",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    // Tarih Sayaçları
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: Color(0xFF818CF8),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hesap Kesim",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      daysCutoff == 0 ? "Bugün" : "$daysCutoff gün sonra",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF34D399),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Son Ödeme",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      daysDue == 0 ? "Bugün" : "$daysDue gün sonra",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Bu Karta Ait Taksitler Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bu Karttaki Taksitler (${cardInstallments.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AddInstallmentSheet.show(context, cardId: currentCard.id),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      "Taksit Ekle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Taksit Kartları Listesi
              if (cardInstallments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Bu karta ait aktif taksitli harcama yok.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...cardInstallments.map((inst) {
                  return InstallmentCard(
                    installment: inst,
                    card: currentCard,
                    onPayNext: () => controller.payNextInstallment(inst.id),
                    onCloseEarly: () => controller.closeInstallmentEarly(inst.id),
                    onDelete: () => controller.deleteInstallment(inst.id),
                  );
                }),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddInstallmentSheet.show(context, cardId: initialCard.id),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Taksit Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmDeleteCard(
    BuildContext context,
    CreditCardController controller,
    CreditCardModel cardToDelete,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                "Kartı Sil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${cardToDelete.cardName} ve bu karta bağlı tüm taksitler silinecek. Emin misiniz?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text("Vazgeç"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Dialog kapat
                        controller.deleteCard(cardToDelete.id);
                        Get.back(); // Detay sayfasından çık
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Sil"),
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
}
