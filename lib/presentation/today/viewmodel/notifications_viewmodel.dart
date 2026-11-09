import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/init/locator.dart';
import '../../../core/utils/notification_bus.dart';
import '../../../models/notification/notification_models.dart';
import '../../../service/notification/notification_service.dart';

/// Bugün ekranındaki bildirim zili için: son bildirimler + okunmamış sayısı.
/// 60 sn'de bir ve ön plana push gelince tazelenir.
class NotificationsViewModel extends ChangeNotifier {
  final INotificationService _svc = locator.get<INotificationService>();

  List<AppNotification> _items = [];
  List<AppNotification> get items => _items;

  int get unread => _items.where((n) => !n.isRead).length;
  bool _loading = false;
  bool get loading => _loading;

  Timer? _timer;

  NotificationsViewModel() {
    load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => load());
    NotificationBus.ping.addListener(_onPing);
  }

  void _onPing() => load();

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      final r = await _svc.getNotifications(perPage: 30);
      if (r.isSuccess && r.data != null) {
        _items = r.data!.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('notifications load error: $e');
    } finally {
      _loading = false;
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    _items = _items
        .map((x) => x.id == n.id ? _copyRead(x) : x)
        .toList(growable: false);
    notifyListeners();
    try {
      await _svc.markAsRead(n.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (unread == 0) return;
    _items = _items.map(_copyRead).toList(growable: false);
    notifyListeners();
    try {
      await _svc.markAllAsRead();
    } catch (_) {}
  }

  AppNotification _copyRead(AppNotification x) => AppNotification(
        id: x.id,
        userId: x.userId,
        notificationType: x.notificationType,
        title: x.title,
        message: x.message,
        referenceId: x.referenceId,
        referenceType: x.referenceType,
        scheduledTime: x.scheduledTime,
        sentAt: x.sentAt,
        isRead: true,
        isDelivered: x.isDelivered,
        createdAt: x.createdAt,
      );

  /// Bildirim hangi alt menüye götürür? (Bugün=0, Notlar=1, Görev=2, Alışk=3,
  /// Takvim=4, Finans=5, Profil=6). Eşleşme yoksa null (Bugün'de kal).
  static int? tabFor(AppNotification n) {
    int? byRef() {
      switch (n.referenceType) {
        case 'note':
          return 1;
        case 'task':
          return 2;
        case 'habit':
          return 3;
        case 'friend':
          return 6;
      }
      return null;
    }

    switch (n.notificationType) {
      case 'friend_request':
      case 'friend_accept':
        return 6;
      case 'share_invite':
      case 'share_accept':
        return byRef();
      case 'shared_note_edited':
        return byRef() ?? 1;
      case 'shared_task_complete':
        return byRef() ?? 2;
      case 'shared_habit_join':
      case 'shared_habit_complete':
        return byRef() ?? 3;
      case 'task_reminder':
        return 2;
      case 'habit_reminder':
      case 'streak':
        return 3;
      case 'subscription_reminder':
      case 'payment_reminder':
        return 5;
      case 'calendar_event_reminder':
        return 4;
      case 'achievement':
      case 'milestone':
        return 6;
    }
    return byRef();
  }

  @override
  void dispose() {
    _timer?.cancel();
    NotificationBus.ping.removeListener(_onPing);
    super.dispose();
  }
}
