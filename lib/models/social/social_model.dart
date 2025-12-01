import '../settings/settings_models.dart';

// Friend Model
class Friend {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  final int level;

  Friend({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    required this.level,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      level: json['level'] as int,
    );
  }
}

// Friend Request Model
class FriendRequest {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final UserInfo? sender;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.sender,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int,
      senderId: json['from_user_id'] as int,
      receiverId: json['to_user_id'] as int,
      status: json['status'] as String,
      sender: json['from_user'] != null
          ? UserInfo.fromJson(json['from_user'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['requested_at'] as String),
    );
  }
}

// User Info Model
class UserInfo {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;

  UserInfo({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }
}

// Follower Model
class Follower {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  final int level;

  Follower({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    required this.level,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      level: json['level'] as int,
    );
  }
}

// Following Model
class Following {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;
  final int level;

  Following({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    required this.level,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      level: json['level'] as int,
    );
  }
}

// User Search Result Model
class UserSearchResult {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;

  UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }
}

// User Profile Model (Başkalarının profilini görüntülerken)
class UserProfile {
  final int id;
  final String username;
  final String displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? coverImageUrl;
  final int level;
  final int totalXp;
  final bool showLevel;
  final bool showAchievements;
  final bool showHabits;
  final ProfileStats? stats;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.coverImageUrl,
    required this.level,
    required this.totalXp,
    required this.showLevel,
    required this.showAchievements,
    required this.showHabits,
    this.stats,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      level: json['level'] as int,
      totalXp: json['total_xp'] as int,
      showLevel: json['show_level'] as bool,
      showAchievements: json['show_achievements'] as bool,
      showHabits: json['show_habits'] as bool,
      stats: json['stats'] != null
          ? ProfileStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }
}