import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  group('CurrencyHelper', () {
    test('parseInput Türkçe ve noktalı biçimleri çözer', () {
      expect(CurrencyHelper.parseInput('1.250,50'), 1250.5);
      expect(CurrencyHelper.parseInput('1250.50'), 1250.5);
      expect(CurrencyHelper.parseInput('34,25'), 34.25);
      expect(CurrencyHelper.parseInput(''), isNull);
    });

    test('toBase kuruşa yuvarlar', () {
      expect(CurrencyHelper.toBase(100, 34.257), 3425.7);
      expect(CurrencyHelper.toBase(50, 37.5), 1875.0);
    });

    test('fromCode bilinmeyen değerde veya eski altın kodunda TRY döner', () {
      expect(CurrencyHelper.fromCode(null), AppCurrency.tryCurrency);
      expect(CurrencyHelper.fromCode('usd'), AppCurrency.usd);
      expect(CurrencyHelper.fromCode('eur'), AppCurrency.eur);
      expect(CurrencyHelper.fromCode('gbp'), AppCurrency.gbp);
      expect(CurrencyHelper.fromCode('XAU'), AppCurrency.tryCurrency);
      expect(CurrencyHelper.fromCode('ABC'), AppCurrency.tryCurrency);
    });

    test('format sembol konumunu uygular', () {
      expect(CurrencyHelper.format(100, AppCurrency.usd), '100,00 \$');
      expect(CurrencyHelper.format(50, AppCurrency.eur), '50,00 €');
      expect(CurrencyHelper.format(20, AppCurrency.gbp), '20,00 £');
      expect(CurrencyHelper.format(150, AppCurrency.tryCurrency), '₺150,00');
    });
  });

  group('AppTransaction geriye dönük uyumluluk', () {
    test('para birimi alanı olmayan eski kayıt TRY olarak okunur', () {
      final tr = AppTransaction.fromJson({
        'id': '1',
        'amount': '250.0',
        'type': 'expense',
        'description': 'Market',
        'date': '2026-10-01T00:00:00.000',
      });
      expect(tr.currency, 'TRY');
      expect(tr.exchangeRate, 1.0);
      expect(tr.baseAmount, 250.0);
      expect(tr.originalAmountValue, 250.0);
      expect(tr.isForeignCurrency, isFalse);
    });

    test('döviz kaydı cache round-trip sonrası korunur', () {
      final tr = AppTransaction(
        id: '2',
        amount: '3400.0',
        type: 'expense',
        description: 'Kitap',
        date: '2026-10-01T00:00:00.000',
        userId: 'u',
        categoryId: 'c',
        createdAt: '',
        updatedAt: '',
        currency: 'USD',
        exchangeRate: 34.0,
        originalAmount: 100.0,
      );
      final restored = AppTransaction.fromJson(tr.toJson());
      expect(restored.currencyEnum, AppCurrency.usd);
      expect(restored.exchangeRate, 34.0);
      expect(restored.originalAmountValue, 100.0);
      expect(restored.baseAmount, 3400.0);
    });
  });
}
