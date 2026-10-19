import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/widgets/create_group_dialog.dart';
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
        title: Obx(() => Text(controller.pageTitle)),
        actions: [
          Obx(() {
            if (controller.currentIndex.value == 1) {
              return IconButton(
                onPressed: () => CreateGroupDialog.show(context),
                icon: const Icon(Icons.group_add_rounded),
                tooltip: "Yeni Grup Oluştur",
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            onPressed: controller.goToProfile,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Profil",
          ),
          IconButton(
            onPressed: controller.cikisYap,
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Çıkış Yap",
          ),
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
        () => AnimatedBottomNavigationBar(
          gapLocation: GapLocation.center,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightBackground,
          icons: const [
            Icons.dashboard_rounded, // 0: Ana Sayfa
            Icons.diversity_3_rounded, // 1: Gruplar
            Icons.pie_chart_rounded, // 2: Raporlar
            Icons.person_rounded, // 3: Profil
          ],
          activeIndex: controller.currentIndex.value,
          splashColor: AppColors.primary,
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.primary,
          inactiveColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black54,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          onTap: controller.changePage,
        ),
      ),
    );
  }
}
