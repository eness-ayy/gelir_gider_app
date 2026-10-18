import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/widgets/expense_donut_chart.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/widgets/financial_overview_card.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/widgets/income_expense_bar_chart.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/widgets/period_selector.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/widgets/top_categories_card.dart';
import 'package:get/get.dart';

class ReportsPage extends GetView<ReportsController> {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            children: const [
              // 1. Ay / Dönem Seçici
              PeriodSelector(),

              // 2. Net Bakiye ve Tasarruf Özeti Kartı
              FinancialOverviewCard(),

              // 3. Kategori Bazlı Gider Dağılımı Donut Grafiği
              ExpenseDonutChart(),

              // 4. En Çok Harcanan İlk 3 Kategori Özeti
              TopCategoriesCard(),

              // 5. Son 6 Ay Gelir vs Gider Çubuk Grafiği
              IncomeExpenseBarChart(),
            ],
          ),
        );
      }),
    );
  }
}
