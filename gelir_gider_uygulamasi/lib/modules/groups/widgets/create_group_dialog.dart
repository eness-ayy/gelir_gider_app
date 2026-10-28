import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

/// Modern, şık ve fintech/social standartlarında Yeni Grup & Etkinlik Oluşturma Diyaloğu
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (_) => const CreateGroupDialog(),
    );
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  late final TextEditingController _groupNameController;
  late final List<TextEditingController> _participantControllers;
  bool _isSubmitting = false;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _skyBlue = Color(0xFF38BDF8);

  // Hızlı Grup / Etkinlik Şablonları
  static const List<Map<String, dynamic>> _quickGroupPresets = [
    {
      'title': 'Ev Masrafları',
      'icon': Icons.home_rounded,
    },
    {
      'title': 'Antalya Tatili',
      'icon': Icons.beach_access_rounded,
    },
    {
      'title': 'Akşam Yemeği',
      'icon': Icons.restaurant_rounded,
    },
    {
      'title': 'Yol & Benzin',
      'icon': Icons.directions_car_rounded,
    },
    {
      'title': 'Doğum Günü',
      'icon': Icons.cake_rounded,
    },
    {
      'title': 'Kamp Etkinliği',
      'icon': Icons.forest_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _participantControllers = [
      TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final c in _participantControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addParticipantField() {
    setState(() {
      _participantControllers.add(TextEditingController());
    });
  }

  void _removeParticipantField(int index) {
    if (_participantControllers.length > 1) {
      setState(() {
        final removed = _participantControllers.removeAt(index);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          removed.dispose();
        });
      });
    }
  }

  Future<void> _submit() async {
    final title = _groupNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bir grup adı girin"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final names = _participantControllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    setState(() => _isSubmitting = true);

    try {
      final groupsController = Get.isRegistered<GroupsController>()
          ? Get.find<GroupsController>()
          : Get.put(GroupsController());

      final created = await groupsController.createNewGroup(
        title: title,
        participantNames: names,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("\"${created.title}\" grubu başarıyla oluşturuldu"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Grup oluşturulurken bir hata oluştu"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCardColor = isDark ? const Color(0xFF1E2028) : Colors.grey.shade50;
    final inputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade300;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: isDark ? const Color(0xFF14161C) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık & İkon & Kapatma Butonu
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, _skyBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Yeni Grup / Etkinlik",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
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
                const SizedBox(height: 16),

                // Hızlı Şablonlar
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: _skyBlue.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Örnek Şablonlar",
                      style: TextStyle(
                        fontSize: 12,
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
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickGroupPresets.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = _quickGroupPresets[index];
                      final isSelected =
                          _groupNameController.text == preset['title'];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _groupNameController.text =
                                preset['title'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryBlue.withValues(alpha: 0.2)
                                : (isDark
                                    ? const Color(0xFF1E222B)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _primaryBlue
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
                                size: 14,
                                color: isSelected
                                    ? _skyBlue
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset['title'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _skyBlue
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

                // Grup Adı
                Text(
                  "Grup Adı",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _groupNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Örn: Ev Arkadaşları, Antalya Tatili",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: bgCardColor,
                    prefixIcon: const Icon(
                      Icons.groups_rounded,
                      color: _skyBlue,
                      size: 20,
                    ),
                    suffixIcon: _groupNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _groupNameController.clear();
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: inputBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _primaryBlue,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Katılımcılar Başlığı & Kişi Ekle Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Diğer Katılımcılar",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addParticipantField,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: _skyBlue,
                      ),
                      label: const Text(
                        "Kişi Ekle",
                        style: TextStyle(
                          color: _skyBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // "Sen (Otomatik Dahil)" Sabit Rozet
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: _skyBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sen",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: _skyBlue,
                              ),
                            ),
                            Text(
                              "Grup Yöneticisi",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryBlue, _skyBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Yönetici",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dinamik Katılımcı Alanları (Varsayılan 1 Katılımcı)
                Column(
                  children: List.generate(
                    _participantControllers.length,
                    (index) {
                      final c = _participantControllers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            // Katılımcı Numaralı Avatar
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E222B)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: inputBorderColor,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: InputDecoration(
                                  hintText: "Katılımcı ${index + 1} adı",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 19,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                  filled: true,
                                  fillColor: bgCardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: inputBorderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _primaryBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_participantControllers.length > 1) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _removeParticipantField(index),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white60
                            : Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        "İptal",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, _skyBlue],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group_add_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Grup Oluştur",
                                    style: TextStyle(
                                      fontSize: 14.5,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
