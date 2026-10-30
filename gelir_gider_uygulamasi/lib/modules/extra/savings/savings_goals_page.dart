import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/savings_goal.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/savings/widgets/add_savings_goal_sheet.dart';
import 'package:gelir_gider_uygulamasi/services/savings_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SavingsGoalsPage extends StatelessWidget {
  const SavingsGoalsPage({super.key});

  SavingsService get service => Get.find<SavingsService>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Birikim Hedefleri",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSavingsGoalSheet.show(context),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Yeni Hedef Ekle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final goals = service.goals;
        final totalSaved = service.totalSavedAmount;
        final totalTarget = service.totalTargetAmount;
        final overallProgress =
            totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Toplam Birikim",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${goals.length} Kumbara",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormatter.format(totalSaved),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hedef: ${currencyFormatter.format(totalTarget)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "%${(overallProgress * 100).toStringAsFixed(1)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Hedefleriniz & Kumbaralar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (goals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Henüz birikim hedefi eklenmemiş",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Aşağıdaki butona basarak ilk kumbaranızı oluşturun!",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalCard(
                      context,
                      goal,
                      isDark,
                      currencyFormatter,
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    SavingsGoal goal,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final progress = goal.progress;
    final goalColor = Color(goal.colorValue ?? 0xFF3B82F6);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: goalColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (goal.category != null && goal.category!.isNotEmpty)
                      Text(
                        goal.category!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    AddSavingsGoalSheet.show(context, goalToEdit: goal);
                  } else if (val == 'delete') {
                    service.deleteGoal(goal.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("Düzenle"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("Sil", style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${currencyFormatter.format(goal.savedAmount)} / ${currencyFormatter.format(goal.targetAmount)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "%${(progress * 100).toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: goalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0
                    ? const Color(0xFF10B981)
                    : goalColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (goal.targetDate != null)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(goal.targetDate!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              if (goal.savedAmount > 0) ...[
                OutlinedButton.icon(
                  onPressed: () => _showMoneyActionDialog(
                    context,
                    goal,
                    isDeposit: false,
                  ),
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  label: const Text("Para Çek"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade700),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _showMoneyActionDialog(
                  context,
                  goal,
                  isDeposit: true,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Para Ekle"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: goalColor,
                  side: BorderSide(color: goalColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoneyActionDialog(
    BuildContext context,
    SavingsGoal goal, {
    required bool isDeposit,
  }) {
    final controller = TextEditingController();
    String selectedPaymentMethod = 'cash';
    final goalColor = Color(goal.colorValue ?? 0xFF3B82F6);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              isDeposit
                  ? "${goal.title} Kumbarasına Para Ekle"
                  : "${goal.title} Kumbarasından Para Çek",
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isDeposit
                        ? "Eklenecek Tutar (₺)"
                        : "Çekilecek Tutar (₺)",
                    hintText: "Örn: 500",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isDeposit
                      ? "Hangi hesaptan aktarılsın?"
                      : "Hangi hesaba aktarılsın?",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Nakit"),
                        selected: selectedPaymentMethod == 'cash',
                        onSelected: (_) {
                          setState(() => selectedPaymentMethod = 'cash');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Banka Kartı"),
                        selected: selectedPaymentMethod == 'bank_card',
                        onSelected: (_) {
                          setState(() => selectedPaymentMethod = 'bank_card');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(
                    controller.text.replaceAll(',', '.').trim(),
                  );
                  if (val != null && val > 0) {
                    if (isDeposit) {
                      service.depositMoney(
                        goal.id,
                        val,
                        paymentMethod: selectedPaymentMethod,
                      );
                    } else {
                      service.withdrawMoney(
                        goal.id,
                        val,
                        paymentMethod: selectedPaymentMethod,
                      );
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDeposit
                      ? goalColor
                      : Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text(isDeposit ? "Ekle" : "Çek"),
              ),
            ],
          );
        },
      ),
    );
  }

}
