// Level Info Model
class LevelInfo {
  final int currentLevel;
  final int currentXp;
  final int totalXp;
  final int nextLevelXp;
  final double progressPercentage;
  final int dailyStreak;
  final int longestDailyStreak;
  final int totalLevelUps;
  final DateTime? lastLevelUpAt;
  final int? globalRank;
  final int? countryRank;

  LevelInfo({
    required this.currentLevel,
    required this.currentXp,
    required this.totalXp,
    required this.nextLevelXp,
    required this.progressPercentage,
    required this.dailyStreak,
    required this.longestDailyStreak,
    required this.totalLevelUps,
    this.lastLevelUpAt,
    this.globalRank,
    this.countryRank,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      currentLevel: json['current_level'] as int,
      currentXp: json['current_xp'] as int,
      totalXp: json['total_xp'] as int,
      nextLevelXp: json['next_level_xp'] as int,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      dailyStreak: json['daily_streak'] as int,
      longestDailyStreak: json['longest_daily_streak'] as int,
      totalLevelUps: json['total_level_ups'] as int,
      lastLevelUpAt: json['last_level_up_at'] != null
          ? DateTime.parse(json['last_level_up_at'] as String)
          : null,
      globalRank: json['global_rank'] as int?,
      countryRank: json['country_rank'] as int?,
    );
  }
}

// XP Transaction Model
class XPTransaction {
  final int id;
  final int amount;
  final String actionCode;
  final String description;
  final int baseAmount;
  final double streakMultiplier;
  final double premiumMultiplier;
  final double totalMultiplier;
  final DateTime earnedAt;

  XPTransaction({
    required this.id,
    required this.amount,
    required this.actionCode,
    required this.description,
    required this.baseAmount,
    required this.streakMultiplier,
    required this.premiumMultiplier,
    required this.totalMultiplier,
    required this.earnedAt,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      id: json['id'] as int,
      amount: json['amount'] as int,
      actionCode: json['action_code'] as String,
      description: json['description'] as String,
      baseAmount: json['base_amount'] as int,
      streakMultiplier: (json['streak_multiplier'] as num).toDouble(),
      premiumMultiplier: (json['premium_multiplier'] as num).toDouble(),
      totalMultiplier: (json['total_multiplier'] as num).toDouble(),
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}

// Achievement Model
class Achievement {
  final int id;
  final String code;
  final String? titleKey;
  final String? descriptionKey;
  final String? icon;
  final String? badgeImageUrl;
  final String category;
  final String rarity;
  final int xpReward;
  final String? badgeColor;
  final String requirementType;
  final int requirementValue;
  final bool isCompleted;
  final int currentProgress;
  final double progressPercentage;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.code,
    this.titleKey,
    this.descriptionKey,
    this.icon,
    this.badgeImageUrl,
    required this.category,
    required this.rarity,
    required this.xpReward,
    this.badgeColor,
    required this.requirementType,
    required this.requirementValue,
    required this.isCompleted,
    required this.currentProgress,
    required this.progressPercentage,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      code: json['code'] as String,
      titleKey: json['title_key'] as String?,
      descriptionKey: json['description_key'] as String?,
      icon: json['icon'] as String?,
      badgeImageUrl: json['badge_image_url'] as String?,
      category: json['category'] as String,
      rarity: json['rarity'] as String,
      xpReward: json['xp_reward'] as int,
      badgeColor: json['badge_color'] as String?,
      requirementType: json['requirement_type'] as String,
      requirementValue: json['requirement_value'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
      currentProgress: json['current_progress'] as int? ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }
}

// Achievement Progress Model
class AchievementProgress {
  final int currentProgress;
  final bool isCompleted;
  final DateTime? unlockedAt;
  final double progressPercentage;

  AchievementProgress({
    required this.currentProgress,
    required this.isCompleted,
    this.unlockedAt,
    required this.progressPercentage,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      currentProgress: json['current_progress'] as int,
      isCompleted: json['is_completed'] as bool,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
    );
  }
}

// Leaderboard Entry Model
class LeaderboardEntry {
  final int rank;
  final LeaderboardUser user;
  final int level;
  final int totalXp;
  final int dailyStreak;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.level,
    required this.totalXp,
    required this.dailyStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      user: LeaderboardUser.fromJson(json['user'] as Map<String, dynamic>),
      level: json['level'] as int,
      totalXp: json['total_xp'] as int,
      dailyStreak: json['daily_streak'] as int,
    );
  }
}

// Leaderboard User Model
class LeaderboardUser {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  final bool? isMe;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    this.isMe,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      isMe: json['is_me'] as bool?,
    );
  }
}