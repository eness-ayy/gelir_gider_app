import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Modern, şık ve fintech standartlarında Taksitli Harcama Ekleme Bottom Sheet'i
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

  static const Color _accentColor = Color(0xFF6366F1); // Indigo
  static const Color _accentDark = Color(0xFF4F46E5);

  // Hızlı Seçim Şablonları (Popüler Taksitli Harcamalar)
  static const List<Map<String, dynamic>> _quickPresets = [
    {
      'title': 'Telefon / Tablet',
      'icon': Icons.phone_iphone_rounded,
      'installments': 6,
    },
    {
      'title': 'Bilgisayar & Donanım',
      'icon': Icons.laptop_mac_rounded,
      'installments': 9,
    },
    {
      'title': 'Beyaz Eşya',
      'icon': Icons.kitchen_rounded,
      'installments': 12,
    },
    {
      'title': 'Mobilya & Ev',
      'icon': Icons.weekend_rounded,
      'installments': 9,
    },
    {
      'title': 'Uçak & Tatil',
      'icon': Icons.flight_takeoff_rounded,
      'installments': 6,
    },
    {
      'title': 'Giyim & Moda',
      'icon': Icons.checkroom_rounded,
      'installments': 3,
    },
    {
      'title': 'Araç Bakım',
      'icon': Icons.directions_car_rounded,
      'installments': 6,
    },
  ];

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

  Color _parseHex(String hex, {Color fallback = _accentColor}) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _titleController.text = preset['title'] as String;
      final inst = preset['installments'] as int?;
      if (inst != null && _installmentPresets.contains(inst)) {
        _isCustomInstallment = false;
        _selectedInstallments = inst;
      }
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    final amount = _enteredAmount;

    if (_selectedCardId.isEmpty) {
      Get.snackbar(
        "Kart Seçimi Gerekli",
        "Lütfen harcamanın bağlı olduğu kredi kartını seçin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
      return;
    }
    if (title.isEmpty) {
      Get.snackbar(
        "Başlık Gerekli",
        "Lütfen bir harcama başlığı girin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
      return;
    }
    if (amount <= 0) {
      Get.snackbar(
        "Geçersiz Tutar",
        "Lütfen geçerli bir toplam harcama tutarı girin.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
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
    final currencyFmt = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );

    final bgCardColor = isDark ? const Color(0xFF1E1F24) : Colors.grey.shade50;
    final inputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.shade300;


    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131418) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sürükleme Tutamacı (Drag Handle)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Başlık Alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accentColor, _accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Taksitli Harcama Ekle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Kart harcamanı aylık taksitlere böl",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Kaydırılabilir İçerik
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + keyboardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hızlı Şablonlar
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: _accentColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Popüler Harcamalar",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickPresets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final preset = _quickPresets[index];
                        final isSelected =
                            _titleController.text == preset['title'];
                        return InkWell(
                          onTap: () => _applyPreset(preset),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _accentColor.withValues(alpha: 0.18)
                                  : (isDark
                                      ? const Color(0xFF1E2028)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _accentColor
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  preset['icon'] as IconData,
                                  size: 15,
                                  color: isSelected
                                      ? _accentColor
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset['title'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? _accentColor
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Kredi Kartı Seçim Kartı
                  Text(
                    "Kredi Kartı",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (controller.cards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Kayıtlı kredi kartınız bulunmuyor. Lütfen önce bir kart ekleyin.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCardId.isNotEmpty &&
                                  controller.cards
                                      .any((c) => c.id == _selectedCardId)
                              ? _selectedCardId
                              : controller.cards.first.id,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _accentColor,
                          ),
                          dropdownColor:
                              isDark ? const Color(0xFF1E1F24) : Colors.white,
                          items: controller.cards.map((c) {
                            final cardColor = _parseHex(c.colorHex);
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "💳",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${c.cardName} (${c.bankName})",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "•••• ${c.last4Digits}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
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
                  Text(
                    "Harcama Başlığı",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Örn: Dyson Süpürge, iPhone 16...",
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      filled: true,
                      fillColor: bgCardColor,
                      prefixIcon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: _accentColor,
                        size: 20,
                      ),
                      suffixIcon: _titleController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _titleController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _accentColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Toplam Tutar
                  Text(
                    "Toplam Harcama Tutarı",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "0,00",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                      ),
                      prefixIcon: Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: const Text(
                          "₺",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: bgCardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _accentColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Taksit Sayısı Seçimi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Taksit Sayısı",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isCustomInstallment = !_isCustomInstallment;
                            if (_isCustomInstallment) {
                              _customInstallmentController.text =
                                  _selectedInstallments.toString();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            _isCustomInstallment
                                ? "Varsayılan Seçenekler"
                                : "Özel Taksit Gir",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!_isCustomInstallment)
                    Row(
                      children: _installmentPresets.map((inst) {
                        final isSelected = _selectedInstallments == inst;
                        final approxMonthly = _enteredAmount > 0
                            ? (_enteredAmount / inst)
                            : 0.0;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedInstallments = inst;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [_accentColor, _accentDark],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : (isDark
                                          ? const Color(0xFF1E2028)
                                          : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentColor
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.grey.shade300),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _accentColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "$inst Taksit",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                    ),
                                    if (approxMonthly > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "₺${approxMonthly.toStringAsFixed(0)}/ay",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white70
                                              : (isDark
                                                  ? Colors.white38
                                                  : Colors.grey.shade600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bgCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _accentColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: _accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Taksit:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _customInstallmentController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (val) {
                                final n = int.tryParse(val) ?? 1;
                                setState(() {
                                  _selectedInstallments = n.clamp(1, 48);
                                });
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                          const Text(" Ay"),
                          const Spacer(),
                          Text(
                            "(1 - 48 ay)",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Canlı Taksit Simülasyon Kartı
                  if (_enteredAmount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor.withValues(alpha: 0.15),
                            _accentDark.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _accentColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          "Aylık Taksit Yükü",
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: _accentColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currencyFmt
                                        .format(_calculatedMonthlyAmount),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _accentColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pie_chart_outline_rounded,
                                  color: _accentColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Görsel Taksit Segment Çubuğu (Mini Progress Bar)
                          Row(
                            children: List.generate(
                              _selectedInstallments.clamp(1, 18),
                              (index) => Expanded(
                                child: Container(
                                  height: 4.5,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? _accentColor
                                        : _accentColor.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Toplam: ${currencyFmt.format(_enteredAmount)}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                "$_selectedInstallments Taksit Planı",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Başlangıç Tarihi Kartı
                  InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bgCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: _accentColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "İlk Ekstre Tarihi",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Builder(
                                  builder: (context) {
                                    final f = DateFormat('d MMMM yyyy', 'tr_TR');
                                    return Text(
                                      f.format(_startDate),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Değiştir",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Onay / Kaydet Butonu
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accentColor, _accentDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Taksiti Kaydet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
