import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddGroupExpenseSheet extends StatelessWidget {
  const AddGroupExpenseSheet({super.key});

  static Future<void> show(BuildContext context, {GroupExpense? expenseToEdit}) {
    final controller = Get.find<GroupDetailController>();
    controller.initExpenseForm(expenseToEdit: expenseToEdit);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGroupExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupDetailController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutma Çubuğu (Drag Handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    controller.editingExpenseId.value != null
                        ? "Grup Harcamasını Düzenle"
                        : "Grup Harcaması Ekle",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: "Kapat",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Harcama Başlığı
            Text(
              "Harcama Başlığı",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller.expenseTitleController,
              decoration: InputDecoration(
                hintText: "Örn: Market Alışverişi, Taksi, Akşam Yemeği",
                prefixIcon: const Icon(Icons.receipt_long_rounded),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Tutar & Tarih
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tutar (₺)",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.expenseAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[\.,]?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: "0.00",
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tarih",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: controller.expenseDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              controller.expenseDate.value = picked;
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd.MM.yy').format(
                                      controller.expenseDate.value,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Parayı Kim Ödedi?
            Text(
              "Parayı Kim Ödedi?",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Obx(() {
              final participants = controller.participants;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: participants.map((p) {
                    final isSelected =
                        controller.selectedPayerId.value == p.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected
                              ? Colors.white
                              : AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            p.initial,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        label: Text(p.displayName),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            controller.selectedPayerId.value = p.id;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Kullanıcı Ödediyse Cüzdan Ödeme Yöntemi Seçimi
            Obx(() {
              final currentGrp = controller.group;
              final isMePayer = currentGrp?.currentUser?.id ==
                  controller.selectedPayerId.value;

              if (!isMePayer) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Parayı başkası ödediği için kişisel cüzdanınızdan düşülmeyecek, sadece grupta borç olarak kaydedilecektir.",
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Cüzdan Ödeme Hesabı:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(Kendi payınız cüzdandan düşer)",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PaymentMethod.expenseMethods.map((method) {
                        final isSelected =
                            controller.selectedPaymentMethod.value == method;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              method.icon,
                              size: 16,
                              color: isSelected ? Colors.white : method.color,
                            ),
                            label: Text(method.title),
                            selected: isSelected,
                            selectedColor: method.color,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                controller.selectedPaymentMethod.value = method;
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }),

            // 4. Kimler Paylaşıyor?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Kimler Paylaşıyor? (Eşit Bölüşüm)",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: controller.selectAllParticipants,
                  child: const Text("Tümünü Seç", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Obx(() {
              final participants = controller.participants;
              final selectedIds = controller.selectedSplitParticipantIds;

              return Column(
                children: participants.map((p) {
                  final isChecked = selectedIds.contains(p.id);
                  return CheckboxListTile(
                    value: isChecked,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.primary,
                    secondary: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        p.initial,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      p.displayName,
                      style: TextStyle(
                        fontWeight:
                            isChecked ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onChanged: (_) => controller.toggleParticipantSplit(p.id),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 20),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Obx(
                  () => Text(
                    controller.editingExpenseId.value != null
                        ? "Değişiklikleri Kaydet"
                        : "Harcamayı Kaydet",
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
      ),
    );
  }
}
