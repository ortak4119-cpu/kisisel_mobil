import 'package:flutter/material.dart';

/// Doğal dilde yazılan görev metninden tarih/saat/öncelik/etiket ayıklar.
/// Cihaz-içi, harici servis/anahtar gerektirmez. TR + EN anahtar kelimeleri ve
/// dilden bağımsız mutlak biçimleri (15:00, 25.10, #etiket, !1) destekler.
class ParsedTask {
  final String title;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final int? priority; // 0/1/2
  final List<String> tags;

  const ParsedTask({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.priority,
    this.tags = const [],
  });

  bool get hasAny =>
      dueDate != null || dueTime != null || priority != null || tags.isNotEmpty;
}

class NlTaskParser {
  /// [now] test edilebilirlik için enjekte edilebilir.
  static ParsedTask parse(String raw, String lang, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var text = ' ${raw.trim()} ';
    DateTime? date;
    TimeOfDay? time;
    int? priority;
    final tags = <String>[];

    // ---- Etiketler: #kelime ----
    text = text.replaceAllMapped(RegExp(r'#([\p{L}0-9_]+)', unicode: true),
        (m) {
      final t = m.group(1)!;
      if (!tags.contains(t)) tags.add(t);
      return ' ';
    });

    // ---- Öncelik: !1 / !2 / !0 / !! / anahtar kelimeler ----
    final pr = _parsePriority(text, lang);
    if (pr != null) {
      priority = pr.$1;
      text = pr.$2;
    }

    // ---- Saat: HH:MM veya HH.MM ----
    final tm = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b').firstMatch(text);
    if (tm != null) {
      time = TimeOfDay(
          hour: int.parse(tm.group(1)!), minute: int.parse(tm.group(2)!));
      text = text.replaceRange(tm.start, tm.end, ' ');
    }

    // ---- Gün bölümü kelimeleri (saat yoksa) ----
    if (time == null) {
      final partMap = <List<String>, TimeOfDay>{
        ['sabah', 'morning']: const TimeOfDay(hour: 9, minute: 0),
        ['öğlen', 'öğle', 'noon']: const TimeOfDay(hour: 12, minute: 0),
        ['akşam', 'evening', 'tonight', 'gece', 'night']:
            const TimeOfDay(hour: 18, minute: 0),
      };
      for (final e in partMap.entries) {
        for (final w in e.key) {
          final re = RegExp(r'\b' + w + r'\b', caseSensitive: false, unicode: true);
          if (re.hasMatch(text)) {
            time = e.value;
            text = text.replaceAll(re, ' ');
            break;
          }
        }
        if (time != null) break;
      }
    }

    // ---- Tarih ----
    final d = _parseDate(text, lang, today);
    if (d != null) {
      date = d.$1;
      text = d.$2;
    }

    // ---- Başlık: kalanı temizle ----
    final title = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTask(
      title: title,
      dueDate: date,
      dueTime: time,
      priority: priority,
      tags: tags,
    );
  }

  static (int, String)? _parsePriority(String text, String lang) {
    // !1 / !2 / !0
    final num = RegExp(r'(^|\s)!([0-2])\b').firstMatch(text);
    if (num != null) {
      return (int.parse(num.group(2)!), text.replaceRange(num.start, num.end, ' '));
    }
    // !!! veya !! → yüksek
    final bang = RegExp(r'(^|\s)!!+').firstMatch(text);
    if (bang != null) {
      return (2, text.replaceRange(bang.start, bang.end, ' '));
    }
    // Anahtar kelimeler (!önekli ya da düz)
    const high = ['acil', 'yüksek', 'urgent', 'high', 'important', 'önemli'];
    const low = ['düşük', 'low'];
    const mid = ['orta', 'medium', 'normal'];
    for (final entry in [(2, high), (1, mid), (0, low)]) {
      for (final w in entry.$2) {
        final re = RegExp(r'!?\b' + w + r'\b', caseSensitive: false, unicode: true);
        final m = re.firstMatch(text);
        // Yalnız "!" önekliyse ya da tek başına güçlü kelimeyse al.
        if (m != null && (m.group(0)!.startsWith('!'))) {
          return (entry.$1, text.replaceRange(m.start, m.end, ' '));
        }
      }
    }
    return null;
  }

  static (DateTime, String)? _parseDate(String text, String lang, DateTime today) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    // bugün / today
    for (final w in ['bugün', 'today']) {
      final re = RegExp(r'\b' + w + r'\b', caseSensitive: false, unicode: true);
      if (re.hasMatch(text)) return (dateOnly(today), text.replaceAll(re, ' '));
    }
    // yarın / tomorrow
    for (final w in ['yarın', 'tomorrow']) {
      final re = RegExp(r'\b' + w + r'\b', caseSensitive: false, unicode: true);
      if (re.hasMatch(text)) {
        return (dateOnly(today.add(const Duration(days: 1))), text.replaceAll(re, ' '));
      }
    }
    // "X gün sonra" / "in X days"
    final inDaysTr = RegExp(r'\b(\d{1,3})\s*gün\s*sonra\b', caseSensitive: false, unicode: true).firstMatch(text);
    final inDaysEn = RegExp(r'\bin\s*(\d{1,3})\s*days?\b', caseSensitive: false).firstMatch(text);
    final inDays = inDaysTr ?? inDaysEn;
    if (inDays != null) {
      final n = int.parse(inDays.group(1)!);
      return (dateOnly(today.add(Duration(days: n))), text.replaceRange(inDays.start, inDays.end, ' '));
    }
    // Hafta günleri → bir sonraki o gün
    const days = {
      1: ['pazartesi', 'monday', 'pzt', 'mon'],
      2: ['salı', 'tuesday', 'sal', 'tue'],
      3: ['çarşamba', 'wednesday', 'çar', 'wed'],
      4: ['perşembe', 'thursday', 'per', 'thu'],
      5: ['cuma', 'friday', 'cum', 'fri'],
      6: ['cumartesi', 'saturday', 'cmt', 'sat'],
      7: ['pazar', 'sunday', 'paz', 'sun'],
    };
    for (final e in days.entries) {
      for (final w in e.value) {
        final re = RegExp(r'\b' + w + r'\b', caseSensitive: false, unicode: true);
        if (re.hasMatch(text)) {
          var delta = (e.key - today.weekday) % 7;
          if (delta <= 0) delta += 7; // her zaman gelecekteki gün
          return (dateOnly(today.add(Duration(days: delta))), text.replaceAll(re, ' '));
        }
      }
    }
    // dd.mm veya dd/mm (yıl opsiyonel)
    final dm = RegExp(r'\b(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?\b').firstMatch(text);
    if (dm != null) {
      final day = int.parse(dm.group(1)!);
      final mon = int.parse(dm.group(2)!);
      if (day >= 1 && day <= 31 && mon >= 1 && mon <= 12) {
        var year = dm.group(3) != null ? int.parse(dm.group(3)!) : today.year;
        if (year < 100) year += 2000;
        var dt = DateTime(year, mon, day);
        if (dm.group(3) == null && dt.isBefore(dateOnly(today))) {
          dt = DateTime(year + 1, mon, day); // geçmişse gelecek yıl
        }
        return (dt, text.replaceRange(dm.start, dm.end, ' '));
      }
    }
    return null;
  }
}
