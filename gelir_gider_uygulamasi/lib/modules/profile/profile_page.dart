import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/categories/widgets/category_management_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widget/info_card.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:get/get.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Obx(
          () {
            final user = controller.user.value;
            final photoUrl = user?.profile_photo;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                InfoCard(
                  title: 'Adı',
                  value: user?.first_name ?? '-',
                ),
                InfoCard(
                  title: 'Soyad',
                  value: user?.last_name ?? '-',
                ),
                InfoCard(
                  title: 'Email',
                  value: user?.email ?? '-',
                ),
                SettingsCard(),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text("Kategori Yönetimi"),
                    subtitle: const Text("Kategorileri düzenle, sil veya ekle"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => CategoryManagementSheet.show(context),
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
                    subtitle: const Text("Hesabınızdan güvenli şekilde çıkış yapın"),
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
              ],
            );
          },
        ),
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
