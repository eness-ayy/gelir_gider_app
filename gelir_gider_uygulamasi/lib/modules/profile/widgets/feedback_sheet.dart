import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/services/feedback_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

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
  final FeedbackService _feedbackService = FeedbackService();

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
  String? _messageError;
  String? _generalError;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Firebase veya sistem hatalarını kullanıcı dostu Türkçe mesaja dönüştürür
  String _getReadableErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Veritabanı yazma yetkisi reddedildi. Firestore güvenlik kurallarının yayınlandığından emin olun.';
        case 'unavailable':
          return 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
        case 'unauthenticated':
          return 'Geri bildirim göndermek için lütfen oturum açınız.';
        case 'deadline-exceeded':
          return 'İşlem zaman aşımına uğradı. İnternet bağlantınızı kontrol ediniz.';
        default:
          return error.message ?? 'Geri bildirim iletilirken bir sorun oluştu.';
      }
    }

    final errorStr = error.toString();
    if (errorStr.contains('permission-denied')) {
      return 'Veritabanı yazma yetkisi reddedildi (Firestore kurallarını kontrol edin).';
    }
    if (errorStr.contains('unavailable') ||
        errorStr.contains('network') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup')) {
      return 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
    }

    return errorStr.replaceAll('Exception: ', '').trim();
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _messageError = "Lütfen bir mesaj / açıklama giriniz.";
      });
      Get.snackbar(
        "Eksik Bilgi",
        "Lütfen açıklama / mesaj alanını doldurunuz.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _messageError = null;
      _generalError = null;
      _isSending = true;
    });

    final typeObj = _types.firstWhere(
      (t) => t['id'] == _selectedTypeId,
      orElse: () => _types.first,
    );
    final typeTitle = typeObj['title'] as String;

    try {
      await _feedbackService.sendFeedback(
        type: typeTitle,
        subject: _subjectController.text,
        message: message,
      );

      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          "Başarılı",
          "Geri bildiriminiz başarıyla iletildi. Teşekkür ederiz!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint("Geri bildirim gönderme hatası: $e");
      final friendlyError = _getReadableErrorMessage(e);

      if (mounted) {
        setState(() {
          _generalError = friendlyError;
        });

        Get.snackbar(
          "Gönderilemedi",
          friendlyError,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _copyEmailAndNotify() async {
    await Clipboard.setData(const ClipboardData(text: FeedbackSheet.supportEmail));
    if (!mounted) return;

    Navigator.pop(context);
    Get.snackbar(
      "E-posta Kopyalandı",
      "Destek e-posta adresi (${FeedbackSheet.supportEmail}) panoya kopyalandı.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blueGrey.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.copy_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
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
                    "Açıklama / Mesajınız *",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    onChanged: (val) {
                      if (_messageError != null && val.trim().isNotEmpty) {
                        setState(() => _messageError = null);
                      }
                      if (_generalError != null) {
                        setState(() => _generalError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText:
                          "Düşüncelerinizi, karşılaştığınız durumu veya yeni özellik önerinizi detaylandırabilirsiniz...",
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.all(14),
                      errorText: _messageError,
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

                  const SizedBox(height: 16),

                  // Hata Bildirim Kutusu (Modal içinde net görünür)
                  if (_generalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _generalError = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Gönder Butonu
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
                      onPressed: _isSending ? null : _submitFeedback,
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
                              "Gönder",
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
