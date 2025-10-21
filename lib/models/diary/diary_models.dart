// Diary Model
class Diary {
  final int id;
  final int userId;
  final DateTime diaryDate;
  final String? title;
  final String content;
  final String? mood;
  final String? moodIcon;
  final String? weather;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  Diary({
    required this.id,
    required this.userId,
    required this.diaryDate,
    this.title,
    required this.content,
    this.mood,
    this.moodIcon,
    this.weather,
    this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      diaryDate: DateTime.parse(json['diary_date'] as String),
      title: json['title'] as String?,
      content: json['content'] as String,
      mood: json['mood'] as String?,
      moodIcon: json['mood_icon'] as String?,
      weather: json['weather'] as String?,
      imageUrls: (json['image_urls'] as List?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'diary_date': diaryDate.toIso8601String().split('T')[0],
      'title': title,
      'content': content,
      'mood': mood,
      'mood_icon': moodIcon,
      'weather': weather,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Diary Stats Model
class DiaryStats {
  final int totalEntries;
  final int thisMonth;
  final int currentStreak;

  DiaryStats({
    required this.totalEntries,
    required this.thisMonth,
    required this.currentStreak,
  });

  factory DiaryStats.fromJson(Map<String, dynamic> json) {
    return DiaryStats(
      totalEntries: json['total_entries'] as int,
      thisMonth: json['this_month'] as int,
      currentStreak: json['current_streak'] as int,
    );
  }
}

// Mood Analysis Model
class MoodAnalysis {
  final int periodDays;
  final int totalEntries;
  final Map<String, int> moodDistribution;
  final String mostCommonMood;

  MoodAnalysis({
    required this.periodDays,
    required this.totalEntries,
    required this.moodDistribution,
    required this.mostCommonMood,
  });

  factory MoodAnalysis.fromJson(Map<String, dynamic> json) {
    return MoodAnalysis(
      periodDays: json['period_days'] as int,
      totalEntries: json['total_entries'] as int,
      moodDistribution: (json['mood_distribution'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int)),
      mostCommonMood: json['most_common_mood'] as String,
    );
  }
}

// Diary Request
class DiaryRequest {
  final String diaryDate;
  final String? title;
  final String content;
  final String? mood;
  final String? moodIcon;
  final String? weather;
  final List<String>? imageUrls;

  DiaryRequest({
    required this.diaryDate,
    this.title,
    required this.content,
    this.mood,
    this.moodIcon,
    this.weather,
    this.imageUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'diary_date': diaryDate,
      'title': title,
      'content': content,
      'mood': mood,
      'mood_icon': moodIcon,
      'weather': weather,
      'image_urls': imageUrls,
    };
  }
}