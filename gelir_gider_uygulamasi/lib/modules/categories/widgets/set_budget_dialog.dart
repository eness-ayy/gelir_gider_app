import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class SetBudgetDialog extends StatefulWidget {
  final AppCategory category;

  const SetBudgetDialog({super.key, required this.category});

  static Future<bool?> show(BuildContext context, {required AppCategory category}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => SetBudgetDialog(category: category),
    );
  }

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  final BudgetService _budgetService = Get.find<BudgetService>();
  double? _currentBudget;

  @override
  void initState() {
    super.initState();
    final catId = widget.category.id;
    if (catId != null) {
      _currentBudget = _budgetService.getBudget(catId);
    }
    _limitController = TextEditingController(
      text: _currentBudget != null && _currentBudget! > 0
          ? _currentBudget!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = widget.category;
    final hasExistingBudget = _currentBudget != null && _currentBudget! > 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              getCategoryIcon(
                iconName: cat.icon ?? 'receipt',
                isSystem: cat.isSystem ?? false,
                type: cat.type ?? '',
                categoryName: cat.name,
              ),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aylık Bütçe Limiti",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  cat.name ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                "Bu kategori için aylık harcama tavanı belirleyin. Harcama %80'e ulaştığında sarı, %100'ü aştığında kırmızı uyarı verilir.",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Aylık Tavan Limit",
                  hintText: "Örn: 1000",
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: "₺",
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Lütfen bir limit tutarı girin";
                  }
                  final amount = double.tryParse(val.replaceAll(',', '.').trim());
                  if (amount == null || amount <= 0) {
                    return "Geçerli ve 0'dan büyük bir tutar girin";
                  }
                  return null;
                },
              ),
              if (hasExistingBudget) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () async {
                      if (cat.id != null) {
                        FocusScope.of(context).unfocus();
                        await _budgetService.removeBudget(cat.id!);
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                        if (Get.context != null) {
                          ScaffoldMessenger.maybeOf(Get.context!)?.showSnackBar(
                            SnackBar(
                              content: Text(
                                "'${cat.name}' kategorisinin bütçe limiti kaldırıldı",
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.black87,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Bütçeyi Kaldır"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  "Vazgeç",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final amount = double.tryParse(
                    _limitController.text.replaceAll(',', '.').trim(),
                  );
                  if (amount != null && cat.id != null) {
                    FocusScope.of(context).unfocus();
                    await _budgetService.setBudget(cat.id!, amount);
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                    if (Get.context != null) {
                      ScaffoldMessenger.maybeOf(Get.context!)?.showSnackBar(
                        SnackBar(
                          content: Text(
                            "'${cat.name}' için aylık limit: ${amount.toStringAsFixed(0)} ₺",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black87,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "Kaydet",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
