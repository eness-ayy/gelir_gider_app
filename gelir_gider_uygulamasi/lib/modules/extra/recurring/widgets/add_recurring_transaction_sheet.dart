import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/recurring_transaction.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

/// Modern, şık ve fintech standartlarında Tekrarlayan Ödeme & Abonelik Ekleme/Düzenleme Bottom Sheet'i
class AddRecurringTransactionSheet extends StatefulWidget {
  final RecurringTransaction? itemToEdit;

  const AddRecurringTransactionSheet({super.key, this.itemToEdit});

  static Future<void> show(
    BuildContext context, {
    RecurringTransaction? itemToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddRecurringTransactionSheet(itemToEdit: itemToEdit),
    );
  }

  @override
  State<AddRecurringTransactionSheet> createState() =>
      _AddRecurringTransactionSheetState();
}

class _AddRecurringTransactionSheetState
    extends State<AddRecurringTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _dayController;

  late String _selectedPeriod;
  late String _selectedCategory;

  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.itemToEdit != null;

  static const Color _accentColor = Color(0xFFA855F7); // Mor / Violet

  // Hızlı Seçim Şablonları (Popüler Abonelikler)
  static const List<Map<String, dynamic>> _quickPresets = [
    {
      'title': 'Netflix',
      'icon': Icons.movie_outlined,
      'category': 'Dijital Medya',
    },
    {
      'title': 'Spotify',
      'icon': Icons.music_note_outlined,
      'category': 'Dijital Medya',
    },
    {
      'title': 'YouTube Premium',
      'icon': Icons.play_circle_outline_rounded,
      'category': 'Dijital Medya',
    },
    {
      'title': 'iCloud',
      'icon': Icons.cloud_outlined,
      'category': 'Bulut & Yazılım',
    },
    {
      'title': 'ChatGPT Plus',
      'icon': Icons.smart_toy_outlined,
      'category': 'Bulut & Yazılım',
    },
    {
      'title': 'Ev Kirası',
      'icon': Icons.home_outlined,
      'category': 'Kira & Konut',
    },
    {
      'title': 'Ev İnterneti',
      'icon': Icons.wifi_rounded,
      'category': 'Faturalar',
    },
    {
      'title': 'Elektrik Faturası',
      'icon': Icons.bolt_rounded,
      'category': 'Faturalar',
    },
    {
      'title': 'Spor Salonu',
      'icon': Icons.fitness_center_rounded,
      'category': 'Sağlık & Spor',
    },
  ];

  // Kategoriler
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Dijital Medya', 'icon': Icons.live_tv_rounded},
    {'name': 'Faturalar', 'icon': Icons.bolt_rounded},
    {'name': 'Kira & Konut', 'icon': Icons.home_rounded},
    {'name': 'Bulut & Yazılım', 'icon': Icons.cloud_done_rounded},
    {'name': 'Sağlık & Spor', 'icon': Icons.fitness_center_rounded},
    {'name': 'Eğitim & Kurs', 'icon': Icons.school_rounded},
    {'name': 'Sigorta & Finans', 'icon': Icons.security_rounded},
    {'name': 'Abonelikler', 'icon': Icons.autorenew_rounded},
    {'name': 'Diğer', 'icon': Icons.category_rounded},
  ];

  // Periyotlar
  static const List<Map<String, String>> _periods = [
    {'key': 'monthly', 'label': 'Aylık'},
    {'key': 'weekly', 'label': 'Haftalık'},
    {'key': 'yearly', 'label': 'Yıllık'},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item != null && item.amount > 0
          ? item.amount.toStringAsFixed(0)
          : '',
    );
    _dayController = TextEditingController(
      text: item != null ? item.paymentDay.toString() : '1',
    );
    _selectedPeriod = item?.period ?? 'monthly';
    _selectedCategory = item?.category ?? 'Dijital Medya';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _titleController.text = preset['title'] as String;
      _selectedCategory = preset['category'] as String;
    });
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(
          _amountController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
    final day = int.tryParse(_dayController.text.trim()) ?? 1;

    final service = Get.find<RecurringService>();

    if (_isEditing) {
      service.updateItem(
        widget.itemToEdit!.copyWith(
          title: title,
          amount: amount,
          paymentDay: day.clamp(1, 31),
          period: _selectedPeriod,
          category: _selectedCategory,
        ),
      );
    } else {
      service.addItem(
        RecurringTransaction(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          amount: amount,
          paymentDay: day.clamp(1, 31),
          period: _selectedPeriod,
          category: _selectedCategory,
          isActive: true,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          color: _accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.autorenew_rounded,
                          color: _accentColor,
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
                                  ? "Ödemeyi Düzenle"
                                  : "Yeni Tekrarlayan Ödeme",
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
                                  ? "Abonelik ve periyodik ödemenizi güncelleyin"
                                  : "Düzenli fatura veya aboneliklerinizi takip edin",
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

                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Popüler Abonelik Şablonları (Yalnızca yeni eklerken)
                      if (!_isEditing) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionLabel(
                              "HIZLI ABONELİK ŞABLONLARI",
                              isDark,
                            ),
                            Text(
                              "Tek tıkla doldur",
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
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _quickPresets.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final preset = _quickPresets[index];
                              return ActionChip(
                                avatar: Icon(
                                  preset['icon'] as IconData,
                                  size: 15,
                                  color: _accentColor,
                                ),
                                label: Text(
                                  preset['title'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                backgroundColor: inputBg,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onPressed: () => _applyPreset(preset),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 4. Hizmet / Başlık Alanı
                      _buildSectionLabel("HİZMET / BAŞLIK", isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Örn: Netflix, Ev Kirası, Fiber İnternet",
                          prefixIcon: const Icon(
                            Icons.subscriptions_outlined,
                            color: _accentColor,
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
                            borderSide: const BorderSide(
                              color: _accentColor,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Lütfen hizmet veya ödeme başlığı girin";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 5. Tutar ve Ödeme Günü (Yan Yana)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("TUTAR (₺)", isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Örn: 249",
                                    prefixIcon: const Icon(
                                      Icons.payments_outlined,
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
                                      borderSide: const BorderSide(
                                        color: _accentColor,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Tutar girin";
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
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("ÖDEME GÜNÜ", isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _dayController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: "1-31",
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                    ),
                                    suffixText: ". Gün",
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
                                      borderSide: const BorderSide(
                                        color: _accentColor,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    final d = int.tryParse(val ?? '');
                                    if (d == null || d < 1 || d > 31) {
                                      return "1-31";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 6. Ödeme Periyodu (Aylık / Haftalık / Yıllık)
                      _buildSectionLabel("TEKRARLAMA PERİYODU", isDark),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: _periods.map((p) {
                            final isSelected = p['key'] == _selectedPeriod;
                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _selectedPeriod = p['key']!;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _accentColor.withValues(
                                            alpha: isDark ? 0.3 : 0.15,
                                          )
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? _accentColor
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    p['label']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.white
                                              : _accentColor)
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 7. Kategori Seçimi (İnteraktif Çipler)
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
                                      ? _accentColor.withValues(
                                          alpha: isDark ? 0.25 : 0.15,
                                        )
                                      : inputBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentColor
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
                                          ? _accentColor
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
                                                : _accentColor)
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

                      const SizedBox(height: 24),

                      // 8. Kaydet Butonu
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: _accentColor.withValues(alpha: 0.4),
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
                                    : "Ödemeyi Kaydet",
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
