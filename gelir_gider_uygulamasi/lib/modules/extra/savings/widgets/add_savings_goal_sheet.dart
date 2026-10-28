import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/savings_goal.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Modern, şık ve fintech standartlarında Birikim Hedefi Ekleme / Düzenleme Bottom Sheet'i
class AddSavingsGoalSheet extends StatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddSavingsGoalSheet({super.key, this.goalToEdit});

  static Future<void> show(BuildContext context, {SavingsGoal? goalToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsGoalSheet(goalToEdit: goalToEdit),
    );
  }

  @override
  State<AddSavingsGoalSheet> createState() => _AddSavingsGoalSheetState();
}

class _AddSavingsGoalSheetState extends State<AddSavingsGoalSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;

  late String _selectedCategory;
  late int _selectedColorValue;
  late DateTime _selectedDate;

  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.goalToEdit != null;

  // Popüler Birikim Kategorileri
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Tatil & Seyahat', 'icon': Icons.flight_takeoff_rounded},
    {'name': 'Teknoloji', 'icon': Icons.devices_rounded},
    {'name': 'Araç & Taşıt', 'icon': Icons.directions_car_rounded},
    {'name': 'Ev & Yaşam', 'icon': Icons.home_rounded},
    {'name': 'Acil Durum', 'icon': Icons.shield_outlined},
    {'name': 'Eğitim', 'icon': Icons.school_rounded},
    {'name': 'Yatırım', 'icon': Icons.trending_up_rounded},
    {'name': 'Genel', 'icon': Icons.track_changes_rounded},
  ];

  // Kumbara Renk Paletleri
  static const List<int> _colorPresets = [
    0xFF2563EB, // Kraliyet Mavisi
    0xFF10B981, // Zümrüt Yeşili
    0xFF8B5CF6, // Asil Mor
    0xFFF59E0B, // Kehribar Sarısı
    0xFFEC4899, // Pembe / Mercan
    0xFF06B6D4, // Turkuaz
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetController = TextEditingController(
      text: g != null && g.targetAmount > 0
          ? g.targetAmount.toStringAsFixed(0)
          : '',
    );
    _savedController = TextEditingController(
      text: g != null && g.savedAmount > 0
          ? g.savedAmount.toStringAsFixed(0)
          : '',
    );

    _selectedCategory = g?.category ?? 'Genel';
    _selectedColorValue = g?.colorValue ?? _colorPresets.first;
    _selectedDate =
        g?.targetDate ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final target = double.tryParse(
          _targetController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
    final saved = double.tryParse(
          _savedController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    final service = Get.find<SavingsService>();

    if (_isEditing) {
      service.updateGoal(
        widget.goalToEdit!.copyWith(
          title: title,
          targetAmount: target,
          savedAmount: saved,
          category: _selectedCategory,
          colorValue: _selectedColorValue,
          targetDate: _selectedDate,
        ),
      );
    } else {
      service.addGoal(
        SavingsGoal(
          id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          targetAmount: target,
          savedAmount: saved,
          category: _selectedCategory,
          colorValue: _selectedColorValue,
          targetDate: _selectedDate,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = Color(_selectedColorValue);
    final daysRemaining = _selectedDate.difference(DateTime.now()).inDays;

    final sheetBg = isDark ? const Color(0xFF1E222D) : Colors.white;
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF4F6F9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Üst Tutma Çubuğu (Drag Handle)
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Başlık ve Kapat Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: currentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_note_rounded
                              : Icons.savings_rounded,
                          color: currentColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? "Hedefi Düzenle"
                                  : "Yeni Birikim Hedefi",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEditing
                                  ? "Kumbaranızı güncelleyin"
                                  : "Gelecek hedefleriniz için birikim başlatın",
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Hedef Adı Alanı
                      _buildSectionLabel("HEDEF ADI", isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Örn: Tatil Kumbarası, Yeni Araba, Laptop",
                          prefixIcon: Icon(
                            Icons.bookmark_outline_rounded,
                            color: currentColor,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: currentColor,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Lütfen hedefinize bir isim verin";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 4. Hedeflenen & Başlangıç Tutarı
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("HEDEF TUTAR (₺)", isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _targetController,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Örn: 25.000",
                                    prefixIcon: const Icon(
                                      Icons.track_changes_rounded,
                                      size: 20,
                                    ),
                                    suffixText: "₺",
                                    filled: true,
                                    fillColor: inputBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: currentColor,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Hedef tutarı girin";
                                    }
                                    final parsed = double.tryParse(
                                      val.trim().replaceAll(',', '.'),
                                    );
                                    if (parsed == null || parsed <= 0) {
                                      return "Geçerli tutar girin";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(
                                  "MEVCUT BİRİKİM (₺)",
                                  isDark,
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _savedController,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    prefixIcon: const Icon(
                                      Icons.savings_outlined,
                                      size: 20,
                                    ),
                                    suffixText: "₺",
                                    filled: true,
                                    fillColor: inputBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: currentColor,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 5. Kategori Seçimi (İnteraktif Çipler)
                      _buildSectionLabel("KATEGORİ", isDark),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected =
                                cat['name'] == _selectedCategory;
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat['name'] as String;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? currentColor.withValues(
                                          alpha: isDark ? 0.25 : 0.15,
                                        )
                                      : inputBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? currentColor
                                        : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 15,
                                      color: isSelected
                                          ? currentColor
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat['name'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? (isDark
                                                ? Colors.white
                                                : currentColor)
                                            : (isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary),
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

                      // 6. Renk Seçici (Kumbaranın Rengi)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel("KUMBARA RENGİ", isDark),
                          Text(
                            "Kart Rengini Belirler",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _colorPresets.map((colorVal) {
                          final color = Color(colorVal);
                          final isSelected = colorVal == _selectedColorValue;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedColorValue = colorVal);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 7. Hedef Tarih Kartı
                      _buildSectionLabel("HEDEF TARİH", isDark),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: currentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: currentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy',
                                        'tr_TR',
                                      ).format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      daysRemaining > 0
                                          ? "$daysRemaining gün kaldı"
                                          : "Bugün",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: daysRemaining > 0
                                            ? currentColor
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 8. Kaydet / Güncelle Butonu
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: currentColor.withValues(alpha: 0.4),
                          ),
                          onPressed: _onSave,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.add_circle_outline_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing
                                    ? "Değişiklikleri Güncelle"
                                    : "Kumbarayı Oluştur",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
    );
  }
}
