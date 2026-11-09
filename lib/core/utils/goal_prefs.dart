import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profil › Kişisel hedefler — kullanıcının kendi belirlediği hedefler.
/// Cihazda saklanır (SharedPreferences); varsayılan 10 görev / %30 tasarruf.
abstract final class GoalPrefs {
  static const _kTasks = 'goal_daily_tasks_v1';
  static const _kSavings = 'goal_savings_pct_v1';

  static final ValueNotifier<int> dailyTasks = ValueNotifier<int>(10);
  static final ValueNotifier<int> savingsPct = ValueNotifier<int>(30);

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      dailyTasks.value = p.getInt(_kTasks) ?? 10;
      savingsPct.value = p.getInt(_kSavings) ?? 30;
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> set({int? tasks, int? savings}) async {
    if (tasks != null) dailyTasks.value = tasks.clamp(1, 99);
    if (savings != null) savingsPct.value = savings.clamp(1, 100);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kTasks, dailyTasks.value);
      await p.setInt(_kSavings, savingsPct.value);
    } catch (_) {}
  }
}
