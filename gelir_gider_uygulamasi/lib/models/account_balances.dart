class AccountBalances {
  /// Cebimdeki Nakit Net Bakiye (Nakit Gelir - Nakit Gider)
  final double cashBalance;
  final double cashIncome;
  final double cashExpense;

  /// Bankadaki Param Net Bakiye (Banka Gelir - Banka Gider)
  final double bankBalance;
  final double bankIncome;
  final double bankExpense;

  /// Kredi Kartı Toplam Harcaması / Borcu
  final double creditCardExpense;
  final double creditCardIncome;

  /// Toplam Hazır / Likit Varlık (Cepteki Nakit + Bankadaki Para)
  final double totalLiquidAssets;

  const AccountBalances({
    required this.cashBalance,
    required this.cashIncome,
    required this.cashExpense,
    required this.bankBalance,
    required this.bankIncome,
    required this.bankExpense,
    required this.creditCardExpense,
    this.creditCardIncome = 0.0,
    required this.totalLiquidAssets,
  });

  static const empty = AccountBalances(
    cashBalance: 0.0,
    cashIncome: 0.0,
    cashExpense: 0.0,
    bankBalance: 0.0,
    bankIncome: 0.0,
    bankExpense: 0.0,
    creditCardExpense: 0.0,
    creditCardIncome: 0.0,
    totalLiquidAssets: 0.0,
  );
}
