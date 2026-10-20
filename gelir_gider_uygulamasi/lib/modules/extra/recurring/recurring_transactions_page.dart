import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/recurring_transaction.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RecurringTransactionsPage extends StatelessWidget {
  const RecurringTransactionsPage({super.key});

  RecurringService get service => Get.find<RecurringService>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tekrarlayan Ödemeler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurringDialog(context),
        backgroundColor: const Color(0xFFA855F7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Yeni Ödeme Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final items = service.items;
        final monthlyTotal = service.monthlyTotal;
        final activeCount = service.activeCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF581C87), Color(0xFF7E22CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7E22CE).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Aylık Tahmini Toplam Yük",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$activeCount Aktif Ödeme",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormatter.format(monthlyTotal),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Kira, abonelikler ve periyodik faturalar dahil",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Düzenli Ödeme & Abonelikleriniz",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Henüz tekrarlayan ödeme eklenmemiş",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildRecurringCard(
                      context,
                      item,
                      isDark,
                      currencyFormatter,
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    RecurringTransaction item,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    final daysRemaining = item.daysUntilNextPayment;
    final periodText = item.period == 'yearly'
        ? 'Yıllık'
        : (item.period == 'weekly' ? 'Haftalık' : 'Aylık');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // İkon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_repeat_rounded,
              color: Color(0xFFA855F7),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        periodText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA855F7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      "Her ayın ${item.paymentDay}. günü",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daysRemaining == 0
                            ? "Bugün!"
                            : "$daysRemaining gün kaldı",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: daysRemaining <= 3
                              ? Colors.redAccent
                              : Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tutar ve Aktiflik
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(item.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA855F7),
                ),
              ),
              const SizedBox(height: 2),
              Switch(
                value: item.isActive,
                activeThumbColor: const Color(0xFFA855F7),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => service.toggleActive(item.id),
              ),
            ],
          ),

          // Silme Butonu
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.grey),
            onPressed: () => service.deleteItem(item.id),
          ),
        ],
      ),
    );
  }

  void _showAddRecurringDialog(BuildContext context,
      {RecurringTransaction? itemToEdit}) {
    final isEditing = itemToEdit != null;
    final titleController =
        TextEditingController(text: itemToEdit?.title ?? '');
    final amountController = TextEditingController(
      text: itemToEdit?.amount.toStringAsFixed(0) ?? '',
    );
    final dayController = TextEditingController(
      text: itemToEdit?.paymentDay.toString() ?? '1',
    );
    String selectedPeriod = itemToEdit?.period ?? 'monthly';
    String selectedCategory = itemToEdit?.category ?? 'Abonelikler';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEditing
                ? "Ödemeyi Düzenle"
                : "Yeni Tekrarlayan Ödeme"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Hizmet / Başlık",
                      hintText: "Örn: Netflix, Ev Kirası, İnternet",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Tutar (₺)",
                      hintText: "Örn: 249",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Ödeme Günü (Ayın 1-31'i)",
                      hintText: "Örn: 15",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: "Periyot",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text("Aylık")),
                      DropdownMenuItem(value: 'weekly', child: Text("Haftalık")),
                      DropdownMenuItem(value: 'yearly', child: Text("Yıllık")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedPeriod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      hintText: "Örn: Abonelikler, Kira & Ev, Faturalar",
                      border: OutlineInputBorder(),
                    ),
                    controller:
                        TextEditingController(text: selectedCategory),
                    onChanged: (val) => selectedCategory = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;
                  final day = int.tryParse(dayController.text.trim()) ?? 1;

                  if (title.isNotEmpty && amount > 0) {
                    if (isEditing) {
                      service.updateItem(itemToEdit.copyWith(
                        title: title,
                        amount: amount,
                        paymentDay: day.clamp(1, 31),
                        period: selectedPeriod,
                        category: selectedCategory,
                      ));
                    } else {
                      service.addItem(RecurringTransaction(
                        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        amount: amount,
                        paymentDay: day.clamp(1, 31),
                        period: selectedPeriod,
                        category: selectedCategory,
                        isActive: true,
                      ));
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? "Güncelle" : "Kaydet"),
              ),
            ],
          );
        },
      ),
    );
  }
}
