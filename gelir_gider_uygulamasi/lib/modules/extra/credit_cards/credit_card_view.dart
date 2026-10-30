import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/add_credit_card_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/add_installment_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/credit_card_item.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/credit_card_transaction_item.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/installment_card.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/installment_load_chart.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreditCardView extends StatefulWidget {
  const CreditCardView({super.key});

  @override
  State<CreditCardView> createState() => _CreditCardViewState();
}

class _CreditCardViewState extends State<CreditCardView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CreditCardController>()
        ? Get.find<CreditCardController>()
        : Get.put(CreditCardController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Kredi Kartları & Taksitler",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        final cards = controller.cards;
        final activeInsts = controller.activeInstallments;
        final monthlyLoads = controller.getNext6MonthsLoad();
        final currentCard = controller.currentSelectedCard;
        final filterBySelectedCard =
            controller.showOnlySelectedCardTransactions.value &&
                cards.length > 1 &&
                currentCard != null;
        final creditCardTxs = filterBySelectedCard
            ? controller.getTransactionsForCard(currentCard.id)
            : controller.allCreditCardTransactions;

        final totalDebt = controller.usedLimit.value;
        final singleShotTotal = controller.singleShotSpendTotal;
        final installmentTotal = controller.installmentRemainingTotal;
        final availableLimit = controller.availableLimit.value;
        final totalLimit = controller.totalLimit.value;
        final utilization = controller.overallUtilizationPercentage;

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ÖZET KARTI (En Üstte)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Toplam Kart Borcu",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFmt.format(totalDebt),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF87171),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Kullanılabilir Limit",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFmt.format(availableLimit),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Genel Doluluk İlerleme Çubuğu
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (utilization / 100).clamp(0.0, 1.0),
                          minHeight: 9,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Genel Doluluk: %${utilization.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            "Toplam Limit: ${currencyFmt.format(totalLimit)}",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tek Çekim: ${currencyFmt.format(singleShotTotal)}",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              "Taksit Yükü: ${currencyFmt.format(installmentTotal)}",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 2. KREDİ KARTLARI CAROUSEL (Yatay Kaydırılabilir)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kayıtlı Kartlarım (${cards.length})",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => AddCreditCardSheet.show(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        "Kart Ekle",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (cards.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.credit_card_off_rounded,
                            size: 44, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          "Henüz kayıtlı kredi kartı bulunmuyor.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () => AddCreditCardSheet.show(context),
                          icon: const Icon(Icons.add),
                          label: const Text("İlk Kartını Ekle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: cards.length,
                          onPageChanged: (i) => controller.selectedCardIndex.value = i,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return CreditCardItem(
                              card: card,
                              onTap: () {
                                Get.toNamed(AppRoutes.creditCardDetail, arguments: card);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sayfa Noktaları
                      if (cards.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(cards.length, (index) {
                            final isCurrent =
                                controller.selectedCardIndex.value == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isCurrent ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: isCurrent
                                    ? const Color(0xFF6366F1)
                                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                const SizedBox(height: 22),

                // 3. KREDİ KARTI HARCAMALARI (TEK ÇEKİM / GÜNLÜK HARCAMALAR)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kredi Kartı Harcamaları (${creditCardTxs.length})",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (cards.length > 1 && currentCard != null)
                      InkWell(
                        onTap: () {
                          controller.showOnlySelectedCardTransactions.value =
                              !controller.showOnlySelectedCardTransactions.value;
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: filterBySelectedCard
                                ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            filterBySelectedCard
                                ? "Sadece: ${currentCard.cardName}"
                                : "Tüm Kartlar",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: filterBySelectedCard
                                  ? const Color(0xFF818CF8)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (creditCardTxs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 38,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          filterBySelectedCard
                              ? "${currentCard.cardName} kartına ait tek çekim harcama bulunmuyor."
                              : "Henüz kredi kartıyla yapılmış tek çekim harcama bulunmuyor.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...creditCardTxs.map((tx) {
                    final matchedCard = controller.getCardForTransaction(tx);
                    return CreditCardTransactionItem(
                      transaction: tx,
                      card: matchedCard,
                      showCardBadge: true,
                      onDelete: controller.deleteCreditCardTransaction,
                    );
                  }),
                const SizedBox(height: 22),

                // 4. GELECEK 6 AYIN TAKSİT YÜKÜ (Mini Bar Chart)
                InstallmentLoadChart(monthlyLoads: monthlyLoads),
                const SizedBox(height: 24),

                // 5. AKTİF TAKSİTLİ HARCAMALAR
                Text(
                  "Aktif Taksitli Harcamalar (${activeInsts.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                if (activeInsts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 40,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Aktif taksitli harcamanız bulunmuyor.",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...activeInsts.map((inst) {
                    final card = controller.getCard(inst.cardId);
                    return InstallmentCard(
                      installment: inst,
                      card: card,
                      onPayNext: () => controller.payNextInstallment(inst.id),
                      onCloseEarly: () => controller.closeInstallmentEarly(inst.id),
                      onDelete: () => controller.deleteInstallment(inst.id),
                    );
                  }),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddInstallmentSheet.show(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Taksitli Harcama Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
