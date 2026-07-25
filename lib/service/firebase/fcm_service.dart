import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification/notification_models.dart';
import '../notification/notification_service.dart';
import '../../core/init/locator.dart';

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
        debugPrint('🔔 Local notification tapped: ${response.payload}');
        // Burada notification tıklamasını handle edebilirsiniz
      },
    );

    // Android için notification channel oluştur
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Önemli Bildirimler',
        description: 'Bu kanal önemli bildirimler için kullanılır',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
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
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground notification received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Foreground'da local notification göster (sesli)
    _showLocalNotification(message);
  }

  /// Local notification göster (sesli)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Android notification detayları
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Önemli Bildirimler',
      channelDescription: 'Bu kanal önemli bildirimler için kullanılır',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification detayları
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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

    // Notification data'sına göre routing yapabilirsiniz
    // Örneğin:
    // if (message.data['type'] == 'task') {
    //   // Navigate to task detail
    // }
  }

  /// FCM token'ı backend'den sil (logout)
  Future<void> deleteTokenFromBackend() async {
    if (_fcmToken == null) {
      debugPrint('⚠️ FCM Token is null, cannot delete from backend');
      return;
    }

    try {
      final deviceId = _fcmToken!;
      final response = await _notificationService.deletePushToken(deviceId);

      if (response.isSuccess) {
        debugPrint('✅ FCM Token deleted from backend successfully');
      } else {
        debugPrint('❌ Failed to delete FCM token from backend: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting FCM token from backend: $e');
    }
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
