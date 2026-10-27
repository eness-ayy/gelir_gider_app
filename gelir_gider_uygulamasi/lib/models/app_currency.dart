import 'package:intl/intl.dart';

/// Uygulamada desteklenen para birimleri:
/// TRY (₺ - Varsayılan), USD ($), EUR (€), GBP (£).
enum AppCurrency {
  tryCurrency(
    code: 'TRY',
    symbol: '₺',
    name: 'Türk Lirası',
    decimalDigits: 2,
    symbolFirst: true,
  ),
  usd(
    code: 'USD',
    symbol: '\$',
    name: 'Amerikan Doları',
    decimalDigits: 2,
    symbolFirst: false,
  ),
  eur(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    decimalDigits: 2,
    symbolFirst: false,
  ),
  gbp(
    code: 'GBP',
    symbol: '£',
    name: 'İngiliz Sterlini',
    decimalDigits: 2,
    symbolFirst: false,
  );

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
    required this.symbolFirst,
  });

  /// ISO para birimi kodu (Firestore'a bu yazılır)
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;

  /// true: "₺1.250,00" | false: "1.250,00 $"
  final bool symbolFirst;

  bool get isBase => this == AppCurrency.tryCurrency;

  /// Seçicide gösterilecek kısa etiket
  String get shortLabel => code;
}

/// Para birimi ayrıştırma ve formatlama yardımcıları.
class CurrencyHelper {
  CurrencyHelper._();

  static const AppCurrency base = AppCurrency.tryCurrency;
  static const String baseCode = 'TRY';

  /// Koddan para birimi bulur. Bilinmeyen / boş veya eski değerler TRY'ye düşer.
  static AppCurrency fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return base;
    final c = code.trim().toUpperCase();
    return AppCurrency.values.firstWhere(
      (e) => e.code == c,
      orElse: () => base,
    );
  }

  /// Tutarı ilgili birimin kurallarına göre formatlar.
  /// Örn: TRY → "₺3.400,00", USD → "100,00 $", EUR → "50,00 €"
  static String format(
    double amount,
    AppCurrency currency, {
    int? decimalDigits,
  }) {
    final digits = decimalDigits ?? currency.decimalDigits;
    final number = NumberFormat.decimalPatternDigits(
      locale: 'tr_TR',
      decimalDigits: digits,
    ).format(amount);
    return currency.symbolFirst
        ? '${currency.symbol}$number'
        : '$number ${currency.symbol}';
  }

  /// Ana para biriminde (TRY) formatlama — uygulamadaki mevcut biçimle aynı.
  static String formatBase(double amount, {int decimalDigits = 2}) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: base.symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  /// Kullanıcı girdisini (virgül/nokta) güvenle double'a çevirir.
  /// "1.250,50" → 1250.5 | "1250.50" → 1250.5 | "34,2" → 34.2
  static double? parseInput(String? raw) {
    if (raw == null) return null;
    var text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (text.contains(',') && text.contains('.')) {
      // Türkçe biçim: nokta binlik, virgül ondalık
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '.');
    }
    return double.tryParse(text);
  }

  /// TRY karşılığını hesaplar (kuruşa yuvarlanmış).
  static double toBase(double originalAmount, double exchangeRate) {
    final result = originalAmount * exchangeRate;
    if (!result.isFinite) return 0.0;
    return (result * 100).roundToDouble() / 100;
  }
}
