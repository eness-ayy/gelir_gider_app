import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';

void main() {
  group('TurkishStringHelper Tests', () {
    test('toLowerCaseTr handles capital İ and I correctly', () {
      expect(TurkishStringHelper.toLowerCaseTr('İSTANBUL'), equals('istanbul'));
      expect(TurkishStringHelper.toLowerCaseTr('IRMAK'), equals('ırmak'));
      expect(TurkishStringHelper.toLowerCaseTr('ÖĞLE ÇİÇEK ŞEKER ÜZÜM'), equals('öğle çiçek şeker üzüm'));
    });

    test('normalizeForSearch strips diacritics', () {
      expect(TurkishStringHelper.normalizeForSearch('İşlem'), equals('islem'));
      expect(TurkishStringHelper.normalizeForSearch('Maaş'), equals('maas'));
      expect(TurkishStringHelper.normalizeForSearch('Öğle'), equals('ogle'));
      expect(TurkishStringHelper.normalizeForSearch('Çiçek'), equals('cicek'));
      expect(TurkishStringHelper.normalizeForSearch('Ilık'), equals('ilik'));
      expect(TurkishStringHelper.normalizeForSearch('Üzüm'), equals('uzum'));
      expect(TurkishStringHelper.normalizeForSearch('Şeker'), equals('seker'));
    });

    test('containsSearch matches with Turkish characters', () {
      expect(TurkishStringHelper.containsSearch('İnternet Faturası', 'internet'), isTrue);
      expect(TurkishStringHelper.containsSearch('İnternet Faturası', 'İnternet'), isTrue);
      expect(TurkishStringHelper.containsSearch('İnternet Faturası', 'İNTERNET'), isTrue);
      expect(TurkishStringHelper.containsSearch('Maaş Ödemesi', 'maaş'), isTrue);
      expect(TurkishStringHelper.containsSearch('Maaş Ödemesi', 'ödemesi'), isTrue);
      expect(TurkishStringHelper.containsSearch('Kahve & Tatlı', 'tatlı'), isTrue);
    });

    test('containsSearch matches without Turkish diacritics (tolerant typing)', () {
      // User types with english keyboard or quickly without accents
      expect(TurkishStringHelper.containsSearch('İnternet Faturası', 'faturasi'), isTrue);
      expect(TurkishStringHelper.containsSearch('Maaş Ödemesi', 'maas'), isTrue);
      expect(TurkishStringHelper.containsSearch('Maaş Ödemesi', 'odemesi'), isTrue);
      expect(TurkishStringHelper.containsSearch('Kahve & Tatlı', 'tatli'), isTrue);
      expect(TurkishStringHelper.containsSearch('Öğle Yemeği', 'ogle'), isTrue);
      expect(TurkishStringHelper.containsSearch('Öğle Yemeği', 'yemegi'), isTrue);
      expect(TurkishStringHelper.containsSearch('Çiçekçi', 'cicekci'), isTrue);
    });

    test('containsSearch returns true for empty query and false for empty target', () {
      expect(TurkishStringHelper.containsSearch('Maaş', ''), isTrue);
      expect(TurkishStringHelper.containsSearch('Maaş', '  '), isTrue);
      expect(TurkishStringHelper.containsSearch(null, 'test'), isFalse);
      expect(TurkishStringHelper.containsSearch('', 'test'), isFalse);
    });
  });
}
