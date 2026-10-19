import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/dashboard_overview_carousel.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/search_filter_bar.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/summary_card.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/transaction_list.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(
        () => controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.refreshDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      // 1. Özet Kartları
                      SizedBox(
                        height: 105,
                        child: Obx(
                          () => ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            children: [
                              SummaryCard(
                                title: "${controller.periodTitle} Gelir",
                                amount: controller.filteredGelir,
                                icon: Icons.arrow_drop_up,
                                color: isDark
                                    ? Colors.green.shade500
                                    : Colors.green.shade200,
                                gradientColors: isDark
                                    ? AppColors.darkIncomeGradient
                                    : AppColors.incomeGradient,
                              ),
                              SummaryCard(
                                title: "${controller.periodTitle} Gider",
                                amount: controller.filteredGider,
                                icon: Icons.arrow_drop_down,
                                color: isDark
                                    ? Colors.red.shade500
                                    : Colors.red.shade200,
                                gradientColors: isDark
                                    ? AppColors.darkExpenseGradient
                                    : AppColors.expenseGradient,
                              ),
                              SummaryCard(
                                title: "${controller.periodTitle} Bakiye",
                                amount: controller.filteredBakiye,
                                icon: Icons.account_balance_wallet,
                                color: isDark
                                    ? AppColors.balanceDark
                                    : AppColors.balanceLight,
                                gradientColors: isDark
                                    ? AppColors.darkBalanceGradient
                                    : AppColors.balanceGradient,
                                isaretGosterilsinMi: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Cüzdan & Bütçe Takip Kartları (Sola Kaydırmalı / Carousel)
                      const DashboardOverviewCarousel(),

                      // 3. Arama ve Filtreleme Çubuğu
                      const SearchFilterBar(),

                      // 4. İşlem Listesi
                      const TransactionList(),

                      // 5. Alt Menü & FAB için boşluk (öğelerin altında kalmaması için)
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
