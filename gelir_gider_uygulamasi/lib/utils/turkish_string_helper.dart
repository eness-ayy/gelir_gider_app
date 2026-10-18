/// Türkçe karakter duyarlı ve aksan katlamalı (diacritic-insensitive) metin arama yardımcısı.
class TurkishStringHelper {
  TurkishStringHelper._();

  /// Türkçe karakterleri doğru şekilde küçük harfe çevirir.
  /// Dart varsayılan `toLowerCase()` fonksiyonunda:
  /// - 'İ' -> 'i\u0307' (birleşik noktalı i karakteri üretir ve standart 'i' ile eşleşmez)
  /// - 'I' -> 'i' (Türkçe'deki 'ı' yerine hatalı olarak 'i' yapar)
  /// Bu metot bu uyumsuzlukları giderir.
  static String toLowerCaseTr(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase()
        .replaceAll('\u0307', '');
  }

  /// Arama işlemleri için metni normalize eder:
  /// 1. Türkçe küçük harfe çevirir.
  /// 2. Türkçe aksanlı harfleri ASCII karşılıklarına eşler (ç->c, ğ->g, ı->i, ö->o, ş->s, ü->u).
  /// Bu sayede kullanıcı ister Türkçe karakterle ('maaş'), ister İngilizce klavye ile ('maas')
  /// arama yapsın, her iki durumda da doğru sonuç bulunur.
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return text;
    return toLowerCaseTr(text)
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  /// [target] metninin [query] sorgusunu içerip içermediğini kontrol eder.
  /// Hem doğrudan Türkçe küçük harf eşleşmesini hem de toleranslı (diacritic-folding) eşleşmeyi destekler.
  static bool containsSearch(String? target, String? query) {
    if (query == null || query.trim().isEmpty) return true;
    if (target == null || target.isEmpty) return false;

    final trimmedQuery = query.trim();

    // 1. Doğrudan Türkçe küçük harf kontrolü (örn: "maaş" içinde "maaş")
    final targetTr = toLowerCaseTr(target);
    final queryTr = toLowerCaseTr(trimmedQuery);
    if (targetTr.contains(queryTr)) return true;

    // 2. Normalleştirilmiş toleranslı kontrol (örn: "Maaş" içinde "maas", "İşlem" içinde "islem")
    final targetNorm = normalizeForSearch(target);
    final queryNorm = normalizeForSearch(trimmedQuery);
    return targetNorm.contains(queryNorm);
  }
}
