import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AccountBalancesCard extends GetView<DashboardController> {
  final EdgeInsetsGeometry? margin;

  const AccountBalancesCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final balances = controller.overallAccountBalances;
      final selectedFilter = controller.selectedAccountFilter.value;

      return Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 4, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Başlık & Filtre Durumu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Cüzdan & Hesap Bakiyeleri",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedFilter != 'all') ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.setAccountFilter('all'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Filtreyi Kaldır",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 3 Hesap Kartı (Nakit, Banka Kartı, Kredi Kartı)
              Row(
                children: [
                  // 1. Cebimdeki Nakit
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Cebimdeki Nakit",
                      subtitle: "Eldeki Para",
                      amount: balances.cashBalance,
                      method: PaymentMethod.cash,
                      isSelected: selectedFilter == PaymentMethod.cash.key,
                      isDark: isDark,
                      onTap: () =>
                          controller.setAccountFilter(PaymentMethod.cash.key),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Bankadaki Param
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Bankadaki Para",
                      subtitle: "Vadesiz Hesap",
                      amount: balances.bankBalance,
                      method: PaymentMethod.bankCard,
                      isSelected: selectedFilter == PaymentMethod.bankCard.key,
                      isDark: isDark,
                      onTap: () => controller.setAccountFilter(
                        PaymentMethod.bankCard.key,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Kredi Kartı
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Kredi Kartı",
                      subtitle: "Harcamalar",
                      amount: balances.creditCardExpense,
                      method: PaymentMethod.creditCard,
                      isSelected:
                          selectedFilter == PaymentMethod.creditCard.key,
                      isDark: isDark,
                      isExpenseOnly: true,
                      onTap: () => controller.setAccountFilter(
                        PaymentMethod.creditCard.key,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Alt Bilgi: Toplam Hazır Para (Nakit + Banka)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Toplam Hazır Para (Nakit + Banka):",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat.currency(
                        symbol: '₺',
                        decimalDigits: 2,
                      ).format(balances.totalLiquidAssets),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: balances.totalLiquidAssets >= 0
                            ? (isDark
                                  ? Colors.greenAccent.shade200
                                  : AppColors.income)
                            : (isDark
                                  ? Colors.redAccent.shade100
                                  : AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required PaymentMethod method,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isExpenseOnly = false,
  }) {
    final methodColor = method.color;
    final formattedAmount = NumberFormat.currency(
      symbol: '₺',
      decimalDigits: 0,
    ).format(amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? methodColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? methodColor
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method.icon, size: 14, color: methodColor),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: methodColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedAmount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isExpenseOnly
                      ? (amount > 0
                            ? (isDark
                                  ? Colors.redAccent.shade100
                                  : Colors.red.shade700)
                            : methodColor)
                      : (amount >= 0
                            ? (isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary)
                            : (isDark
                                  ? Colors.redAccent.shade100
                                  : AppColors.expense)),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
