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
                        "Son Güncelleme: 24 Ekim 2026",
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
          "Lütfen Hesaply mobil uygulamasını kullanmadan önce bu Kullanım Koşullarını dikkatlice okuyunuz. Uygulamayı indirerek, kurarak veya kullanarak işbu sözleşmede yer alan tüm şartları kabul etmiş sayılırsınız.",
          isDark,
        ),
        const SizedBox(height: 16),
        _buildArticleItem(
          number: "1",
          title: "Hizmetin Niteliği ve Kapsamı",
          body:
              "Hesaply, kullanıcıların kişisel gelir ve harcamalarını manuel olarak kayıt altına almalarını, bütçelerini grafiklerle görselleştirmelerini ve periyodik mali özet raporları (PDF) oluşturmalarını sağlayan bir kişisel finans yönetim asistanıdır.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "2",
          title: "Finansal Tavsiye ve Sorumluluk Reddi",
          body:
              "Hesaply bir banka, resmi muhasebe ofisi veya portföy yönetim kuruluşu değildir. Uygulama içerisinde sunulan bakiye, grafik ve raporlar kullanıcının doğrudan kendi girdiği verilere dayanmaktadır ve yalnızca kişisel takip amaçlıdır. Hesaply, uygulama verilerine dayanılarak alınan kişisel harcama veya yatırım kararlarından doğabilecek maddi ya da manevi kayıplardan sorumlu tutulamaz.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "3",
          title: "Hesap Güvenliği ve Kullanıcı Yükümlülüğü",
          body:
              "Kullanıcı, hesabına erişim sağlayan e-posta ve şifre bilgilerinin gizliliğini korumaktan şahsen sorumludur. Hesabınız üzerinden gerçekleştirilen tüm işlemler sizin yetkiniz dahilinde kabul edilir. Yetkisiz bir erişim fark ettiğinizde durumu gecikmeksizin destek adresimize bildirmeniz gerekir.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "4",
          title: "Kabul Edilebilir Kullanım Kuralları",
          body:
              "Kullanıcılar uygulamayı hukuka uygun amaçlarla kullanmayı; uygulamanın güvenliğini tehlikeye atacak tersine mühendislik girişimlerinde bulunmamayı ve sistem kaynaklarını suistimal etmemeyi kabul eder. Kötü niyetli kullanım tespitinde hesaplar önceden bildirim yapılmaksızın askıya alınabilir.\n\nHesaply Mobil Uygulaması • Resmi Kullanım Sözleşmesi",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "5",
          title: "Fikri Mülkiyet Hakları",
          body:
              "Hesaply uygulamasının adı, görsel kimliği, arayüz tasarımları, logoları, kaynak kodları ve tüm yazılımsal bileşenleri geliştiriciye aittir. Telif hakları yasalarıyla korunmakta olup, geliştiricinin yazılı izni olmadan kısmen veya tamamen kopyalanamaz, çoğaltılamaz ve ticari amaçla dağıtılamaz.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "6",
          title: "Hizmet Sürekliliği ve Değişiklikler",
          body:
              "Geliştirici, uygulamanın işlevlerini iyileştirme, yeni özellikler ekleme veya mevcut modülleri güncelleme hakkını saklı tutar. Kullanım koşullarında yapılabilecek esaslı güncellemeler bu sayfa üzerinden duyurulur ve yürürlüğe girer.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "7",
          title: "Destek ve İletişim",
          body:
              "Geliştirici İletişim & Destek Masası\n\nKullanım Koşulları ve sözleşme maddeleri ile ilgili tüm bildirim, öneri veya şikayetleriniz için aşağıdaki resmi destek e-posta adresimiz üzerinden bizimle irtibat kurabilirsiniz.\n\nE-posta: ensayy63@gmail.com\n\nHesaply Mobil Uygulaması • Resmi Kullanım Sözleşmesi",
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
          "Hesaply ekibi olarak kullanıcılarımızın gizliliğine ve kişisel verilerinin korunmasına azami önem veriyoruz. Bu Gizlilik Politikası, Hesaply mobil uygulamasını kullandığınızda hangi kişisel verilerin toplandığını, işlenme esaslarını ve güvenliğinin nasıl sağlandığını şeffaf bir şekilde açıklar.",
          isDark,
        ),
        const SizedBox(height: 16),
        _buildArticleItem(
          number: "1",
          title: "Toplanan Bilgiler ve Veri Türleri",
          body:
              "• Hesap Bilgileri: Uygulamaya kayıt olurken veya giriş yaparken ilettiğiniz e-posta adresi ve şifre gibi kimlik doğrulama verileri toplanır. Kullanıcı parolaları tarafımızca açık halde görüntülenemez; endüstri standardı kriptografik yöntemlerle şifrelenerek korunur.\n\n• Finansal ve İşlem Kayıtları: Uygulama içerisinde manuel olarak girdiğiniz gelir tutarları, gider tutarları, harcama kategorileri, işlem açıklamaları ve tarihler kayıt altına alınır. Hesaply bir banka veya resmi finans kuruluşu değildir; doğrudan banka hesaplarınıza, IBAN şifrelerinize veya kredi kartı detaylarınıza erişim talep etmez.\n\n• Cihaz ve Kullanım Verileri: Uygulama performansını izlemek, çökme raporlarını tespit etmek ve arayüz kararlılığını sağlamak için işletim sistemi sürümü ve genel kullanım istatistikleri toplanabilir.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "2",
          title: "Verilerin Kullanım Amaçları",
          body:
              "Toplanan tüm kişisel ve finansal veriler münhasıran aşağıdaki operasyonel amaçlar doğrultusunda işlenmektedir:\n\n• Uygulamanın temel işlevlerini eksiksiz yerine getirmek, gelir ve giderleri hesaplayıp bakiye dengesini sunmak.\n• Finansal verileri grafiksel ve kategorik özetlerle analiz edilebilir hale getirmek.\n• Kullanıcı tarafından talep edilen tarih aralıklarında yerel PDF formatında harcama raporu oluşturmak.\n• Kullanıcı oturum güvenliğini ve hesap bütünlüğünü sürdürmek.\n• Sistem hatalarını tespit ederek teknik destek sağlamak.\n\nHesaply Mobil Uygulaması • Resmi Yasal Belge",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "3",
          title: "Verilerin Saklanması ve Güvenliği",
          body:
              "Hesaply kullanıcı verileri, Google Cloud altyapısı üzerinde yer alan güvenli bulut sunucularında muhafaza edilmektedir. İstemci ile sunucu arasındaki tüm veri transferi SSL/TLS şifreleme protokolleriyle güvence altına alınır. Kullanıcı verileri kesinlikle üçüncü taraflara satılmaz, kiralanmaz veya ticari amaçla devredilmez.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "4",
          title: "Dışa Aktarma ve Cihaz Depolama İzinleri",
          body:
              "Uygulama üzerinden gelir ve gider verilerinizi PDF olarak dışa aktarmak istediğinizde, oluşturulan dosyanın cihaz belleğine kaydedilmesi veya paylaştırılabilmesi için depolama ve yazdırma erişimleri kullanılır. Bu erişim izinleri yalnızca oluşturulan PDF raporunun yönetimi amacıyla sınırlıdır.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "5",
          title: "Veri Silme ve Hesap İptali (Google Play & App Store Uyumu)",
          body:
              "Kullanıcılar verileri üzerinde koşulsuz tasarruf hakkına sahiptir. Uygulama içerisindeki Profil ekranında yer alan Hesabımı Sil bağlantısını kullanarak dilediğiniz an hesabınızı ve hesaba ait tüm gelir, gider ve kategori kayıtlarını kalıcı olarak silebilirsiniz. Silinen veriler veritabanlarımızdan geri döndürülemez biçimde temizlenir.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "6",
          title: "Üçüncü Taraf Altyapı Sağlayıcıları",
          body:
              "Uygulamamız kimlik doğrulama, oturum yönetimi ve veritabanı senkronizasyonu için Google Firebase altyapısını kullanmaktadır. Bu hizmetler uluslararası güvenlik ve veri koruma standartlarına tam uyumludur.",
          isDark: isDark,
        ),
        _buildArticleItem(
          number: "7",
          title: "İletişim ve Veri Sorumlusu",
          body:
              "Geliştirici & Destek İletişim Kanalı\n\nGizlilik Politikası, veri silme talepleri veya kişisel veri haklarınız ile ilgili her türlü soru ve bildirim için bizimle e-posta yoluyla iletişime geçebilirsiniz.\n\nE-posta: ensayy63@gmail.com\n\nHesaply Mobil Uygulaması • Resmi Yasal Belge",
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
