import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileDialog(),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ProfileController _controller = Get.find<ProfileController>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _photoUrlController;

  String? _selectedPhotoUrl;
  bool _clearPhoto = false;
  bool _isPhotoSectionExpanded = false;

  // Modern preset avatars for quick selection
  static const List<String> presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=200&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final user = _controller.user.value;
    _firstNameController = TextEditingController(text: user?.first_name ?? '');
    _lastNameController = TextEditingController(text: user?.last_name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _photoUrlController = TextEditingController(text: user?.profile_photo ?? '');
    _selectedPhotoUrl = user?.profile_photo;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  String get _avatarInitial {
    final first = _firstNameController.text.trim();
    if (first.isNotEmpty) return first[0].toUpperCase();
    final userFirst = _controller.user.value?.first_name?.trim();
    if (userFirst != null && userFirst.isNotEmpty) return userFirst[0].toUpperCase();
    return 'E';
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty) {
      Get.snackbar(
        "Uyarı",
        "Lütfen adınızı giriniz",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _controller.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      profilePhoto: _clearPhoto ? null : _selectedPhotoUrl,
      clearPhoto: _clearPhoto,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final effectivePhoto = _clearPhoto ? null : _selectedPhotoUrl;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profili Düzenle",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Bilgilerinizi ve fotoğrafınızı güncelleyin",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Photo Interactive Preview
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPhotoSectionExpanded = !_isPhotoSectionExpanded;
                      });
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: (effectivePhoto != null && effectivePhoto.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                effectivePhoto,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  _avatarInitial,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              _avatarInitial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPhotoSectionExpanded = !_isPhotoSectionExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Toggle Photo Section Button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isPhotoSectionExpanded = !_isPhotoSectionExpanded;
                  });
                },
                icon: Icon(
                  _isPhotoSectionExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.add_photo_alternate_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  _isPhotoSectionExpanded
                    ? "Fotoğraf Seçeneklerini Gizle"
                    : "Profil Fotoğrafını Değiştir",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // Expandable Photo Options Section
            if (_isPhotoSectionExpanded) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hazır Avatarlardan Seç",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Preset Avatar Row
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: presetAvatars.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final avatarUrl = presetAvatars[index];
                          final isSelected = effectivePhoto == avatarUrl;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPhotoUrl = avatarUrl;
                                _photoUrlController.text = avatarUrl;
                                _clearPhoto = false;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Custom URL input
                    Text(
                      "veya Fotoğraf Bağlantısı (URL)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _photoUrlController,
                      decoration: InputDecoration(
                        hintText: "https://... (Resim linki yapıştırın)",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _selectedPhotoUrl = _photoUrlController.text.trim();
                              _clearPhoto = false;
                            });
                          },
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedPhotoUrl = val.trim();
                          _clearPhoto = false;
                        });
                      },
                    ),

                    if (effectivePhoto != null && effectivePhoto.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _clearPhoto = true;
                              _selectedPhotoUrl = null;
                              _photoUrlController.clear();
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          label: const Text(
                            "Fotoğrafı Kaldır",
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Adı (First Name) Field
            Text(
              "Ad",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                hintText: "Adınız",
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Soyadı (Last Name) Field
            Text(
              "Soyad",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                hintText: "Soyadınız",
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // E-posta (Email) Field
            Text(
              "E-posta",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                hintText: "ornek@email.com",
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      "Vazgeç",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: _controller.isUpdating.value ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _controller.isUpdating.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Değişiklikleri Kaydet",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
