import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TransactionList extends GetView<DashboardController> {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final transactions = controller.filteredTransactions;
      final totalCount = controller.myTransaction.length;
      final filteredCount = transactions.length;

      // 1. Hiç işlem yok durumu
      if (totalCount == 0) {
        return Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: isDark
                        ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                        : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz kayıtlı bir işlem yok",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Aşağıdaki + butonuna dokunarak ilk gelirinizi veya giderinizi ekleyebilirsiniz.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 2. Filtre veya arama sonucunda işlem bulunamadı durumu
      if (filteredCount == 0) {
        return Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Eşleşen işlem bulunamadı",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Arama veya filtre kriterlerinize uyan bir kayıt bulunamadı. Filtreleri temizleyerek tüm işlemleri görebilirsiniz.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.clearFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Filtreleri Temizle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 3. Filtrelenmiş liste
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liste Üst Bilgi Başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "İşlemler",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.hasActiveFilters
                      ? "$filteredCount / $totalCount işlem"
                      : "$filteredCount işlem",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // İşlem Listesi
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: filteredCount,
              separatorBuilder: (context, index) {
                return const Divider(height: 1, indent: 72, endIndent: 16);
              },
              itemBuilder: (context, index) {
                final oankiTransaction = transactions[index];
                final category = oankiTransaction.category;
                final isIncome = oankiTransaction.type == "income";

                // Grup harcaması tespiti: [grup_adi] aciklama formatı
                final groupMatch = RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(
                  oankiTransaction.description.trim(),
                );
                final isGroupTransaction = groupMatch != null;
                final groupName = groupMatch?.group(1)?.trim() ?? '';
                final expenseDesc = groupMatch?.group(2)?.trim() ?? '';

                // Kategori adını ve ikonunu akıllıca tespit et (Asla "İsimsiz Kategori" veya kullanıcının açıklaması olmasın):
                String categoryTitle = '';
                String categoryIcon = category?.icon ?? 'category';

                final currentCatName = category?.name.trim() ?? '';
                final desc = oankiTransaction.description.trim();
                final isMistakenDesc = desc.isNotEmpty &&
                    currentCatName == desc &&
                    desc != 'Gelir İşlemi' &&
                    desc != 'Gider İşlemi';

                if (category != null &&
                    currentCatName.isNotEmpty &&
                    !isMistakenDesc &&
                    currentCatName != 'İsimsiz Kategori') {
                  categoryTitle = currentCatName;
                } else {
                  // 1. Controller'ın yüklü kategorilerinden ID veya isim ile ara
                  final foundInController = controller.categories.firstWhereOrNull(
                    (c) =>
                        c.id == oankiTransaction.categoryId ||
                        (c.name != null &&
                            c.name!.toLowerCase() ==
                                oankiTransaction.categoryId.toLowerCase()),
                  );

                  if (foundInController != null &&
                      foundInController.name != null &&
                      foundInController.name!.isNotEmpty) {
                    categoryTitle = foundInController.name!;
                    categoryIcon = foundInController.icon ?? 'category';
                  } else {
                    // 2. Standart varsayılan servis kategorilerinden ID veya isim ile ara
                    final foundInDef = CategoryService.defaultCategories.firstWhereOrNull(
                      (c) =>
                          c.id == oankiTransaction.categoryId ||
                          c.name.toLowerCase() ==
                              oankiTransaction.categoryId.toLowerCase(),
                    );

                    if (foundInDef != null) {
                      categoryTitle = foundInDef.name;
                      categoryIcon = foundInDef.icon;
                    } else {
                      // 3. CategoryRepository varsayılanlarından ara
                      final foundInRepo = CategoryRepository.defaultCategories.firstWhereOrNull(
                        (c) =>
                            c.id == oankiTransaction.categoryId ||
                            (c.name != null &&
                                c.name!.toLowerCase() ==
                                    oankiTransaction.categoryId.toLowerCase()),
                      );
                      if (foundInRepo != null && foundInRepo.name != null) {
                        categoryTitle = foundInRepo.name!;
                        categoryIcon = foundInRepo.icon ?? 'category';
                      } else if (oankiTransaction.categoryId.isNotEmpty &&
                          !oankiTransaction.categoryId.startsWith('def_') &&
                          !oankiTransaction.categoryId.startsWith('cat_') &&
                          oankiTransaction.categoryId != desc) {
                        // Eğer categoryId doğrudan bir isimse (örn. "Yemek")
                        categoryTitle = oankiTransaction.categoryId;
                      } else {
                        // KESİNLİKLE description ATA-MA! Kategori adı her zaman gerçek kategori adıdır.
                        categoryTitle = isIncome ? 'Diğer Gelir' : 'Diğer Gider';
                      }
                    }
                  }
                }

                String displayTitle;
                if (isGroupTransaction) {
                  if (expenseDesc.isNotEmpty) {
                    displayTitle =
                        expenseDesc[0].toUpperCase() + expenseDesc.substring(1);
                  } else if (groupName.isNotEmpty) {
                    displayTitle = '$groupName Harcaması';
                  } else {
                    displayTitle = 'Grup Harcaması';
                  }
                } else {
                  displayTitle = categoryTitle;
                }

                final incomeBg = isDark
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.green.shade50;
                final expenseBg = isDark
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.red.shade50;

                final incomeColor = isDark
                    ? Colors.greenAccent.shade200
                    : Colors.green.shade700;
                final expenseColor = isDark
                    ? Colors.redAccent.shade100
                    : Colors.red.shade700;

                final parsedAmount = oankiTransaction.baseAmount;
                final isForeign = oankiTransaction.isForeignCurrency;
                final amountLabel = isForeign
                    ? CurrencyHelper.format(
                        oankiTransaction.originalAmountValue,
                        oankiTransaction.currencyEnum,
                      )
                    : CurrencyHelper.formatBase(parsedAmount);
                final parsedDate =
                    DateTime.tryParse(oankiTransaction.date) ?? DateTime.now();

                return Dismissible(
                  key: ValueKey(oankiTransaction.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await controller.deleteTransactions(
                      oankiTransaction.id,
                    );
                  },
                  background: Container(
                    color: Colors.red.shade600,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline, color: Colors.white),
                      ],
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.transaction,
                        arguments: oankiTransaction,
                      );
                    },
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isIncome ? incomeBg : expenseBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGroupTransaction
                            ? Icons.groups_rounded
                            : getCategoryIcon(
                                iconName: categoryIcon,
                                isSystem: true,
                                type: category?.type ?? oankiTransaction.type,
                                categoryName: displayTitle,
                              ),
                        color: isIncome ? incomeColor : expenseColor,
                      ),
                    ),
                    title: Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Builder(
                      builder: (context) {
                        final method =
                            oankiTransaction.paymentMethod != null &&
                                oankiTransaction.paymentMethod!.isNotEmpty
                            ? PaymentMethod.fromKey(
                                oankiTransaction.paymentMethod,
                              )
                            : controller.accountService.getPaymentMethod(
                                oankiTransaction.id,
                              );

                        final hasUserDescription = !isGroupTransaction &&
                            desc.isNotEmpty &&
                            desc != displayTitle &&
                            desc != 'Gelir İşlemi' &&
                            desc != 'Gider İşlemi';

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method.icon,
                              size: 13,
                              color: method.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              method.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : method.color,
                              ),
                            ),
                            if (hasUserDescription) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "• $desc",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                            if (isGroupTransaction &&
                                groupName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3ECE0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.groups_rounded,
                                      size: 13,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      groupName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'} $amountLabel',
                          style: TextStyle(
                            color: isIncome ? incomeColor : expenseColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isForeign) ...[
                          const SizedBox(height: 2),
                          Text(
                            '~${CurrencyHelper.formatBase(parsedAmount)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd.MM.yyyy').format(parsedDate),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
