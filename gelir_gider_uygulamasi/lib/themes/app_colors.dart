import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana Marka / Finans Renkleri
  static const Color primary = Color(0xFF1E88E5); // Modern Mavi
  static const Color secondary = Color(0xFF26A69A); // Turkuaz/Teal

  // Finans Özel Renkleri
  static const Color income = Color(0xFF2E7D32); // Gelir Yeşili
  static const Color expense = Color(0xFFD32F2F); // Gider Kırmızısı
  static const Color warning = Color(0xFFFFA000); // Uyarı Turuncusu

  // Açık Tema Nötr Renkler
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1C1B1F);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Koyu Tema Nötr Renkler
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE6E1E5);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF2C2C2C);

  static const Color balanceLight = Color(
    0xFF1976D2,
  ); // Açık tema için ana bakiye mavisi
  static const Color balanceDark = Color(
    0xFF64B5F6,
  ); // Koyu tema için yumuşak açık mavi

  // Gradient - Light
  static const List<Color> balanceGradient = [
    Color(0xFFB3E5FC),
    Color(0xFF81D4FA),
  ];

  // Gradient - Dark
  static const List<Color> darkBalanceGradient = [
    Color(0xFF0D3B66),
    Color(0xFF1D4E89),
  ];

  // Gradient Renkler - Light
  static const List<Color> incomeGradient = [
    Color(0xFFB4F8C8),
    Color(0xFFA0E6A9),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFFFAEBC),
    Color(0xFFFF8FA1),
  ];

  // Gradient Renkler - Dark (Koyu temaya uygun, göz almayan derin tonlar)
  static const List<Color> darkIncomeGradient = [
    Color(0xFF1B4332), // Derin orman yeşili
    Color(0xFF2D6A4F), // Canlı zümrüt tonu
  ];

  static const List<Color> darkExpenseGradient = [
    Color(0xFF591A24), // Derin bordo tonu
    Color(0xFF7F2633), // Yumuşak gül kırmızısı
  ];
}

class FinancialColors extends ThemeExtension<FinancialColors> {
  final Color? income;
  final Color? expense;
  final Color? warning;
  final List<Color>? incomeGradient;
  final List<Color>? expenseGradient;

  const FinancialColors({
    required this.income,
    required this.expense,
    required this.warning,
    this.incomeGradient,
    this.expenseGradient,
  });

  @override
  FinancialColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    List<Color>? incomeGradient,
    List<Color>? expenseGradient,
  }) {
    return FinancialColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      incomeGradient: incomeGradient ?? this.incomeGradient,
      expenseGradient: expenseGradient ?? this.expenseGradient,
    );
  }

  @override
  FinancialColors lerp(ThemeExtension<FinancialColors>? other, double t) {
    if (other is! FinancialColors) return this;
    return FinancialColors(
      income: Color.lerp(income, other.income, t),
      expense: Color.lerp(expense, other.expense, t),
      warning: Color.lerp(warning, other.warning, t),
      incomeGradient: t < 0.5 ? incomeGradient : other.incomeGradient,
      expenseGradient: t < 0.5 ? expenseGradient : other.expenseGradient,
    );
  }

  static const light = FinancialColors(
    income: AppColors.income,
    expense: AppColors.expense,
    warning: AppColors.warning,
    incomeGradient: AppColors.incomeGradient,
    expenseGradient: AppColors.expenseGradient,
  );

  static const dark = FinancialColors(
    income: Color(0xFF81C784), // Koyu temada göz yormayan açık yeşil
    expense: Color(0xFFE57373), // Koyu temada yumuşak kırmızı
    warning: Color(0xFFFFB74D),
    incomeGradient: AppColors.darkIncomeGradient,
    expenseGradient: AppColors.darkExpenseGradient,
  );
}
