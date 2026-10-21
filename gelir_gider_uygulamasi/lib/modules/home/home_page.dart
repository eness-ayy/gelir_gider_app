import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_page.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_view.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_page.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentIndex.value;
      // Ortadaki (+) butonu sadece Cüzdan sekmesindeyken (index 0) görünür
      final isWalletTab = currentIndex == 0;
      // Ekstra sekmesinde (index 2) standart AppBar gizlenir, sayfa içi modern geniş başlık kullanılır
      final isExtraTab = currentIndex == 2;

      return Scaffold(
        appBar: isExtraTab
            ? null
            : AppBar(
                title: Text(
                  controller.pageTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.lightTextPrimary,
                  ),
                ),
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
        body: IndexedStack(
          index: currentIndex,
          children: const [
            DashboardPage(), // Sekme 0: Cüzdan
            ReportsPage(), // Sekme 1: İstatistik
            ExtraView(), // Sekme 2: Ekstra
            ProfilePage(showAppBar: false), // Sekme 3: Profil
          ],
        ),
        // Sadece Cüzdan sekmesindeyken FAB görünür, doğrudan işlem ekleme sayfasını açar
        floatingActionButton: isWalletTab
            ? FloatingActionButton(
                onPressed: () => controller.goToTransaction(),
                backgroundColor: AppColors.primary, // Canlı mavi
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          itemCount: 4,
          tabBuilder: (int index, bool isActive) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final color = isActive
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark ? Colors.white54 : Colors.black45);

            const navItems = [
              (
                inactiveIcon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: "Cüzdan",
              ),
              (
                inactiveIcon: Icons.pie_chart_outline_rounded,
                activeIcon: Icons.pie_chart_rounded,
                label: "İstatistik",
              ),
              (
                inactiveIcon: Icons.widgets_outlined,
                activeIcon: Icons.widgets,
                label: "Ekstra",
              ),
              (
                inactiveIcon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: "Profil",
              ),
            ];
            final item = navItems[index];
            final icon = isActive ? item.activeIcon : item.inactiveIcon;

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
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
          gapLocation: GapLocation.none,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightBackground,
          activeIndex: currentIndex,
          splashColor: AppColors.primary,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          onTap: controller.changePage,
        ),
      );
    });
  }
}

// MainNavigationWrapper alias desteği
typedef MainNavigationWrapper = HomePage;
