import 'package:flutter/material.dart';

class CalendarEvent {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String eventType;
  final String eventDate;
  final String? eventTime;
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
    this.referenceId,
    this.referenceType,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    try {
      // event_date ISO8601 formatında geliyor, sadece tarihi alalım
      String eventDate = json['event_date'] as String;
      if (eventDate.contains('T')) {
        eventDate = eventDate.split('T')[0]; // 2025-10-28
      }

      return CalendarEvent(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        description: json['description'],
        eventType: json['event_type'] as String,
        eventDate: eventDate,
        eventTime: json['event_time'],
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
  final int? referenceId;
  final String? referenceType;

  CalendarEventRequest({
    required this.title,
    this.description,
    required this.eventType,
    required this.eventDate,
    this.eventTime,
    this.referenceId,
    this.referenceType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'event_type': eventType,
      'event_date': eventDate,
    };

    if (description != null) json['description'] = description;
    if (eventTime != null) json['event_time'] = eventTime;
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

  CalendarEventUpdateRequest({
    this.title,
    this.description,
    this.eventDate,
    this.eventTime,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (eventDate != null) json['event_date'] = eventDate;
    if (eventTime != null) json['event_time'] = eventTime;

    return json;
  }
}

class MonthViewResponse {
  final int year;
  final int month;
  final List<CalendarEvent> events;
  final int total;

  MonthViewResponse({
    required this.year,
    required this.month,
    required this.events,
    required this.total,
  });

  factory MonthViewResponse.fromJson(Map<String, dynamic> json) {
    return MonthViewResponse(
      year: json['year'] as int,
      month: json['month'] as int,
      events: (json['events'] as List)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'events': events.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

class DayViewResponse {
  final String date;
  final List<CalendarEvent> events;
  final int total;

  DayViewResponse({
    required this.date,
    required this.events,
    required this.total,
  });

  factory DayViewResponse.fromJson(Map<String, dynamic> json) {
    return DayViewResponse(
      date: json['date'] as String,
      events: (json['events'] as List)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'events': events.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

enum CalendarEventType {
  habit('habit'),
  task('task'),
  subscription('subscription'),
  diary('diary'),
  reminder('reminder'),
  custom('custom');

  final String value;
  const CalendarEventType(this.value);

  static CalendarEventType fromString(String value) {
    return CalendarEventType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => CalendarEventType.custom,
    );
  }

  @override
  String toString() => value;
}