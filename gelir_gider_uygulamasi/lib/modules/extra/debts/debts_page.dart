import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/debt_item.dart';
import 'package:gelir_gider_uygulamasi/services/debt_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  String _selectedFilter = 'all'; // 'all', 'receivable', 'payable'

  DebtService get service => Get.find<DebtService>();

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
          "Borç & Alacak Defteri",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(context),
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Yeni Kayıt Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final allDebts = service.debts;
        final totalReceivables = service.totalReceivables;
        final totalPayables = service.totalPayables;
        final netBalance = service.netBalance;

        final filteredDebts = allDebts.where((d) {
          if (_selectedFilter == 'receivable') return d.isReceivable;
          if (_selectedFilter == 'payable') return !d.isReceivable;
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet Bakiye Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Net Bakiye Durumu",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (netBalance >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            netBalance >= 0 ? "Alacaklısınız" : "Borçlusunuz",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: netBalance >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${netBalance >= 0 ? '+' : ''}${currencyFormatter.format(netBalance)}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: netBalance >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Toplam Alacak",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "+${currencyFormatter.format(totalReceivables)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Toplam Borç",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "-${currencyFormatter.format(totalPayables)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filtre Butonları
              Row(
                children: [
                  _buildFilterTab("Tümü", 'all', isDark),
                  const SizedBox(width: 8),
                  _buildFilterTab("Alacaklarım", 'receivable', isDark),
                  const SizedBox(width: 8),
                  _buildFilterTab("Borçlarım", 'payable', isDark),
                ],
              ),

              const SizedBox(height: 14),

              if (filteredDebts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Bu filtrede kayıt bulunamadı",
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
                  itemCount: filteredDebts.length,
                  itemBuilder: (context, index) {
                    final debt = filteredDebts[index];
                    return _buildDebtCard(
                      context,
                      debt,
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

  Widget _buildFilterTab(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF97316)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF97316)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    DebtItem debt,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    final isReceivable = debt.isReceivable;
    final statusColor = isReceivable
        ? const Color(0xFF10B981) // Yeşil
        : const Color(0xFFEF4444); // Kırmızı

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
          // Durum İkonu / Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceivable
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: statusColor,
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
                      debt.personName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: debt.isPaid
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isReceivable ? "Alacak" : "Borç",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (debt.notes != null && debt.notes!.isNotEmpty)
                  Text(
                    debt.notes!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                if (debt.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Vade: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),

          // Tutar & Ödendi Durumu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isReceivable ? '+' : '-'}${currencyFormatter.format(debt.amount)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => service.togglePaid(debt.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        debt.isPaid
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: debt.isPaid ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        debt.isPaid ? "Ödendi" : "Bekliyor",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: debt.isPaid ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Silme Butonu
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.grey),
            onPressed: () => service.deleteDebt(debt.id),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, {DebtItem? debtToEdit}) {
    final isEditing = debtToEdit != null;
    final nameController =
        TextEditingController(text: debtToEdit?.personName ?? '');
    final amountController = TextEditingController(
      text: debtToEdit?.amount.toStringAsFixed(0) ?? '',
    );
    final notesController =
        TextEditingController(text: debtToEdit?.notes ?? '');
    String selectedType = debtToEdit?.type ?? 'receivable';
    DateTime selectedDate =
        debtToEdit?.dueDate ?? DateTime.now().add(const Duration(days: 15));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEditing ? "Kaydı Düzenle" : "Yeni Borç / Alacak"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tür Seçimi (Alacaklıyım vs Borçluyum)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Alacaklıyım")),
                          selected: selectedType == 'receivable',
                          selectedColor:
                              const Color(0xFF10B981).withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) setState(() => selectedType = 'receivable');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Borçluyum")),
                          selected: selectedType == 'payable',
                          selectedColor:
                              const Color(0xFFEF4444).withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) setState(() => selectedType = 'payable');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Kişi / Kurum Adı",
                      hintText: "Örn: Ahmet Yılmaz, Ev Sahibi",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Tutar (₺)",
                      hintText: "Örn: 1500",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: "Açıklama / Not",
                      hintText: "Örn: Yemek hesabı, Kira farkı",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Vade Tarihi"),
                    subtitle: Text(
                      DateFormat('dd.MM.yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
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
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;

                  if (name.isNotEmpty && amount > 0) {
                    if (isEditing) {
                      service.updateDebt(debtToEdit.copyWith(
                        personName: name,
                        amount: amount,
                        type: selectedType,
                        notes: notesController.text.trim(),
                        dueDate: selectedDate,
                      ));
                    } else {
                      service.addDebt(DebtItem(
                        id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                        personName: name,
                        amount: amount,
                        type: selectedType,
                        notes: notesController.text.trim(),
                        dueDate: selectedDate,
                      ));
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
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
