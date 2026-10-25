import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/core/utils/nl_task_parser.dart';

void main() {
  final now = DateTime(2026, 10, 25, 10, 0); // Pazar
  test('tomorrow + time + priority (en)', () {
    final p = NlTaskParser.parse('Workout tomorrow 14:30 !2', 'tr', now: now);
    expect(p.title, 'Workout');
    expect(p.dueDate, DateTime(2026, 10, 26));
    expect(p.dueTime, const TimeOfDay(hour: 14, minute: 30));
    expect(p.priority, 2);
  });

  test('turkish keywords + tag', () {
    final p = NlTaskParser.parse('faturayı öde yarın 09:00 #ev !1', 'tr', now: now);
    expect(p.title, 'faturayı öde');
    expect(p.dueDate, DateTime(2026, 10, 26));
    expect(p.dueTime, const TimeOfDay(hour: 9, minute: 0));
    expect(p.tags, ['ev']);
    expect(p.priority, 1);
  });

  test('weekday → next occurrence', () {
    // 25 Oct 2026 = Pazar (Sunday). "pazartesi" → 26 Oct.
    final p = NlTaskParser.parse('toplantı pazartesi', 'tr', now: now);
    expect(p.dueDate, DateTime(2026, 10, 26));
    expect(p.title, 'toplantı');
  });

  test('dd.mm date + evening part', () {
    final p = NlTaskParser.parse('tatil 25.12 akşam', 'tr', now: now);
    expect(p.dueDate, DateTime(2026, 12, 25));
    expect(p.dueTime, const TimeOfDay(hour: 18, minute: 0));
    expect(p.title, 'tatil');
  });

  test('no tokens → plain title', () {
    final p = NlTaskParser.parse('sadece bir görev', 'tr', now: now);
    expect(p.hasAny, false);
    expect(p.title, 'sadece bir görev');
  });

  test('in X days (en)', () {
    final p = NlTaskParser.parse('call in 3 days', 'tr', now: now);
    expect(p.dueDate, DateTime(2026, 10, 28));
    expect(p.title, 'call');
  });
}
