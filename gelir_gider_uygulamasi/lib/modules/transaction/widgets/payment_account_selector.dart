import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/add_credit_card_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentAccountSelector extends GetView<TransactionController> {
  const PaymentAccountSelector({super.key});

  static CreditCardService? get _creditCardService =>
      Get.isRegistered<CreditCardService>()
          ? Get.find<CreditCardService>()
          : null;

  static Future<void> showNoCreditCardInfoDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Kredi Kartı Bilgilendirmesi",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Kredi kartıyla harcama eklemek üzeresiniz ancak henüz uygulamaya tanımlı bir kredi kartınız bulunmuyor.\n\nKart limitinizi, kalan bakiyenizi ve hesap kesim günlerinizi takip edebilmek için hemen bir kart eklemek ister misiniz?",
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Şimdilik Geç",
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              AddCreditCardSheet.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text(
              "Hemen Kart Ekle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isExpense = controller.transactionType.value == 'expense';
      final currentMethod = controller.selectedPaymentMethod.value;
      final availableMethods = isExpense
          ? PaymentMethod.expenseMethods
          : PaymentMethod.incomeMethods;
      final cards = _creditCardService?.cards ?? <CreditCardModel>[];
      final hasCreditCards = cards.isNotEmpty;
      final isCreditCardSelected =
          isExpense && currentMethod == PaymentMethod.creditCard;
      final showNoCardBanner = isCreditCardSelected && !hasCreditCards;
      final showCardPicker = isCreditCardSelected && hasCreditCards;

      final activeCardId = controller.selectedCreditCardId.value;
      final effectiveSelectedCardId =
          (activeCardId != null && cards.any((c) => c.id == activeCardId))
              ? activeCardId
              : (cards.isNotEmpty ? cards.first.id : null);
      if (showCardPicker &&
          effectiveSelectedCardId != null &&
          controller.selectedCreditCardId.value != effectiveSelectedCardId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.selectedCreditCardId.value !=
              effectiveSelectedCardId) {
            controller.selectedCreditCardId.value = effectiveSelectedCardId;
          }
        });
      }

      final sectionTitle = isExpense
          ? "Hangi hesaptan ödendi?"
          : "Hangi hesaba aktarıldı?";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: availableMethods.map((method) {
              final isSelected = currentMethod == method;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildAccountOption(
                    context: context,
                    method: method,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () {
                      controller.selectedPaymentMethod.value = method;
                      if (method == PaymentMethod.creditCard) {
                        final currentCards =
                            _creditCardService?.cards ?? <CreditCardModel>[];
                        if (currentCards.isEmpty) {
                          showNoCreditCardInfoDialog(context);
                        } else if (controller.selectedCreditCardId.value ==
                                null ||
                            !currentCards.any(
                              (c) =>
                                  c.id == controller.selectedCreditCardId.value,
                            )) {
                          controller.selectedCreditCardId.value =
                              currentCards.first.id;
                        }
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          if (showCardPicker) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card_rounded,
                        size: 15,
                        color: Color(0xFF8E24AA),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Hangi kredi kartıyla ödendi?",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => AddCreditCardSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        "+ Yeni Kart",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cards.map((card) {
                  final isCardSelected = effectiveSelectedCardId == card.id;
                  final cardColor = _parseCardColor(card.colorHex);
                  final usedInstallments = _creditCardService?.installments
                          .where((i) => i.cardId == card.id && !i.isCompleted)
                          .fold<double>(
                            0.0,
                            (sum, i) => sum + i.remainingAmount,
                          ) ??
                      0.0;
                  final usedSingle =
                      _creditCardService?.getSingleShotSpendForCard(card.id) ??
                          0.0;
                  final remainingLimit = (card.totalLimit -
                          usedInstallments -
                          usedSingle)
                      .clamp(0.0, card.totalLimit);
                  final limitFmt = NumberFormat.currency(
                    locale: 'tr_TR',
                    symbol: '₺',
                    decimalDigits: 0,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        controller.selectedCreditCardId.value = card.id;
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCardSelected
                              ? cardColor.withValues(alpha: isDark ? 0.35 : 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCardSelected
                                ? const Color(0xFF8E24AA)
                                : (isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                            width: isCardSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.credit_card_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      card.cardName,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (card.last4Digits.isNotEmpty &&
                                        card.last4Digits != '0000') ...[
                                      const SizedBox(width: 5),
                                      Text(
                                        "• ${card.last4Digits}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${card.bankName} • Kalan: ${limitFmt.format(remainingLimit)}",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (isCardSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 17,
                                color: Color(0xFF8E24AA),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (showNoCardBanner) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF6366F1,
                ).withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Henüz kayıtlı bir kredi kartınız yok. Limit ve ekstre takibi için kartınızı tanımlayabilirsiniz.",
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => AddCreditCardSheet.show(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_card_rounded, size: 15),
                    label: const Text(
                      "Kart Ekle",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildAccountOption({
    required BuildContext context,
    required PaymentMethod method,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = method.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method.icon,
                  size: 20,
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                method.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diğer harcama pencerelerinde (Grup / Ortak Bütçe) kullanılabilir
  /// ortak kredi kartı seçim bileşeni.
  static Widget buildCardPickerSection({
    required BuildContext context,
    required bool isDark,
    required String? selectedCardId,
    required ValueChanged<String> onSelectCard,
  }) {
    final service = _creditCardService;
    if (service == null || service.cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final cards = service.cards;
    final effectiveId = (selectedCardId != null &&
            cards.any((c) => c.id == selectedCardId))
        ? selectedCardId
        : cards.first.id;

    final limitFmt = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    size: 15,
                    color: Color(0xFF8E24AA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Hangi kredi kartıyla ödendi?",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => AddCreditCardSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "+ Yeni Kart",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cards.map((card) {
              final isCardSelected = effectiveId == card.id;
              final cardColor = _parseCardColor(card.colorHex);
              final usedInstallments = service.installments
                  .where((i) => i.cardId == card.id && !i.isCompleted)
                  .fold<double>(0.0, (sum, i) => sum + i.remainingAmount);
              final usedSingle = service.getSingleShotSpendForCard(card.id);
              final remainingLimit =
                  (card.totalLimit - usedInstallments - usedSingle)
                      .clamp(0.0, card.totalLimit);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelectCard(card.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCardSelected
                          ? cardColor.withValues(alpha: isDark ? 0.35 : 0.12)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCardSelected
                            ? const Color(0xFF8E24AA)
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                        width: isCardSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.cardName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "${card.bankName} • Kalan: ${limitFmt.format(remainingLimit)}",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static Color _parseCardColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.tryParse(full, radix: 16) ?? 0xFF312E81);
  }
}
