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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol hizalı büyük fintech başlık alanı & sağ üst köşe ikonları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ekstra\nAraçlar",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Gelişmiş finansal yönetim araçları",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.lightTextSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // B. Modül Kartları (ListTile / Card Yapısı)
              Column(
                children: [
                  // 1. Grup Harcamaları (Etkinlik & Arkadaşlar)
                  ExtraModuleCard(
                    icon: Icons.groups_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF2563EB), // Canlı Mavi
                    title: "Grup Harcamaları",
                    subtitle: "Arkadaşlarınızla etkinlik ve gezi harcamalarını bölüşün.",
                    onTap: controller.goToGroups,
                  ),

                  // 2. Ortak Hesap (Ev / Yurt Arkadaşları)
                  ExtraModuleCard(
                    icon: Icons.cottage_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF0D9488), // Canlı Teal
                    title: "Ortak Hesap",
                    subtitle:
                        "Ev ve yurt arkadaşlarınızla ortak kasa ve bütçe tutun.",
                    onTap: controller.goToSharedBudget,
                  ),

                  // 2. Birikim Hedefleri
                  ExtraModuleCard(
                    icon: Icons.savings_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF10B981), // Canlı Yeşil
                    title: "Birikim Hedefleri",
                    subtitle:
                        "Hedefler belirleyin, kumbara oluşturun ve ilerlemenizi izleyin.",
                    onTap: controller.goToSavingsGoals,
                  ),

                  // 3. Borç & Alacak Defteri
                  ExtraModuleCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFF97316), // Canlı Turuncu
                    title: "Borç & Alacak Defteri",
                    subtitle:
                        "Kime ne kadar borcunuz var, kimden ne alacağınız var takip edin.",
                    onTap: controller.goToDebts,
                  ),

                  // 4. Tekrarlayan Ödemeler
                  ExtraModuleCard(
                    icon: Icons.event_repeat_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFA855F7), // Canlı Mor
                    title: "Tekrarlayan Ödemeler",
                    subtitle:
                        "Kira, fatura ve abonelik periyotlarını otomatikleştirin.",
                    onTap: controller.goToRecurringTransactions,
                  ),

                  // 5. Kredi Kartları & Taksitler
                  Obx(
                    () => ExtraModuleCard(
                      icon: Icons.credit_card_rounded,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF4F46E5), // Koyu Mavi / İndigo
                      title: "Kredi Kartları & Taksitler",
                      subtitle:
                          "Hesap kesim tarihleri, kart limitleri ve taksit yükü takibi.",
                      badgeText: controller.creditCardBadgeText,
                      badgeTextColor: const Color(0xFF818CF8),
                      badgeBgColor:
                          const Color(0xFF6366F1).withValues(alpha: 0.15),
                      onTap: controller.goToCreditCards,
                    ),
                  ),
                ],
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
      ),
    );
  }
}

// Geriye dönük veya alternatif isimlendirme desteği
typedef ExtraPage = ExtraView;
