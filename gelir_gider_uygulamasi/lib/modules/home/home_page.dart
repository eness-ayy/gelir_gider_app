import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_page.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
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
            DashboardPage(),
            ReportsPage(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.goToTransaction,
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
              : AppColors.darkBackground,
          icons: const [
            Icons.dashboard_rounded,
            Icons.pie_chart_rounded,
          ],
          activeIndex: controller.currentIndex.value,
          splashColor: AppColors.primary,
          activeColor: Colors.white,
          inactiveColor: Colors.white54,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          onTap: controller.changePage,
        ),
      ),
    );
  }
}
