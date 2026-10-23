import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  static const String supportEmail = 'destek.gelirgider@gmail.com';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeedbackSheet(),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {
      'id': 'bug',
      'title': 'Hata Bildirimi',
      'icon': Icons.bug_report_outlined,
      'color': Colors.redAccent,
    },
    {
      'id': 'suggestion',
      'title': 'Öneri / İstek',
      'icon': Icons.lightbulb_outline_rounded,
      'color': Colors.amber,
    },
    {
      'id': 'general',
      'title': 'Genel İletişim',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': Colors.blueAccent,
    },
  ];

  String _selectedTypeId = 'bug';
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _launchEmail() async {
    final typeObj = _types.firstWhere(
      (t) => t['id'] == _selectedTypeId,
      orElse: () => _types.first,
    );
    final typeTitle = typeObj['title'] as String;

    final userSubject = _subjectController.text.trim();
    final userMessage = _messageController.text.trim();

    final subject = userSubject.isNotEmpty
        ? '[$typeTitle] $userSubject'
        : '[Gelir-Gider App] $typeTitle';

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Belirtilmedi';

    final bodyBuffer = StringBuffer();
    if (userMessage.isNotEmpty) {
      bodyBuffer.writeln('Açıklama / Mesaj:');
      bodyBuffer.writeln(userMessage);
      bodyBuffer.writeln();
    }
    bodyBuffer.writeln('----------------------------------------');
    bodyBuffer.writeln('Uygulama: Gelir-Gider Takip');
    bodyBuffer.writeln('Sürüm: v1.0.0');
    bodyBuffer.writeln('Kullanıcı: $userEmail');
    bodyBuffer.writeln('Tarih: ${DateTime.now().toLocal().toString().split('.').first}');

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: FeedbackSheet.supportEmail,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': bodyBuffer.toString(),
      }),
    );

    setState(() => _isSending = true);

    try {
      final launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await _copyEmailAndNotify();
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      await _copyEmailAndNotify();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _copyEmailAndNotify() async {
    await Clipboard.setData(const ClipboardData(text: FeedbackSheet.supportEmail));
    if (mounted) {
      Navigator.pop(context);
    }
    Get.snackbar(
      "E-posta Kopyalandı",
      "Cihazınızda e-posta istemcisi açılamadı. Destek e-posta adresi (${FeedbackSheet.supportEmail}) panoya kopyalandı.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.copy_rounded, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Geri Bildirim & İletişim",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Hata bildirin veya önerinizi paylaşın",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Kapat",
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bildirim Türü Seçimi
                  const Text(
                    "Bildirim Türü",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _types.map((type) {
                      final isSelected = _selectedTypeId == type['id'];
                      final color = type['color'] as Color;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTypeId = type['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  color: isSelected
                                      ? color
                                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? color
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.grey.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Konu / Başlık
                  const Text(
                    "Konu (İsteğe Bağlı)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: "Örn: İşlem eklerken karşılaşılan hata",
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mesaj / Açıklama
                  const Text(
                    "Açıklama / Mesajınız",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          "Düşüncelerinizi, karşılaştığınız durumu veya yeni özellik önerinizi detaylandırabilirsiniz...",
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Destek E-Postası Bilgi Rozeti
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alternate_email_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            FeedbackSheet.supportEmail,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _copyEmailAndNotify,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Kopyala",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // E-posta ile Gönder Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSending ? null : _launchEmail,
                      icon: _isSending
                          ? const SizedBox.shrink()
                          : const Icon(Icons.send_rounded, size: 18),
                      label: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              "E-posta Uygulamasında Aç",
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
          ),
        ],
      ),
    );
  }
}
