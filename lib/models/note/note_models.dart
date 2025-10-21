class Note {
  final int id;
  final String? title;
  final String? content;
  final int? categoryId;
  final String? templateType;
  final String? color;
  final DateTime? reminderDate;
  final bool isLocked;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? wordCount;
  final int? characterCount;
  final int? orderIndex;
  final int? version;
  final bool? reminderEnabled;

  Note({
    required this.id,
    this.title,
    this.content,
    this.categoryId,
    this.templateType,
    this.color,
    this.reminderDate,
    required this.isLocked,
    required this.isPinned,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.wordCount,
    this.characterCount,
    this.orderIndex,
    this.version,
    this.reminderEnabled,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String?,
      content: json['content'] as String?,
      categoryId: json['category_id'] as int?,
      templateType: json['template_type'] as String?,
      color: json['color'] as String?,
      reminderDate: json['reminder_date'] != null
          ? DateTime.parse(json['reminder_date'] as String)
          : null,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      wordCount: json['word_count'] as int?,
      characterCount: json['character_count'] as int?,
      orderIndex: json['order_index'] as int?,
      version: json['version'] as int?,
      reminderEnabled: json['reminder_enabled'] == true || json['reminder_enabled'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category_id': categoryId,
      'template_type': templateType,
      'color': color,
      'reminder_date': reminderDate?.toIso8601String(),
      'is_locked': isLocked,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'word_count': wordCount,
      'character_count': characterCount,
      'order_index': orderIndex,
      'version': version,
      'reminder_enabled': reminderEnabled,
    };
  }
}

// Note Category
class NoteCategory {
  final int id;
  final String name;
  final String? icon;
  final String? color;
  final int notesCount;
  final int orderIndex;

  NoteCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.notesCount,
    required this.orderIndex,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      notesCount: json['notes_count'] as int? ?? 0,
      orderIndex: json['order_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'notes_count': notesCount,
      'order_index': orderIndex,
    };
  }
}

// Note Request
class NoteRequest {
  final String? title;
  final String? content;
  final int? categoryId;
  final String? templateType;
  final String? color;
  final DateTime? reminderDate;
  final bool isLocked;
  final bool isPinned;

  NoteRequest({
    this.title,
    this.content,
    this.categoryId,
    this.templateType,
    this.color,
    this.reminderDate,
    required this.isLocked,
    required this.isPinned,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category_id': categoryId,
      'template_type': templateType,
      'color': color,
      'reminder_date': reminderDate?.toIso8601String(),
      'is_locked': isLocked,
      'is_pinned': isPinned,
    };
  }
}

// Note Category Request
class NoteCategoryRequest {
  final String name;
  final String? icon;
  final String? color;

  NoteCategoryRequest({
    required this.name,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}