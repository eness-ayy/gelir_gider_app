import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/edit_profile_dialog.dart';
import 'package:gelir_gider_uygulamasi/services/notification_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bool isGuest =
        FirebaseAuth.instance.currentUser?.isAnonymous ?? true;
    if (isGuest) {
      return EditProfileDialog.show(
        context,
        title: "Bildirimleri Aktifleştirin",
        subtitle:
            "Fatura hatırlatıcıları, kredi kartı vade uyarıları ve bütçe limit bildirimlerini cihazınızda alabilmek için ücretsiz hesabınızı oluşturun.",
        icon: Icons.notifications_active_outlined,
      );
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().checkPermissionGranted();
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifService = Get.find<NotificationService>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutma Çubuğu (Drag Handle)
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık Alanı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bildirim Ayarları",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Hatırlatıcı ve uyarı bildirimlerini yönetin",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),

          // İçerik Listesi
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Obx(() {
                final isMaster = notifService.isMasterEnabled.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!notifService.isSystemPermissionGranted.value)
                      _buildSystemPermissionWarning(
                          context, notifService, isDark),
                    // Ana Açma/Kapama Kartı
                    _buildMasterCard(context, notifService, isDark, isMaster),
                    const SizedBox(height: 20),

                    // Bölüm Başlığı: Günlük Hatırlatıcı
                    _buildSectionHeader(
                      title: "GÜNLÜK RUTİN",
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildToggleCard(
                      icon: Icons.edit_calendar_rounded,
                      iconColor: Colors.blueAccent,
                      title: "Günlük Harcama Hatırlatıcısı",
                      subtitle:
                          "Günün sonunda harcamalarınızı ve fişlerinizi kaydetmeniz için hatırlatır.",
                      value: notifService.isDailyEnabled.value,
                      enabled: isMaster,
                      isDark: isDark,
                      onChanged: (val) => notifService.setDailyEnabled(val),
                    ),

                    if (isMaster && notifService.isDailyEnabled.value) ...[
                      const SizedBox(height: 6),
                      _buildTimePickerCard(
                        context: context,
                        notifService: notifService,
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Bölüm Başlığı: Ödeme & Vade Uyarıları
                    _buildSectionHeader(
                      title: "ÖDEME & VADE HATIRLATICILARI",
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildToggleCard(
                      icon: Icons.event_repeat_rounded,
                      iconColor: Colors.amber.shade700,
                      title: "Fatura & Abonelik Bildirimleri",
                      subtitle:
                          "Kira, abonelik ve faturaların ödeme gününden 1 gün önce ve ödeme gününde uyarı gönderir.",
                      value: notifService.isRecurringEnabled.value,
                      enabled: isMaster,
                      isDark: isDark,
                      onChanged: (val) => notifService.setRecurringEnabled(val),
                    ),
                    const SizedBox(height: 8),

                    _buildToggleCard(
                      icon: Icons.credit_card_rounded,
                      iconColor: Colors.purpleAccent,
                      title: "Kredi Kartı Son Ödeme & Kesim",
                      subtitle:
                          "Son ödeme gününe 2 gün kala ve ekstre hesap kesim gününde bilgilendirir.",
                      value: notifService.isCardEnabled.value,
                      enabled: isMaster,
                      isDark: isDark,
                      onChanged: (val) => notifService.setCardEnabled(val),
                    ),

                    const SizedBox(height: 20),

                    // Bölüm Başlığı: Bütçe Denetimi
                    _buildSectionHeader(
                      title: "BÜTÇE DENETİMİ",
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildToggleCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.orangeAccent.shade400,
                      title: "Bütçe Aşım ve Limit Uyarıları",
                      subtitle:
                          "Kategori harcamanız %80 limitine ulaştığında veya bütçeyi aştığında anında bildirim gönderir.",
                      value: notifService.isBudgetAlertEnabled.value,
                      enabled: isMaster,
                      isDark: isDark,
                      onChanged: (val) =>
                          notifService.setBudgetAlertEnabled(val),
                    ),

                    const SizedBox(height: 24),

                    // Test Bildirimi ve İzin Butonları
                    _buildTestButton(context, notifService, isDark, isMaster),
                    const SizedBox(height: 10),
                    _buildPermissionButton(notifService, isDark),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMasterCard(
    BuildContext context,
    NotificationService notifService,
    bool isDark,
    bool isMaster,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMaster
            ? (isDark
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : const Color(0xFFECFDF5))
            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMaster
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.grey.shade300),
          width: isMaster ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMaster
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white12 : Colors.grey.shade400),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMaster ? Icons.notifications_active : Icons.notifications_off,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tüm Bildirimler",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isMaster
                      ? "Planlanmış ve anlık hatırlatıcılar aktif"
                      : "Tüm bildirimler devre dışı bırakıldı",
                  style: TextStyle(
                    fontSize: 12,
                    color: isMaster
                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                        : (isDark ? Colors.white38 : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isMaster,
            activeTrackColor: const Color(0xFF10B981),
            onChanged: (val) => notifService.setMasterEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    final effectiveEnabled = enabled;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (effectiveEnabled ? iconColor : Colors.grey)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: effectiveEnabled ? iconColor : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: effectiveEnabled
                ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ),
        trailing: Switch(
          value: value && effectiveEnabled,
          onChanged: effectiveEnabled ? onChanged : null,
          activeTrackColor: const Color(0xFF10B981),
        ),
      ),
    );
  }

  Widget _buildTimePickerCard({
    required BuildContext context,
    required NotificationService notifService,
    required bool isDark,
  }) {
    final hour = notifService.dailyHour.value;
    final minute = notifService.dailyMinute.value;
    final formattedTime =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blueAccent.withValues(alpha: 0.08)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_filled_rounded,
            color: Colors.blueAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            "Hatırlatma Saati:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
                confirmText: "KAYDET",
                cancelText: "İPTAL",
                helpText: "BİLDİRİM SAATİNİ SEÇİN",
              );
              if (picked != null) {
                final timeStr =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                await notifService.setDailyTime(picked.hour, picked.minute);
                Get.snackbar(
                  "Saat Güncellendi",
                  "Günlük harcama hatırlatıcısı her gün saat $timeStr için ayarlandı.",
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Değiştir",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    NotificationService notifService,
    bool isDark,
    bool isMaster,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isMaster
            ? () async {
                await notifService.sendTestNotification();
                Get.snackbar(
                  "Test Bildirimi Gönderildi",
                  "Cihazınızın üst bildirim panelini kontrol edin.",
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 14,
                  duration: const Duration(seconds: 3),
                );
              }
            : null,
        icon: const Icon(Icons.send_rounded, size: 18),
        label: const Text(
          "Test Bildirimi Gönder",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? Colors.white12 : Colors.grey.shade300,
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildPermissionButton(
    NotificationService notifService,
    bool isDark,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final granted = await notifService.requestPermissions();
          Get.snackbar(
            granted ? "İzin Kontrol Edildi" : "İzin Gerekiyor",
            granted
                ? "Bildirim izinleri başarıyla onaylandı."
                : "Lütfen cihaz ayarlarınızdan Hesaply için bildirim izni verin.",
            backgroundColor: granted ? const Color(0xFF10B981) : Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
        icon: Icon(
          Icons.security_rounded,
          size: 16,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
        label: Text(
          "Sistem Bildirim İzinlerini Yenile",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemPermissionWarning(
    BuildContext context,
    NotificationService notifService,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bildirim İzni Kapalı",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Hatırlatıcıların cihazınızda çalabilmesi için bildirim izni vermeniz gerekmektedir.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final granted = await notifService.requestPermissions();
                    if (granted) {
                      Get.snackbar(
                        "İzin Verildi",
                        "Bildirimler başarıyla aktifleştirildi.",
                        backgroundColor: const Color(0xFF10B981),
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    "İzin İste / Aç",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
