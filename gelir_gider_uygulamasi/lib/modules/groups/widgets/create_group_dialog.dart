import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Yeni Grup / Etkinlik",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grup Adı
              Text(
                "Grup Adı",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: "Örn: Ev Arkadaşları, Antalya Tatili",
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Katılımcılar Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Diğer Katılımcılar",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addParticipantField,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Kişi Ekle", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // "Sen (Grup Yöneticisi)" Sabit Rozet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Sen (Otomatik Dahil)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Yönetici",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dinamik Katılımcı Alanları
              Column(
                children: List.generate(
                  _participantControllers.length,
                  (index) {
                    final c = _participantControllers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: c,
                              decoration: InputDecoration(
                                hintText: "Katılımcı ${index + 1} adı",
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                ),
                                filled: true,
                                isDense: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 18),

              // Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text("İptal"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Grup Oluştur"),
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
