// Habit Model
class Habit {
  final int id;
  final String title;
  final String? description;
  final String category;
  final String? icon;
  final String? color;
  final String difficultyLevel;
  final String timePeriod;
  final List<int>? specificDays;
  final String targetFrequencyType;
  final int? targetFrequencyValue;
  final bool reminderEnabled;
  final List<String>? reminderTimes;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final String? whyDescription;
  final String? motivationQuote;
  final String? cue;
  final String? reward;
  final bool isPublic;
  final bool isActive;
  final int? sharedHabitId;
  final bool completedToday;
  final bool skippedToday;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.icon,
    this.color,
    required this.difficultyLevel,
    required this.timePeriod,
    this.specificDays,
    required this.targetFrequencyType,
    this.targetFrequencyValue,
    required this.reminderEnabled,
    this.reminderTimes,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    this.whyDescription,
    this.motivationQuote,
    this.cue,
    this.reward,
    required this.isPublic,
    required this.isActive,
    this.sharedHabitId,
    required this.completedToday,
    required this.skippedToday,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      difficultyLevel: json['difficulty_level'] as String,
      timePeriod: json['time_period'] as String,
      specificDays: (json['specific_days'] as List?)?.cast<int>(),
      targetFrequencyType: json['target_frequency_type'] as String,
      targetFrequencyValue: json['target_frequency_value'] as int?,
      reminderEnabled: json['reminder_enabled'] as bool,
      reminderTimes: (json['reminder_times'] as List?)?.cast<String>(),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalCompletions: json['total_completions'] as int? ?? 0,
      whyDescription: json['why_description'] as String?,
      motivationQuote: json['motivation_quote'] as String?,
      cue: json['cue'] as String?,
      reward: json['reward'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sharedHabitId: json['shared_habit_id'] as int?,
      completedToday: json['completed_today'] as bool? ?? false,
      skippedToday: json['skipped_today'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'difficulty_level': difficultyLevel,
      'time_period': timePeriod,
      'specific_days': specificDays,
      'target_frequency_type': targetFrequencyType,
      'target_frequency_value': targetFrequencyValue,
      'reminder_enabled': reminderEnabled,
      'reminder_times': reminderTimes,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completions': totalCompletions,
      'why_description': whyDescription,
      'motivation_quote': motivationQuote,
      'cue': cue,
      'reward': reward,
      'is_public': isPublic,
      'is_active': isActive,
      'shared_habit_id': sharedHabitId,
      'completed_today': completedToday,
      'skipped_today': skippedToday,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Habit Log Model
class HabitLog {
  final int id;
  final int habitId;
  final DateTime logDate;
  final bool completed;
  final DateTime? completedAt;
  final bool skipped;
  final String? skipReason;
  final String? notes;
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.completed,
    this.completedAt,
    required this.skipped,
    this.skipReason,
    this.notes,
    required this.createdAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as int,
      habitId: json['habit_id'] as int,
      logDate: DateTime.parse(json['log_date'] as String),
      completed: json['completed'] as bool,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      skipped: json['skipped'] as bool? ?? false,
      skipReason: json['skip_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// Habit Stats Model
class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final double completionRate;
  final int completedThisWeek;
  final int completedThisMonth;
  final String? lastCompleted;

  HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.completionRate,
    required this.completedThisWeek,
    required this.completedThisMonth,
    this.lastCompleted,
  });

  factory HabitStats.fromJson(Map<String, dynamic> json) {
    return HabitStats(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      totalCompletions: json['total_completions'] as int,
      completionRate: (json['completion_rate'] as num).toDouble(),
      completedThisWeek: json['completed_this_week'] as int,
      completedThisMonth: json['completed_this_month'] as int,
      lastCompleted: json['last_completed'] as String?,
    );
  }
}

// Create/Update Habit Request
class HabitRequest {
  final String title;
  final String? description;
  final String category;
  final String? icon;
  final String? color;
  final String difficultyLevel;
  final String timePeriod;
  final List<int>? specificDays;
  final String targetFrequencyType;
  final int? targetFrequencyValue;
  final bool reminderEnabled;
  final List<String>? reminderTimes;
  final String? whyDescription;
  final String? motivationQuote;
  final String? cue;
  final String? reward;
  final bool isPublic;

  HabitRequest({
    required this.title,
    this.description,
    required this.category,
    this.icon,
    this.color,
    required this.difficultyLevel,
    required this.timePeriod,
    this.specificDays,
    required this.targetFrequencyType,
    this.targetFrequencyValue,
    required this.reminderEnabled,
    this.reminderTimes,
    this.whyDescription,
    this.motivationQuote,
    this.cue,
    this.reward,
    required this.isPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'difficulty_level': difficultyLevel,
      'time_period': timePeriod,
      'specific_days': specificDays,
      'target_frequency_type': targetFrequencyType,
      'target_frequency_value': targetFrequencyValue,
      'reminder_enabled': reminderEnabled,
      'reminder_times': reminderTimes,
      'why_description': whyDescription,
      'motivation_quote': motivationQuote,
      'cue': cue,
      'reward': reward,
      'is_public': isPublic,
    };
  }
}

// Complete Habit Request
class CompleteHabitRequest {
  final String date;
  final String? notes;

  CompleteHabitRequest({
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'notes': notes,
    };
  }
}

// Skip Habit Request
class SkipHabitRequest {
  final String date;
  final String? reason;

  SkipHabitRequest({
    required this.date,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'reason': reason,
    };
  }
}