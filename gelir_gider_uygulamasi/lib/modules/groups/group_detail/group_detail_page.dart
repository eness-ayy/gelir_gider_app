import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_settlement.dart';
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
            Obx(() {
              final code = controller.group?.effectiveInviteCode ?? '';
              if (code.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Grup davet kodu ($code) kopyalandı!"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }),
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
                text: "Hesaplaşma",
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
    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);
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
      badgeColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
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

    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

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
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => AddGroupExpenseSheet.show(context, expenseToEdit: exp),
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

                  // Tutar & Silme / Düzenleme Menüsü
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
                      if (val == 'edit') {
                        AddGroupExpenseSheet.show(context, expenseToEdit: exp);
                      } else if (val == 'delete') {
                        _confirmDeleteExpense(context, exp);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text("Harcamayı Düzenle"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Harcamayı Sil",
                              style: TextStyle(color: Colors.redAccent),
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
    final currencyFormat = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

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

    final paidCount = settlements.where((s) => s.isPaid).length;
    final allPaid = paidCount == settlements.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        // Bilgi ve Ödeme Durumu Kartı
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: allPaid
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allPaid
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                allPaid
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_rounded,
                color: allPaid ? const Color(0xFF10B981) : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allPaid
                      ? "Gruptaki tüm ödemeler tamamlandı! Herkes ödeşti."
                      : "Ödeme yapan kişilerin yanındaki 'Ödendi' kutucuğunu işaretleyerek takibi kolayca yapabilirsiniz:",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: allPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$paidCount / ${settlements.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: allPaid
                        ? const Color(0xFF10B981)
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transfer Kartları
        ...settlements.map((settle) => _buildSettlementCard(
              context: context,
              settle: settle,
              group: group,
              isDark: isDark,
              currencyFormat: currencyFormat,
            )),
      ],
    );
  }

  /// Sade, modern ve kafa karışıklığını sıfıra indiren Hesaplaşma/Transfer Kartı
  Widget _buildSettlementCard({
    required BuildContext context,
    required GroupSettlement settle,
    required ExpenseGroup group,
    required bool isDark,
    required NumberFormat currencyFormat,
  }) {
    final fromP = group.findParticipant(settle.fromParticipantId);
    final toP = group.findParticipant(settle.toParticipantId);

    final fromName = fromP?.displayName ?? "Bilinmeyen";
    final toName = toP?.displayName ?? "Bilinmeyen";

    final isMeFrom = fromP?.isCurrentUser ?? false;
    final isMeTo = toP?.isCurrentUser ?? false;
    final isPaid = settle.isPaid;

    // Durum ve tema renkleri
    final Color accentColor;
    final String amountText;

    if (isPaid) {
      accentColor = const Color(0xFF10B981);
      amountText = isMeTo
          ? "+${currencyFormat.format(settle.amount)}"
          : (isMeFrom
              ? "-${currencyFormat.format(settle.amount)}"
              : currencyFormat.format(settle.amount));
    } else if (isMeTo) {
      // 1. Kullanıcı alacaklı (Örn: Faruk bana ödeyecek)
      accentColor = const Color(0xFF10B981); // Zümrüt yeşili
      amountText = "+${currencyFormat.format(settle.amount)}";
    } else if (isMeFrom) {
      // 2. Kullanıcı borçlu (Örn: Ben Faruk'a ödeyeceğim)
      accentColor = const Color(0xFFEF4444); // Canlı kırmızı
      amountText = "-${currencyFormat.format(settle.amount)}";
    } else {
      // 3. Diğer iki katılımcı arası transfer
      accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB); // Canlı mavi
      amountText = currencyFormat.format(settle.amount);
    }

    final Color cardBorderColor = isPaid
        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.5 : 0.4)
        : (isMeTo
            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3)
            : (isMeFrom
                ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.4 : 0.3)
                : (isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : Colors.grey.shade200)));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: isPaid
          ? (isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : const Color(0xFFECFDF5).withValues(alpha: 0.6))
          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorderColor, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.toggleSettlementPaid(settle),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Ödendi Checkbox
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: isPaid,
                  onChanged: (_) => controller.toggleSettlementPaid(settle),
                  activeColor: const Color(0xFF10B981),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white38 : Colors.grey.shade400),
                    width: 1.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),

              // Transfer Akışı (Borçlu ──► Alacaklı)
              Expanded(
                child: Opacity(
                  opacity: isPaid ? 0.65 : 1.0,
                  child: Row(
                    children: [
                      // Borçlu (Ödeyen) Avatarı
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: isMeFrom
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : (isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200),
                        child: Text(
                          fromP?.initial ?? '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMeFrom
                                ? const Color(0xFFEF4444)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Borçlu Adı
                      Flexible(
                        child: Text(
                          fromName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration:
                                isPaid ? TextDecoration.lineThrough : null,
                            color: isMeFrom
                                ? const Color(0xFFEF4444)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Yön Oku
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF262626)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ),

                      // Alacaklı (Alan) Avatarı
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: isMeTo
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : (isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200),
                        child: Text(
                          toP?.initial ?? '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMeTo
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Alacaklı Adı
                      Flexible(
                        child: Text(
                          toName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration:
                                isPaid ? TextDecoration.lineThrough : null,
                            color: isMeTo
                                ? const Color(0xFF10B981)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Tutar ve Ödendi Rozeti
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFF10B981).withValues(alpha: 0.16)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPaid ? "✓ Ödendi" : "Ödendi",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPaid
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
