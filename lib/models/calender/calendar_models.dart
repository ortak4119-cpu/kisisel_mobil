import 'package:flutter/material.dart';

class CalendarEvent {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String eventType;
  final String eventDate;
  final String? eventTime;
  final String? endDate;
  final String? endTime;
  final bool allDay;
  final String? color;
  final String? category;
  final String? kind;
  final String? location;
  final String? recurrence;
  final String? tag;
  final List<int> reminderMinutes;
  final int? referenceId;
  final String? referenceType;

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.eventType,
    required this.eventDate,
    this.eventTime,
    this.endDate,
    this.endTime,
    this.allDay = false,
    this.color,
    this.category,
    this.kind,
    this.location,
    this.recurrence,
    this.tag,
    this.reminderMinutes = const [],
    this.referenceId,
    this.referenceType,
  });

  /// Backend artık `date:Y-m-d` cast'i ile sade tarih dizgesi dönüyor.
  /// Yine de eski ISO ('...T...') biçimine karşı dayanıklı olmak için T'den
  /// önceki kısmı alıyoruz — saat dilimi KAYDIRMASI YAPMADAN (eski +3 hile'si
  /// kaldırıldı; cihaz saat diliminden bağımsız doğru günü verir).
  static String _dateOnly(String raw) {
    if (raw.contains('T')) return raw.split('T').first;
    if (raw.contains(' ')) return raw.split(' ').first;
    return raw;
  }

  /// TIME kolonu "HH:MM:SS" dönebilir; forma uygun "HH:MM"e indir.
  static String? _hhmm(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    try {
      return CalendarEvent(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        description: json['description'],
        eventType: json['event_type'] as String,
        eventDate: _dateOnly(json['event_date'] as String),
        eventTime: _hhmm(json['event_time']),
        endDate: json['end_date'] != null
            ? _dateOnly(json['end_date'] as String)
            : null,
        endTime: _hhmm(json['end_time']),
        allDay: json['all_day'] == true || json['all_day'] == 1,
        color: json['color'] as String?,
        category: json['category'] as String?,
        kind: json['kind'] as String?,
        location: json['location'] as String?,
        recurrence: json['recurrence'] as String?,
        tag: json['tag'] as String?,
        reminderMinutes: (json['reminder_minutes'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        referenceId: json['reference_id'],
        referenceType: json['reference_type'],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ CalendarEvent.fromJson error: $e');
      debugPrint('❌ JSON data: $json');
      debugPrint('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'event_date': eventDate,
      'event_time': eventTime,
      'end_date': endDate,
      'end_time': endTime,
      'all_day': allDay,
      'color': color,
      'category': category,
      'kind': kind,
      'location': location,
      'recurrence': recurrence,
      'tag': tag,
      'reminder_minutes': reminderMinutes,
      'reference_id': referenceId,
      'reference_type': referenceType,
    };
  }

  CalendarEvent copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? eventType,
    String? eventDate,
    String? eventTime,
    String? endDate,
    String? endTime,
    bool? allDay,
    String? color,
    String? category,
    String? kind,
    String? location,
    String? recurrence,
    String? tag,
    List<int>? reminderMinutes,
    int? referenceId,
    String? referenceType,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      color: color ?? this.color,
      category: category ?? this.category,
      kind: kind ?? this.kind,
      location: location ?? this.location,
      recurrence: recurrence ?? this.recurrence,
      tag: tag ?? this.tag,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
    );
  }
}

class CalendarEventRequest {
  final String title;
  final String? description;
  final String eventType;
  final String eventDate;
  final String? eventTime;
  final String? endDate;
  final String? endTime;
  final bool allDay;
  final String? color;
  final String? category;
  final String? kind;
  final String? location;
  final String? recurrence;
  final String? tag;
  final List<int> reminderMinutes;
  final int? referenceId;
  final String? referenceType;

  CalendarEventRequest({
    required this.title,
    this.description,
    required this.eventType,
    required this.eventDate,
    this.eventTime,
    this.endDate,
    this.endTime,
    this.allDay = false,
    this.color,
    this.category,
    this.kind,
    this.location,
    this.recurrence,
    this.tag,
    this.reminderMinutes = const [],
    this.referenceId,
    this.referenceType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'event_type': eventType,
      'event_date': eventDate,
      'all_day': allDay,
      'reminder_minutes': reminderMinutes,
    };

    if (description != null) json['description'] = description;
    if (eventTime != null) json['event_time'] = eventTime;
    if (endDate != null) json['end_date'] = endDate;
    if (endTime != null) json['end_time'] = endTime;
    if (color != null) json['color'] = color;
    if (category != null) json['category'] = category;
    if (kind != null) json['kind'] = kind;
    if (location != null) json['location'] = location;
    if (recurrence != null) json['recurrence'] = recurrence;
    if (tag != null) json['tag'] = tag;
    if (referenceId != null) json['reference_id'] = referenceId;
    if (referenceType != null) json['reference_type'] = referenceType;

    return json;
  }
}

class CalendarEventUpdateRequest {
  final String? title;
  final String? description;
  final String? eventDate;
  final String? eventTime;
  final String? endDate;
  final String? endTime;
  final bool? allDay;
  final String? color;
  final String? category;
  final String? kind;
  final String? location;
  final String? recurrence;
  final String? tag;
  final List<int>? reminderMinutes;

  CalendarEventUpdateRequest({
    this.title,
    this.description,
    this.eventDate,
    this.eventTime,
    this.endDate,
    this.endTime,
    this.allDay,
    this.color,
    this.category,
    this.kind,
    this.location,
    this.recurrence,
    this.tag,
    this.reminderMinutes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (eventDate != null) json['event_date'] = eventDate;
    if (eventTime != null) json['event_time'] = eventTime;
    if (endDate != null) json['end_date'] = endDate;
    if (endTime != null) json['end_time'] = endTime;
    if (allDay != null) json['all_day'] = allDay;
    if (color != null) json['color'] = color;
    if (category != null) json['category'] = category;
    if (kind != null) json['kind'] = kind;
    if (location != null) json['location'] = location;
    if (recurrence != null) json['recurrence'] = recurrence;
    if (tag != null) json['tag'] = tag;
    if (reminderMinutes != null) json['reminder_minutes'] = reminderMinutes;

    return json;
  }
}
