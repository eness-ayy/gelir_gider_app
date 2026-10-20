import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_page.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_view.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_page.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _buildProfileAvatar(context),
            ),
          ),
        ],
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            DashboardPage(), // Sekme 0: Cüzdan
            ReportsPage(), // Sekme 1: İstatistik
            ExtraView(), // Sekme 2: Ekstra
            ProfilePage(showAppBar: false), // Sekme 3: Profil
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showAddActionSheet(context),
        backgroundColor: AppColors.primary, // Canlı mavi
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
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

  /// AppBar sağ üst köşesindeki yeşil zeminli baş harf avatarı ("E")
  Widget _buildProfileAvatar(BuildContext context) {
    return Tooltip(
      message: "Profil & Ayarlar",
      child: GestureDetector(
        onTap: () => controller.changePage(3),
        child: Obx(() {
          final authService = Get.isRegistered<AuthService>()
              ? Get.find<AuthService>()
              : null;
          final user = authService?.currentUser.value;
          final photoUrl = user?.profile_photo;

          final initial =
              (user?.first_name != null && user!.first_name!.trim().isNotEmpty)
                  ? user.first_name!.trim()[0].toUpperCase()
                  : 'E';

          return Container(
            width: 38,
            height: 38,
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipOval(
                    child: photoUrl.startsWith('assets/')
                        ? Image.asset(
                            photoUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Image.network(
                            photoUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  )
                : Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
          );
        }),
      ),
    );
  }
}

// MainNavigationWrapper alias desteği
typedef MainNavigationWrapper = HomePage;

