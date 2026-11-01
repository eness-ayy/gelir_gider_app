import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/edit_profile_dialog.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

/// Misafir kullanıcılar için sade, kısa ve modern bilgilendirme diyaloğu.
class GuestFeatureDialog extends StatelessWidget {
  final String title;
  final String featureName;
  final String description;
  final IconData icon;
  final Color accentColor;

  const GuestFeatureDialog({
    super.key,
    required this.title,
    required this.featureName,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  /// Diyaloğu görüntüler
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String featureName,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => GuestFeatureDialog(
        title: title,
        featureName: featureName,
        description: description,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Dialog(
      backgroundColor: bgColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // İkon: 56x56 yumuşak daire + kilit rozeti
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 28, color: accentColor),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Kısa Başlık
              Text(
                "$featureName İçin Giriş Yapın",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Kısa Açıklama Metni
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Ana Buton: Giriş Yap / Kayıt Ol
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (!Get.isRegistered<ProfileController>()) {
                      Get.put(ProfileController());
                    }
                    EditProfileDialog.show(
                      context,
                      title: "$featureName İçin Giriş Yapın",
                      subtitle:
                          "Bu özelliği kullanabilmek için ücretsiz hesabınızı oluşturun veya giriş yapın.",
                      icon: icon,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Giriş Yap / Kayıt Ol",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Vazgeç Butonu
              SizedBox(
                width: double.infinity,
                height: 38,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  child: const Text(
                    "Vazgeç",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
