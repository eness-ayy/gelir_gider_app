import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/recurring_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late final StorgeService _storage;

  // Depolama Anahtarları
  static const String _keyMasterEnabled = 'notif_master_enabled';
  static const String _keyDailyEnabled = 'notif_daily_enabled';
  static const String _keyDailyHour = 'notif_daily_hour';
  static const String _keyDailyMinute = 'notif_daily_minute';
  static const String _keyRecurringEnabled = 'notif_recurring_enabled';
  static const String _keyCardEnabled = 'notif_card_enabled';
  static const String _keyBudgetEnabled = 'notif_budget_enabled';

  // ID Aralıkları
  static const int _testNotificationId = 999;
  static const int _dailyReminderId = 1000;
  static const int _recurringBaseId = 2000;
  static const int _cardBaseId = 3000;
  static const int _budgetBaseId = 4000;

  // Reaktif Ayar Değişkenleri
  final isMasterEnabled = true.obs;
  final isDailyEnabled = true.obs;
  final dailyHour = 21.obs; // Varsayılan akşam 21:00
  final dailyMinute = 0.obs;
  final isRecurringEnabled = true.obs;
  final isCardEnabled = true.obs;
  final isBudgetAlertEnabled = true.obs;
  final isSystemPermissionGranted = true.obs;

  Future<NotificationService> init() async {
    _storage = Get.find<StorgeService>();
    _loadSettings();
    await _initPlugin();
    await checkPermissionGranted();
    await rescheduleAll();
    return this;
  }

  void _loadSettings() {
    isMasterEnabled.value =
        _storage.getValueOrDefault<bool>(_keyMasterEnabled, true);
    isDailyEnabled.value =
        _storage.getValueOrDefault<bool>(_keyDailyEnabled, true);
    dailyHour.value = _storage.getValueOrDefault<int>(_keyDailyHour, 21);
    dailyMinute.value = _storage.getValueOrDefault<int>(_keyDailyMinute, 0);
    isRecurringEnabled.value =
        _storage.getValueOrDefault<bool>(_keyRecurringEnabled, true);
    isCardEnabled.value =
        _storage.getValueOrDefault<bool>(_keyCardEnabled, true);
    isBudgetAlertEnabled.value =
        _storage.getValueOrDefault<bool>(_keyBudgetEnabled, true);
  }

  Future<void> _initPlugin() async {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {
        // Fallback default timezone
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("Bildirime tıklandı: ${response.payload}");
        },
      );

      await requestPermissions();
    } catch (e) {
      debugPrint("Bildirim servisi başlatılırken hata: $e");
    }
  }

  /// Cihaz düzeyinde bildirim izinlerinin açık olup olmadığını kontrol eder
  Future<bool> checkPermissionGranted() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final enabled = await androidPlatform.areNotificationsEnabled();
        isSystemPermissionGranted.value = enabled ?? true;
        return isSystemPermissionGranted.value;
      }
      return true;
    } catch (e) {
      debugPrint("Bildirim izni kontrol hatası: $e");
      return true;
    }
  }

  /// Android 13+ ve iOS izinlerini talep eder
  Future<bool> requestPermissions() async {
    try {
      bool granted = true;
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final notifGranted =
            await androidPlatform.requestNotificationsPermission();
        await androidPlatform.requestExactAlarmsPermission();
        granted = notifGranted ?? true;
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final iosGranted = await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? true;
      }

      isSystemPermissionGranted.value = granted;
      return granted;
    } catch (e) {
      debugPrint("Bildirim izni istenirken hata: $e");
      return false;
    }
  }

  // --- Ayar Güncelleme Metotları ---

  Future<void> setMasterEnabled(bool value) async {
    isMasterEnabled.value = value;
    await _storage.setValue<bool>(_keyMasterEnabled, value);
    if (!value) {
      await cancelAll();
    } else {
      await rescheduleAll();
    }
  }

  Future<void> setDailyEnabled(bool value) async {
    isDailyEnabled.value = value;
    await _storage.setValue<bool>(_keyDailyEnabled, value);
    await scheduleDailyReminder();
  }

  Future<void> setDailyTime(int hour, int minute) async {
    dailyHour.value = hour;
    dailyMinute.value = minute;
    await _storage.setValue<int>(_keyDailyHour, hour);
    await _storage.setValue<int>(_keyDailyMinute, minute);
    await scheduleDailyReminder();
  }

  Future<void> setRecurringEnabled(bool value) async {
    isRecurringEnabled.value = value;
    await _storage.setValue<bool>(_keyRecurringEnabled, value);
    await scheduleRecurringReminders();
  }

  Future<void> setCardEnabled(bool value) async {
    isCardEnabled.value = value;
    await _storage.setValue<bool>(_keyCardEnabled, value);
    await scheduleCreditCardReminders();
  }

  Future<void> setBudgetAlertEnabled(bool value) async {
    isBudgetAlertEnabled.value = value;
    await _storage.setValue<bool>(_keyBudgetEnabled, value);
  }

  // --- Bildirim Detay Şablonları ---

  NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF10B981),
      enableVibration: true,
      playSound: true,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: darwin);
  }

  // --- Tüm Bildirimleri Senkronize Et ---

  Future<void> rescheduleAll() async {
    if (!isMasterEnabled.value) {
      await cancelAll();
      return;
    }
    await scheduleDailyReminder();
    await scheduleRecurringReminders();
    await scheduleCreditCardReminders();
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("Bildirimler iptal edilirken hata: $e");
    }
  }

  // --- 1. Günlük Harcama Girişi Hatırlatıcısı ---

  Future<void> scheduleDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(id: _dailyReminderId);

      if (!isMasterEnabled.value || !isDailyEnabled.value) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        dailyHour.value,
        dailyMinute.value,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final details = _buildNotificationDetails(
        channelId: 'daily_reminder_channel',
        channelName: 'Günlük Harcama Hatırlatıcısı',
        channelDesc:
            'Harcamalarınızı her gün düzenli kaydetmeniz için bildirim gönderir',
      );

      await _notificationsPlugin.zonedSchedule(
        id: _dailyReminderId,
        title: '📝 Günlük Bütçe Kontrolü',
        body:
            'Bugünkü harcamalarını ve fişlerini kaydettin mi? Bütçeni güncel tutmak için bir dakikanı ayır.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );
      debugPrint("Günlük bildirim planlandı: $scheduledDate");
    } catch (e) {
      debugPrint("Günlük bildirim planlanırken hata: $e");
    }
  }

  // --- 2. Tekrarlayan Ödeme & Fatura Hatırlatıcıları ---

  Future<void> scheduleRecurringReminders() async {
    try {
      // Önceki tekrarlayan hatırlatıcıları temizle (2000-2999)
      for (int i = 0; i < 200; i++) {
        await _notificationsPlugin.cancel(id: _recurringBaseId + i);
      }

      if (!isMasterEnabled.value || !isRecurringEnabled.value) return;

      if (!Get.isRegistered<RecurringService>()) return;
      final recurringService = Get.find<RecurringService>();
      final items = recurringService.items.where((i) => i.isActive).toList();

      final details = _buildNotificationDetails(
        channelId: 'recurring_reminder_channel',
        channelName: 'Fatura ve Abonelik Hatırlatıcıları',
        channelDesc:
            'Yaklaşan kira, fatura ve abonelik ödemeleriniz için bildirim gönderir',
      );

      final now = tz.TZDateTime.now(tz.local);

      for (int i = 0; i < items.length && i < 80; i++) {
        final item = items[i];
        final nextDate = item.nextPaymentDate;

        // 1 gün önce sabah 09:30'da hatırlat
        var oneDayBefore = tz.TZDateTime(
          tz.local,
          nextDate.year,
          nextDate.month,
          nextDate.day,
          9,
          30,
        ).subtract(const Duration(days: 1));

        if (oneDayBefore.isAfter(now)) {
          final notifId = _recurringBaseId + (i * 2);
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: '🔔 Yaklaşan Ödeme: ${item.title}',
            body:
                'Yarın ${item.title} için ₺${item.amount.toStringAsFixed(2)} tutarında ödemeniz bulunuyor.',
            scheduledDate: oneDayBefore,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'recurring_${item.id}',
          );
        }

        // Ödeme günü sabah 09:00'da hatırlat
        var onTheDay = tz.TZDateTime(
          tz.local,
          nextDate.year,
          nextDate.month,
          nextDate.day,
          9,
          0,
        );

        if (onTheDay.isAfter(now)) {
          final notifId = _recurringBaseId + (i * 2) + 1;
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: '💳 Ödeme Günü: ${item.title}',
            body:
                'Bugün ${item.title} için ₺${item.amount.toStringAsFixed(2)} ödeme gününüzdür.',
            scheduledDate: onTheDay,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'recurring_${item.id}',
          );
        }
      }
      debugPrint("Tekrarlayan ödemeler planlandı. Aktif kayıt: ${items.length}");
    } catch (e) {
      debugPrint("Tekrarlayan ödemeler planlanırken hata: $e");
    }
  }

  // --- 3. Kredi Kartı Son Ödeme & Hesap Kesim Uyarıları ---

  Future<void> scheduleCreditCardReminders() async {
    try {
      // Önceki kart hatırlatıcılarını temizle (3000-3999)
      for (int i = 0; i < 200; i++) {
        await _notificationsPlugin.cancel(id: _cardBaseId + i);
      }

      if (!isMasterEnabled.value || !isCardEnabled.value) return;

      if (!Get.isRegistered<CreditCardService>()) return;
      final cardService = Get.find<CreditCardService>();
      final cards = cardService.cards;

      final details = _buildNotificationDetails(
        channelId: 'card_reminder_channel',
        channelName: 'Kredi Kartı Hatırlatıcıları',
        channelDesc:
            'Kredi kartı hesap kesim ve son ödeme tarihleri için uyarı gönderir',
      );

      final now = tz.TZDateTime.now(tz.local);

      for (int i = 0; i < cards.length && i < 50; i++) {
        final card = cards[i];

        // 1. Son Ödeme Gününe 2 Gün Kala (Sabah 10:00)
        var dueMonth = now.month;
        var dueYear = now.year;
        var targetDueDate = DateTime(dueYear, dueMonth, card.dueDay);
        if (targetDueDate.isBefore(DateTime(now.year, now.month, now.day))) {
          dueMonth += 1;
          if (dueMonth > 12) {
            dueMonth = 1;
            dueYear += 1;
          }
        }

        var twoDaysBeforeDue = tz.TZDateTime(
          tz.local,
          dueYear,
          dueMonth,
          card.dueDay,
          10,
          0,
        ).subtract(const Duration(days: 2));

        if (twoDaysBeforeDue.isAfter(now)) {
          final notifId = _cardBaseId + (i * 2);
          final last4Text = card.last4Digits.isNotEmpty
              ? 'Son 4 hane: ${card.last4Digits}'
              : '';
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: '💳 Kredi Kartı Son Ödeme Yaklaşıyor',
            body:
                '${card.cardName} ($last4Text) son ödeme gününe 2 gün kaldı.',
            scheduledDate: twoDaysBeforeDue,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'card_${card.id}',
          );
        }

        // 2. Hesap Kesim Günü Sabah 10:00
        var cutoffMonth = now.month;
        var cutoffYear = now.year;
        var targetCutoffDate = DateTime(cutoffYear, cutoffMonth, card.cutoffDay);
        if (targetCutoffDate.isBefore(DateTime(now.year, now.month, now.day))) {
          cutoffMonth += 1;
          if (cutoffMonth > 12) {
            cutoffMonth = 1;
            cutoffYear += 1;
          }
        }

        var cutoffScheduled = tz.TZDateTime(
          tz.local,
          cutoffYear,
          cutoffMonth,
          card.cutoffDay,
          10,
          0,
        );

        if (cutoffScheduled.isAfter(now)) {
          final notifId = _cardBaseId + (i * 2) + 1;
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: '📑 Hesap Kesim Günü: ${card.cardName}',
            body:
                '${card.cardName} kartınızın hesap kesim tarihi bugün. Yeni dönem ekstre harcamalarınızı kontrol edebilirsiniz.',
            scheduledDate: cutoffScheduled,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'card_${card.id}',
          );
        }
      }
      debugPrint(
          "Kredi kartı bildirimleri planlandı. Kart sayısı: ${cards.length}");
    } catch (e) {
      debugPrint("Kredi kartı bildirimleri planlanırken hata: $e");
    }
  }

  // --- 4. Bütçe Limiti & Aşım Anlık Bildirimi ---

  Future<void> showBudgetAlertNotification({
    required String categoryName,
    required double spentPercent,
    required double limit,
    required double currentSpent,
  }) async {
    if (!isMasterEnabled.value || !isBudgetAlertEnabled.value) return;

    try {
      final details = _buildNotificationDetails(
        channelId: 'budget_alert_channel',
        channelName: 'Bütçe Aşım ve Limit Uyarıları',
        channelDesc:
            'Kategori bütçesi %80 veya %100 sınırına ulaştığında anında uyarır',
        importance: Importance.max,
        priority: Priority.max,
      );

      final isOverBudget = spentPercent >= 100.0;
      final title = isOverBudget
          ? '🚨 Bütçe Limiti Aşıldı!'
          : '⚠️ Bütçe Uyarısı (%${spentPercent.toStringAsFixed(0)})';

      final body = isOverBudget
          ? '$categoryName bütçenizi %${spentPercent.toStringAsFixed(0)} oranında aştınız! (Limit: ₺${limit.toStringAsFixed(0)}, Harcama: ₺${currentSpent.toStringAsFixed(0)})'
          : '$categoryName kategorisi harcamanız bütçenizin %${spentPercent.toStringAsFixed(0)}\'ine ulaştı. Kalan bütçe: ₺${(limit - currentSpent).clamp(0, double.infinity).toStringAsFixed(0)}';

      final notifId = _budgetBaseId + categoryName.hashCode.abs() % 500;
      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'budget_$categoryName',
      );
    } catch (e) {
      debugPrint("Bütçe uyarısı bildirimi gönderilirken hata: $e");
    }
  }

  // --- 5. Test Bildirimi Gönder ---

  Future<void> sendTestNotification() async {
    try {
      final details = _buildNotificationDetails(
        channelId: 'test_channel',
        channelName: 'Test Bildirimleri',
        channelDesc: 'Bildirim test kanalı',
        importance: Importance.max,
        priority: Priority.high,
      );

      await _notificationsPlugin.show(
        id: _testNotificationId,
        title: '🎉 Bildirimler Başarıyla Aktif!',
        body:
            'Hesaply bütçe limitleri, fatura günleri ve harcama hatırlatıcıları artık cihazınızda çalışıyor.',
        notificationDetails: details,
        payload: 'test_notification',
      );
    } catch (e) {
      debugPrint("Test bildirimi gönderilirken hata: $e");
    }
  }

  /// Genel anlık bildirim gösterici
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isMasterEnabled.value) return;

    try {
      final details = _buildNotificationDetails(
        channelId: 'instant_channel',
        channelName: 'Anlık Bildirimler',
        channelDesc: 'Uygulama anlık bilgilendirme bildirimleri',
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Anlık bildirim gösterilirken hata: $e");
    }
  }
}
