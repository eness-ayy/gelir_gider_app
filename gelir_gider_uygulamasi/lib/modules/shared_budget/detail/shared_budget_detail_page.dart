import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/need_model.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/detail/shared_budget_detail_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/widgets/add_shared_expense_sheet.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Ortak Ev & Yurt Bütçesi & İhtiyaçlar Detay Ekranı
class SharedBudgetDetailPage extends GetView<SharedBudgetDetailController> {
  const SharedBudgetDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Obx(() {
          final groupName = controller.group.value?.name ?? "Ev / Yurt Odası";
          return Text(
            groupName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          );
        }),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: "Hesaplaşma & Bakiye Özeti",
            icon: const Icon(Icons.balance_rounded, size: 22),
            onPressed: () => _showSettlementSheet(context, isDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final group = controller.group.value;
          final isLoading = controller.isInitialLoading.value;

          if (isLoading && group == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (group == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    "Oda bilgisi bulunamadı.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text("Geri Dön"),
                  ),
                ],
              ),
            );
          }

          final activeTab = controller.selectedTabIndex.value;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. ÜST BİLGİ KARTI (Oda adı, kod, üye avatarları ve İhtiyaç Sayaç Rozeti)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _buildHeroCard(
                    context,
                    group,
                    isDark,
                    currencyFormatter,
                  ),
                ),
              ),

              // 2. SEKME DEĞİŞTİRİCİ (İhtiyaçlar & Ortak Harcamalar)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildTabSwitcher(context, isDark),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // 3. AKTİF SEKME İÇERİĞİ
              if (activeTab == 0) ...[
                // --- 1. SEKME: HARCAMALAR & KASA (ORTAK HARCAMALAR) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildExpenseOverviewCard(
                      context,
                      isDark,
                      currencyFormatter,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Ortak Ev Harcamaları",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${controller.expenses.length}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Sola kaydırarak sil",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                controller.expenses.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          child: _buildEmptyExpensesState(context, isDark),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final expense = controller.expenses[index];
                              return _buildExpenseCard(
                                context,
                                expense,
                                isDark,
                                currencyFormatter,
                              );
                            },
                            childCount: controller.expenses.length,
                          ),
                        ),
                      ),
              ] else ...[
                // --- 2. SEKME: İHTİYAÇLAR (ODAYA LAZIM) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Alınacak İhtiyaçlar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${controller.needs.length}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Sola kaydırarak sil",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Canlı İhtiyaç Listesi veya Boş Durum
                controller.needs.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                          child: _buildEmptyNeedsState(context, isDark),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final need = controller.needs[index];
                              return _buildNeedItemCard(context, need, isDark);
                            },
                            childCount: controller.needs.length,
                          ),
                        ),
                      ),
              ],
            ],
          );
        }),
      ),

      // Alt Kısım: İhtiyaçlar sekmesinde (activeTab == 1) Pratik Hızlı Giriş Çubuğu
      bottomNavigationBar: Obx(() {
        if (controller.selectedTabIndex.value == 1) {
          return _buildQuickAddBar(context, isDark);
        }
        return const SizedBox.shrink();
      }),

      // Floating Action Button
      floatingActionButton: Obx(() {
        final activeTab = controller.selectedTabIndex.value;
        if (activeTab == 0) {
          // Ortak Harcamalar sekmesinde Gider Ekle FAB
          return FloatingActionButton.extended(
            heroTag: "fab_add_expense",
            onPressed: () => AddSharedExpenseSheet.show(context),
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              "Gider Ekle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          );
        }
        // İhtiyaçlar sekmesinde sağ alttaki buton kaldırıldı, sadece alttaki giriş çubuğu var
        return const SizedBox.shrink();
      }),
    );
  }

  // ===========================================================================
  // 1. ÜST BİLGİ KARTI (Oda adı, kod, üyeler ve Eksik Sayaç Rozeti)
  // ===========================================================================
  Widget _buildHeroCard(
    BuildContext context,
    GroupModel group,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık & Davet Kodu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D9488).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cottage_rounded,
                          color: Color(0xFF0D9488),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => controller.copyInviteCode(group.inviteCode),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          border: Border.all(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Kod: ${group.inviteCode}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.copy_rounded,
                                size: 13, color: Color(0xFF0D9488)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => controller.shareInviteLink(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          border: Border.all(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.share_rounded,
                            size: 14, color: Color(0xFF0D9488)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Odadaki Arkadaşların Avatarları
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: group.members.length,
                separatorBuilder: (_, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final member = group.members[index];
                  final isMe = member.toLowerCase() ==
                      controller.currentUserName.toLowerCase();

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF0D9488).withValues(alpha: 0.16)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe
                            ? const Color(0xFF0D9488).withValues(alpha: 0.4)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: isMe
                              ? const Color(0xFF0D9488)
                              : (isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMe ? "$member (Sen)" : member,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.w500,
                            color: isMe
                                ? const Color(0xFF0D9488)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // BEKLEYEN / ALINACAK EKSİK SAYACI ROZETİ (Tıklanabilir - İhtiyaçlar sekmesine götürür)
            Obx(() {
              final pending = controller.pendingNeedsCount;
              final hasPending = pending > 0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.selectedTabIndex.value = 1,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: hasPending
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasPending
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                            : const Color(0xFF10B981).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: hasPending
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                : const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasPending
                                ? Icons.shopping_basket_rounded
                                : Icons.check_circle_rounded,
                            size: 16,
                            color: hasPending
                                ? const Color(0xFFD97706)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasPending
                                ? "$pending Eksik Bekliyor"
                                : "Odada hiçbir eksik yok, her şey tamam! 🎉",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasPending
                                  ? (isDark
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFB45309))
                                  : (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF047857)),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: hasPending
                              ? const Color(0xFFD97706).withValues(alpha: 0.7)
                              : const Color(0xFF10B981).withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. SEKME DEĞİŞTİRİCİ (Ortak Harcamalar vs Odaya Lazım - Yerleri değiştirildi)
  // ===========================================================================
  Widget _buildTabSwitcher(BuildContext context, bool isDark) {
    return Obx(() {
      final active = controller.selectedTabIndex.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 1. SOL SEKME: Ortak Harcamalar (index: 0)
            Expanded(
              child: InkWell(
                onTap: () => controller.selectedTabIndex.value = 0,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active == 0
                        ? (isDark
                            ? const Color(0xFF0D9488)
                            : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: active == 0
                            ? (isDark ? Colors.white : const Color(0xFF0D9488))
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Ortak Harcamalar",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: active == 0
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. SAĞ SEKME: Odaya Lazım (index: 1)
            Expanded(
              child: InkWell(
                onTap: () => controller.selectedTabIndex.value = 1,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active == 1
                        ? (isDark
                            ? const Color(0xFF0D9488)
                            : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 18,
                        color: active == 1
                            ? (isDark ? Colors.white : const Color(0xFF0D9488))
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Odaya Lazım",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: active == 1
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.grey,
                        ),
                      ),
                      if (controller.pendingNeedsCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: active == 1
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFF0D9488))
                                : const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${controller.pendingNeedsCount}",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 3. İHTİYAÇ ELEMANI KARTI (Checkbox, strikethrough, Dismissible)
  // ===========================================================================
  Widget _buildNeedItemCard(
    BuildContext context,
    NeedModel need,
    bool isDark,
  ) {
    final formattedDate =
        DateFormat('d MMMM, HH:mm', 'tr').format(need.createdAt);

    return Dismissible(
      key: Key(need.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              "Sil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => controller.deleteNeed(need.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: need.isCompleted ? 0.04 : 0.08)
                : Colors.black
                    .withValues(alpha: need.isCompleted ? 0.03 : 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.toggleNeed(need),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Checkbox Dairesi
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: need.isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: need.isCompleted
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white38 : Colors.grey.shade400),
                        width: 2,
                      ),
                    ),
                    child: need.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Başlık & Ekleyen Bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          need.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: need.isCompleted
                                ? FontWeight.normal
                                : FontWeight.bold,
                            decoration: need.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                            color: need.isCompleted
                                ? (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              "${need.addedBy} ekledi • $formattedDate",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                            if (need.isCompleted &&
                                need.completedBy != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                "• ${need.completedBy} aldı ✓",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. MODERN & ŞIK HIZLI GİRİŞ ÇUBUĞU (Ekranın Altı)
  // ===========================================================================
  Widget _buildQuickAddBar(BuildContext context, bool isDark) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = viewInsets > 0;
    final bottomPadding = isKeyboardOpen
        ? viewInsets + 8
        : (MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 14.0);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol İkon Rozeti
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 18,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),

            // Metin Giriş Alanı
            Expanded(
              child: TextField(
                controller: controller.quickNeedController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Odaya ne lazım? (örn: Deterjan, Su...)",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (val) => controller.addNeed(val),
              ),
            ),
            const SizedBox(width: 6),

            // Gönder Butonu
            Obx(() {
              final isAdding = controller.isAddingNeed.value;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isAdding ? null : () => controller.addNeed(),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0D9488).withValues(alpha: 0.38),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isAdding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. BOŞ DURUM TASARIMLARI
  // ===========================================================================
  Widget _buildEmptyNeedsState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text("🎉", style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Odada hiçbir eksik yok, her şey tamam! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Odaya veya eve bir şey lazım olduğunda hemen aşağıdan yazıp ekleyebilirsin.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExpensesState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 28,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Henüz Ortak Gider Yok",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Yapılan harcamaları 'Gider Ekle' butonuyla ortak kasaya ekleyin.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. HARCAMA ÖZETİ & LİSTESİ BİLEŞENLERİ
  // ===========================================================================
  Widget _buildExpenseOverviewCard(
    BuildContext context,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final netBalance = controller.userNetBalance;
    final isCreditor = netBalance > 0.01;
    final isDebtor = netBalance < -0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOPLAM EV HARCAMASI",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(controller.totalExpense),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showSettlementSheet(context, isDark),
                icon: const Icon(Icons.balance_rounded, size: 16),
                label: const Text("Hesaplaş", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  title: "Senin Ödediğin",
                  value: currencyFormatter.format(controller.userPaidTotal),
                  color: const Color(0xFF0D9488),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  title: "Kendi Payın",
                  value: currencyFormatter.format(controller.userShareTotal),
                  color: Colors.orange.shade700,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  title: "Net Durum",
                  value: isCreditor
                      ? "+${currencyFormatter.format(netBalance)}"
                      : isDebtor
                          ? currencyFormatter.format(netBalance)
                          : "0,00 ₺",
                  color: isCreditor
                      ? const Color(0xFF10B981)
                      : isDebtor
                          ? const Color(0xFFEF4444)
                          : Colors.grey,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel expense,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final formattedDate =
        DateFormat('d MMMM yyyy, HH:mm', 'tr').format(expense.date);
    final isPayerMe = expense.paidBy.toLowerCase() ==
        controller.currentUserName.toLowerCase();

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "Sil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await controller.confirmDeleteExpense(expense);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => AddSharedExpenseSheet.show(
            context,
            expenseToEdit: expense,
          ),
          onLongPress: () => controller.confirmDeleteExpense(expense),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPayerMe
                                ? "Sen ödedin"
                                : "${expense.paidBy} ödedi",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isPayerMe
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(expense.amount),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Kişi başı: ${currencyFormatter.format(expense.perPersonAmount)} (${expense.splitMembers.length} kişi)",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        if (expense.paymentMethod != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              PaymentMethod.fromKey(expense.paymentMethod).title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. HESAPLAŞMA / BAKİYE ÖZETİ MODALI
  // ===========================================================================
  void _showSettlementSheet(BuildContext context, bool isDark) {
    final members = controller.members;
    final currencyFormatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.balance_rounded,
                      color: Color(0xFF0D9488),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ev / Yurt Bakiye Özeti",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Kimin ne kadar alacağı veya borcu var?",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...members.map((member) {
                final paid = controller.expenses
                    .where((e) =>
                        e.paidBy.toLowerCase() == member.toLowerCase())
                    .fold<double>(0.0, (sum, e) => sum + e.amount);

                final share = controller.expenses
                    .where((e) => e.splitMembers
                        .any((m) => m.toLowerCase() == member.toLowerCase()))
                    .fold<double>(0.0, (sum, e) => sum + e.perPersonAmount);

                final balance = paid - share;
                final isPositive = balance > 0.01;
                final isNegative = balance < -0.01;
                final memberKey = member.trim().toLowerCase();

                return Obx(() {
                  final isSettled =
                      controller.paidSettlementMembers.contains(memberKey);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? (isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : const Color(0xFFECFDF5).withValues(alpha: 0.7))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSettled
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => controller.toggleSettlementPaid(memberKey),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: isSettled,
                                onChanged: (_) =>
                                    controller.toggleSettlementPaid(memberKey),
                                activeColor: const Color(0xFF10B981),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: isSettled
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400),
                                  width: 1.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Opacity(
                                opacity: isSettled ? 0.65 : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration: isSettled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Ödediği: ${currencyFormatter.format(paid)} | Payı: ${currencyFormatter.format(share)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isPositive
                                      ? "+${currencyFormatter.format(balance)}"
                                      : isNegative
                                          ? currencyFormatter.format(balance)
                                          : "0,00 ₺",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: isSettled
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isSettled
                                        ? const Color(0xFF10B981)
                                        : (isPositive
                                            ? const Color(0xFF10B981)
                                            : isNegative
                                                ? const Color(0xFFEF4444)
                                                : Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSettled
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.16)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isSettled ? "✓ Ödendi" : "Ödendi",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSettled
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600),
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
                });
              }),
            ],
          ),
        );
      },
    );
  }
}
