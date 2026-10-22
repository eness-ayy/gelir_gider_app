import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/shared_budget_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/widgets/shared_budget_card.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:get/get.dart';

/// Ortak Ev & Yurt Bütçesi Ana / Lobi Sayfası
class SharedBudgetPage extends GetView<SharedBudgetController> {
  const SharedBudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SharedBudgetController>()
        ? Get.find<SharedBudgetController>()
        : Get.put(SharedBudgetController());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Navigator.canPop(context)
                ? Icons.arrow_back_ios_new_rounded
                : Icons.home_rounded,
            size: 22,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed(AppRoutes.home);
            }
          },
          tooltip: Navigator.canPop(context) ? "Geri" : "Ana Sayfa",
        ),
        title: const Text(
          "Ortak Ev & Yurt Bütçesi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.userSession.refreshGroups();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Üst Karşılama Alanı
                _buildHeader(context, controller, isDark),
                const SizedBox(height: 20),

                // 2. Hızlı İşlem Kartları (Oda Kur & Koda Göre Katıl)
                _buildActionCards(context, controller, isDark),
                const SizedBox(height: 26),

                // 3. Odalarım Başlığı
                _buildSectionHeader(controller, isDark),
                const SizedBox(height: 14),

                // 4. Liste veya Boş Durum
                Obx(() {
                  final groups = controller.userGroups;
                  if (groups.isEmpty) {
                    return _buildEmptyState(context, controller, isDark);
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return SharedBudgetCard(
                        group: group,
                        onTap: () => controller.openGroupDetail(group),
                        onCopyCode: () =>
                            controller.copyInviteCode(group.inviteCode),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SharedBudgetController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // Avatar
          Obx(() {
            final name = controller.currentUserName;
            final initial =
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 14),

          // Kullanıcı İsmi
          Expanded(
            child: Obx(() {
              final name = controller.currentUserName;
              return Text(
                name.isNotEmpty ? name : "Ev Arkadaşı",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),

          // Kalem / Düzenle Butonu
          InkWell(
            onTap: () => controller.showNicknameSheet(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(
    BuildContext context,
    SharedBudgetController controller,
    bool isDark,
  ) {
    return Row(
      children: [
        // 1. Yeni Ev / Yurt Odası Kur
        Expanded(
          child: _ActionButton(
            title: "Yeni Ev / Oda\nKur",
            subtitle: "Ortak kasa aç",
            icon: Icons.cottage_rounded,
            gradientColors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
            onTap: () => controller.showCreateHouseSheet(),
          ),
        ),
        const SizedBox(width: 14),

        // 2. Koda Göre Katıl
        Expanded(
          child: _ActionButton(
            title: "Koda Göre\nKatıl",
            subtitle: "6 haneli odaya gir",
            icon: Icons.vpn_key_rounded,
            gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            onTap: () => controller.showJoinHouseSheet(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      SharedBudgetController controller, bool isDark) {
    return Obx(() {
      final count = controller.userGroups.length;
      return Row(
        children: [
          Text(
            "Kayıtlı Ev & Yurt Odaların",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(
    BuildContext context,
    SharedBudgetController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cottage_outlined,
              size: 40,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Henüz bir ortak evin/yurdun yok",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Kira, fatura, mutfak ve market masraflarını canlı bölüşmek için bir oda kur ya da arkadaşından aldığın kodla katıl.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => controller.showCreateHouseSheet(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              "+ İlk Odanı Kur",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
