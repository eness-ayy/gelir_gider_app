import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/widgets/create_group_dialog.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class GroupsPage extends GetView<GroupsController> {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        final groups = controller.groups;

        if (groups.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _buildGroupCard(context, group, isDark);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.diversity_3_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Henüz bir grup yok",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              "Arkadaşlarınızla tatil, ev masrafı veya etkinlik harcamalarını bölüşmek için hemen ilk grubunuzu oluşturun.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => CreateGroupDialog.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Yeni Grup Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    ExpenseGroup group,
    bool isDark,
  ) {
    final currencyFormat =
        NumberFormat.currency(symbol: "₺", decimalDigits: 2);
    final netBalance = group.userNetBalance;

    Color badgeColor;
    Color badgeTextColor;
    String statusText;

    if (netBalance > 0.01) {
      badgeColor = isDark
          ? Colors.green.shade900.withValues(alpha: 0.4)
          : Colors.green.shade50;
      badgeTextColor = isDark ? Colors.greenAccent : Colors.green.shade800;
      statusText = "+${currencyFormat.format(netBalance)} Alacaksın";
    } else if (netBalance < -0.01) {
      badgeColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.4)
          : Colors.red.shade50;
      badgeTextColor = isDark ? Colors.redAccent : Colors.red.shade800;
      statusText = "${currencyFormat.format(netBalance.abs())} Borçlusun";
    } else {
      badgeColor = isDark
          ? Colors.grey.shade900
          : Colors.grey.shade100;
      badgeTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
      statusText = "Ödeşildi";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      elevation: isDark ? 2 : 1,
      child: InkWell(
        onTap: () => controller.openGroupDetail(group),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: İkon + Grup Başlığı + Silme Menüsü
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                            : [const Color(0xFF93C5FD), const Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${group.participants.length} Katılımcı • ${group.expenses.length} Harcama",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white54 : Colors.grey,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteGroup(context, group);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text("Grubu Sil",
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Alt Satır: Toplam Harcama & Kullanıcının Net Durumu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Toplam Harcama",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(group.totalExpense),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          netBalance > 0.01
                              ? Icons.arrow_upward_rounded
                              : (netBalance < -0.01
                                  ? Icons.arrow_downward_rounded
                                  : Icons.check_circle_outline_rounded),
                          size: 14,
                          color: badgeTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, ExpenseGroup group) {
    Get.defaultDialog(
      title: "Grubu Sil",
      middleText:
          "\"${group.title}\" grubunu ve içindeki harcamaları silmek istediğinize emin misiniz?",
      textConfirm: "Evet, Sil",
      textCancel: "Vazgeç",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back();
        controller.deleteGroup(group.id);
      },
    );
  }
}
