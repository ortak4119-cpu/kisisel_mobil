import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final INotificationService _notificationService = locator.get<INotificationService>();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// FCM servisini başlat
  Future<void> initialize() async {
    try {
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

    // Burada local notification gösterebilirsiniz
    // Veya in-app notification UI'ı gösterebilirsiniz
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
