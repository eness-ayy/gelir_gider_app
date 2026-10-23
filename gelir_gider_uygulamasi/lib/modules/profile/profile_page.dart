import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_management_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/delete_account_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/edit_profile_dialog.dart';
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
              const SizedBox(height: 16),
            ],
          );
        }),
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
