// Paylaşımlı alışkanlık modelleri (SharedHabit + katılımcı + lider tablosu).

class SharedHabit {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? icon;
  final String? color;
  final String? joinCode;
  final int totalParticipants;
  final int totalCompletions;
  final int? createdByUserId;
  final bool isActive;
  final List<SharedHabitParticipant> participants;

  SharedHabit({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.icon,
    this.color,
    this.joinCode,
    this.totalParticipants = 0,
    this.totalCompletions = 0,
    this.createdByUserId,
    this.isActive = true,
    this.participants = const [],
  });

  factory SharedHabit.fromJson(Map<String, dynamic> j) {
    return SharedHabit(
      id: j['id'] as int,
      title: (j['title'] ?? '') as String,
      description: j['description'] as String?,
      category: j['category'] as String?,
      icon: j['icon'] as String?,
      color: j['color'] as String?,
      joinCode: j['join_code'] as String?,
      totalParticipants: (j['total_participants'] as int?) ?? 0,
      totalCompletions: (j['total_completions'] as int?) ?? 0,
      createdByUserId: j['created_by_user_id'] as int? ?? j['creator_id'] as int?,
      isActive: j['is_active'] == true || j['is_active'] == 1,
      participants: (j['participants'] as List?)
              ?.map((e) =>
                  SharedHabitParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class SharedHabitParticipant {
  final int id;
  final int userId;
  final String role; // admin | member
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final String? username;
  final String? displayName;
  final String? profilePictureUrl;

  SharedHabitParticipant({
    required this.id,
    required this.userId,
    required this.role,
    this.totalCompletions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.username,
    this.displayName,
    this.profilePictureUrl,
  });

  String get name =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : (username ?? 'Kullanıcı');

  factory SharedHabitParticipant.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return SharedHabitParticipant(
      id: j['id'] as int,
      userId: (j['user_id'] as int?) ?? (user?['id'] as int?) ?? 0,
      role: (j['role'] ?? 'member') as String,
      totalCompletions: (j['total_completions'] as int?) ?? 0,
      currentStreak: (j['current_streak'] as int?) ?? 0,
      longestStreak: (j['longest_streak'] as int?) ?? 0,
      username: user?['username'] as String?,
      displayName: user?['display_name'] as String?,
      profilePictureUrl: user?['profile_picture_url'] as String?,
    );
  }
}

// Paylaşımlı alışkanlık oluşturma isteği.
class SharedHabitRequest {
  final String title;
  final String? description;
  final String category;
  final String? icon;
  final String? color;
  final String timePeriod; // daily | weekly | monthly
  final String targetFrequencyType; // times_per_day | days_per_week | continuous
  final int targetFrequencyValue;
  final bool enableLeaderboard;

  SharedHabitRequest({
    required this.title,
    this.description,
    this.category = 'health_fitness',
    this.icon = 'star',
    this.color = '#F6A821',
    this.timePeriod = 'daily',
    this.targetFrequencyType = 'times_per_day',
    this.targetFrequencyValue = 1,
    this.enableLeaderboard = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'icon': icon,
        'color': color,
        'time_period': timePeriod,
        'target_frequency_type': targetFrequencyType,
        'target_frequency_value': targetFrequencyValue,
        'enable_leaderboard': enableLeaderboard,
      };
}
