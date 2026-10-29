import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AccountBalancesCard extends GetView<DashboardController> {
  final EdgeInsetsGeometry? margin;

  const AccountBalancesCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final balances = controller.overallAccountBalances;
      final selectedFilter = controller.selectedAccountFilter.value;

      return Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 4, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Başlık & Filtre Durumu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Cüzdan & Hesap Bakiyeleri",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showTransferSheet(context, isDark),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Transfer / Borç Öde",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedFilter != 'all') ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.setAccountFilter('all'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Filtreyi Kaldır",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 3 Hesap Kartı (Nakit, Banka Kartı, Kredi Kartı)
              Row(
                children: [
                  // 1. Cebimdeki Nakit
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Nakit",
                      subtitle: "Eldeki Para",
                      amount: balances.cashBalance,
                      method: PaymentMethod.cash,
                      isSelected: selectedFilter == PaymentMethod.cash.key,
                      isDark: isDark,
                      onTap: () =>
                          controller.setAccountFilter(PaymentMethod.cash.key),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Bankadaki Param
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Banka",
                      subtitle: "Vadesiz Hesap",
                      amount: balances.bankBalance,
                      method: PaymentMethod.bankCard,
                      isSelected: selectedFilter == PaymentMethod.bankCard.key,
                      isDark: isDark,
                      onTap: () => controller.setAccountFilter(
                        PaymentMethod.bankCard.key,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Kredi Kartı
                  Expanded(
                    child: _buildAccountTile(
                      context: context,
                      title: "Kredi Kartı",
                      subtitle: "Harcamalar",
                      amount: balances.creditCardExpense,
                      method: PaymentMethod.creditCard,
                      isSelected:
                          selectedFilter == PaymentMethod.creditCard.key,
                      isDark: isDark,
                      isExpenseOnly: true,
                      onTap: () => controller.setAccountFilter(
                        PaymentMethod.creditCard.key,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Alt Bilgi: Toplam Hazır Para (Nakit + Banka)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Toplam Para:",
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat.currency(
                        symbol: '₺',
                        decimalDigits: 2,
                      ).format(balances.totalLiquidAssets),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: balances.totalLiquidAssets >= 0
                            ? (isDark
                                  ? Colors.greenAccent.shade200
                                  : AppColors.income)
                            : (isDark
                                  ? Colors.redAccent.shade100
                                  : AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required PaymentMethod method,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isExpenseOnly = false,
  }) {
    final methodColor = method.color;
    final formattedAmount = NumberFormat.currency(
      symbol: '₺',
      decimalDigits: 0,
    ).format(amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? methodColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? methodColor
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method.icon, size: 14, color: methodColor),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: methodColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedAmount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isExpenseOnly
                      ? (amount > 0
                            ? (isDark
                                  ? Colors.redAccent.shade100
                                  : Colors.red.shade700)
                            : methodColor)
                      : (amount >= 0
                            ? (isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary)
                            : (isDark
                                  ? Colors.redAccent.shade100
                                  : AppColors.expense)),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferSheet(BuildContext context, bool isDark) {
    final amountController = TextEditingController();
    int selectedPreset = 0;
    // Presets:
    // 0: Banka -> Nakit (ATM Para Çekme)
    // 1: Nakit -> Banka (Para Yatırma)
    // 2: Banka -> Kredi Kartı (Kart Borcu Ödeme)
    // 3: Nakit -> Kredi Kartı (Nakit Kart Borcu Ödeme)
    final presets = <({String label, String fromKey, String toKey, IconData icon})>[
      (
        label: "Banka ➔ Nakit (ATM Para Çekme)",
        fromKey: PaymentMethod.bankCard.key,
        toKey: PaymentMethod.cash.key,
        icon: Icons.local_atm_rounded,
      ),
      (
        label: "Nakit ➔ Banka (Hesaba Yatırma)",
        fromKey: PaymentMethod.cash.key,
        toKey: PaymentMethod.bankCard.key,
        icon: Icons.account_balance_rounded,
      ),
      (
        label: "Banka ➔ Kredi Kartı (Kart Borcu Öde)",
        fromKey: PaymentMethod.bankCard.key,
        toKey: PaymentMethod.creditCard.key,
        icon: Icons.credit_score_rounded,
      ),
      (
        label: "Nakit ➔ Kredi Kartı (Kart Borcu Öde)",
        fromKey: PaymentMethod.cash.key,
        toKey: PaymentMethod.creditCard.key,
        icon: Icons.payments_rounded,
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      "Hesaplar Arası Transfer & Kart Borcu Öde",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Aylık gelir/gider toplamınızı şişirmeden hesaplarınız arasında para aktarın veya kart borcunuzu kapatın.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(presets.length, (i) {
                      final p = presets[i];
                      final isSel = selectedPreset == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setModalState(() => selectedPreset = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                                width: isSel ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  p.icon,
                                  size: 20,
                                  color: isSel
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    p.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSel)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Transfer Tutarı (₺)",
                        hintText: "Örn: 1500",
                        prefixIcon: const Icon(Icons.currency_lira_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final raw = amountController.text
                              .replaceAll(',', '.')
                              .trim();
                          final amt = double.tryParse(raw) ?? 0.0;
                          if (amt <= 0) return;
                          final chosen = presets[selectedPreset];
                          Navigator.of(ctx).pop();
                          await controller.createAccountTransfer(
                            fromKey: chosen.fromKey,
                            toKey: chosen.toKey,
                            amount: amt,
                            title: chosen.label,
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text(
                          "Transferi Tamamla",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
