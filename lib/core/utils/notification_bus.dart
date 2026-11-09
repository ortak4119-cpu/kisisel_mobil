import 'package:flutter/foundation.dart';

/// Uygulama içi bildirim "nabzı": FCM ön planda mesaj alınca artar; Bugün
/// ekranındaki zil bunu dinleyip listeyi tazeler (anında çalmaya başlar).
abstract final class NotificationBus {
  static final ValueNotifier<int> ping = ValueNotifier<int>(0);

  static void notifyIncoming() => ping.value++;
}
