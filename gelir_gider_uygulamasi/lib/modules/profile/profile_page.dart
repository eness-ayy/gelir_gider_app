import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_management_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/delete_account_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/edit_profile_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/export_pdf_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/feedback_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/monthly_budget_limits_sheet.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class ProfilePage extends GetView<ProfileController> {
  final bool showAppBar;
  const ProfilePage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: showAppBar
          ? AppBar(
              title: const Text(
                "Profilim",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, showAppBar ? 40 : 100),
        child: Obx(() {
          final user = controller.user.value;
          User? fbUser;
          try {
            fbUser = FirebaseAuth.instance.currentUser;
          } catch (_) {
            fbUser = null;
          }
          final photoUrl = user?.profile_photo;

          final fullName = [
            user?.first_name,
            user?.last_name,
          ].where((s) => s != null && s.trim().isNotEmpty).join(' ').trim();

          final displayName = fullName.isNotEmpty
              ? fullName
              : (fbUser?.displayName?.trim().isNotEmpty == true
                  ? fbUser!.displayName!.trim()
                  : (fbUser?.email?.split('@').first ?? "Kullanıcı"));

          final displayEmail = (user?.email != null && user!.email!.isNotEmpty)
              ? user.email!
              : (fbUser?.email ?? "");

          final initial = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : (displayEmail.isNotEmpty ? displayEmail[0].toUpperCase() : 'K');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Yeşil renkli dairesel avatar ("E" veya seçilen avatar)
              GestureDetector(
                onTap: () => EditProfileDialog.show(context),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: (photoUrl != null && photoUrl.isNotEmpty)
                      ? ClipOval(
                          child: photoUrl.startsWith('assets/')
                              ? Image.asset(
                                  photoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                              : Image.network(
                                  photoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                ),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Ad Soyad (Büyük ve Kalın)
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              // Email (Daha küçük ve sönük gri)
              Text(
                displayEmail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              // Profili Düzenle Kartı
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Profili Düzenle",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => EditProfileDialog.show(context),
                ),
              ),
              const SizedBox(height: 8),
              SettingsCard(),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text("Kategori Yönetimi"),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => CategoryManagementSheet.show(context),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.speed_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Aylık Limit Belirleme",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Kategoriler için aylık harcama limitleri",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => MonthlyBudgetLimitsSheet.show(context),
                ),
              ),
              const SizedBox(height: 8),
              // Verileri Dışa Aktar (PDF) Kartı
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Verileri Dışa Aktar (PDF)",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Tarih aralığı seçerek PDF raporu oluşturun",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => ExportPdfDialog.show(context),
                ),
              ),
              const SizedBox(height: 8),
              // Geri Bildirim & İletişim Kartı
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Geri Bildirim & İletişim",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Hata bildirin veya önerinizi paylaşın",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => FeedbackSheet.show(context),
                ),
              ),
              const SizedBox(height: 8),
              // Verileri Sıfırla Kartı
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.orange.withValues(alpha: 0.25),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restart_alt_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Verileri Sıfırla",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    "Tüm gelir, gider ve bütçe kayıtlarını temizleyin",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.orange,
                  ),
                  onTap: () => _showResetDataDialog(context),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.redAccent.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Çıkış Yap",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.redAccent,
                  ),
                  onTap: () {
                    Get.defaultDialog(
                      title: "Çıkış Yap",
                      middleText:
                          "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
                      textConfirm: "Evet, Çıkış Yap",
                      textCancel: "Vazgeç",
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.redAccent,
                      onConfirm: () {
                        Get.back();
                        controller.cikisYap();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Hesabı Sil Kartı
              Card(
                color: Colors.red.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Hesabı Sil",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    "Hesabınızı ve verilerinizi kalıcı olarak silin",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red,
                  ),
                  onTap: () => DeleteAccountDialog.show(context),
                ),
              ),
              const SizedBox(height: 24),
              // Sürüm Bilgisi
              Center(
                child: Text(
                  "v1.0.0",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }

  void _showResetDataDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Verileri Sıfırla",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tüm gelir, gider, bütçe ve harcama kayıtlarınız kalıcı olarak silinecek, kategorileriniz varsayılan duruma getirilecektir.",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bu işlem geri alınamaz!",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Vazgeç",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          Obx(() {
            final loading = controller.isResetting.value;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      Get.back();
                      await controller.resetUserData();
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      "Evet, Sıfırla",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  SettingsCard({super.key});
  final ThemeServices themeServices = Get.find<ThemeServices>();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.brightness_6),
        title: Text("Tema"),
        trailing: Obx(
          () => Switch(
            value: themeServices.isDarkMode,
            onChanged: (value) => themeServices.toggleTheme(),
          ),
        ),
      ),
    );
  }
}

// ProfileView alias desteği
typedef ProfileView = ProfilePage;
