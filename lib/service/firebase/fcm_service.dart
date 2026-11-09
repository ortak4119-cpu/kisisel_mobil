import 'dart:io';
import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification/notification_models.dart';
import '../notification/notification_service.dart';
import '../notification/notification_sound.dart';
import '../notification/reminder_service.dart';
import '../../core/init/locator.dart';
import '../../core/utils/notification_bus.dart';

// Background message handler - Top level function olmalı
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background notification received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

// Local notifications için global instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final INotificationService _notificationService = locator.get<INotificationService>();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// FCM servisini başlat
  Future<void> initialize() async {
    try {
      // Local notifications'ı başlat
      await _initializeLocalNotifications();

      // Permission iste
      await _requestPermission();

      // Token al
      await _getToken();

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend();
      });

      // Background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // iOS foreground presentation options - SES İÇİN ÖNEMLİ
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Message opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageOpened(message);
        }
      });

      // Message opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ FCM Service initialization failed: $e');
    }
  }

  /// Local notifications'ı başlat
  Future<void> _initializeLocalNotifications() async {
    // Android için ayarlar
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS için ayarlar
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Local notification tapped: ${response.actionId}');
        // Rutin hatırlatıcısı "Ertele" aksiyonu (uygulama ön plandayken).
        if (response.actionId == 'snooze') {
          ReminderService.snooze();
        }
      },
      // Uygulama kapalı/arka plandayken aksiyon (Ertele/Tamam).
      onDidReceiveBackgroundNotificationResponse: reminderBackgroundResponse,
    );

    // Android: her bildirim sesi için AYRI kanal oluştur (kanal sesi sonradan
    // değiştirilemez; kullanıcı ses değiştirince ilgili kanal kullanılır).
    if (Platform.isAndroid) {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      for (final s in NotifSound.all) {
        final channel = AndroidNotificationChannel(
          s.channelId,
          'notifications.channelName'.tr(),
          description: 'notifications.channelDescription'.tr(),
          importance: Importance.high,
          playSound: s.playSound,
          enableVibration: true,
          sound: s.raw != null
              ? RawResourceAndroidNotificationSound(s.raw!)
              : null,
        );
        await android?.createNotificationChannel(channel);
      }
    }

    debugPrint('✅ Local notifications initialized');
  }

  /// Notification permission iste
  Future<void> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User declined or has not accepted notification permission');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
    }
  }

  /// FCM token al
  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('📱 FCM Token: $_fcmToken');

        // Otomatik olarak multiple topic'lere subscribe et
        await subscribeToTopic('all_users');
        await subscribeToTopic('test_notifications');
        await subscribeToTopic('ios_users');

        // Token'ı backend'e göndermeyi dene (kullanıcı login ise başarılı olur)
        await _sendTokenToBackend();
      } else {
        debugPrint('❌ FCM Token is null');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Token'ı backend'e gönder
  Future<void> _sendTokenToBackend() async {
    if (_fcmToken == null) {
      debugPrint('⚠️ FCM Token is null, cannot send to backend');
      return;
    }

    try {
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      final deviceId = _fcmToken; // Token'ı device ID olarak kullanıyoruz

      final request = PushTokenRequest(
        token: _fcmToken!,
        deviceType: deviceType,
        deviceId: deviceId,
        // Otomatik bildirimlerin kullanıcının YEREL saatine göre (gece değil)
        // gönderilmesi için cihazın UTC offset'i (dakika).
        timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
        // Arka plandaki push'ların doğru ses/kanalla gelmesi için seçili ses.
        notificationSound: NotifSoundPrefs.currentId,
        // Backend bildirim metinlerini uygulamanın SEÇİLİ dilinde üretsin.
        locale: await _appLanguageCode(),
      );

      final response = await _notificationService.storePushToken(request);

      if (response.isSuccess) {
        debugPrint('✅ FCM Token sent to backend successfully');
      } else {
        debugPrint('❌ Failed to send FCM token to backend: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Kullanıcı login olduğunda token gönder
  Future<void> sendTokenToBackendAfterLogin() async {
    await _sendTokenToBackend();
  }

  /// Foreground message handler
  /// easy_localization'ın kaydettiği seçili dil ('tr_TR' → 'tr'); yoksa cihaz dili.
  Future<String> _appLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('locale');
      if (saved != null && saved.isNotEmpty) {
        return saved.split(RegExp('[_-]')).first.toLowerCase();
      }
    } catch (_) {}
    return PlatformDispatcher.instance.locale.languageCode;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground notification received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Bugün ekranındaki zil anında tazelensin/çalsın.
    NotificationBus.notifyIncoming();

    // Foreground'da local notification göster (sesli)
    _showLocalNotification(message);
  }

  /// Local notification göster (sesli)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Seçili bildirim sesine göre kanal/ses (foreground gösterim).
    final snd = NotifSoundPrefs.current;

    // Android notification detayları
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      snd.channelId,
      'notifications.channelName'.tr(),
      channelDescription: 'notifications.channelDescription'.tr(),
      importance: Importance.high,
      priority: Priority.high,
      playSound: snd.playSound,
      sound: snd.raw != null
          ? RawResourceAndroidNotificationSound(snd.raw!)
          : null,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification detayları
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: snd.playSound,
      sound: snd.iosFile ?? 'default',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Notification açıldığında (tapped)
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('🔔 Notification opened');
    debugPrint('Data: ${message.data}');

    // Otomatik bildirim türüyse açılma metriği için backend'e bildir.
    final type = message.data['type']?.toString();
    const autoTypes = {'engagement', 'winback', 'streak', 'milestone'};
    if (type != null && autoTypes.contains(type)) {
      () async {
        try {
          await _notificationService.markAutoOpened(type);
        } catch (_) {
          // Metrik bildirimi başarısız olsa da sessizce geç.
        }
      }();
    }

    // Notification data'sına göre routing yapabilirsiniz
    // Örneğin:
    // if (message.data['type'] == 'task') {
    //   // Navigate to task detail
    // }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
