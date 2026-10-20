import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/widgets/extra_module_card.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class ExtraView extends GetView<ExtraController> {
  const ExtraView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller kayıtlı değilse güvenli oluştur
    if (!Get.isRegistered<ExtraController>()) {
      Get.put(ExtraController());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B. Modül Kartları (ListTile / Card Yapısı)
            Obx(
              () => Column(
                children: [
                  // 1. Gruplar & Ortak Harcamalar
                  ExtraModuleCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFF10B981), // Canlı Zümrüt Yeşili
                    iconBgColor: const Color(
                      0xFF10B981,
                    ).withValues(alpha: 0.16),
                    title: "Gruplar & Ortak Harcamalar",
                    subtitle:
                        "Arkadaşlarınızla ortak etkinlikleri, seyahatleri ve hesaplaşmaları bölün.",
                    badgeText: controller.groupBadgeText,
                    badgeTextColor: const Color(0xFF34D399),
                    badgeBgColor: const Color(
                      0xFF10B981,
                    ).withValues(alpha: 0.15),
                    onTap: controller.goToGroups,
                  ),

                  // 2. Birikim Hedefleri (Kumbara)
                  ExtraModuleCard(
                    icon: Icons.savings_outlined,
                    iconColor: const Color(0xFF3B82F6), // Mavi
                    iconBgColor: const Color(
                      0xFF3B82F6,
                    ).withValues(alpha: 0.16),
                    title: "Birikim Hedefleri",
                    subtitle:
                        "Hedefler belirleyin, kumbara oluşturun ve ilerlemenizi izleyin.",
                    badgeText: controller.savingsBadgeText,
                    badgeTextColor: const Color(0xFF60A5FA),
                    badgeBgColor: const Color(
                      0xFF3B82F6,
                    ).withValues(alpha: 0.15),
                    onTap: controller.goToSavingsGoals,
                  ),

                  // 2. Borç & Alacak Takibi
                  ExtraModuleCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFFF97316), // Turuncu
                    iconBgColor: const Color(
                      0xFFF97316,
                    ).withValues(alpha: 0.16),
                    title: "Borç & Alacak Defteri",
                    subtitle:
                        "Kime ne kadar borcunuz var, kimden ne alacağınız var takip edin.",
                    badgeText: controller.netDebtBadgeText,
                    badgeTextColor: controller.netDebtBalance >= 0
                        ? const Color(0xFF10B981) // Pozitif ise yeşil
                        : const Color(0xFFEF4444), // Negatif ise kırmızı
                    badgeBgColor: controller.netDebtBalance >= 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    onTap: controller.goToDebts,
                  ),

                  // 3. Tekrarlayan İşlemler & Abonelikler
                  ExtraModuleCard(
                    icon: Icons.event_repeat_rounded,
                    iconColor: const Color(0xFFA855F7), // Mor
                    iconBgColor: const Color(
                      0xFFA855F7,
                    ).withValues(alpha: 0.16),
                    title: "Tekrarlayan Ödemeler",
                    subtitle:
                        "Kira, fatura ve abonelik periyotlarını otomatikleştirin.",
                    badgeText: controller.recurringBadgeText,
                    badgeTextColor: const Color(0xFFC084FC),
                    badgeBgColor: const Color(
                      0xFFA855F7,
                    ).withValues(alpha: 0.15),
                    onTap: controller.goToRecurringTransactions,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bilgi & İpucu Kutusu (Premium Görünüm)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171717)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "İpucu: Düzenli harcamalarınızı tekrarlayan ödemelere bağlayarak bütçe tahminlerinizi otomatik hale getirebilirsiniz.",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Geriye dönük veya alternatif isimlendirme desteği
typedef ExtraPage = ExtraView;
