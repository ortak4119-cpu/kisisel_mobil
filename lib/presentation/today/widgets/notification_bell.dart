import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/design/app_design.dart';
import '../../../core/utils/animation_prefs.dart';
import '../../../models/notification/notification_models.dart';
import '../viewmodel/notifications_viewmodel.dart';

/// Sağ üst bildirim zili. Okunmamış bildirim varsa SÜREKLİ çalar (sallanır),
/// yoksa sabit durur. Üstünde okunmamış sayısı rozeti.
class RingingBell extends StatefulWidget {
  final int count;
  final bool open;
  final VoidCallback onTap;
  final AppColors c;
  const RingingBell({
    super.key,
    required this.count,
    required this.open,
    required this.onTap,
    required this.c,
  });

  @override
  State<RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<RingingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _sync();
  }

  @override
  void didUpdateWidget(covariant RingingBell old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final shouldRing = widget.count > 0 && AnimationPrefs.isOn;
    if (shouldRing && !_ring.isAnimating) {
      _ring.repeat();
    } else if (!shouldRing && _ring.isAnimating) {
      _ring.stop();
      _ring.value = 0;
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  // Çalma eğrisi: periyodun ilk %45'inde sönümlü salınım, kalanı dinlenme.
  double _angle(double t) {
    if (t > 0.45) return 0;
    final p = t / 0.45;
    final decay = (1 - p);
    return math.sin(p * math.pi * 5) * 0.28 * decay;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final has = widget.count > 0;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.open
              ? Color.alphaBlend(c.accent.withValues(alpha: .18), c.card)
              : c.card,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ring,
              builder: (_, child) => Transform.rotate(
                angle: _angle(_ring.value),
                alignment: Alignment.topCenter,
                child: child,
              ),
              child: Icon(
                has
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 22,
                color: has ? c.accent : c.textPrimary,
              ),
            ),
            if (has)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2574C),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.bg, width: 1.5),
                  ),
                  child: Text(
                    widget.count > 9 ? '9+' : '${widget.count}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zile basınca başlığın altından aşağı açılan bildirim listesi.
class NotificationPanel extends StatelessWidget {
  final NotificationsViewModel vm;
  final AppColors c;
  final void Function(int tab) onOpenTab;
  final VoidCallback onClose;
  const NotificationPanel({
    super.key,
    required this.vm,
    required this.c,
    required this.onOpenTab,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final items = vm.items.take(12).toList();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('today.notifications'.tr(),
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary)),
                ),
                if (vm.unread > 0)
                  TextButton(
                    onPressed: vm.markAllRead,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('today.markAllRead'.tr(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.accent)),
                  ),
                IconButton(
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Row(children: [
                Icon(Icons.notifications_off_outlined,
                    size: 18, color: c.textMuted),
                const SizedBox(width: 8),
                Text('today.noNotifications'.tr(),
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
              ]),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              _row(context, items[i]),
              if (i != items.length - 1)
                Divider(height: 1, indent: 60, color: c.border),
            ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppNotification n) {
    final (icon, color) = _style(n);
    final tab = NotificationsViewModel.tabFor(n);
    return InkWell(
      onTap: () {
        vm.markRead(n);
        onClose();
        if (tab != null) onOpenTab(tab);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .15), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, height: 1.3, color: c.textSecondary)),
                  const SizedBox(height: 3),
                  Text(_ago(n.createdAt),
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(children: [
              if (!n.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                ),
              if (tab != null) ...[
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _style(AppNotification n) {
    switch (n.notificationType) {
      case 'friend_request':
      case 'friend_accept':
        return (Icons.person_add_alt_1_rounded, const Color(0xFF4C9AFF));
      case 'share_invite':
      case 'share_accept':
      case 'shared_note_edited':
      case 'shared_task_complete':
      case 'shared_habit_join':
      case 'shared_habit_complete':
        return (Icons.group_rounded, const Color(0xFF9D8DF1));
      case 'task_reminder':
        return (Icons.check_box_outlined, const Color(0xFF68B37A));
      case 'habit_reminder':
      case 'streak':
        return (Icons.local_fire_department_rounded, const Color(0xFFF6A821));
      case 'subscription_reminder':
      case 'payment_reminder':
        return (Icons.account_balance_wallet_outlined, const Color(0xFF7B93D8));
      case 'calendar_event_reminder':
        return (Icons.event_rounded, const Color(0xFF9D8DF1));
      case 'achievement':
      case 'milestone':
        return (Icons.emoji_events_rounded, const Color(0xFFF2B32C));
      default:
        return (Icons.notifications_rounded, c.accent);
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return 'today.justNow'.tr();
    if (d.inHours < 1) return 'today.minutesAgo'.tr(args: ['${d.inMinutes}']);
    if (d.inDays < 1) return 'today.hoursAgo'.tr(args: ['${d.inHours}']);
    return 'today.daysAgo'.tr(args: ['${d.inDays}']);
  }
}
