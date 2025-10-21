// Settings Model
class Settings {
  final int id;
  final int userId;
  final bool notificationsEnabled;
  final bool taskNotifications;
  final bool habitNotifications;
  final bool subscriptionNotifications;
  final bool noteNotifications;
  final bool diaryReminders;
  final bool socialNotifications;
  final bool darkMode;
  final String themeColor;
  final bool requireBiometric;
  final int autoLockTimeout;
  final String firstDayOfWeek;
  final String dateFormat;
  final String timeFormat;

  Settings({
    required this.id,
    required this.userId,
    required this.notificationsEnabled,
    required this.taskNotifications,
    required this.habitNotifications,
    required this.subscriptionNotifications,
    required this.noteNotifications,
    required this.diaryReminders,
    required this.socialNotifications,
    required this.darkMode,
    required this.themeColor,
    required this.requireBiometric,
    required this.autoLockTimeout,
    required this.firstDayOfWeek,
    required this.dateFormat,
    required this.timeFormat,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      taskNotifications: json['task_notifications'] as bool? ?? true,
      habitNotifications: json['habit_notifications'] as bool? ?? true,
      subscriptionNotifications: json['subscription_notifications'] as bool? ?? true,
      noteNotifications: json['note_notifications'] as bool? ?? true,
      diaryReminders: json['diary_reminders'] as bool? ?? true,
      socialNotifications: json['social_notifications'] as bool? ?? true,
      darkMode: json['dark_mode'] as bool? ?? false,
      themeColor: json['theme_color']?.toString() ?? 'purple',
      requireBiometric: json['require_biometric'] as bool? ?? false,
      autoLockTimeout: json['auto_lock_timeout'] as int? ?? 0,
      firstDayOfWeek: json['first_day_of_week']?.toString() ?? 'monday',
      dateFormat: json['date_format']?.toString() ?? 'DD/MM/YYYY',
      timeFormat: json['time_format']?.toString() ?? '24',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notifications_enabled': notificationsEnabled,
      'task_notifications': taskNotifications,
      'habit_notifications': habitNotifications,
      'subscription_notifications': subscriptionNotifications,
      'note_notifications': noteNotifications,
      'diary_reminders': diaryReminders,
      'social_notifications': socialNotifications,
      'dark_mode': darkMode,
      'theme_color': themeColor,
      'require_biometric': requireBiometric,
      'auto_lock_timeout': autoLockTimeout,
      'first_day_of_week': firstDayOfWeek,
      'date_format': dateFormat,
      'time_format': timeFormat,
    };
  }
}

// Settings Update Request
class SettingsUpdateRequest {
  final bool? notificationsEnabled;
  final bool? taskNotifications;
  final bool? habitNotifications;
  final bool? subscriptionNotifications;
  final bool? noteNotifications;
  final bool? diaryReminders;
  final bool? socialNotifications;
  final bool? darkMode;
  final String? themeColor;
  final bool? requireBiometric;
  final int? autoLockTimeout;
  final String? firstDayOfWeek;
  final String? dateFormat;
  final String? timeFormat;

  SettingsUpdateRequest({
    this.notificationsEnabled,
    this.taskNotifications,
    this.habitNotifications,
    this.subscriptionNotifications,
    this.noteNotifications,
    this.diaryReminders,
    this.socialNotifications,
    this.darkMode,
    this.themeColor,
    this.requireBiometric,
    this.autoLockTimeout,
    this.firstDayOfWeek,
    this.dateFormat,
    this.timeFormat,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notificationsEnabled != null) map['notifications_enabled'] = notificationsEnabled;
    if (taskNotifications != null) map['task_notifications'] = taskNotifications;
    if (habitNotifications != null) map['habit_notifications'] = habitNotifications;
    if (subscriptionNotifications != null) map['subscription_notifications'] = subscriptionNotifications;
    if (noteNotifications != null) map['note_notifications'] = noteNotifications;
    if (diaryReminders != null) map['diary_reminders'] = diaryReminders;
    if (socialNotifications != null) map['social_notifications'] = socialNotifications;
    if (darkMode != null) map['dark_mode'] = darkMode;
    if (themeColor != null) map['theme_color'] = themeColor;
    if (requireBiometric != null) map['require_biometric'] = requireBiometric;
    if (autoLockTimeout != null) map['auto_lock_timeout'] = autoLockTimeout;
    if (firstDayOfWeek != null) map['first_day_of_week'] = firstDayOfWeek;
    if (dateFormat != null) map['date_format'] = dateFormat;
    if (timeFormat != null) map['time_format'] = timeFormat;
    return map;
  }
}

// Profile Update Request
class ProfileUpdateRequest {
  final String? username;
  final String? displayName;
  final String? bio;
  final String? preferredLanguage;
  final String? profileVisibility;
  final bool? showLevel;
  final bool? showAchievements;
  final bool? showHabits;

  ProfileUpdateRequest({
    this.username,
    this.displayName,
    this.bio,
    this.preferredLanguage,
    this.profileVisibility,
    this.showLevel,
    this.showAchievements,
    this.showHabits,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map['username'] = username;
    if (displayName != null) map['display_name'] = displayName;
    if (bio != null) map['bio'] = bio;
    if (preferredLanguage != null) map['preferred_language'] = preferredLanguage;
    if (profileVisibility != null) map['profile_visibility'] = profileVisibility;
    if (showLevel != null) map['show_level'] = showLevel;
    if (showAchievements != null) map['show_achievements'] = showAchievements;
    if (showHabits != null) map['show_habits'] = showHabits;
    return map;
  }
}

// Profile Stats Model
class ProfileStats {
  final HabitStats habits;
  final TaskStats tasks;
  final NoteStats notes;
  final BudgetStatsProfile budget;
  final SubscriptionStatsProfile subscriptions;
  final DiaryStatsProfile diary;
  final SocialStats social;
  final GamificationStatsProfile gamification;

  ProfileStats({
    required this.habits,
    required this.tasks,
    required this.notes,
    required this.budget,
    required this.subscriptions,
    required this.diary,
    required this.social,
    required this.gamification,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      habits: HabitStats.fromJson(json['habits'] as Map<String, dynamic>),
      tasks: TaskStats.fromJson(json['tasks'] as Map<String, dynamic>),
      notes: NoteStats.fromJson(json['notes'] as Map<String, dynamic>),
      budget: BudgetStatsProfile.fromJson(json['budget'] as Map<String, dynamic>),
      subscriptions: SubscriptionStatsProfile.fromJson(json['subscriptions'] as Map<String, dynamic>),
      diary: DiaryStatsProfile.fromJson(json['diary'] as Map<String, dynamic>),
      social: SocialStats.fromJson(json['social'] as Map<String, dynamic>),
      gamification: GamificationStatsProfile.fromJson(json['gamification'] as Map<String, dynamic>),
    );
  }
}

class HabitStats {
  final int total;
  final int active;
  final int completedToday;
  final int currentStreak;

  HabitStats({
    required this.total,
    required this.active,
    required this.completedToday,
    required this.currentStreak,
  });

  factory HabitStats.fromJson(Map<String, dynamic> json) {
    return HabitStats(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      completedToday: json['completed_today'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
    );
  }
}

class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) {
    return TaskStats(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
    );
  }
}

class NoteStats {
  final int total;
  final int categories;
  final int locked;

  NoteStats({
    required this.total,
    required this.categories,
    required this.locked,
  });

  factory NoteStats.fromJson(Map<String, dynamic> json) {
    return NoteStats(
      total: json['total'] as int? ?? 0,
      categories: json['categories'] as int? ?? 0,
      locked: json['locked'] as int? ?? 0,
    );
  }
}

class BudgetStatsProfile {
  final double monthlyBudget;
  final double totalExpenses;
  final double thisMonthExpenses;

  BudgetStatsProfile({
    required this.monthlyBudget,
    required this.totalExpenses,
    required this.thisMonthExpenses,
  });

  factory BudgetStatsProfile.fromJson(Map<String, dynamic> json) {
    return BudgetStatsProfile(
      monthlyBudget: double.tryParse(json['monthly_budget']?.toString() ?? '0') ?? 0.0,
      totalExpenses: double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0.0,
      thisMonthExpenses: double.tryParse(json['this_month_expenses']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class SubscriptionStatsProfile {
  final int total;
  final int active;
  final double monthlyCost;

  SubscriptionStatsProfile({
    required this.total,
    required this.active,
    required this.monthlyCost,
  });

  factory SubscriptionStatsProfile.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatsProfile(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      monthlyCost: double.tryParse(json['monthly_cost']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DiaryStatsProfile {
  final int totalEntries;
  final int thisMonth;

  DiaryStatsProfile({
    required this.totalEntries,
    required this.thisMonth,
  });

  factory DiaryStatsProfile.fromJson(Map<String, dynamic> json) {
    return DiaryStatsProfile(
      totalEntries: json['total_entries'] as int? ?? 0,
      thisMonth: json['this_month'] as int? ?? 0,
    );
  }
}

class SocialStats {
  final int friends;
  final int followers;
  final int following;
  final int sharedHabits;

  SocialStats({
    required this.friends,
    required this.followers,
    required this.following,
    required this.sharedHabits,
  });

  factory SocialStats.fromJson(Map<String, dynamic> json) {
    return SocialStats(
      friends: json['friends'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      sharedHabits: json['shared_habits'] as int? ?? 0,
    );
  }
}

class GamificationStatsProfile {
  final int level;
  final int totalXp;
  final int achievementsUnlocked;

  GamificationStatsProfile({
    required this.level,
    required this.totalXp,
    required this.achievementsUnlocked,
  });

  factory GamificationStatsProfile.fromJson(Map<String, dynamic> json) {
    return GamificationStatsProfile(
      level: json['level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      achievementsUnlocked: json['achievements_unlocked'] as int? ?? 0,
    );
  }
}