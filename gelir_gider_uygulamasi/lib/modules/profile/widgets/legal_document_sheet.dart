import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

enum LegalDocumentType {
  terms,
  privacy,
}

/// Uygulama içi Kullanım Koşulları ve Gizlilik Politikası Modal Bottom Sheet'i
class LegalDocumentSheet extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentSheet({
    super.key,
    required this.type,
  });

  static Future<void> showTerms(BuildContext context) {
    return show(context, type: LegalDocumentType.terms);
  }

  static Future<void> showPrivacy(BuildContext context) {
    return show(context, type: LegalDocumentType.privacy);
  }

  static Future<void> show(
    BuildContext context, {
    required LegalDocumentType type,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentSheet(type: type),
    );
  }

  bool get _isTerms => type == LegalDocumentType.terms;

  String get _title => _isTerms ? "Kullanım Koşulları" : "Gizlilik Politikası";

  IconData get _icon =>
      _isTerms ? Icons.description_outlined : Icons.privacy_tip_outlined;

  Color get _accentColor =>
      _isTerms ? const Color(0xFF0284C7) : const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sürükleme Çubuğu (Drag Handle)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Başlık Alanı ve Kapatma Butonu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _icon,
                    color: _accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Son Güncelleme: 30 Ekim 2026",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: "Kapat",
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),

          // Kaydırılabilir İçerik Alanı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: _isTerms
                  ? _buildTermsContent(isDark)
                  : _buildPrivacyContent(isDark),
            ),
          ),

          // Alt Kapatma / Kabul Butonu
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Anladım",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kullanım Koşulları Maddeleri
  Widget _buildTermsContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntroText(
          "Lütfen Hesaply mobil uygulamasını kullanmadan önce işbu Kullanım Koşullarını dikkatlice okuyunuz. Uygulamayı indirerek, misafir veya kayıtlı hesap oluşturarak ya da kullanarak aşağıdaki tüm şartları kabul etmiş sayılırsınız.",
          isDark,
        ),
        const SizedBox(height: 16),
        _buildArticleItem(
          number: "1",
          title: "Hizmetin Kapsamı ve Özellikleri",
          body:
              "Hesaply; kullanıcıların kişisel gelir ve giderlerini (Nakit, Banka Kartı, Kredi Kartı ve Döviz/Altın cinsinden) kaydetmelerini, kredi kartı ekstre/taksit takibi yapmalarını, sabit ödemelerini (kira, fatura, abonelik), birikim kumbaralarını ve borç/alacaklarını yönetmelerini, davet kodu ile ortak grup/ev bütçesi paylaşmalarını ve PDF finansal raporları oluşturmalarını sağlayan kapsamlı bir kişisel finans asistanıdır.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "2",
          title: "Finansal Tavsiye ve Bankacılık Sorumluluk Reddi",
          body:
              "Hesaply bir banka, ödeme kuruluşu, elektronik para şirketi veya yatırım danışmanlığı kurumu değildir. Uygulama üzerinden gerçek para transferi (EFT/Havale) veya kredi kartı tahsilatı yapılmaz; 'Transfer / Borç Öde', 'Taksit Öde' ve 'Ödendi' butonları yalnızca kullanıcının kendi kişisel kayıtlarını ve hesap bakiyelerini senkronize etmek içindir. Döviz ve altın kurları bilgilendirme amaçlı olup anlık piyasa farklılıklarından veya kullanıcıların mali kararlarından doğabilecek zararlardan geliştirici sorumlu tutulamaz.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "3",
          title: "Üyelik, Misafir Kullanımı ve Hesap Güvenliği",
          body:
              "Uygulamayı E-posta/Şifre, Google Hesabı veya Misafir (Anonim) modda kullanabilirsiniz. Misafir kullanıcılar cihaz sıfırlandığında veya uygulama silindiğinde veri kaybı yaşamamak için Profil ekranından hesaplarını Google veya E-posta ile kalıcı hesaba bağlamalıdır. Hesap şifresinin ve ortak grup davet kodlarının güvenliğinden kullanıcı bizzat sorumludur.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "4",
          title: "Ortak Bütçe ve Grup Harcamaları Kuralları",
          body:
              "6 haneli davet kodu ile oluşturulan veya katılınan Ortak Ev/Yurt Bütçesi ve Grup Harcamaları modüllerinde; gruba eklenen harcama başlıkları, tutarlar, ihtiyaç listesi maddeleri ve katılımcı adları o grubun diğer üyeleri tarafından görüntülenebilir. Kullanıcılar ortak gruplarda yanıltıcı, hukuka aykırı veya üçüncü kişilerin haklarını ihlal eden içerikler paylaşmamayı kabul eder.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "5",
          title: "Kabul Edilebilir Kullanım ve Hizmet Bütünlüğü",
          body:
              "Kullanıcılar uygulamayı yalnızca yasal ve kişisel bütçe yönetimi amacıyla kullanmayı; uygulamanın bulut veritabanı (Firebase) ve API servislerini suistimal edecek otomatik bot, tersine mühendislik veya yetkisiz erişim girişimlerinde bulunmamayı taahhüt eder. Güvenliği tehlikeye atan hesaplar askıya alınabilir.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "6",
          title: "Fikri Mülkiyet Hakları",
          body:
              "Hesaply uygulamasının adı, arayüz tasarımları, grafik bileşenleri, kaynak kodları ve özgün içerikleri geliştiriciye aittir. Geliştiricinin yazılı izni olmaksızın kopyalanamaz, değiştirilemez veya ticari amaçla çoğaltılamaz.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "7",
          title: "Veri Sıfırlama, Hesap Silme ve Değişiklikler",
          body:
              "Kullanıcı dilediği zaman Profil menüsünden 'Verileri Sıfırla' seçeneğiyle tüm finansal kayıtlarını temizleyebilir veya 'Hesabı Sil' seçeneğiyle hesabını kalıcı olarak kapatabilir. Geliştirici, uygulama özelliklerini ve kullanım koşullarını güncelleme hakkını saklı tutar.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "8",
          title: "İletişim ve Destek",
          body:
              "Kullanım Koşulları ile ilgili her türlü soru, görüş ve teknik destek talebiniz için uygulama içi 'Geri Bildirim & İletişim' formundan veya aşağıdaki e-posta adresinden bize ulaşabilirsiniz.\n\nE-posta: ensayy63@gmail.com\n\nHesaply Mobil Uygulaması • Resmi Kullanım Sözleşmesi",
          isDark: isDark,
        ),
      ],
    );
  }

  /// Gizlilik Politikası Maddeleri
  Widget _buildPrivacyContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntroText(
          "Hesaply olarak kişisel ve finansal verilerinizin gizliliğini en üst düzeyde koruyoruz. İşbu Gizlilik Politikası, 6698 sayılı KVKK, GDPR ve Google Play / App Store veri güvenliği standartları uyarınca uygulamamızda hangi verilerin toplandığını, nerede kullanıldığını ve nasıl korunduğunu şeffaf biçimde açıklar.",
          isDark,
        ),
        const SizedBox(height: 16),
        _buildArticleItem(
          number: "1",
          title: "Toplanan Veriler ve Kapsamı",
          body:
              "Hesaply yalnızca uygulamanın işlevlerini sunabilmek için doğrudan sizin girdiğiniz aşağıdaki verileri işler:\n\n"
              "• Kimlik ve Profil Bilgileri: Kayıt veya Google ile giriş sırasında alınan Ad, Soyad, E-posta adresi, kullanıcı kimliği (UID) ve uygulama içinden seçilen profil avatarı/fotoğrafı.\n\n"
              "• Gelir, Gider ve Bütçe Kayıtları: Eklediğiniz gelir/gider tutarları, döviz/altın cinsi (TRY, USD, EUR, GBP, GAU), işlem tarihi, açıklaması, özel kategorileriniz, aylık kategori harcama limitleriniz ve ödeme yöntemi (Nakit, Banka Kartı, Kredi Kartı) tercihleriniz.\n\n"
              "• Kredi Kartı, Taksit, Borç, Kumbara ve Sabit Ödemeler: Ekstra modüllerde takip amaçlı girdiğiniz kart adı, banka adı, kart limiti, kesim/son ödeme günü, isteğe bağlı kartın yalnızca son 4 hanesi, taksit planları, borç/alacak kayıtları, birikim hedefleri ve fatura/abonelik hatırlatmaları. (ÖNEMLİ: Uygulamamızda 16 haneli tam kredi kartı numarası, CVV/CVC güvenlik kodu, IBAN veya internet bankacılığı şifresi KESİNLİKLE talep edilmez ve saklanmaz.)\n\n"
              "• Ortak Bütçe ve Grup Verileri: Ortak ev/yurt bütçesi veya harcama gruplarında oluşturduğunuz grup adı, katılımcı isimleri, ortak giderler, hesaplaşma durumları ve oda ihtiyaç listesi.\n\n"
              "• Geri Bildirim Kayıtları: İsteğe bağlı gönderdiğiniz hata/öneri mesajları ile hesap silme sırasında seçtiğiniz ayrılma nedeni.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "2",
          title: "Verilerin Hangi Amaçlarla ve Nerede Kullanıldığı",
          body:
              "• Ana Ekran ve Raporlar: Gelir-gider dengesini, Nakit/Banka/Kredi Kartı hesap bakiyelerini ve son 6 aylık kategori/trend grafiklerini hesaplamak için kullanılır.\n"
              "• Çoklu Cihaz ve Bulut Senkronizasyonu: Kayıtlı kullanıcıların verilerini cihaz değişiminde kaybetmemesi için Google Firebase (Cloud Firestore) üzerindeki kullanıcıya özel izole koleksiyonlarda (`users/{uid}`) senkronize etmek için kullanılır.\n"
              "• Ortak Grup Paylaşımı: 6 haneli davet koduyla katılınan ortak gruplarda harcama ve ihtiyaç listesini yalnızca o grubun üyeleri arasında eşzamanlı göstermek için kullanılır.\n"
              "• Hatırlatıcı ve Uyarılar: Fatura/abonelik günleri, kredi kartı kesim/son ödeme tarihleri ve bütçe limit aşımları için cihaz içi yerel bildirimler oluşturmak amacıyla kullanılır.\n"
              "• PDF Raporlama: Seçtiğiniz tarih aralığındaki işlemleri cihazınızda yerel olarak PDF belgesine dönüştürüp paylaşabilmeniz için kullanılır.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "3",
          title: "Cihaz İzinleri ve Yerel Depolama",
          body:
              "• Bildirim İzni: Yalnızca sizin aktif ettiğiniz günlük harcama, fatura, kart vadesi ve bütçe aşım uyarılarını cihazınızda göstermek için kullanılır.\n"
              "• Geçici Dosya ve Yazdırma/Paylaşım Erişimi: 'Verileri Dışa Aktar (PDF)' özelliğini kullandığınızda PDF dosyası tamamen cihazınızın geçici belleğinde oluşturulur; harici bir sunucuya yüklenmez.\n"
              "• Yerel Önbellek (SharedPreferences): Çevrimdışı çalışma, tema tercihi (Açık/Koyu mod) ve hızlı açılış için veriler cihazınızda kullanıcı kimliğinize özel anahtarlarla (`scopedKey`) izole edilerek saklanır.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "4",
          title: "Veri Güvenliği ve Üçüncü Taraflarla Paylaşım",
          body:
              "Kullanıcı verileri hiçbir koşulda reklam ağlarına veya üçüncü taraflara satılmaz, kiralanmaz ve pazarlama amacıyla paylaşılmaz. Kimlik doğrulama ve bulut yedekleme işlemleri Google Firebase (Firebase Authentication & Cloud Firestore) altyapısı üzerinde HTTPS/TLS şifrelemesi ile korunmaktadır. Döviz kurları için harici kur servislerine yalnızca anonim kur sorgusu yapılır, kişisel veri iletilmez.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "5",
          title: "Verileri Sıfırlama ve Kalıcı Hesap Silme Hakkı",
          body:
              "• Verileri Sıfırla: Profil > Verileri Sıfırla adımıyla hesabınızı kapatmadan tüm gelir, gider, kategori, bütçe limiti, kredi kartı, taksit, borç, kumbara, sabit ödeme ve grup verilerinizi tek dokunuşla hem cihazdan hem buluttan temizleyebilirsiniz.\n\n"
              "• Hesabı Sil: Profil > Hesabı Sil adımıyla hesabınızı sildiğinizde; Firebase Authentication kimlik kaydınız ile Firestore üzerindeki tüm kişisel profiliniz, işlemleriniz, kategorileriniz ve ekstra modül verileriniz geri döndürülemez biçimde kalıcı olarak silinir.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "6",
          title: "İletişim ve Veri Sorumlusu",
          body:
              "Kişisel verilerinizle ilgili her türlü soru, bilgi talebi veya silme başvurusu için uygulama içi 'Geri Bildirim & İletişim' bölümünden veya aşağıdaki e-posta adresinden veri sorumlusuna ulaşabilirsiniz.\n\nE-posta: ensayy63@gmail.com\n\nHesaply Mobil Uygulaması • Resmi Gizlilik Politikası",
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildIntroText(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildArticleItem({
    required String number,
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
