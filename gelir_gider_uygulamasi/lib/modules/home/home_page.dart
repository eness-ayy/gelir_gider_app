import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_page.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_page.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.pageTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(() {
            if (controller.currentIndex.value == 3) {
              return IconButton(
                tooltip: "Çıkış Yap",
                icon: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.lightTextPrimary,
                ),
                onPressed: () {
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
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            DashboardPage(), // Sekme 0: Ana Sayfa / Cüzdan
            GroupsPage(), // Sekme 1: Gruplar & Etkinlikler [YENİ]
            ReportsPage(), // Sekme 2: İstatistikler & Raporlar
            ProfilePage(), // Sekme 3: Profil & Ayarlar
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showAddActionSheet(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(
        () => AnimatedBottomNavigationBar.builder(
          itemCount: 4,
          tabBuilder: (int index, bool isActive) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final color = isActive
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark ? Colors.white54 : Colors.black45);

            const navItems = [
              (icon: Icons.dashboard_rounded, label: "Dashboard"),
              (icon: Icons.diversity_3_rounded, label: "Gruplar"),
              (icon: Icons.pie_chart_rounded, label: "İstatistikler"),
              (icon: Icons.person_rounded, label: "Profil"),
            ];
            final item = navItems[index];

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            );
          },
          height: 64,
          gapLocation: GapLocation.center,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightBackground,
          activeIndex: controller.currentIndex.value,
          splashColor: AppColors.primary,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          onTap: controller.changePage,
        ),
      ),
    );
  }
}
