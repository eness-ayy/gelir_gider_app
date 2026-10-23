import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/pdf_export_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

class ExportPdfDialog extends StatefulWidget {
  const ExportPdfDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExportPdfDialog(),
    );
  }

  @override
  State<ExportPdfDialog> createState() => _ExportPdfDialogState();
}

enum DateRangePreset { thisMonth, last3Months, thisYear, custom }

class _ExportPdfDialogState extends State<ExportPdfDialog> {
  DateRangePreset _selectedPreset = DateRangePreset.thisMonth;
  late DateTimeRange _dateRange;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(DateRangePreset.thisMonth);
  }

  void _applyPreset(DateRangePreset preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (preset) {
      case DateRangePreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateRangePreset.last3Months:
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateRangePreset.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case DateRangePreset.custom:
        return;
    }

    setState(() {
      _selectedPreset = preset;
      _dateRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = DateRangePreset.custom;
        _dateRange = DateTimeRange(
          start: picked.start,
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isGenerating = true);

    try {
      // 1. İşlemleri çek
      List<AppTransaction> allTransactions = [];

      if (Get.isRegistered<TransactionRepostory>()) {
        allTransactions = await Get.find<TransactionRepostory>().getTransactions();
      } else if (Get.isRegistered<DashboardController>()) {
        allTransactions = Get.find<DashboardController>().myTransaction.toList();
      }

      // 2. Seçilen tarih aralığına göre filtrele
      final filtered = allTransactions.where((t) {
        DateTime tDate;
        try {
          tDate = DateTime.parse(t.date);
        } catch (_) {
          tDate = DateTime.now();
        }

        final start = DateTime(
          _dateRange.start.year,
          _dateRange.start.month,
          _dateRange.start.day,
        );
        final end = DateTime(
          _dateRange.end.year,
          _dateRange.end.month,
          _dateRange.end.day,
          23,
          59,
          59,
        );

        return !tDate.isBefore(start) && !tDate.isAfter(end);
      }).toList();

      // Tarihe göre yeniden eskiye sırala
      filtered.sort((a, b) {
        final aDate = DateTime.tryParse(a.date) ?? DateTime.now();
        final bDate = DateTime.tryParse(b.date) ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      // 3. Kayıt kontrolü
      if (filtered.isEmpty) {
        Get.snackbar(
          "İşlem Bulunamadı",
          "Seçilen tarih aralığında (${DateFormat('dd.MM.yyyy').format(_dateRange.start)} - ${DateFormat('dd.MM.yyyy').format(_dateRange.end)}) herhangi bir gelir veya gider kaydı bulunamadı.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 4. Kullanıcı e-postası tespiti
      String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (userEmail.isEmpty && Get.isRegistered<AuthService>()) {
        userEmail = Get.find<AuthService>().currentUser.value?.email ?? '';
      }

      // 5. PDF oluştur ve yerel paylaşım ekranını aç
      await PdfExportService.exportAndShareFromAppTransactions(
        appTransactions: filtered,
        dateRange: _dateRange,
        userEmail: userEmail,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("[PDF EXPORT] Hata: $e");
      final errorStr = e.toString();
      String friendlyMessage = "PDF oluşturulurken bir sorun oluştu: $e";

      if (errorStr.contains('MissingPluginException')) {
        friendlyMessage =
            "Yeni paketler eklendiği için lütfen uygulamayı tamamen durdurup (Stop) terminalden tekrar 'flutter run' ile baştan başlatınız.";
      }

      Get.snackbar(
        "Hata",
        friendlyMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PDF Raporu Dışa Aktar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Gelir ve gider işlemlerinizi PDF olarak indirin",
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
                  // Hızlı Aralık Seçimi
                  const Text(
                    "Tarih Aralığı Seçin",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(
                        title: "Bu Ay",
                        preset: DateRangePreset.thisMonth,
                        onTap: () => _applyPreset(DateRangePreset.thisMonth),
                        isDark: isDark,
                      ),
                      _buildPresetChip(
                        title: "Son 3 Ay",
                        preset: DateRangePreset.last3Months,
                        onTap: () => _applyPreset(DateRangePreset.last3Months),
                        isDark: isDark,
                      ),
                      _buildPresetChip(
                        title: "Bu Yıl",
                        preset: DateRangePreset.thisYear,
                        onTap: () => _applyPreset(DateRangePreset.thisYear),
                        isDark: isDark,
                      ),
                      _buildPresetChip(
                        title: "Özel Aralık",
                        preset: DateRangePreset.custom,
                        onTap: _selectCustomRange,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Seçili Tarih Kartı
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Seçilen Rapor Dönemi",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedPreset == DateRangePreset.custom)
                              InkWell(
                                onTap: _selectCustomRange,
                                child: const Text(
                                  "Değiştir",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Başlangıç",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(_dateRange.start),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Bitiş",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(_dateRange.end),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bilgilendirme Rozeti
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Oluşturulan PDF belgesinde toplam gelir, gider, net bakiye özeti ve tüm işlemlerinizin detaylı listesi yer alır. Hiçbir veriniz harici sunuculara gönderilmez.",
                            style: TextStyle(fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PDF Oluştur & Paylaş Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isGenerating ? null : _handleExport,
                      icon: _isGenerating
                          ? const SizedBox.shrink()
                          : const Icon(Icons.share_rounded, size: 18),
                      label: _isGenerating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "PDF Raporu Hazırlanıyor...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              "PDF Raporu Oluştur & Paylaş",
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

  Widget _buildPresetChip({
    required String title,
    required DateRangePreset preset,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = _selectedPreset == preset;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }
}
