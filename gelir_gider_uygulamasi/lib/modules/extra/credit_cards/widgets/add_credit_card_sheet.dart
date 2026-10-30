import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddCreditCardSheet extends StatefulWidget {
  final CreditCardModel? cardToEdit;

  const AddCreditCardSheet({super.key, this.cardToEdit});

  static Future<void> show(
    BuildContext context, {
    CreditCardModel? cardToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCreditCardSheet(cardToEdit: cardToEdit),
    );
  }

  @override
  State<AddCreditCardSheet> createState() => _AddCreditCardSheetState();
}

class _AddCreditCardSheetState extends State<AddCreditCardSheet> {
  final _cardNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _limitController = TextEditingController();
  final _last4Controller = TextEditingController();

  int _cutoffDay = 15;
  int _dueDay = 25;
  String _selectedColorHex = '#1E1B4B'; // Varsayılan İndigo

  final List<Map<String, dynamic>> _colorPresets = [
    {'name': 'İndigo', 'hex': '#1E1B4B', 'color': const Color(0xFF1E1B4B)},
    {'name': 'Titanyum', 'hex': '#0F172A', 'color': const Color(0xFF0F172A)},
    {'name': 'Zümrüt', 'hex': '#064E3B', 'color': const Color(0xFF064E3B)},
    {'name': 'Asil Mor', 'hex': '#4A044E', 'color': const Color(0xFF4A044E)},
    {'name': 'Tunç / Bakır', 'hex': '#431407', 'color': const Color(0xFF431407)},
    {'name': 'Okyanus', 'hex': '#164E63', 'color': const Color(0xFF164E63)},
  ];

  final List<String> _popularBanks = [
    'Garanti BBVA',
    'İş Bankası',
    'Yapı Kredi',
    'Akbank',
    'QNB Finansbank',
    'Ziraat Bankası',
    'VakıfBank',
    'Halkbank',
    'Enpara',
  ];

  @override
  void initState() {
    super.initState();
    final editing = widget.cardToEdit;
    if (editing != null) {
      _cardNameController.text = editing.cardName;
      _bankNameController.text = editing.bankName;
      _limitController.text = editing.totalLimit.toStringAsFixed(0);
      _last4Controller.text =
          editing.last4Digits == '0000' ? '' : editing.last4Digits;
      _cutoffDay = editing.cutoffDay;
      _dueDay = editing.dueDay;
      _selectedColorHex = editing.colorHex;
    }
    _cardNameController.addListener(_onFieldChanged);
    _bankNameController.addListener(_onFieldChanged);
    _limitController.addListener(_onFieldChanged);
    _last4Controller.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _cardNameController.removeListener(_onFieldChanged);
    _bankNameController.removeListener(_onFieldChanged);
    _limitController.removeListener(_onFieldChanged);
    _last4Controller.removeListener(_onFieldChanged);
    _cardNameController.dispose();
    _bankNameController.dispose();
    _limitController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF1E1B4B);
    }
  }

  void _showDayPicker({
    required BuildContext context,
    required String title,
    required int initialDay,
    required ValueChanged<int> onDaySelected,
  }) {
    int tempDay = initialDay;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: 290,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        "Vazgeç",
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onDaySelected(tempDay);
                        Navigator.pop(ctx);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                      child: const Text(
                        "Seç",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: (initialDay - 1).clamp(0, 30),
                    ),
                    itemExtent: 44,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      tempDay = index + 1;
                    },
                    children: List.generate(31, (index) {
                      final day = index + 1;
                      return Center(
                        child: Text(
                          "$day. Gün",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _save() {
    final cardName = _cardNameController.text.trim();
    final bankName = _bankNameController.text.trim();
    final cleanLimitText = _limitController.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final limit = double.tryParse(cleanLimitText) ?? 0.0;
    final last4 = _last4Controller.text.trim();

    if (cardName.isEmpty) {
      Get.snackbar(
        "Eksik Bilgi",
        "Lütfen bir kart adı girin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    if (limit <= 0) {
      Get.snackbar(
        "Geçersiz Limit",
        "Lütfen geçerli bir kart limiti girin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final controller = Get.isRegistered<CreditCardController>()
        ? Get.find<CreditCardController>()
        : Get.put(CreditCardController());

    if (widget.cardToEdit != null) {
      controller.updateExistingCard(
        id: widget.cardToEdit!.id,
        cardName: cardName,
        bankName: bankName.isNotEmpty ? bankName : "Banka",
        totalLimit: limit,
        cutoffDay: _cutoffDay,
        dueDay: _dueDay,
        colorHex: _selectedColorHex,
        last4Digits: last4.isNotEmpty ? last4.padLeft(4, '0') : "0000",
      );
    } else {
      controller.addNewCard(
        cardName: cardName,
        bankName: bankName.isNotEmpty ? bankName : "Banka",
        totalLimit: limit,
        cutoffDay: _cutoffDay,
        dueDay: _dueDay,
        colorHex: _selectedColorHex,
        last4Digits: last4.isNotEmpty ? last4.padLeft(4, '0') : "0000",
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final baseColor = _parseColor(_selectedColorHex);

    // Canlı Önizleme Metinleri
    final previewBank = _bankNameController.text.trim().isNotEmpty
        ? _bankNameController.text.trim().toUpperCase()
        : "BANKA ADI";
    final previewCardName = _cardNameController.text.trim().isNotEmpty
        ? _cardNameController.text.trim()
        : "KART ADI";
    final previewLast4 = _last4Controller.text.trim().isNotEmpty
        ? _last4Controller.text.trim().padLeft(4, '0')
        : "0000";

    final rawLimit = double.tryParse(
          _limitController.text.replaceAll('.', '').replaceAll(',', '.').trim(),
        ) ??
        0.0;
    final limitFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final previewLimitText = rawLimit > 0
        ? "Limit: ${limitFormatter.format(rawLimit)}"
        : "Limit: ₺0";

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + keyboardPadding),
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
                margin: const EdgeInsets.only(bottom: 12),
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
                  widget.cardToEdit != null
                      ? "Kredi Kartını Düzenle"
                      : "Yeni Kredi Kartı Ekle",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- 3. CANLI KART ÖNİZLEMESİ (Live Preview) ---
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 320,
                height: 170,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      baseColor,
                      Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Üst: Banka & Temassız
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            previewBank,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),

                    // Orta: Altın Çip & Kart Numarası
                    Row(
                      children: [
                        // Altın EMV Çip
                        Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 22,
                              height: 15,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "••••  ••••  ••••  $previewLast4",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Alt: Kart Adı, Limit & Sayaç
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                previewCardName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                previewLimitText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            "Kesim: $_cutoffDay | Son: $_dueDay",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Kart Adı
            TextField(
              controller: _cardNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Kart Adı (Örn: Bonus Platinum)",
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.credit_card_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Banka Adı
            TextField(
              controller: _bankNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Banka Adı",
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.account_balance_rounded),
              ),
            ),
            const SizedBox(height: 8),

            // Hızlı Banka Seçimi Çipleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _popularBanks.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(b, style: const TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                      onPressed: () {
                        setState(() {
                          _bankNameController.text = b;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Form Elemanları: Kart Limiti (₺ simgesi ve kısaltılmış başlık) & Son 4 Hane (4 hane ve rakam kısıtlaması)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: "Kart Limiti (₺)",
                      hintText: "50.000",
                      filled: true,
                      fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.currency_lira_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _last4Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: "Son 4 Hane",
                      counterText: "",
                      hintText: "5824",
                      filled: true,
                      fillColor: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. HESAP KESİM VE SON ÖDEME SEÇİCİLERİ (Modern Yan Yana Seçim Butonları)
            Row(
              children: [
                // Hesap Kesim Günü Butonu
                Expanded(
                  child: InkWell(
                    onTap: () => _showDayPicker(
                      context: context,
                      title: "Hesap Kesim Günü",
                      initialDay: _cutoffDay,
                      onDaySelected: (day) => setState(() => _cutoffDay = day),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Hesap Kesim",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$_cutoffDay. Gün",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Son Ödeme Günü Butonu
                Expanded(
                  child: InkWell(
                    onTap: () => _showDayPicker(
                      context: context,
                      title: "Son Ödeme Günü",
                      initialDay: _dueDay,
                      onDaySelected: (day) => setState(() => _dueDay = day),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Son Ödeme",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$_dueDay. Gün",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. KART RENK TEMASI SEÇİMİ
            Text(
              "Kart Görünüm Rengi",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _colorPresets.map((preset) {
                final isSelected = _selectedColorHex == preset['hex'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorHex = preset['hex'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: preset['color'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: (preset['color'] as Color).withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
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
                child: Text(
                  widget.cardToEdit != null
                      ? "Değişiklikleri Kaydet"
                      : "Kartı Kaydet",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
