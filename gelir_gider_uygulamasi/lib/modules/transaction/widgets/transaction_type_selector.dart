import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class TransactionTypeSelector extends GetView<TransactionController> {
  const TransactionTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isIncome = controller.transactionType.value == 'income';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'expense',
              label: Text("Gider"),
              icon: Icon(Icons.remove_circle_outline),
            ),
            ButtonSegment(
              value: 'income',
              label: Text("Gelir"),
              icon: Icon(Icons.add_circle_outline_rounded),
            ),
          ],
          selected: {controller.transactionType.value},
          onSelectionChanged: (selection) {
            controller.transactionType.value = selection.first;
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                if (isIncome) {
                  return isDark ? Colors.green.shade700 : AppColors.income;
                } else {
                  return isDark ? Colors.red.shade700 : AppColors.expense;
                }
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary;
            }),
          ),
        );
      },
    );
  }
}
