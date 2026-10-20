import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/widgets/create_group_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class HomeController extends BaseController {
  final fabVisible = true.obs;
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (currentIndex.value == index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentIndex.value = index;
      // İstatistikler sekmesine geçildiğinde verileri güncelle
      if (index == 1 && Get.isRegistered<ReportsController>()) {
        Get.find<ReportsController>().loadData();
      }
      // Ekstra sekmesine geçildiğinde özetleri güncelle
      if (index == 2 && Get.isRegistered<ExtraController>()) {
        Get.find<ExtraController>().refreshSummaryData();
      }
    });
  }

  String get pageTitle {
    switch (currentIndex.value) {
      case 0:
        return "Cüzdan";
      case 1:
        return "İstatistik";
      case 2:
        return "Ekstra Araçlar";
      case 3:
        return "Profil & Ayarlar";
      default:
        return "Gelir Gider App";
    }
  }

  @override
  void onInit() {
    super.onInit();
    fabVisible.value = true;
  }

  Future<void> cikisYap() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  void goToTransaction() {
    Get.toNamed(AppRoutes.transaction, arguments: null);
  }

  void goToProfile() {
    changePage(3);
  }

  /// Ortadaki (+) butonuna basıldığında açılan seçim modalı:
  /// "Kişisel İşlem" ve "Grup Harcaması"
  void showAddActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Hızlı İşlem Ekle",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                "Eklemek istediğiniz işlem türünü seçin:",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Seçenek 1: Kişisel İşlem
              _buildActionTile(
                context: context,
                isDark: isDark,
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                title: "Kişisel İşlem",
                subtitle: "Kendi bütçenize ait gelir veya gider ekleyin",
                onTap: () {
                  Get.back();
                  goToTransaction();
                },
              ),
              const SizedBox(height: 10),

              // Seçenek 2: Grup Harcaması
              _buildActionTile(
                context: context,
                isDark: isDark,
                icon: Icons.diversity_3_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: "Grup Harcaması",
                subtitle:
                    "Arkadaşlarınızla ortak bir etkinlik / bölüşüm harcaması",
                onTap: () {
                  Get.back();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      _handleGroupExpenseSelection(context);
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Grup harcaması seçildiğinde grup varsa doğrudan ekleme formu veya grup seçimi,
  /// grup yoksa yeni grup oluşturma penceresi açar.
  void _handleGroupExpenseSelection(BuildContext context) {
    if (!Get.isRegistered<GroupService>()) return;
    final groupService = Get.find<GroupService>();

    if (groupService.groups.isEmpty) {
      CreateGroupDialog.show(context);
      return;
    }

    if (groupService.groups.length == 1) {
      final grp = groupService.groups.first;
      Get.toNamed(AppRoutes.groupDetail, arguments: grp.id);
      return;
    }

    // Birden fazla grup varsa hangi grup olduğunu sor
    _showGroupPickerSheet(context, groupService);
  }

  void _showGroupPickerSheet(
      BuildContext context, GroupService groupService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hangi Gruba Harcama Eklenecek?",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...groupService.groups.map((g) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.diversity_3,
                          color: AppColors.primary, size: 20),
                    ),
                    title: Text(g.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("${g.participants.length} katılımcı"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.groupDetail, arguments: g.id);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
