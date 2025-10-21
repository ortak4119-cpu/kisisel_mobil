// User Model
class User {
  final int id;
  final String username;
  final String? email;
  final String displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? coverImageUrl;
  final String preferredLanguage;
  final bool isGuest;
  final bool isVerified;
  final String? subscriptionType;
  final String? subscriptionStatus;
  final String profileVisibility;
  final bool showLevel;
  final bool showAchievements;
  final bool showHabits;
  final UserLevel level;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.coverImageUrl,
    required this.preferredLanguage,
    required this.isGuest,
    required this.isVerified,
    this.subscriptionType,
    this.subscriptionStatus,
    required this.profileVisibility,
    required this.showLevel,
    required this.showAchievements,
    required this.showHabits,
    required this.level,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'tr',
      isGuest: json['is_guest'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      subscriptionType: json['subscription_type'] as String?,
      subscriptionStatus: json['subscription_status'] as String?,
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
      showLevel: json['show_level'] as bool? ?? true,
      showAchievements: json['show_achievements'] as bool? ?? true,
      showHabits: json['show_habits'] as bool? ?? true,
      level: UserLevel.fromJson(json['level'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'cover_image_url': coverImageUrl,
      'preferred_language': preferredLanguage,
      'is_guest': isGuest,
      'is_verified': isVerified,
      'subscription_type': subscriptionType,
      'subscription_status': subscriptionStatus,
      'profile_visibility': profileVisibility,
      'show_level': showLevel,
      'show_achievements': showAchievements,
      'show_habits': showHabits,
      'level': level.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// User Level Model
class UserLevel {
  final int currentLevel;
  final int currentXp;
  final int totalXp;
  final int nextLevelXp;
  final int dailyStreak;
  final int longestDailyStreak;

  UserLevel({
    required this.currentLevel,
    required this.currentXp,
    required this.totalXp,
    required this.nextLevelXp,
    required this.dailyStreak,
    required this.longestDailyStreak,
  });

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      currentLevel: json['current_level'] as int,
      currentXp: json['current_xp'] as int,
      totalXp: json['total_xp'] as int,
      nextLevelXp: json['next_level_xp'] as int,
      dailyStreak: json['daily_streak'] as int? ?? 0,
      longestDailyStreak: json['longest_daily_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_level': currentLevel,
      'current_xp': currentXp,
      'total_xp': totalXp,
      'next_level_xp': nextLevelXp,
      'daily_streak': dailyStreak,
      'longest_daily_streak': longestDailyStreak,
    };
  }

  double get progressPercentage {
    if (nextLevelXp == 0) return 0;
    return (currentXp / nextLevelXp) * 100;
  }
}

// Auth Response Model
class AuthResponse {
  final User user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

// Login Request Models
class LoginRequest {
  final String email;
  final String password;
  final String? deviceId;

  LoginRequest({
    required this.email,
    required this.password,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}

class RegisterRequest {
  final String email;
  final String username;
  final String password;
  final String passwordConfirmation;
  final String? displayName;
  final String? preferredLanguage;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirmation,
    this.displayName,
    this.preferredLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (displayName != null) 'display_name': displayName,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
    };
  }
}

class GoogleLoginRequest {
  final String googleId;
  final String email;
  final String displayName;
  final String? profilePictureUrl;
  final String? deviceId;

  GoogleLoginRequest({
    required this.googleId,
    required this.email,
    required this.displayName,
    this.profilePictureUrl,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'google_id': googleId,
      'email': email,
      'display_name': displayName,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}

class AppleLoginRequest {
  final String appleId;
  final String? email;
  final String? displayName;
  final String? deviceId;

  AppleLoginRequest({
    required this.appleId,
    this.email,
    this.displayName,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'apple_id': appleId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}

class GuestLoginRequest {
  final String deviceId;

  GuestLoginRequest({required this.deviceId});

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
    };
  }
}