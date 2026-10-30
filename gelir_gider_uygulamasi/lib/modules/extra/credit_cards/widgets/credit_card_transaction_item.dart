import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreditCardTransactionItem extends StatelessWidget {
  final AppTransaction transaction;
  final CreditCardModel? card;
  final bool showCardBadge;
  final Future<bool> Function(String id)? onDelete;

  const CreditCardTransactionItem({
    super.key,
    required this.transaction,
    this.card,
    this.showCardBadge = true,
    this.onDelete,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    final clean = hex.replaceAll('#', '');
    final full = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.tryParse(full, radix: 16) ?? 0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryName = transaction.category?.name.trim() ?? '';
    final rawDesc = transaction.description.trim();

    // Grup harcaması formatı varsa temizle: [GrupAdı|Tutar] Açıklama
    final groupMatch = RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(rawDesc);
    final isGroup = groupMatch != null;
    final groupHeader = groupMatch?.group(1)?.split('|').first.trim() ?? '';
    final cleanDesc = isGroup
        ? (groupMatch.group(2) ?? '')
            .replaceAll(RegExp(r'\s*\[(GRP_STL|SHR_STL):.*?\]'), '')
            .trim()
        : rawDesc;

    final String title;
    final String? subtitleDesc;
    if (isGroup) {
      title = cleanDesc.isNotEmpty
          ? cleanDesc
          : (groupHeader.isNotEmpty ? '$groupHeader Harcaması' : 'Grup Harcaması');
      subtitleDesc = groupHeader.isNotEmpty ? 'Grup: $groupHeader' : null;
    } else if (categoryName.isNotEmpty && categoryName != 'İsimsiz Kategori') {
      title = categoryName;
      subtitleDesc = (cleanDesc.isNotEmpty &&
              cleanDesc != categoryName &&
              cleanDesc != 'Gider İşlemi' &&
              cleanDesc != 'Gelir İşlemi')
          ? cleanDesc
          : null;
    } else {
      title = cleanDesc.isNotEmpty ? cleanDesc : 'Kredi Kartı Harcaması';
      subtitleDesc = null;
    }

    final parsedDate = DateTime.tryParse(transaction.date) ?? DateTime.now();
    final dateStr = DateFormat('d MMM yyyy', 'tr_TR').format(parsedDate);
    final amountStr = CurrencyHelper.formatBase(transaction.baseAmount);
    final cardColor = _parseColor(card?.colorHex);

    final content = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.toNamed(AppRoutes.transaction, arguments: transaction);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Kategori İkonu
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E24AA)
                        .withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGroup
                        ? Icons.groups_rounded
                        : getCategoryIcon(
                            iconName: transaction.category?.icon ?? 'credit_card',
                            isSystem: true,
                            type: 'expense',
                            categoryName: title,
                          ),
                    color: const Color(0xFFAB47BC),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Başlık, Açıklama ve Kart Etiketi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (subtitleDesc != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (showCardBadge && card != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor.withValues(
                                  alpha: isDark ? 0.28 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: cardColor.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    size: 11,
                                    color: isDark ? Colors.white : cardColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    card!.cardName,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : cardColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tutar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "-$amountStr",
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tek Çekim",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
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

    if (onDelete == null) return content;

    return Dismissible(
      key: ValueKey('cc_tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete!(transaction.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Sil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      child: content,
    );
  }
}

