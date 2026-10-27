import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

/// Tutar girişi + 4 Para Birimi Seçici (TRY, USD, EUR, GBP) + Modern Dönüşüm Kartı
class AmountInput extends GetView<TransactionController> {
  const AmountInput({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final currency = controller.selectedCurrency.value;
      final isForeign = !currency.isBase;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Şık Para Birimi Seçici
          _CurrencySegmentedSelector(
            selected: currency,
            isDark: isDark,
            onSelected: controller.selectCurrency,
          ),
          const SizedBox(height: 12),

          // 2. Tutar Giriş Alanı
          TextFormField(
            key: const ValueKey('amount_input'),
            controller: controller.amountController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: "Miktar (${currency.symbol})",
              hintText: "0,00",
              border: const OutlineInputBorder(),
              prefixIcon: _SymbolIcon(symbol: currency.symbol),
              suffixText: currency.code,
              suffixStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Lütfen bir miktar giriniz";
              }
              final parsed = CurrencyHelper.parseInput(value);
              if (parsed == null || parsed <= 0) {
                return "Lütfen geçerli pozitif bir miktar giriniz";
              }
              return null;
            },
          ),

          // 3. Döviz Seçildiğinde Açılan Entegre Dönüşüm & Kur Kartı
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isForeign
                ? _ForeignConversionCard(currency: currency, isDark: isDark)
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    });
  }
}

/// 4 Para Birimi Seçici (TRY, USD, EUR, GBP)
class _CurrencySegmentedSelector extends StatelessWidget {
  const _CurrencySegmentedSelector({
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final AppCurrency selected;
  final bool isDark;
  final ValueChanged<AppCurrency> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: AppCurrency.values.map((c) {
          final isSelected = c == selected;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('currency_chip_${c.code}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: isDark ? 0.24 : 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark ? Colors.white : primary)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.code,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : primary)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Yeniden Tasarlanan Premium Döviz Dönüşüm & Kur Kartı
class _ForeignConversionCard extends GetView<TransactionController> {
  const _ForeignConversionCard({
    required this.currency,
    required this.isDark,
  });

  final AppCurrency currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B202C) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final isManual = controller.isManualRate.value;
        final isExpanded = controller.isRateEditingExpanded.value;
        final currentRate = controller.exchangeRate.value;
        final rateFormatted = currentRate > 0
            ? currentRate.toStringAsFixed(2).replaceAll('.', ',')
            : '0,00';
        final baseAmount = controller.enteredBaseAmount;
        final isLoading = controller.currencyService.isLoading.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst Satır: Canlı / Özel Kur Rozeti + Yenileme & Düzenleme Butonları
            Row(
              children: [
                // Durum Rozeti
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isManual
                        ? Colors.amber.withValues(alpha: isDark ? 0.2 : 0.14)
                        : const Color(0xFF00E676)
                            .withValues(alpha: isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isManual
                          ? Colors.amber.withValues(alpha: 0.4)
                          : const Color(0xFF00E676).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: isManual
                              ? Colors.amber.shade400
                              : const Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isManual
                            ? "1 ${currency.code} = $rateFormatted ₺ (Özel Kur)"
                            : "1 ${currency.code} = $rateFormatted ₺ (Canlı)",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isManual
                              ? (isDark ? Colors.amber.shade300 : Colors.amber.shade800)
                              : (isDark
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF00897B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Canlı Kura Dön Butonu (yalnızca özel kur girildiyse)
                if (isManual) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: controller.resetToLiveRate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.undo_rounded, size: 13, color: primary),
                          const SizedBox(width: 3),
                          Text(
                            "Canlı Kura Dön",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Yenile Butonu (Canlı moddaysa)
                if (!isManual)
                  IconButton(
                    tooltip: "Kuru Yenile",
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: isLoading ? null : controller.refreshLiveRate,
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh_rounded, color: secondary),
                  ),

                const SizedBox(width: 4),

                // Kuru Düzenle / Gizle Butonu
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: controller.toggleRateEditing,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.close_rounded : Icons.edit_rounded,
                          size: 13,
                          color: isExpanded ? Colors.redAccent : secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isExpanded ? "Kapat" : "Düzenle",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isExpanded ? Colors.redAccent : secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Orta Satır: Büyük & Şık TRY Karşılığı Özeti
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "YAKLAŞIK TRY KARŞILIĞI",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyHelper.formatBase(baseAmount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),

            // Düzenle Tıklandığında Açılan Akordeon Alanı
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Özel Kur Belirleyin (1 ${currency.code} = ? ₺)",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: const ValueKey('exchange_rate_input'),
                                    controller: controller.rateController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      hintText: "Örn: 34,50",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixText: '₺',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (val) {
                                      controller.isManualRate.value = true;
                                    },
                                    validator: controller.validateRate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    controller.isRateEditingExpanded.value =
                                        false;
                                  },
                                  child: const Text(
                                    "Tamam",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }),
    );
  }
}

/// Prefix sembol ikonu
class _SymbolIcon extends StatelessWidget {
  const _SymbolIcon({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
