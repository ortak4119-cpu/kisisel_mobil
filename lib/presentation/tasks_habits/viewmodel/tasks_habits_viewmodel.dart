import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/init/locator.dart';
import '../../../service/task/task_service.dart';
import '../../../service/habit/habit_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../../../models/auth/auth_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/utils/nl_task_parser.dart';
import '../../../core/utils/app_locale.dart';

enum TaskFilter { all, pending, completed }

/// Görevin backend'de tutulmayan ek alanları (kategori/etiket/ek/konum/bağlantı).
/// Cihazda kalıcı olarak saklanır, görev id'siyle eşlenir.
class TaskMeta {
  String? category;
  List<String> tags;
  List<String> attachments; // yerel dosya yolları
  String? location;
  String? link;
  TaskMeta({
    this.category,
    List<String>? tags,
    List<String>? attachments,
    this.location,
    this.link,
  })  : tags = tags ?? [],
        attachments = attachments ?? [];

  bool get isEmpty =>
      category == null &&
      tags.isEmpty &&
      attachments.isEmpty &&
      (location == null || location!.isEmpty) &&
      (link == null || link!.isEmpty);

  Map<String, dynamic> toJson() => {
        'category': category,
        'tags': tags,
        'attachments': attachments,
        'location': location,
        'link': link,
      };

  factory TaskMeta.fromJson(Map<String, dynamic> j) => TaskMeta(
        category: j['category'] as String?,
        tags: (j['tags'] as List?)?.cast<String>() ?? [],
        attachments: (j['attachments'] as List?)?.cast<String>() ?? [],
        location: j['location'] as String?,
        link: j['link'] as String?,
      );

  TaskMeta copy() => TaskMeta(
        category: category,
        tags: List.from(tags),
        attachments: List.from(attachments),
        location: location,
        link: link,
      );
}

class TasksHabitsViewModel extends ChangeNotifier {
  final ITaskService _taskService = locator.get<ITaskService>();
  final IHabitService _habitService = locator.get<IHabitService>();
  final IProfileService _profileService = locator.get<IProfileService>();

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUserLoaded = false;
  bool get isUserLoaded => _isUserLoaded;

  // Task Filter
  TaskFilter _currentTaskFilter = TaskFilter.all;
  TaskFilter get currentTaskFilter => _currentTaskFilter;

  void setTaskFilter(TaskFilter filter) {
    _currentTaskFilter = filter;
    notifyListeners();
  }

  // Tasks
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;

  List<Task> get filteredTasks {
    switch (_currentTaskFilter) {
      case TaskFilter.all:
        return _tasks;
      case TaskFilter.pending:
        return pendingTasks;
      case TaskFilter.completed:
        return completedTasks;
    }
  }

  // Habits
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  int get completedTodayCount => _habits.where((h) => h.completedToday).length;
  int get longestStreak => _habits.isEmpty
      ? 0
      : _habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);

  // Editing state
  int? _editingTaskId;
  int? get editingTaskId => _editingTaskId;
  int? _editingHabitId;

  // Task Form State
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController = TextEditingController();
  int _taskPriority = 1;
  int get taskPriority => _taskPriority;
  String _taskType = 'daily';
  String get taskType => _taskType;
  String _taskRecurrence = 'none';
  String get taskRecurrence => _taskRecurrence;
  bool _reminderEnabled = false;
  bool get reminderEnabled => _reminderEnabled;
  int _reminderBeforeMinutes = 30;
  int get reminderBeforeMinutes => _reminderBeforeMinutes;
  TimeOfDay? _reminderTime;
  TimeOfDay? get reminderTime => _reminderTime;

  void setTaskPriority(int priority) {
    _taskPriority = priority;
    notifyListeners();
  }

  void setTaskType(String type) {
    _taskType = type;
    notifyListeners();
  }

  void setTaskRecurrence(String recurrence) {
    _taskRecurrence = recurrence;
    notifyListeners();
  }

  void setReminderEnabled(bool enabled) {
    _reminderEnabled = enabled;
    notifyListeners();
  }

  void setReminderBeforeMinutes(int minutes) {
    _reminderBeforeMinutes = minutes;
    notifyListeners();
  }

  void setReminderTime(TimeOfDay? time) {
    _reminderTime = time;
    notifyListeners();
  }

  // ==================== YENİ TASARIM: TARİH / KATEGORİ / EKLER ====================

  // Görev tarih & saati (backend: due_date / due_time)
  DateTime? _taskDueDate;
  DateTime? get taskDueDate => _taskDueDate;
  TimeOfDay? _taskDueTime;
  TimeOfDay? get taskDueTime => _taskDueTime;
  void setTaskDueDate(DateTime? d) {
    _taskDueDate = d;
    notifyListeners();
  }

  void setTaskDueTime(TimeOfDay? t) {
    _taskDueTime = t;
    notifyListeners();
  }

  // Kategori (yerel meta)
  String? _taskCategory;
  String? get taskCategory => _taskCategory;
  void setTaskCategory(String? c) {
    _taskCategory = c;
    notifyListeners();
  }

  // Etiketler / konum / bağlantı (yerel meta)
  final List<String> _taskTags = [];
  List<String> get taskTags => _taskTags;
  void addTaskTag(String t) {
    final v = t.trim();
    if (v.isNotEmpty && !_taskTags.contains(v)) {
      _taskTags.add(v);
      notifyListeners();
    }
  }

  void removeTaskTag(int i) {
    if (i >= 0 && i < _taskTags.length) {
      _taskTags.removeAt(i);
      notifyListeners();
    }
  }

  String? _taskLocation;
  String? get taskLocation => _taskLocation;
  void setTaskLocation(String? v) {
    _taskLocation = (v == null || v.trim().isEmpty) ? null : v.trim();
    notifyListeners();
  }

  String? _taskLink;
  String? get taskLink => _taskLink;
  void setTaskLink(String? v) {
    _taskLink = (v == null || v.trim().isEmpty) ? null : v.trim();
    notifyListeners();
  }

  // Alt görev taslakları (yeni görev oluştururken)
  final List<String> _subtaskDrafts = [];
  List<String> get subtaskDrafts => _subtaskDrafts;
  void addSubtaskDraft(String t) {
    final v = t.trim();
    if (v.isNotEmpty) {
      _subtaskDrafts.add(v);
      notifyListeners();
    }
  }

  void removeSubtaskDraft(int i) {
    if (i >= 0 && i < _subtaskDrafts.length) {
      _subtaskDrafts.removeAt(i);
      notifyListeners();
    }
  }

  // Ekler (yerel dosya/foto — kaydedince backend'e yüklenir)
  final List<File> _taskPickedFiles = [];
  List<File> get taskPickedFiles => _taskPickedFiles;
  // Düzenlenen görevin backend'deki mevcut ekleri.
  List<TaskAttachment> _editingTaskAttachments = [];
  List<String> get taskExistingAttachments =>
      _editingTaskAttachments.map((a) => a.fileUrl).toList();
  final ImagePicker _taskImagePicker = ImagePicker();

  Future<void> pickTaskImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _taskImagePicker.pickMultiImage(imageQuality: 80);
        for (final f in files) {
          _taskPickedFiles.add(File(f.path));
        }
      } else {
        final f =
            await _taskImagePicker.pickImage(source: source, imageQuality: 80);
        if (f != null) _taskPickedFiles.add(File(f.path));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> pickTaskFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        for (final f in result.files) {
          if (f.path != null) _taskPickedFiles.add(File(f.path!));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void removeTaskPickedFile(int i) {
    if (i >= 0 && i < _taskPickedFiles.length) {
      _taskPickedFiles.removeAt(i);
      notifyListeners();
    }
  }

  /// Mevcut (backend) eki kaldırır — sunucudan da siler.
  Future<void> removeTaskExistingAttachment(int i) async {
    if (i < 0 || i >= _editingTaskAttachments.length) return;
    final att = _editingTaskAttachments[i];
    _editingTaskAttachments.removeAt(i);
    notifyListeners();
    try {
      await _taskService.deleteTaskAttachment(att.id);
      final idx = _tasks.indexWhere((t) => t.id == _editingTaskId);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(
            attachments: _tasks[idx]
                .attachments
                .where((a) => a.id != att.id)
                .toList());
      }
    } catch (_) {}
  }

  int get taskAttachmentCount =>
      _taskPickedFiles.length + _editingTaskAttachments.length;

  /// Seçilen yerel dosyaları göreve (backend) yükler ve yerel listeyi günceller.
  Future<void> _uploadTaskAttachments(int taskId) async {
    for (final f in List<File>.from(_taskPickedFiles)) {
      try {
        final r = await _taskService.uploadTaskAttachment(taskId, f);
        if (r.isSuccess && r.data != null) {
          final idx = _tasks.indexWhere((t) => t.id == taskId);
          if (idx != -1) {
            _tasks[idx] = _tasks[idx]
                .copyWith(attachments: [..._tasks[idx].attachments, r.data!]);
          }
        }
      } catch (_) {}
    }
  }

  // ---- Meta artık backend'de (kategori/etiket/konum/bağlantı/ek). Eski yerel
  // store yalnız tek seferlik göç için okunur. ----
  static const String _kTaskMetaKey = 'task_meta_v1';
  final Map<int, TaskMeta> _taskMeta = {};

  /// Görev meta'sını backend task nesnesinden üretir.
  TaskMeta metaForTask(int id) {
    for (final t in _tasks) {
      if (t.id == id) {
        return TaskMeta(
          category: t.category,
          tags: List.from(t.tags),
          location: t.location,
          link: t.link,
          attachments: t.attachments.map((a) => a.fileUrl).toList(),
        );
      }
    }
    return TaskMeta();
  }

  Future<void> loadTaskMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kTaskMetaKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _taskMeta.clear();
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is Map<String, dynamic>) {
          final m = TaskMeta.fromJson(v);
          // Var olmayan ek dosyalarını ele
          m.attachments =
              m.attachments.where((p) => File(p).existsSync()).toList();
          if (!m.isEmpty) _taskMeta[id] = m;
        }
      });
      notifyListeners();
    } catch (_) {}
  }

  /// Eski yerel task meta'sını (kategori/etiket/konum/bağlantı + ek dosyaları)
  /// bir kez backend'e taşır, sonra yerel anahtarı siler. Backend zaten meta
  /// içeren görevlere dokunmaz. Mevcut diğer alanlar korunur (tam istek).
  Future<void> migrateLocalTaskMetaOnce() async {
    await loadTaskMeta();
    if (_taskMeta.isEmpty) return;
    final entries = Map<int, TaskMeta>.from(_taskMeta);
    for (final entry in entries.entries) {
      final taskId = entry.key;
      final m = entry.value;
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx == -1) continue; // backend'de yok → atla
      final t = _tasks[idx];
      final backendHasMeta = (t.category != null) ||
          t.tags.isNotEmpty ||
          (t.location != null) ||
          (t.link != null) ||
          t.attachments.isNotEmpty;
      try {
        final hasTextMeta = m.category != null ||
            m.tags.isNotEmpty ||
            (m.location != null && m.location!.isNotEmpty) ||
            (m.link != null && m.link!.isNotEmpty);
        if (!backendHasMeta && hasTextMeta) {
          await _taskService.updateTask(
            taskId,
            TaskRequest(
              title: t.title,
              description: t.description,
              taskType: t.taskType,
              dueDate: t.dueDate,
              dueTime: t.dueTime,
              reminderEnabled: t.reminderEnabled,
              reminderBeforeMinutes: t.reminderBeforeMinutes,
              reminderTime: t.reminderTime,
              priority: t.priority,
              isRecurring: t.isRecurring,
              recurringPattern: t.recurringPattern,
              estimatedDurationMinutes: t.estimatedDurationMinutes,
              category: m.category,
              tags: m.tags.isEmpty ? null : m.tags,
              location: m.location,
              link: m.link,
            ),
          );
        }
        // Yerel ek dosyalarını yükle (yalnız backend'de hiç ek yoksa).
        if (t.attachments.isEmpty) {
          for (final p in m.attachments) {
            final f = File(p);
            if (f.existsSync()) {
              await _taskService.uploadTaskAttachment(taskId, f);
            }
          }
        }
      } catch (_) {}
    }
    // Göç tamamlandı: yerel anahtarı temizle ve listeyi tazele.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTaskMetaKey);
    } catch (_) {}
    _taskMeta.clear();
    await loadTasks();
  }

  // ---- Ana görev / alt görev yardımcıları ----
  List<Task> get parentTasks =>
      _tasks.where((t) => t.parentTaskId == null).toList();
  List<Task> subtasksOf(int parentId) =>
      _tasks.where((t) => t.parentTaskId == parentId).toList();

  DateTime? dueDateOf(Task t) {
    if (t.dueDate == null || t.dueDate!.isEmpty) return null;
    try {
      return DateTime.parse(t.dueDate!);
    } catch (_) {
      return null;
    }
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Seçili gün (hafta seçici)
  DateTime _selectedDay = DateTime.now();
  DateTime get selectedDay => _selectedDay;
  void setSelectedDay(DateTime d) {
    _selectedDay = d;
    notifyListeners();
  }

  // Üst-seviye görev sayaçları (istatistik kartları)
  List<Task> get _openParents =>
      parentTasks.where((t) => !t.isCompleted).toList();
  int get todayTaskCount {
    final now = DateTime.now();
    return _openParents.where((t) {
      final d = dueDateOf(t);
      return d != null && isSameDay(d, now);
    }).length;
  }

  int get upcomingTaskCount {
    final today = DateTime.now();
    return _openParents.where((t) {
      final d = dueDateOf(t);
      return d != null && d.isAfter(DateTime(today.year, today.month, today.day, 23, 59));
    }).length;
  }

  int get overdueTaskCount {
    final today = DateTime.now();
    return _openParents.where((t) {
      final d = dueDateOf(t);
      final overdueByDate =
          d != null && d.isBefore(DateTime(today.year, today.month, today.day));
      return t.isOverdue || overdueByDate;
    }).length;
  }

  int get completedTaskCount => parentTasks.where((t) => t.isCompleted).length;

  // Aktif istatistik filtresi: today | upcoming | overdue | completed
  String _taskStatFilter = 'today';
  String get taskStatFilter => _taskStatFilter;
  void setTaskStatFilter(String f) {
    _taskStatFilter = f;
    notifyListeners();
  }

  List<Task> get upcomingTasksList {
    final today = DateTime.now();
    return _applySort(_openParents.where((t) {
      final d = dueDateOf(t);
      return d != null &&
          d.isAfter(DateTime(today.year, today.month, today.day, 23, 59));
    }).toList());
  }

  List<Task> get overdueTasksList {
    final today = DateTime.now();
    return _applySort(_openParents.where((t) {
      final d = dueDateOf(t);
      final od =
          d != null && d.isBefore(DateTime(today.year, today.month, today.day));
      return t.isOverdue || od;
    }).toList());
  }

  List<Task> get completedTasksList =>
      _applySort(parentTasks.where((t) => t.isCompleted).toList());

  // Seçili güne ait görevler + "daha sonra"
  List<Task> get tasksForSelectedDay {
    return parentTasks.where((t) {
      final d = dueDateOf(t);
      return d != null && isSameDay(d, _selectedDay);
    }).toList();
  }

  List<Task> get laterTasks {
    return parentTasks.where((t) {
      if (t.isCompleted) return false;
      final d = dueDateOf(t);
      if (d == null) return true; // tarihsiz → daha sonra
      return d.isAfter(DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59));
    }).toList();
  }

  // Günlük ilerleme (seçili gün)
  double get dayProgress {
    final list = tasksForSelectedDay;
    if (list.isEmpty) return 0;
    final done = list.where((t) => t.isCompleted).length;
    return done / list.length;
  }

  int get dayDoneCount =>
      tasksForSelectedDay.where((t) => t.isCompleted).length;
  int get dayTotalCount => tasksForSelectedDay.length;

  // Sıralama
  String _taskSort = 'priority'; // priority | time | created
  String get taskSort => _taskSort;
  void setTaskSort(String s) {
    _taskSort = s;
    notifyListeners();
  }

  List<Task> _applySort(List<Task> list) {
    final l = List<Task>.from(list);
    switch (_taskSort) {
      case 'priority':
        l.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'time':
        l.sort((a, b) => (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99'));
        break;
      case 'manual':
        // Elle sıralama: order_index, eşitlikte en yeni üstte.
        l.sort((a, b) {
          final c = a.orderIndex.compareTo(b.orderIndex);
          return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
        });
        break;
      default:
        l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return l;
  }

  List<Task> get sortedTasksForSelectedDay => _applySort(tasksForSelectedDay);

  /// Sürükle-bırak yalnız "manual" sıralama modunda ve arama yokken aktif.
  bool get canReorderTasks =>
      _taskSort == 'manual' && _taskSearch.trim().isEmpty;

  /// Seçili günün görevlerini elle sırala (sürükle-bırak). reorderable_grid_view
  /// konvansiyonu değil; ReorderableListView: oldIndex < newIndex ise newIndex--.
  Future<void> reorderTasksForSelectedDay(int oldIndex, int newIndex) async {
    final visible = sortedTasksForSelectedDay;
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    if (oldIndex < newIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, visible.length - 1);
    if (oldIndex == newIndex) return;

    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    // Yeni sırayı order_index olarak yerel Task'lara yaz (anında yansısın).
    for (var i = 0; i < visible.length; i++) {
      final idx = _tasks.indexWhere((t) => t.id == visible[i].id);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(orderIndex: i);
      }
    }
    notifyListeners();

    try {
      await _taskService.reorderTasks(visible.map((t) => t.id).toList());
    } catch (_) {}
  }

  // ---- Doğal dil girişi (Faz 2) ----
  /// Başlık değişince önizleme çubuğunu tazelemek için rebuild tetikler.
  void onTaskTitleChanged() => notifyListeners();

  /// Başlık metninin canlı doğal dil önizlemesi.
  ParsedTask get nlPreview =>
      NlTaskParser.parse(taskTitleController.text, AppLocale.code);

  /// Doğal dil çözümlemesini form durumuna uygular: başlığı sadeleştirir ve
  /// algılanan tarih/saat/öncelik/etiketi set eder (metinde olmayan alanlara
  /// dokunmaz). Kaydetmeden hemen önce çağrılır.
  void _applyNlParseToState() {
    final p = NlTaskParser.parse(taskTitleController.text, AppLocale.code);
    if (!p.hasAny) return;
    if (p.title.isNotEmpty) taskTitleController.text = p.title;
    if (p.dueDate != null) _taskDueDate = p.dueDate;
    if (p.dueTime != null) _taskDueTime = p.dueTime;
    if (p.priority != null) _taskPriority = p.priority!;
    for (final t in p.tags) {
      if (!_taskTags.contains(t)) _taskTags.add(t);
    }
  }

  // Arama
  String _taskSearch = '';
  String get taskSearch => _taskSearch;
  void setTaskSearch(String q) {
    _taskSearch = q;
    notifyListeners();
  }

  List<Task> get searchResults {
    final q = _taskSearch.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return parentTasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  // Habit Form State
  final TextEditingController habitTitleController = TextEditingController();
  final TextEditingController habitDescriptionController = TextEditingController();
  // Atomic Habits döngüsü: ipucu (cue) + ödül (reward)
  final TextEditingController habitCueController = TextEditingController();
  final TextEditingController habitRewardController = TextEditingController();
  String _habitCategory = 'health';
  String get habitCategory => _habitCategory;
  String _habitDifficulty = 'beginner';
  String get habitDifficulty => _habitDifficulty;
  String _selectedIcon = 'star';
  String get selectedIcon => _selectedIcon;
  // Zaman seçimi: morning(09:00), noon(13:00), evening(17:00)
  String _habitTimePeriod = 'morning';
  String get habitTimePeriod => _habitTimePeriod;

  // Zaman periyoduna göre bildirim saati
  String getReminderTimeForPeriod(String period) {
    switch (period) {
      case 'morning':
        return '09:00';
      case 'noon':
        return '13:00';
      case 'evening':
        return '17:00';
      default:
        return '09:00';
    }
  }

  void setHabitCategory(String category) {
    _habitCategory = category;
    notifyListeners();
  }

  void setHabitDifficulty(String difficulty) {
    _habitDifficulty = difficulty;
    notifyListeners();
  }

  void setHabitTimePeriod(String period) {
    _habitTimePeriod = period;
    notifyListeners();
  }

  void setSelectedIcon(String icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  // ===== YENİ TASARIM: ALIŞKANLIK FORM ALANLARI =====
  String _habitColor = '#F6A821';
  String get habitColor => _habitColor;
  void setHabitColor(String c) {
    _habitColor = c;
    notifyListeners();
  }

  int _habitGoal = 1;
  int get habitGoal => _habitGoal;
  void setHabitGoal(int g) {
    _habitGoal = g < 1 ? 1 : g;
    notifyListeners();
  }

  // daily | weekly | custom
  String _habitRecurrence = 'daily';
  String get habitRecurrence => _habitRecurrence;
  void setHabitRecurrence(String r) {
    _habitRecurrence = r;
    if (r == 'daily') _habitDays = {1, 2, 3, 4, 5, 6, 7};
    notifyListeners();
  }

  Set<int> _habitDays = {1, 2, 3, 4, 5, 6, 7}; // 1=Pzt .. 7=Paz
  Set<int> get habitDays => _habitDays;
  void toggleHabitDay(int d) {
    if (_habitDays.contains(d)) {
      _habitDays.remove(d);
    } else {
      _habitDays.add(d);
    }
    notifyListeners();
  }

  bool _habitReminderEnabled = true;
  bool get habitReminderEnabled => _habitReminderEnabled;
  void setHabitReminderEnabled(bool v) {
    _habitReminderEnabled = v;
    notifyListeners();
  }

  // Çoklu hatırlatıcı saatleri (Faz 3). Backend reminder_times zaten liste.
  List<TimeOfDay> _habitReminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
  List<TimeOfDay> get habitReminderTimes {
    final l = List<TimeOfDay>.from(_habitReminderTimes);
    l.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return l;
  }

  TimeOfDay get habitReminderTime =>
      _habitReminderTimes.isNotEmpty ? habitReminderTimes.first : const TimeOfDay(hour: 9, minute: 0);

  void setHabitReminderTime(TimeOfDay t) {
    _habitReminderTimes = [t];
    notifyListeners();
  }

  void addHabitReminderTime(TimeOfDay t) {
    final exists = _habitReminderTimes
        .any((x) => x.hour == t.hour && x.minute == t.minute);
    if (!exists) {
      _habitReminderTimes.add(t);
      notifyListeners();
    }
  }

  void removeHabitReminderTimeAt(int i) {
    final sorted = habitReminderTimes;
    if (i < 0 || i >= sorted.length) return;
    final t = sorted[i];
    _habitReminderTimes
        .removeWhere((x) => x.hour == t.hour && x.minute == t.minute);
    if (_habitReminderTimes.isEmpty) {
      _habitReminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
    }
    notifyListeners();
  }

  // Sıklık türü (Faz 3): times_per_day | times_per_week | times_per_month
  String _habitFreqType = 'times_per_day';
  String get habitFreqType => _habitFreqType;
  void setHabitFreqType(String t) {
    _habitFreqType = t;
    notifyListeners();
  }

  DateTime _habitStartDate = DateTime.now();
  DateTime get habitStartDate => _habitStartDate;
  void setHabitStartDate(DateTime d) {
    _habitStartDate = d;
    notifyListeners();
  }

  // ===== ALIŞKANLIK GÜNLÜK İLERLEMESİ (yerel) =====
  static const String _kHabitProgressKey = 'habit_progress_v1';
  final Map<int, int> _habitDailyCount = {};
  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadHabitProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHabitProgressKey);
      _habitDailyCount.clear();
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['date'] != _todayKey()) return; // eski gün → sıfır
      final counts = map['counts'] as Map<String, dynamic>?;
      counts?.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is int) _habitDailyCount[id] = v;
      });
    } catch (_) {}
  }

  Future<void> _persistHabitProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kHabitProgressKey,
          jsonEncode({
            'date': _todayKey(),
            'counts':
                _habitDailyCount.map((k, v) => MapEntry(k.toString(), v)),
          }));
    } catch (_) {}
  }

  int habitGoalOf(Habit h) => (h.targetFrequencyValue ?? 1) < 1
      ? 1
      : (h.targetFrequencyValue ?? 1);

  int habitProgressOf(Habit h) {
    if (isHabitDoneToday(h)) return habitGoalOf(h);
    return _habitDailyCount[h.id] ?? 0;
  }

  /// Bugün tamamlandı mı? Backend completed_today VEYA yerel sayacın hedefe
  /// ulaşması (cihaz saati sunucudan farklı olsa bile UI doğru görünsün).
  bool isHabitDoneToday(Habit h) =>
      h.completedToday || (_habitDailyCount[h.id] ?? 0) >= habitGoalOf(h);

  /// Alışkanlık dairesine dokunulunca: hedefe göre artır veya tamamla.
  Future<void> tapHabit(Habit h, BuildContext context) async {
    final goal = habitGoalOf(h);
    if (isHabitDoneToday(h)) {
      _habitDailyCount[h.id] = 0;
      await _persistHabitProgress();
      await toggleHabitComplete(h, context);
      return;
    }
    if (goal <= 1) {
      _habitDailyCount[h.id] = goal;
      await _persistHabitProgress();
      await toggleHabitComplete(h, context);
      return;
    }
    final cur = (_habitDailyCount[h.id] ?? 0) + 1;
    if (cur >= goal) {
      _habitDailyCount[h.id] = goal;
      await _persistHabitProgress();
      await toggleHabitComplete(h, context);
    } else {
      _habitDailyCount[h.id] = cur;
      await _persistHabitProgress();
      notifyListeners();
    }
  }

  // Alışkanlık istatistikleri (üst kart)
  int get habitTodayDone => _habits.where(isHabitDoneToday).length;
  int get habitTodayTotal => _habits.length;
  double get habitDayProgress =>
      _habits.isEmpty ? 0 : habitTodayDone / _habits.length;
  int get habitBestStreak => longestStreak;
  int get habitDayPercent => (habitDayProgress * 100).round();

  void resetTaskForm() {
    taskTitleController.clear();
    taskDescriptionController.clear();
    _taskPriority = 1;
    _taskType = 'daily';
    _taskRecurrence = 'none';
    _reminderEnabled = false;
    _reminderBeforeMinutes = 30;
    _reminderTime = null;
    _editingTaskId = null;
    _taskDueDate = DateTime.now(); // yeni görevler varsayılan bugüne
    _taskDueTime = null;
    _taskCategory = null;
    _taskTags.clear();
    _taskLocation = null;
    _taskLink = null;
    _subtaskDrafts.clear();
    _taskPickedFiles.clear();
    _editingTaskAttachments = [];
    notifyListeners();
  }

  void resetHabitForm() {
    habitTitleController.clear();
    habitDescriptionController.clear();
    habitCueController.clear();
    habitRewardController.clear();
    _habitCategory = 'health';
    _habitDifficulty = 'beginner';
    _habitTimePeriod = 'morning';
    _selectedIcon = 'star';
    _editingHabitId = null;
    _habitColor = '#F6A821';
    _habitGoal = 1;
    _habitRecurrence = 'daily';
    _habitDays = {1, 2, 3, 4, 5, 6, 7};
    _habitReminderEnabled = true;
    _habitReminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
    _habitFreqType = 'times_per_day';
    _habitStartDate = DateTime.now();
    notifyListeners();
  }

  HabitRequest _buildHabitRequest() {
    final rts = habitReminderTimes
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();
    return HabitRequest(
      title: habitTitleController.text.trim(),
      description: null,
      category: _habitCategory,
      icon: _selectedIcon,
      color: _habitColor,
      difficultyLevel: _habitDifficulty,
      timePeriod: _habitRecurrence == 'weekly' ? 'weekly' : 'daily',
      targetFrequencyType: _habitFreqType,
      targetFrequencyValue: _habitGoal,
      reminderEnabled: _habitReminderEnabled,
      reminderTimes: _habitReminderEnabled ? rts : null,
      specificDays: _habitRecurrence == 'custom'
          ? (_habitDays.toList()..sort())
          : null,
      whyDescription: habitDescriptionController.text.trim().isEmpty
          ? null
          : habitDescriptionController.text.trim(),
      motivationQuote: null,
      cue: habitCueController.text.trim().isEmpty
          ? null
          : habitCueController.text.trim(),
      reward: habitRewardController.text.trim().isEmpty
          ? null
          : habitRewardController.text.trim(),
      isPublic: false,
    );
  }

  // ==================== TASK DÜZENLEME ====================

  void prepareEditTask(Task task) {
    _editingTaskId = task.id;
    taskTitleController.text = task.title;
    taskDescriptionController.text = task.description ?? '';
    _taskPriority = task.priority;
    _taskType = task.taskType;
    _taskRecurrence = task.recurringPattern ?? 'none';
    _reminderEnabled = task.reminderEnabled;
    _reminderBeforeMinutes = task.reminderBeforeMinutes ?? 30;

    // Tarih & saat
    _taskDueDate = dueDateOf(task);
    _taskDueTime = null;
    if (task.dueTime != null) {
      try {
        final p = task.dueTime!.split(':');
        if (p.length >= 2) {
          _taskDueTime =
              TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      } catch (_) {}
    }

    // Meta backend'den (kategori/etiket/konum/bağlantı/ek)
    _taskCategory = task.category;
    _taskTags
      ..clear()
      ..addAll(task.tags);
    _taskLocation = task.location;
    _taskLink = task.link;
    _editingTaskAttachments = List.from(task.attachments);
    _taskPickedFiles.clear();
    _subtaskDrafts.clear();

    // Parse reminder_time if exists (format: "HH:mm:ss" or "HH:mm")
    if (task.reminderTime != null) {
      try {
        final parts = task.reminderTime!.split(':');
        if (parts.length >= 2) {
          _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        _reminderTime = null;
      }
    } else {
      _reminderTime = null;
    }

    notifyListeners();
  }

  Future<void> updateTask(BuildContext context) async {
    // Doğal dil çözümlemesini uygula (başlıkta tarih/saat/öncelik/etiket varsa).
    _applyNlParseToState();
    if (_editingTaskId == null) {
      CustomSnackBar.showError(context, 'errors.taskNotFound'.tr());
      return;
    }

    if (taskTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.taskTitleEmpty'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Convert TimeOfDay to HH:mm format
      String? reminderTimeString;
      if (_reminderEnabled && _reminderTime != null) {
        final hour = _reminderTime!.hour.toString().padLeft(2, '0');
        final minute = _reminderTime!.minute.toString().padLeft(2, '0');
        reminderTimeString = '$hour:$minute';
      }

      final request = TaskRequest(
        title: taskTitleController.text.trim(),
        description: taskDescriptionController.text.trim().isEmpty
            ? null
            : taskDescriptionController.text.trim(),
        taskType: _taskType,
        priority: _taskPriority,
        reminderEnabled: _reminderEnabled,
        isRecurring: _taskRecurrence != 'none',
        recurringPattern: _taskRecurrence != 'none' ? _taskRecurrence : null,
        dueDate: _fmtDueDate(_taskDueDate),
        dueTime: _fmtDueTime(_taskDueTime),
        reminderBeforeMinutes: _reminderEnabled && _reminderTime == null ? _reminderBeforeMinutes : null,
        reminderTime: reminderTimeString,
        estimatedDurationMinutes: null,
        parentTaskId: null,
        category: _taskCategory,
        tags: _taskTags.isEmpty ? null : List.from(_taskTags),
        location: _taskLocation,
        link: _taskLink,
      );

      final editingId = _editingTaskId!;
      final response = await _taskService.updateTask(editingId, request);

      if (response.isSuccess && response.data != null) {
        final index = _tasks.indexWhere((t) => t.id == editingId);
        if (index != -1) {
          _tasks[index] = response.data!;
        }
        // Yeni seçilen yerel dosyaları backend'e yükle.
        await _uploadTaskAttachments(editingId);
        resetTaskForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.taskUpdated'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.updateFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.taskUpdateFailed'.tr());
      }
      debugPrint('Task update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HABIT DÜZENLEME ====================

  void prepareEditHabit(Habit habit) {
    _editingHabitId = habit.id;
    habitTitleController.text = habit.title;
    habitDescriptionController.text =
        habit.whyDescription ?? habit.description ?? '';
    habitCueController.text = habit.cue ?? '';
    habitRewardController.text = habit.reward ?? '';
    _habitCategory = habit.category;
    _habitDifficulty = habit.difficultyLevel;
    _selectedIcon = habit.icon ?? '⭐';
    _habitTimePeriod = _getTimePeriodFromReminderTimes(habit.reminderTimes);

    _habitColor = habit.color ?? '#F6A821';
    _habitGoal = habit.targetFrequencyValue ?? 1;
    _habitFreqType = habit.targetFrequencyType.isEmpty
        ? 'times_per_day'
        : habit.targetFrequencyType;
    if (habit.specificDays != null && habit.specificDays!.isNotEmpty) {
      _habitRecurrence = 'custom';
      _habitDays = habit.specificDays!.toSet();
    } else if (habit.timePeriod == 'weekly') {
      _habitRecurrence = 'weekly';
      _habitDays = {1, 2, 3, 4, 5, 6, 7};
    } else {
      _habitRecurrence = 'daily';
      _habitDays = {1, 2, 3, 4, 5, 6, 7};
    }
    _habitReminderEnabled = habit.reminderEnabled;
    if (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty) {
      final parsed = <TimeOfDay>[];
      for (final s in habit.reminderTimes!) {
        try {
          final p = s.split(':');
          parsed.add(
              TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
        } catch (_) {}
      }
      if (parsed.isNotEmpty) _habitReminderTimes = parsed;
    }
    _habitStartDate = DateTime.now();
    notifyListeners();
  }

  // Hatırlatma saatinden zaman dilimini belirle
  String _getTimePeriodFromReminderTimes(List<String>? reminderTimes) {
    if (reminderTimes == null || reminderTimes.isEmpty) {
      return 'morning';
    }

    final time = reminderTimes.first;
    final hour = int.tryParse(time.split(':').first) ?? 9;

    if (hour < 12) {
      return 'morning';
    } else if (hour < 15) {
      return 'noon';
    } else {
      return 'evening';
    }
  }

  Future<void> updateHabit(BuildContext context) async {
    if (_editingHabitId == null) {
      CustomSnackBar.showError(context, 'errors.habitNotFound'.tr());
      return;
    }

    if (habitTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.habitTitleEmpty'.tr());
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = _buildHabitRequest();

      final response = await _habitService.updateHabit(_editingHabitId!, request);

      if (response.isSuccess && response.data != null) {
        final index = _habits.indexWhere((h) => h.id == _editingHabitId);
        if (index != -1) {
          _habits[index] = response.data!;
        }
        resetHabitForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.habitUpdated'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.updateFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.habitUpdateFailed'.tr());
      }
      debugPrint('Habit update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    habitTitleController.dispose();
    habitDescriptionController.dispose();
    habitCueController.dispose();
    habitRewardController.dispose();
    super.dispose();
  }

  // ==================== TASKS ====================

  Future<void> _loadCurrentUser() async {
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    } finally {
      _isUserLoaded = true;
      notifyListeners();
    }
  }

  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      notifyListeners();

      // User bilgisini çek (premium kontrolü için)
      await _loadCurrentUser();

      final response = await _taskService.getAllTasks(
        sortBy: 'due_date',
        sortOrder: 'asc',
      );

      if (response.isSuccess && response.data != null) {
        _tasks = response.data!;
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(BuildContext context) async {
    // Doğal dil: "yarın 15:00 ... !1 #ev" → tarih/saat/öncelik/etiket.
    _applyNlParseToState();
    if (taskTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.taskTitleEmpty'.tr());
      return;
    }

    // Premium limit kontrolü
    final canCreate = await PremiumHelper.checkTaskLimit(
      context: context,
      user: _currentUser,
      currentTaskCount: _tasks.length,
    );

    if (!canCreate) {
      return; // Limit aşıldı, paywall gösterildi
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Convert TimeOfDay to HH:mm format
      String? reminderTimeString;
      if (_reminderEnabled && _reminderTime != null) {
        final hour = _reminderTime!.hour.toString().padLeft(2, '0');
        final minute = _reminderTime!.minute.toString().padLeft(2, '0');
        reminderTimeString = '$hour:$minute';
      }

      final request = TaskRequest(
        title: taskTitleController.text.trim(),
        description: taskDescriptionController.text.trim().isEmpty
            ? null
            : taskDescriptionController.text.trim(),
        taskType: _taskType,
        priority: _taskPriority,
        reminderEnabled: _reminderEnabled,
        isRecurring: _taskRecurrence != 'none',
        recurringPattern: _taskRecurrence != 'none' ? _taskRecurrence : null,
        dueDate: _fmtDueDate(_taskDueDate),
        dueTime: _fmtDueTime(_taskDueTime),
        reminderBeforeMinutes: _reminderEnabled && _reminderTime == null ? _reminderBeforeMinutes : null,
        reminderTime: reminderTimeString,
        estimatedDurationMinutes: null,
        parentTaskId: null,
        category: _taskCategory,
        tags: _taskTags.isEmpty ? null : List.from(_taskTags),
        location: _taskLocation,
        link: _taskLink,
      );

      final response = await _taskService.createTask(request);

      if (response.isSuccess && response.data != null) {
        final parent = response.data!;
        _tasks.insert(0, parent);
        // Ekleri backend'e yükle (kategori/etiket/konum/bağlantı istekle gitti).
        await _uploadTaskAttachments(parent.id);
        // Alt görevleri oluştur (backend: parent_task_id)
        for (final title in List<String>.from(_subtaskDrafts)) {
          final subReq = TaskRequest(
            title: title,
            taskType: _taskType,
            priority: _taskPriority,
            reminderEnabled: false,
            isRecurring: false,
            parentTaskId: parent.id,
            dueDate: _fmtDueDate(_taskDueDate),
          );
          final subRes = await _taskService.createTask(subReq);
          if (subRes.isSuccess && subRes.data != null) {
            _tasks.add(subRes.data!);
          }
        }
        resetTaskForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.taskAdded'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.unknownError'.tr(),
          );
        }
        debugPrint('Task creation error: ${response.errors}');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.taskAddFailed'.tr());
      }
      debugPrint('Task creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gecikmiş (açık) görevleri bugüne taşır — her görevin verisini koruyarak
  /// yalnızca dueDate'i bugün yapar. Planlayıcıdaki "Gecikenleri bugüne taşı".
  Future<void> carryOverdueToToday(BuildContext context) async {
    final today = _fmtDueDate(DateTime.now());
    final list = List<Task>.from(overdueTasksList);
    if (list.isEmpty) return;
    int moved = 0;
    for (final t in list) {
      final req = TaskRequest(
        title: t.title,
        description: t.description,
        taskType: t.taskType,
        priority: t.priority,
        reminderEnabled: t.reminderEnabled,
        isRecurring: t.isRecurring,
        recurringPattern: t.recurringPattern,
        dueDate: today,
        dueTime: t.dueTime,
        reminderBeforeMinutes: t.reminderBeforeMinutes,
        reminderTime: t.reminderTime,
        estimatedDurationMinutes: t.estimatedDurationMinutes,
        parentTaskId: t.parentTaskId,
        category: t.category,
        tags: t.tags.isEmpty ? null : List.from(t.tags),
        location: t.location,
        link: t.link,
      );
      try {
        final resp = await _taskService.updateTask(t.id, req);
        if (resp.isSuccess) moved++;
      } catch (_) {}
    }
    if (moved > 0) await refreshAll();
    if (context.mounted) {
      CustomSnackBar.showSuccess(
          context, 'tasks.planner.movedCount'.tr(namedArgs: {'n': '$moved'}));
    }
  }

  Future<void> toggleTaskComplete(Task task, BuildContext context) async {
    try {
      if (task.isCompleted) {
        final response = await _taskService.markIncomplete(task.id);
        if (response.isSuccess) {
          // Update only this task in the list
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(
              isCompleted: false,
              completedAt: null,
            );
            notifyListeners();
          }
          if (context.mounted) {
            CustomSnackBar.showInfo(context, 'success.taskMarkedIncomplete'.tr());
          }
        }
      } else {
        final response = await _taskService.markComplete(task.id);
        if (response.isSuccess) {
          // Update only this task in the list
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            );
            notifyListeners();
          }
          if (context.mounted) {
            CustomSnackBar.showSuccess(context, 'success.taskCompleted'.tr());
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    }
  }

  Future<void> deleteTask(int taskId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _taskService.deleteTask(taskId);

      if (response.isSuccess) {
        _tasks.removeWhere((t) => t.id == taskId || t.parentTaskId == taskId);
        // Meta + ekler backend'de; silme sunucuda cascade temizleniyor.
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.taskDeleted'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, response.errorMessage ?? 'errors.general'.tr());
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.taskDeleteFailed'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _fmtDueDate(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String? _fmtDueTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Alt görev tamamlanınca listeyi anında günceller (backend + yerel).
  Future<void> toggleSubtask(Task sub, BuildContext context) async {
    await toggleTaskComplete(sub, context);
  }

  /// Var olan bir göreve anında alt görev ekler (düzenleme modunda).
  Future<void> addSubtaskToTask(int parentId, String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    try {
      final req = TaskRequest(
        title: t,
        taskType: _taskType,
        priority: 1,
        reminderEnabled: false,
        isRecurring: false,
        parentTaskId: parentId,
      );
      final res = await _taskService.createTask(req);
      if (res.isSuccess && res.data != null) {
        _tasks.add(res.data!);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> removeSubtask(int subId) async {
    try {
      final res = await _taskService.deleteTask(subId);
      if (res.isSuccess) {
        _tasks.removeWhere((t) => t.id == subId);
        notifyListeners();
      }
    } catch (_) {}
  }

  Color getTaskPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return const Color(0xFF81C784); // Green
      case 1:
        return const Color(0xFFFFD54F); // Yellow
      case 2:
        return const Color(0xFFFF5252); // Red
      default:
        return const Color(0xFF7EC8F5); // Blue
    }
  }

  // ==================== HABITS ====================

  Future<void> loadHabits() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _habitService.getAllHabits(
        isActive: true,
      );

      if (response.isSuccess && response.data != null) {
        _habits = response.data!;
      }
      await loadHabitProgress();
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHabit(BuildContext context) async {
    if (habitTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.habitTitleEmpty'.tr());
      return;
    }

    // Premium limit kontrolü
    final canCreate = await PremiumHelper.checkHabitLimit(
      context: context,
      user: _currentUser,
      currentHabitCount: _habits.length,
    );

    if (!canCreate) {
      return; // Limit aşıldı, paywall gösterildi
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = _buildHabitRequest();

      final response = await _habitService.createHabit(request);

      if (response.isSuccess && response.data != null) {
        _habits.insert(0, response.data!);
        resetHabitForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.habitAdded'.tr());
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.unknownError'.tr(),
          );
        }
        debugPrint('Habit creation error: ${response.errors}');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.habitAddFailed'.tr());
      }
      debugPrint('Habit creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleHabitComplete(Habit habit, BuildContext context) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final request = CompleteHabitRequest(
        date: today,
        notes: null,
      );

      final response = await _habitService.markComplete(habit.id, request);

      if (response.isSuccess) {
        await loadHabits();
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            habit.completedToday
                ? 'success.habitCancelled'.tr()
                : 'success.habitCompleted'.tr(),
          );
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.general'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Toggle habit exception: $e');
    }
  }

  /// Alışkanlık istatistikleri (seri/tamamlanma oranı) — geçmiş ekranı için.
  Future<HabitStats?> fetchHabitStats(int id, {int days = 56}) async {
    try {
      final r = await _habitService.getHabitStats(id, days: days);
      return r.isSuccess ? r.data : null;
    } catch (_) {
      return null;
    }
  }

  /// Bugünün tamamlama kaydına not ekler/günceller (markComplete upsert eder).
  /// Not: alışkanlığı bugün için tamamlanmış olarak işaretler.
  Future<bool> setHabitTodayNote(int habitId, String note) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = await _habitService.markComplete(
        habitId,
        CompleteHabitRequest(
            date: today, notes: note.trim().isEmpty ? null : note.trim()),
      );
      if (r.isSuccess) {
        await loadHabits();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Alışkanlık günlük kayıtları (ısı haritası için) — son [days] gün.
  Future<List<HabitLog>> fetchHabitLogs(int id, {int days = 56}) async {
    try {
      final r =
          await _habitService.getHabitLogs(id, days: days, perPage: days + 10);
      return (r.isSuccess && r.data != null) ? r.data!.data : <HabitLog>[];
    } catch (_) {
      return <HabitLog>[];
    }
  }

  /// Alışkanlığı bugün için atla (seriyi bozmadan "dinlenme günü"). İsteğe
  /// bağlı sebep. Backend skipHabit zaten vardı, UI'a yeni açılıyor.
  Future<void> skipHabitToday(Habit habit, BuildContext context,
      {String? reason}) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _habitService.skipHabit(
        habit.id,
        SkipHabitRequest(date: today, reason: reason),
      );
      if (response.isSuccess) {
        await loadHabits();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.habitSkipped'.tr());
        }
      } else if (context.mounted) {
        CustomSnackBar.showError(
            context, response.errorMessage ?? 'errors.general'.tr());
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Skip habit exception: $e');
    }
  }

  Future<void> deleteHabit(int habitId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _habitService.deleteHabit(habitId);

      if (response.isSuccess) {
        _habits.removeWhere((h) => h.id == habitId);
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'success.habitDeleted'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'errors.general'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.habitDeleteFailed'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Color getHabitColor(String? colorHex) {
    if (colorHex == null) return const Color(0xFFB794F6);
    try {
      return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (e) {
      return const Color(0xFFB794F6);
    }
  }

  // ==================== COMMON ====================

  bool _taskMetaMigrated = false;

  Future<void> refreshAll() async {
    await Future.wait([
      loadTasks(),
      loadHabits(),
    ]);
    // Eski yerel task meta'sını bir kez backend'e taşı (ilk yüklemeden sonra).
    if (!_taskMetaMigrated) {
      _taskMetaMigrated = true;
      await migrateLocalTaskMetaOnce();
    }
  }
}