import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_management_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/amount_input.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/budget_warning_banner.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/category_dropdown.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/date_input.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/description_input.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/save_button.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/transaction_type_selector.dart';
import 'package:get/get.dart';

class TransactionPage extends GetView<TransactionController> {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditing.value ? "İşlemi Düzenle" : "İşlem Ekle",
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TransactionTypeSelector(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: CategoryDropdown()),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: "Kategorileri Yönet",
                            onPressed: () => CategoryManagementSheet.show(
                              context,
                              initialType: controller.transactionType.value,
                            ),
                            icon: const Icon(Icons.tune_rounded),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const BudgetWarningBanner(),
                      const SizedBox(height: 16),
                      const AmountInput(),
                      const SizedBox(height: 16),
                      const DescriptionInput(),
                      const SizedBox(height: 16),
                      const DateInput(),
                      const SizedBox(height: 24),
                      const SaveButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
