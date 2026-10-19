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
        final hasGroups = groups.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. İkincil Başlık Satırı (AppBar'ın hemen altı)
            _buildSecondaryHeader(context, isDark, hasGroups, groups.length),

            // 2. İçerik Alanı: Boş Durum (Empty State) veya Dolu Durum (Kart Listesi)
            Expanded(
              child: hasGroups
                  ? _buildGroupList(context, isDark, groups)
                  : _buildEmptyState(context, isDark),
            ),
          ],
        );
      }),
    );
  }

  /// AppBar'ın altındaki ikincil başlık satırı
  Widget _buildSecondaryHeader(
    BuildContext context,
    bool isDark,
    bool hasGroups,
    int groupCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol Başlık: "Gruplarım (X)" veya liste boşken sade "Gruplarım (0)"
          Text(
            hasGroups ? "Gruplarım ($groupCount)" : "Gruplarım (0)",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),

          // Sağ Buton: Sadece en az 1 grup varken "+ Yeni Ekle" butonu görünür; liste boşken GİZLİ
          if (hasGroups)
            ElevatedButton.icon(
              onPressed: () => CreateGroupDialog.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.group_add_rounded, size: 16),
              label: const Text(
                "+ Yeni Ekle",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  /// 2. BOŞ DURUM (EMPTY STATE)
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Üstte: Hafif transparan gri/mavi yuvarlak zemin içinde büyük ikon
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: isDark ? 0.35 : 0.2),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.group_add_outlined,
                        size: 38,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Başlık (Label): Kalın ve beyaz/koyu
                  Text(
                    "İlk Grup Harcamanı Ekle",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Açıklama metni: Sönük gri renkte
                  Text(
                    "Arkadaşlarınla yaptığın etkinlikleri, tatil veya ev masraflarını bölüşmek için hemen başla.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buton: Dikkat çekici, canlı mavi, tam genişlikte "+ Grup Harcaması Oluştur"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => CreateGroupDialog.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        "Grup Harcaması Oluştur",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 3. DOLU DURUM (LİSTE VARKEN KART YAPISI)
  Widget _buildGroupList(
    BuildContext context,
    bool isDark,
    List<ExpenseGroup> groups,
  ) {
    return ListView.builder(
      // Sayfa içeriğinin altına en az 80px (100px) alt boşluk bırakılarak FAB çakışması önlenir
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(context, group, isDark);
      },
    );
  }

  /// Modern Grup Kartı
  Widget _buildGroupCard(
    BuildContext context,
    ExpenseGroup group,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);
    final netBalance = group.userNetBalance;

    Color badgeBgColor;
    Color badgeTextColor;
    String statusText;

    if (netBalance > 0.01) {
      badgeBgColor = isDark
          ? const Color(0xFF065F46).withValues(alpha: 0.35)
          : const Color(0xFFECFDF5);
      badgeTextColor = isDark
          ? const Color(0xFF34D399)
          : const Color(0xFF059669);
      statusText = "▲ +${currencyFormat.format(netBalance)} Alacaklısın";
    } else if (netBalance < -0.01) {
      badgeBgColor = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
          : const Color(0xFFFEF2F2);
      badgeTextColor = isDark
          ? const Color(0xFFF87171)
          : const Color(0xFFDC2626);
      statusText = "▼ -${currencyFormat.format(netBalance.abs())} Borçlusun";
    } else {
      badgeBgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade100;
      badgeTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
      statusText = "✓ Ödeşildi";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.6)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => controller.openGroupDetail(group),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Kısım: Mavi kare grup ikonu + Grup adı & Detay + 3 Nokta Menüsü
              Row(
                children: [
                  // Sol: Mavi kare içinde grup ikonu
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: isDark ? 0.35 : 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Orta: Grup Adı & X Katılımcı • X Harcama
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${group.participants.length} Katılımcı • ${group.expenses.length} Harcama",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sağ: 3 Nokta Menüsü
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: isDark ? AppColors.darkSurface : Colors.white,
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
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Grubu Sil",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // İnce Çizgi (Divider)
              Divider(
                height: 1,
                thickness: 0.8,
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                    : Colors.grey.shade200,
              ),
              const SizedBox(height: 12),

              // Alt Kısım: "Toplam Harcama" tutarı & Sağda yeşil/kırmızı net bakiye rozeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Toplam Harcama",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(group.totalExpense),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeTextColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                      ),
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
