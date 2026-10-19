import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class PaymentAccountSelector extends GetView<TransactionController> {
  const PaymentAccountSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isExpense = controller.transactionType.value == 'expense';
      final currentMethod = controller.selectedPaymentMethod.value;
      final availableMethods = isExpense
          ? PaymentMethod.expenseMethods
          : PaymentMethod.incomeMethods;

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
                    },
                  ),
                ),
              );
            }).toList(),
          ),
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
}
