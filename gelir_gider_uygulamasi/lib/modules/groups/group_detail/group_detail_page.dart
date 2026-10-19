import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/widgets/add_group_expense_sheet.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class GroupDetailPage extends GetView<GroupDetailController> {
  const GroupDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(controller.group?.title ?? "Grup Detayı")),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: "Katılımcı Ekle",
              onPressed: () => _showAddParticipantDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.receipt_long_rounded, size: 20),
                text: "Harcamalar",
              ),
              Tab(
                icon: Icon(Icons.handshake_rounded, size: 20),
                text: "Hesaplaşma & Denge",
              ),
            ],
          ),
        ),
        body: Obx(() {
          final group = controller.group;
          if (group == null) {
            return const Center(child: Text("Grup bulunamadı"));
          }

          return Column(
            children: [
              // 1. Üst Özet Kartı (Grup Toplamı & Net Durum)
              _buildOverviewCard(context, group, isDark),

              // 2. Tab İçerikleri
              Expanded(
                child: TabBarView(
                  children: [
                    // Sekme 1: Harcamalar
                    _buildExpensesTab(context, group, isDark),

                    // Sekme 2: Hesaplaşma & Denge (Settle Up)
                    _buildSettlementsTab(context, group, isDark),
                  ],
                ),
              ),
            ],
          );
        }),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => AddGroupExpenseSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  "Grup Harcaması Ekle",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Üst Özet Kartı
  Widget _buildOverviewCard(
    BuildContext context,
    ExpenseGroup group,
    bool isDark,
  ) {
    final currencyFormat =
        NumberFormat.currency(symbol: "₺", decimalDigits: 2);
    final netBalance = group.userNetBalance;

    Color badgeColor;
    Color badgeTextColor;
    String statusTitle;
    String statusValue;

    if (netBalance > 0.01) {
      badgeColor = isDark
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : Colors.green.shade50;
      badgeTextColor = isDark ? Colors.greenAccent : Colors.green.shade800;
      statusTitle = "Gruptan Alacağın";
      statusValue = "+${currencyFormat.format(netBalance)}";
    } else if (netBalance < -0.01) {
      badgeColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50;
      badgeTextColor = isDark ? Colors.redAccent : Colors.red.shade800;
      statusTitle = "Gruba Borcun";
      statusValue = currencyFormat.format(netBalance.abs());
    } else {
      badgeColor = isDark
          ? Colors.grey.shade900
          : Colors.grey.shade100;
      badgeTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
      statusTitle = "Genel Durum";
      statusValue = "Ödeşildi (0.00 ₺)";
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol: Toplam Harcama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toplam Harcama",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(group.totalExpense),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${group.participants.length} Katılımcı",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 44,
            width: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          const SizedBox(width: 16),

          // Sağ: Kullanıcının Net Durumu
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusValue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Sekme 1: Harcamalar
  Widget _buildExpensesTab(
    BuildContext context,
    ExpenseGroup group,
    bool isDark,
  ) {
    final expenses = group.expenses;

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                "Henüz harcama eklenmedi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Aşağıdaki butona dokunarak grupta yapılan ilk harcamayı ekleyebilirsiniz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat =
        NumberFormat.currency(symbol: "₺", decimalDigits: 2);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final payer = group.findParticipant(exp.paidById);
        final payerName = payer?.displayName ?? "Bilinmeyen";
        final isMePayer = payer?.isCurrentUser ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // İkon Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Başlık & Kimin Ödediği
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${isMePayer ? 'Sen ödedin' : '$payerName ödedi'} • ${exp.splitParticipantIds.length} kişi bölüştü",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(exp.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tutar & Silme Menüsü
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(exp.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Kişi başı: ${currencyFormat.format(exp.perPersonAmount)}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _confirmDeleteExpense(context, exp);
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
                          Text("Harcamayı Sil",
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MARK: - Sekme 2: Hesaplaşma & Denge (Settle Up)
  Widget _buildSettlementsTab(
    BuildContext context,
    ExpenseGroup group,
    bool isDark,
  ) {
    final settlements = group.calculateSettlements();
    final currencyFormat =
        NumberFormat.currency(symbol: "₺", decimalDigits: 2);

    if (settlements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tüm Hesaplar Denge!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                "Gruptaki herkes ödeşmiş durumda. Hiçbir borç veya alacak kalmadı.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        // Bilgi Kartı
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "En az sayıda transfer ile borçların kapanması için otomatik sadeleştirilmiş hesaplaşma planı:",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Transfer Kartları
        ...settlements.map((settle) {
          final fromP = group.findParticipant(settle.fromParticipantId);
          final toP = group.findParticipant(settle.toParticipantId);

          final fromName = fromP?.displayName ?? "Bilinmeyen";
          final toName = toP?.displayName ?? "Bilinmeyen";

          final isMeFrom = fromP?.isCurrentUser ?? false;
          final isMeTo = toP?.isCurrentUser ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isMeFrom
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : (isMeTo
                        ? Colors.green.withValues(alpha: 0.4)
                        : (isDark ? Colors.white10 : Colors.grey.shade200)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Borçlu Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isMeFrom
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    child: Text(
                      fromP?.initial ?? '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMeFrom ? Colors.redAccent : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Borçlu Adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isMeFrom ? Colors.redAccent : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isMeFrom)
                          const Text(
                            "Sen ödemelisin",
                            style: TextStyle(fontSize: 10, color: Colors.redAccent),
                          ),
                      ],
                    ),
                  ),

                  // Ok ve Tutar Rozeti
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            currencyFormat.format(settle.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  // Alacaklı Adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          toName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isMeTo ? Colors.green : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isMeTo)
                          const Text(
                            "Sana ödenecek",
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Alacaklı Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isMeTo
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    child: Text(
                      toP?.initial ?? '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMeTo ? Colors.green : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddParticipantDialog(BuildContext context) {
    final textController = TextEditingController();
    Get.defaultDialog(
      title: "Katılımcı Ekle",
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Katılımcı adı",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      textConfirm: "Ekle",
      textCancel: "Vazgeç",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        final name = textController.text.trim();
        if (name.isNotEmpty) {
          Get.back();
          controller.addParticipant(name);
        }
      },
    );
  }

  void _confirmDeleteExpense(BuildContext context, GroupExpense expense) {
    Get.defaultDialog(
      title: "Harcamayı Sil",
      middleText:
          "\"${expense.title}\" harcamasını gruptan silmek istediğinize emin misiniz?",
      textConfirm: "Evet, Sil",
      textCancel: "Vazgeç",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back();
        controller.deleteExpense(expense.id);
      },
    );
  }
}
