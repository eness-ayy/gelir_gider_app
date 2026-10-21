import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddInstallmentSheet extends StatefulWidget {
  final String? preselectedCardId;

  const AddInstallmentSheet({
    super.key,
    this.preselectedCardId,
  });

  static Future<void> show(BuildContext context, {String? cardId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddInstallmentSheet(preselectedCardId: cardId),
    );
  }

  @override
  State<AddInstallmentSheet> createState() => _AddInstallmentSheetState();
}

class _AddInstallmentSheetState extends State<AddInstallmentSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customInstallmentController = TextEditingController();

  late String _selectedCardId;
  int _selectedInstallments = 6;
  DateTime _startDate = DateTime.now();
  bool _isCustomInstallment = false;

  final List<int> _installmentPresets = [3, 6, 9, 12];

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CreditCardController>();
    if (widget.preselectedCardId != null &&
        widget.preselectedCardId!.isNotEmpty) {
      _selectedCardId = widget.preselectedCardId!;
    } else if (controller.cards.isNotEmpty) {
      _selectedCardId = controller.cards.first.id;
    } else {
      _selectedCardId = '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customInstallmentController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    final text = _amountController.text.replaceAll(',', '.').trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _calculatedMonthlyAmount {
    if (_selectedInstallments <= 0) return 0.0;
    return _enteredAmount / _selectedInstallments;
  }

  void _save() {
    final title = _titleController.text.trim();
    final amount = _enteredAmount;

    if (_selectedCardId.isEmpty) {
      Get.snackbar("Hata", "Lütfen harcamanın bağlı olduğu kartı seçin.",
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (title.isEmpty) {
      Get.snackbar("Hata", "Lütfen bir harcama başlığı girin.",
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (amount <= 0) {
      Get.snackbar("Hata", "Lütfen geçerli bir toplam tutar girin.",
          snackPosition: SnackPosition.TOP);
      return;
    }

    final controller = Get.find<CreditCardController>();
    controller.addNewInstallment(
      cardId: _selectedCardId,
      title: title,
      totalAmount: amount,
      totalInstallments: _selectedInstallments,
      startDate: _startDate,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreditCardController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sürükleme Çubuğu
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Taksitli Harcama Ekle",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Kart Seçimi
            Text(
              "Kredi Kartı",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCardId.isNotEmpty ? _selectedCardId : null,
                  isExpanded: true,
                  hint: const Text("Kart Seçin"),
                  items: controller.cards.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text("${c.cardName} (${c.bankName})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCardId = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Harcama Başlığı
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Harcama Başlığı (Örn: Dyson Süpürge)",
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Toplam Tutar
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Toplam Harcama Tutarı (₺)",
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.receipt_long_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Taksit Sayısı (3, 6, 9, 12 + Diğer)
            Text(
              "Taksit Sayısı",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ..._installmentPresets.map((inst) {
                  final isSelected = !_isCustomInstallment && _selectedInstallments == inst;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isCustomInstallment = false;
                            _selectedInstallments = inst;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : (isDark ? const Color(0xFF27272A) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$inst Taksit",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),

            // Canlı Aylık Taksit Bilgi Kutusu
            if (_enteredAmount > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Aylık Ödenecek Tutar:",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${currencyFmt.format(_calculatedMonthlyAmount)} / ay",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Başlangıç Ayı & Tarihi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    const months = [
                      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                    ];
                    final dateStr = "${_startDate.day} ${months[_startDate.month - 1]} ${_startDate.year}";
                    return Text(
                      "Başlangıç: $dateStr",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text("Tarihi Değiştir"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Taksiti Kaydet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
