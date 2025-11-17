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
  final DateTime createdAt;

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
    required this.createdAt,
  });

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
      createdAt: DateTime.parse(json['created_at'] as String),
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
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
    };
  }
}