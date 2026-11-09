import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../firebase/fcm_service.dart' show flutterLocalNotificationsPlugin;
import 'notification_sound.dart';

/// Günlük "rutin hatırlatıcısı" — cihazda planlanan yerel bildirim (offline da
/// çalışır), seçili bildirim sesiyle + "Ertele / Tamam" aksiyonlarıyla.
/// (Seçilen sistem = A: güçlendirilmiş bildirim; telefon alarmı değil.)
class ReminderService {
  static const String _kEnabled = 'routine_reminder_enabled';
  static const String _kHour = 'routine_reminder_hour';
  static const String _kMinute = 'routine_reminder_minute';
  // Arka plan (uygulama kapalıyken erteleme) için saklanan metin/ses.
  static const String _kTitle = 'routine_reminder_title';
  static const String _kBody = 'routine_reminder_body';
  static const String _kSound = 'routine_reminder_sound';

  // Sabit bildirim kimlikleri (modül hatırlatıcılarıyla çakışmaması için yüksek).
  static const int dailyId = 900001;
  static const int snoozeId = 900002;
  static const int snoozeMinutes = 10;

  static bool _tzReady = false;

  /// Zaman dilimi veritabanını bir kez hazırlar (zonedSchedule için şart).
  static Future<void> ensureTz() async {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // getLocation başarısızsa UTC'de kalır; yine de çalışır.
    }
    _tzReady = true;
  }

  static Future<TimeOfDay?> getTime() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool(_kEnabled) ?? false)) return null;
      final h = p.getInt(_kHour);
      final m = p.getInt(_kMinute);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  /// Bildirim detayları. [snoozeLabel]/[doneLabel] arka plandan çağrıda
  /// lokalize metin olmadan sabit verilebilir.
  static NotificationDetails detailsFor(NotifSound snd,
      {required String snoozeLabel, required String doneLabel}) {
    final android = AndroidNotificationDetails(
      snd.channelId,
      'LifeSync',
      channelDescription: 'LifeSync',
      importance: Importance.high,
      priority: Priority.high,
      playSound: snd.playSound,
      sound: snd.raw != null
          ? RawResourceAndroidNotificationSound(snd.raw!)
          : null,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('snooze', snoozeLabel,
            showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('done', doneLabel,
            showsUserInterface: false, cancelNotification: true),
      ],
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: snd.playSound,
      sound: snd.iosFile ?? 'default',
      categoryIdentifier: 'routine_reminder',
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  static NotificationDetails _details() => detailsFor(NotifSoundPrefs.current,
      snoozeLabel: 'reminder.snooze'.tr(), doneLabel: 'reminder.done'.tr());

  /// Her gün [hour]:[minute] saatinde tekrarlayan hatırlatıcı kurar.
  static Future<void> setDailyReminder(int hour, int minute) async {
    await ensureTz();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kEnabled, true);
      await p.setInt(_kHour, hour);
      await p.setInt(_kMinute, minute);
      await p.setString(_kTitle, 'reminder.title'.tr());
      await p.setString(_kBody, 'reminder.body'.tr());
      await p.setString(_kSound, NotifSoundPrefs.currentId);
    } catch (_) {}

    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      dailyId,
      'reminder.title'.tr(),
      'reminder.body'.tr(),
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // günlük tekrar
    );
  }

  static Future<void> cancel() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kEnabled, false);
    } catch (_) {}
    await flutterLocalNotificationsPlugin.cancel(dailyId);
    await flutterLocalNotificationsPlugin.cancel(snoozeId);
  }

  /// "Ertele": [snoozeMinutes] dakika sonra tek seferlik tekrar (ön plan).
  static Future<void> snooze() async {
    await ensureTz();
    final when = tz.TZDateTime.now(tz.local)
        .add(const Duration(minutes: snoozeMinutes));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      snoozeId,
      'reminder.title'.tr(),
      'reminder.bodySnoozed'.tr(),
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

/// Bildirim aksiyonuna (Ertele/Tamam) uygulama ARKA PLANDAYKEN/KAPALIYKEN
/// basılınca çalışır (ayrı izolat). "Ertele" ise saklı metin/sesle +10 dk
/// yeniden planlar. easy_localization burada çalışmayabileceği için saklı
/// (lokalize) metinler + sabit buton etiketleri kullanılır.
@pragma('vm:entry-point')
Future<void> reminderBackgroundResponse(NotificationResponse r) async {
  if (r.actionId != 'snooze') return;
  try {
    final p = await SharedPreferences.getInstance();
    final soundId = p.getString(ReminderService._kSound) ?? 'chime';
    final title = p.getString(ReminderService._kTitle) ?? 'LifeSync';
    final body = p.getString(ReminderService._kBody) ?? '';
    final snd = NotifSound.byId(soundId);

    // Bu izolatta eklentiyi yeniden başlat (göstermek/planlamak için şart).
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(init);

    tzdata.initializeTimeZones();
    // Göreli +10 dk mutlak bir andır; zaman dilimi adı doğru olmasa da tetiklenir.
    final when = tz.TZDateTime.now(tz.local)
        .add(const Duration(minutes: ReminderService.snoozeMinutes));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      ReminderService.snoozeId,
      title,
      body,
      when,
      ReminderService.detailsFor(snd, snoozeLabel: 'Ertele', doneLabel: 'Tamam'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (_) {}
}
