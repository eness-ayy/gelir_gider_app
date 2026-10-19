import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
import 'package:get/get.dart';

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık & İkon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Yeni Grup / Etkinlik",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Grup Adı
                Text(
                  "Grup Adı",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: "Örn: Ev Arkadaşları, Antalya Tatili",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF27272A)
                        : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Katılımcılar Başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Diğer Katılımcılar",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addParticipantField,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      label: const Text(
                        "Kişi Ekle",
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // "Sen (Otomatik Dahil)" Sabit Rozet
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B)
                        .withValues(alpha: isDark ? 0.45 : 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Sen",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
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
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: InputDecoration(
                                  hintText: "Katılımcı ${index + 1} adı",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF27272A)
                                      : Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (_participantControllers.length > 1) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _removeParticipantField(index),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

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
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                      child: const Text(
                        "İptal",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(124, 46),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
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
                          : const Text(
                              "Grup Oluştur",
                              style: TextStyle(
                                fontSize: 15,
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
      ),
    );
  }
}
