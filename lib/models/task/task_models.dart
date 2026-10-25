// Task Attachment (göreve bağlı görsel/dosya — backend polimorfik attachments)
class TaskAttachment {
  final int id;
  final String fileName;
  final String fileType;
  final String fileUrl;
  final String? thumbnailUrl;

  TaskAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    this.thumbnailUrl,
  });

  bool get isImage => fileType.startsWith('image/');

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as int,
      fileName: (json['file_name'] ?? '') as String,
      fileType: (json['file_type'] ?? 'application/octet-stream') as String,
      fileUrl: (json['file_url'] ?? '') as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

// Task Model
class Task {
  final int id;
  final String title;
  final String? description;
  final String taskType;
  final String? dueDate;
  final String? dueTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool reminderEnabled;
  final int? reminderBeforeMinutes;
  final String? reminderTime;
  final int priority;
  final bool isRecurring;
  final String? recurringPattern;
  final int? estimatedDurationMinutes;
  final int? actualDurationMinutes;
  final bool isOverdue;
  final int? parentTaskId;
  final int orderIndex;
  final DateTime createdAt;
  // Faz 1: backend'e taşınan meta alanları
  final String? category;
  final List<String> tags;
  final String? location;
  final String? link;
  final List<TaskAttachment> attachments;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.taskType,
    this.dueDate,
    this.dueTime,
    required this.isCompleted,
    this.completedAt,
    required this.reminderEnabled,
    this.reminderBeforeMinutes,
    this.reminderTime,
    required this.priority,
    required this.isRecurring,
    this.recurringPattern,
    this.estimatedDurationMinutes,
    this.actualDurationMinutes,
    required this.isOverdue,
    this.parentTaskId,
    this.orderIndex = 0,
    required this.createdAt,
    this.category,
    List<String>? tags,
    this.location,
    this.link,
    List<TaskAttachment>? attachments,
  })  : tags = tags ?? const [],
        attachments = attachments ?? const [];

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      taskType: json['task_type'] as String,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1, // ← Null-safe
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      reminderEnabled: json['reminder_enabled'] == true || json['reminder_enabled'] == 1, // ← Null-safe
      reminderBeforeMinutes: json['reminder_before_minutes'] as int?,
      reminderTime: json['reminder_time'] as String?,
      priority: json['priority'] as int? ?? 1, // ← Default değer
      isRecurring: json['is_recurring'] == true || json['is_recurring'] == 1, // ← Null-safe
      recurringPattern: json['recurring_pattern'] as String?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      actualDurationMinutes: json['actual_duration_minutes'] as int?,
      isOverdue: json['is_overdue'] == true || json['is_overdue'] == 1, // ← Null-safe
      parentTaskId: json['parent_task_id'] as int?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      location: json['location'] as String?,
      link: json['link'] as String?,
      attachments: (json['attachments'] as List?)
              ?.map((e) => TaskAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'task_type': taskType,
      'due_date': dueDate,
      'due_time': dueTime,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'reminder_before_minutes': reminderBeforeMinutes,
      'reminder_time': reminderTime,
      'priority': priority,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'is_overdue': isOverdue,
      'parent_task_id': parentTaskId,
      'created_at': createdAt.toIso8601String(),
      'category': category,
      'tags': tags,
      'location': location,
      'link': link,
    };
  }

  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Medium';
    }
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? taskType,
    String? dueDate,
    String? dueTime,
    bool? isCompleted,
    DateTime? completedAt,
    bool? reminderEnabled,
    int? reminderBeforeMinutes,
    String? reminderTime,
    int? priority,
    bool? isRecurring,
    String? recurringPattern,
    int? estimatedDurationMinutes,
    int? actualDurationMinutes,
    bool? isOverdue,
    int? parentTaskId,
    int? orderIndex,
    DateTime? createdAt,
    String? category,
    List<String>? tags,
    String? location,
    String? link,
    List<TaskAttachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderBeforeMinutes: reminderBeforeMinutes ?? this.reminderBeforeMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      isOverdue: isOverdue ?? this.isOverdue,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      link: link ?? this.link,
      attachments: attachments ?? this.attachments,
    );
  }
}

// Task Request
class TaskRequest {
  final String title;
  final String? description;
  final String taskType;
  final String? dueDate;
  final String? dueTime;
  final bool reminderEnabled;
  final int? reminderBeforeMinutes;
  final String? reminderTime;
  final int priority;
  final bool isRecurring;
  final String? recurringPattern;
  final int? estimatedDurationMinutes;
  final int? parentTaskId;
  final String? category;
  final List<String>? tags;
  final String? location;
  final String? link;

  TaskRequest({
    required this.title,
    this.description,
    required this.taskType,
    this.dueDate,
    this.dueTime,
    required this.reminderEnabled,
    this.reminderBeforeMinutes,
    this.reminderTime,
    required this.priority,
    required this.isRecurring,
    this.recurringPattern,
    this.estimatedDurationMinutes,
    this.parentTaskId,
    this.category,
    this.tags,
    this.location,
    this.link,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'task_type': taskType,
      'due_date': dueDate,
      'due_time': dueTime,
      'reminder_enabled': reminderEnabled,
      'reminder_before_minutes': reminderBeforeMinutes,
      'reminder_time': reminderTime,
      'priority': priority,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'parent_task_id': parentTaskId,
      'category': category,
      'tags': tags,
      'location': location,
      'link': link,
    };
  }
}