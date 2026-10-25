import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/init/locator.dart';

/// Ana ekran takvim widget'ını günceller: bugünün ilk 3 etkinlik/görevini
/// (başlık + saat) home_widget üzerinden Android'e yazar.
class CalendarWidgetService {
  static Future<void> update() async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${_p(now.month)}-${_p(now.day)}';

      final items = <_AgendaItem>[];

      // Bugünün takvim etkinlikleri
      final evResp = await calendarService.getAllEvents(
        startDate: today,
        endDate: today,
      );
      if (evResp.isSuccess && evResp.data != null) {
        for (final e in evResp.data!) {
          if (e.eventDate != today) continue;
          final time = e.allDay
              ? 'Tüm gün'
              : (e.eventTime != null && e.eventTime!.length >= 5
                  ? e.eventTime!.substring(0, 5)
                  : '');
          final key = e.allDay
              ? '00:00'
              : (time.isEmpty ? '99:98' : time);
          items.add(_AgendaItem(key, time, e.title));
        }
      }

      // Bugün biten, tamamlanmamış görevler
      final tResp = await taskService.getAllTasks();
      if (tResp.isSuccess && tResp.data != null) {
        for (final t in tResp.data!) {
          if (t.isCompleted || t.dueDate == null) continue;
          if (!t.dueDate!.startsWith(today)) continue;
          final time = (t.dueTime != null && t.dueTime!.length >= 5)
              ? t.dueTime!.substring(0, 5)
              : '';
          final key = time.isEmpty ? '99:99' : time;
          items.add(_AgendaItem(key, time, t.title));
        }
      }

      items.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      final top = items.take(3).toList();

      await HomeWidget.saveWidgetData<int>('cal_count', top.length);
      for (var i = 0; i < 3; i++) {
        final it = i < top.length ? top[i] : null;
        await HomeWidget.saveWidgetData<String>(
          'cal_title_${i + 1}',
          (it?.title.trim().isEmpty ?? true) ? '—' : it!.title.trim(),
        );
        await HomeWidget.saveWidgetData<String>(
          'cal_time_${i + 1}',
          it?.time ?? '',
        );
      }

      await HomeWidget.updateWidget(androidName: 'CalendarWidgetProvider');
    } catch (e) {
      debugPrint('Calendar widget update error: $e');
    }
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}

class _AgendaItem {
  final String sortKey;
  final String time;
  final String title;
  _AgendaItem(this.sortKey, this.time, this.title);
}
