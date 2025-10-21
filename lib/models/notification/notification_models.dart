// ==================== NOTIFICATION MODELS ====================

// Notification Model
class AppNotification {
  final int id;
  final int userId;
  final String notificationType;
  final String title;
  final String message;
  final int? referenceId;
  final String? referenceType;
  final DateTime? scheduledTime;
  final DateTime? sentAt;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    this.scheduledTime,
    this.sentAt,
    required this.isRead,
    required this.isDelivered,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      referenceId: json['reference_id'] as int?,
      referenceType: json['reference_type'] as String?,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      isRead: json['is_read'] as bool,
      isDelivered: json['is_delivered'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'is_read': isRead,
      'is_delivered': isDelivered,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Push Token Request
class PushTokenRequest {
  final String token;
  final String deviceType;
  final String? deviceId;

  PushTokenRequest({
    required this.token,
    required this.deviceType,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'device_type': deviceType,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}

// ==================== SOCIAL MODELS ====================

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
      'level': level,
    };
  }
}

// Friend Request Model
class FriendRequest {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final FriendRequestUser sender;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.sender,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      status: json['status'] as String,
      sender: FriendRequestUser.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// Friend Request User Model
class FriendRequestUser {
  final int id;
  final String username;
  final String displayName;
  final String? profilePictureUrl;

  FriendRequestUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
  });

  factory FriendRequestUser.fromJson(Map<String, dynamic> json) {
    return FriendRequestUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }
}

// ==================== UTILITY MODELS ====================

// Quote Model
class Quote {
  final int id;
  final String quoteText;
  final String author;
  final String language;
  final String category;
  final bool isActive;

  Quote({
    required this.id,
    required this.quoteText,
    required this.author,
    required this.language,
    required this.category,
    required this.isActive,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int,
      quoteText: json['quote_text'] as String,
      author: json['author'] as String,
      language: json['language'] as String,
      category: json['category'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}

// Dashboard Data Model
class DashboardData {
  final DashboardHabits habits;
  final DashboardTasks tasks;
  final DashboardBudget budget;
  final DashboardLevel level;

  DashboardData({
    required this.habits,
    required this.tasks,
    required this.budget,
    required this.level,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      habits: DashboardHabits.fromJson(json['habits'] as Map<String, dynamic>),
      tasks: DashboardTasks.fromJson(json['tasks'] as Map<String, dynamic>),
      budget: DashboardBudget.fromJson(json['budget'] as Map<String, dynamic>),
      level: DashboardLevel.fromJson(json['level'] as Map<String, dynamic>),
    );
  }
}

class DashboardHabits {
  final int totalToday;
  final int completed;
  final int remaining;
  final double completionRate;

  DashboardHabits({
    required this.totalToday,
    required this.completed,
    required this.remaining,
    required this.completionRate,
  });

  factory DashboardHabits.fromJson(Map<String, dynamic> json) {
    return DashboardHabits(
      totalToday: json['total_today'] as int,
      completed: json['completed'] as int,
      remaining: json['remaining'] as int,
      completionRate: (json['completion_rate'] as num).toDouble(),
    );
  }
}

class DashboardTasks {
  final int dueToday;
  final int overdue;

  DashboardTasks({
    required this.dueToday,
    required this.overdue,
  });

  factory DashboardTasks.fromJson(Map<String, dynamic> json) {
    return DashboardTasks(
      dueToday: json['due_today'] as int,
      overdue: json['overdue'] as int,
    );
  }
}

class DashboardBudget {
  final double monthlyBudget;
  final double spent;
  final double remaining;

  DashboardBudget({
    required this.monthlyBudget,
    required this.spent,
    required this.remaining,
  });

  factory DashboardBudget.fromJson(Map<String, dynamic> json) {
    return DashboardBudget(
      monthlyBudget: (json['monthly_budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
    );
  }
}

class DashboardLevel {
  final int currentLevel;
  final int currentXp;
  final int nextLevelXp;
  final double progress;

  DashboardLevel({
    required this.currentLevel,
    required this.currentXp,
    required this.nextLevelXp,
    required this.progress,
  });

  factory DashboardLevel.fromJson(Map<String, dynamic> json) {
    return DashboardLevel(
      currentLevel: json['current_level'] as int,
      currentXp: json['current_xp'] as int,
      nextLevelXp: json['next_level_xp'] as int,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

// App Info Model
class AppInfo {
  final String version;
  final String minSupportedVersion;
  final bool updateRequired;
  final bool maintenanceMode;

  AppInfo({
    required this.version,
    required this.minSupportedVersion,
    required this.updateRequired,
    required this.maintenanceMode,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      version: json['version'] as String,
      minSupportedVersion: json['min_supported_version'] as String,
      updateRequired: json['update_required'] as bool,
      maintenanceMode: json['maintenance_mode'] as bool,
    );
  }
}

// Feedback Request
class FeedbackRequest {
  final String feedbackType;
  final String? subject;
  final String message;
  final String? email;
  final String? appVersion;
  final String? deviceInfo;
  final List<String>? screenshotUrls;

  FeedbackRequest({
    required this.feedbackType,
    this.subject,
    required this.message,
    this.email,
    this.appVersion,
    this.deviceInfo,
    this.screenshotUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'feedback_type': feedbackType,
      'subject': subject,
      'message': message,
      'email': email,
      'app_version': appVersion,
      'device_info': deviceInfo,
      'screenshot_urls': screenshotUrls,
    };
  }
}