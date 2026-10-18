import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/categories_controller.dart';
import 'package:gelir_gider_uygulamasi/services/budget_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/icon_helper.dart';
import 'package:get/get.dart';

class CategoryFormDialog extends StatefulWidget {
  final AppCategory? categoryToEdit;
  final String? initialType;

  const CategoryFormDialog({
    super.key,
    this.categoryToEdit,
    this.initialType,
  });

  static Future<bool?> show(
    BuildContext context, {
    AppCategory? categoryToEdit,
    String? initialType,
  }) {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController());
    }
    return showDialog<bool>(
      context: context,
      builder: (context) => CategoryFormDialog(
        categoryToEdit: categoryToEdit,
        initialType: initialType,
      ),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late String _selectedType;
  late String _selectedIcon;

  final List<String> availableIcons = [
    'wallet',
    'cash',
    'trending-up',
    'cart',
    'receipt',
    'bus',
    'medical',
    'school',
    'game-controller',
    'restaurant',
    'family',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.categoryToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    final catId = edit?.id;
    final existingBudget = catId != null && Get.isRegistered<BudgetService>()
        ? Get.find<BudgetService>().getBudget(catId)
        : null;
    _budgetController = TextEditingController(
      text: existingBudget != null && existingBudget > 0
          ? existingBudget.toStringAsFixed(0)
          : '',
    );
    _selectedType = (edit?.type?.isNotEmpty == true)
        ? edit!.type!
        : (widget.initialType?.isNotEmpty == true
            ? widget.initialType!
            : 'expense');
    _selectedIcon = (edit?.icon?.isNotEmpty == true) ? edit!.icon! : availableIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;
    final controller = Get.find<CategoriesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomeColor = isDark ? Colors.greenAccent.shade200 : AppColors.income;
    final expenseColor = isDark ? Colors.redAccent.shade100 : AppColors.expense;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isEditing ? "Kategoriyi Düzenle" : "Yeni Kategori Ekle",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              // 1. Tür Seçimi (Gelir / Gider)
              const Text(
                "Kategori Türü",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: _selectedType == 'expense'
                                ? Colors.white
                                : expenseColor,
                          ),
                          const SizedBox(width: 4),
                          const Text("Gider"),
                        ],
                      ),
                      selected: _selectedType == 'expense',
                      selectedColor: expenseColor,
                      labelStyle: TextStyle(
                        color: _selectedType == 'expense' ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: _selectedType == 'income'
                                ? Colors.white
                                : incomeColor,
                          ),
                          const SizedBox(width: 4),
                          const Text("Gelir"),
                        ],
                      ),
                      selected: _selectedType == 'income',
                      selectedColor: incomeColor,
                      labelStyle: TextStyle(
                        color: _selectedType == 'income' ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'income');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Kategori Adı
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Kategori Adı",
                  hintText: "Örn: Market, Kira, Maaş",
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Kategori adı boş bırakılamaz";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // 3. Aylık Bütçe Limiti (Yalnızca Gider kategorileri için)
              if (_selectedType == 'expense') ...[
                TextFormField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Aylık Bütçe Limiti (Opsiyonel)",
                    hintText: "Örn: 1000",
                    prefixIcon: const Icon(Icons.speed_rounded),
                    suffixText: "₺",
                    suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 4. İkon Seçimi
              const Text(
                "Kategori İkonu",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableIcons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        getCategoryIcon(
                          iconName: iconName,
                          isSystem: true,
                          type: _selectedType,
                        ),
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          FocusScope.of(context).unfocus();
                          final success = await controller.saveCategory(
                            id: widget.categoryToEdit?.id,
                            name: _nameController.text.trim(),
                            type: _selectedType,
                            icon: _selectedIcon,
                          );
                          if (success) {
                            final targetCatId = widget.categoryToEdit?.id ??
                                (controller.categories.isNotEmpty
                                    ? controller.categories.last.id
                                    : null);
                            if (targetCatId != null &&
                                Get.isRegistered<BudgetService>()) {
                              final budgetService = Get.find<BudgetService>();
                              if (_selectedType == 'expense') {
                                final budgetAmount = double.tryParse(
                                  _budgetController.text
                                      .replaceAll(',', '.')
                                      .trim(),
                                );
                                if (budgetAmount != null && budgetAmount > 0) {
                                  await budgetService.setBudget(
                                    targetCatId,
                                    budgetAmount,
                                  );
                                } else if (_budgetController.text.trim().isEmpty) {
                                  await budgetService.removeBudget(targetCatId);
                                }
                              } else {
                                // Gelir kategorilerinde bütçe limiti olamaz
                                await budgetService.removeBudget(targetCatId);
                              }
                            }
                          }
                          if (success && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? "Güncelle" : "Kaydet",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
