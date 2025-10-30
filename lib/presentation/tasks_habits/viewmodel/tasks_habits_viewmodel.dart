import 'package:flutter/material.dart';
import '../../../core/init/locator.dart';
import '../../../service/task/task_service.dart';
import '../../../service/habit/habit_service.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../../../core/utils/custom_snackbar.dart';

class TasksHabitsViewModel extends ChangeNotifier {
  final ITaskService _taskService = locator.get<ITaskService>();
  final IHabitService _habitService = locator.get<IHabitService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Tasks
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;

  // Habits
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  int get completedTodayCount => _habits.where((h) => h.completedToday).length;
  int get longestStreak => _habits.isEmpty
      ? 0
      : _habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);

  // Editing state
  int? _editingTaskId;
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

  // Habit Form State
  final TextEditingController habitTitleController = TextEditingController();
  final TextEditingController habitDescriptionController = TextEditingController();
  String _habitCategory = 'health_fitness';
  String get habitCategory => _habitCategory;
  String _habitDifficulty = 'beginner';
  String get habitDifficulty => _habitDifficulty;
  String _selectedIcon = '⭐';
  String get selectedIcon => _selectedIcon;

  void setHabitCategory(String category) {
    _habitCategory = category;
    notifyListeners();
  }

  void setHabitDifficulty(String difficulty) {
    _habitDifficulty = difficulty;
    notifyListeners();
  }

  void setSelectedIcon(String icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  void resetTaskForm() {
    taskTitleController.clear();
    taskDescriptionController.clear();
    _taskPriority = 1;
    _taskType = 'daily';
    _taskRecurrence = 'none';
    _editingTaskId = null;
    notifyListeners();
  }

  void resetHabitForm() {
    habitTitleController.clear();
    habitDescriptionController.clear();
    _habitCategory = 'health_fitness';
    _habitDifficulty = 'beginner';
    _selectedIcon = '⭐';
    _editingHabitId = null;
    notifyListeners();
  }

  // ==================== TASK DÜZENLEME ====================

  void prepareEditTask(Task task) {
    _editingTaskId = task.id;
    taskTitleController.text = task.title;
    taskDescriptionController.text = task.description ?? '';
    _taskPriority = task.priority;
    _taskType = task.taskType;
    _taskRecurrence = task.recurringPattern ?? 'none';
    notifyListeners();
  }

  Future<void> updateTask(BuildContext context) async {
    if (_editingTaskId == null) {
      CustomSnackBar.showError(context, 'Düzenlenecek görev bulunamadı');
      return;
    }

    if (taskTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Görev başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = TaskRequest(
        title: taskTitleController.text.trim(),
        description: taskDescriptionController.text.trim().isEmpty
            ? null
            : taskDescriptionController.text.trim(),
        taskType: _taskType,
        priority: _taskPriority,
        reminderEnabled: false,
        isRecurring: _taskRecurrence != 'none',
        recurringPattern: _taskRecurrence != 'none' ? _taskRecurrence : null,
        dueDate: null,
        dueTime: null,
        reminderBeforeMinutes: null,
        estimatedDurationMinutes: null,
        parentTaskId: null,
      );

      final response = await _taskService.updateTask(_editingTaskId!, request);

      if (response.isSuccess && response.data != null) {
        final index = _tasks.indexWhere((t) => t.id == _editingTaskId);
        if (index != -1) {
          _tasks[index] = response.data!;
        }
        resetTaskForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'Görev güncellendi');
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Güncelleme başarısız',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Görev güncellenirken hata oluştu');
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
    habitDescriptionController.text = habit.description ?? '';
    _habitCategory = habit.category;
    _habitDifficulty = habit.difficultyLevel;
    _selectedIcon = habit.icon ?? '⭐';
    notifyListeners();
  }

  Future<void> updateHabit(BuildContext context) async {
    if (_editingHabitId == null) {
      CustomSnackBar.showError(context, 'Düzenlenecek alışkanlık bulunamadı');
      return;
    }

    if (habitTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Alışkanlık başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = HabitRequest(
        title: habitTitleController.text.trim(),
        description: habitDescriptionController.text.trim().isEmpty
            ? null
            : habitDescriptionController.text.trim(),
        category: _habitCategory,
        icon: _selectedIcon,
        color: '#FFD54F',
        difficultyLevel: _habitDifficulty,
        timePeriod: 'daily',
        targetFrequencyType: 'times_per_day',
        targetFrequencyValue: 1,
        reminderEnabled: false,
        reminderTimes: null,
        specificDays: null,
        whyDescription: null,
        motivationQuote: null,
        cue: null,
        reward: null,
        isPublic: false,
      );

      final response = await _habitService.updateHabit(_editingHabitId!, request);

      if (response.isSuccess && response.data != null) {
        final index = _habits.indexWhere((h) => h.id == _editingHabitId);
        if (index != -1) {
          _habits[index] = response.data!;
        }
        resetHabitForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'Alışkanlık güncellendi');
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Güncelleme başarısız',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Alışkanlık güncellenirken hata oluştu');
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
    super.dispose();
  }

  // ==================== TASKS ====================

  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      notifyListeners();

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
    if (taskTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Görev başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = TaskRequest(
        title: taskTitleController.text.trim(),
        description: taskDescriptionController.text.trim().isEmpty
            ? null
            : taskDescriptionController.text.trim(),
        taskType: _taskType,
        priority: _taskPriority,
        reminderEnabled: false,
        isRecurring: _taskRecurrence != 'none',
        recurringPattern: _taskRecurrence != 'none' ? _taskRecurrence : null,
        dueDate: null,
        dueTime: null,
        reminderBeforeMinutes: null,
        estimatedDurationMinutes: null,
        parentTaskId: null,
      );

      final response = await _taskService.createTask(request);

      if (response.isSuccess && response.data != null) {
        _tasks.insert(0, response.data!);
        resetTaskForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'Görev başarıyla eklendi');
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Bilinmeyen hata',
          );
        }
        debugPrint('Task creation error: ${response.errors}');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Görev eklenirken hata oluştu');
      }
      debugPrint('Task creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskComplete(Task task, BuildContext context) async {
    try {
      if (task.isCompleted) {
        final response = await _taskService.markIncomplete(task.id);
        if (response.isSuccess) {
          await loadTasks();
          if (context.mounted) {
            CustomSnackBar.showInfo(context, 'Görev tamamlanmadı olarak işaretlendi');
          }
        }
      } else {
        final response = await _taskService.markComplete(task.id);
        if (response.isSuccess) {
          await loadTasks();
          if (context.mounted) {
            CustomSnackBar.showSuccess(context, 'Görev tamamlandı! 🎉');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız oldu');
      }
    }
  }

  Future<void> deleteTask(int taskId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _taskService.deleteTask(taskId);

      if (response.isSuccess) {
        _tasks.removeWhere((t) => t.id == taskId);
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'Görev silindi');
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, response.errorMessage ?? 'Hata oluştu');
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Görev silinirken hata oluştu');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHabit(BuildContext context) async {
    if (habitTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Alışkanlık başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = HabitRequest(
        title: habitTitleController.text.trim(),
        description: habitDescriptionController.text.trim().isEmpty
            ? null
            : habitDescriptionController.text.trim(),
        category: _habitCategory,
        icon: _selectedIcon,
        color: '#FFD54F',
        difficultyLevel: _habitDifficulty,
        timePeriod: 'daily',
        targetFrequencyType: 'times_per_day',
        targetFrequencyValue: 1,
        reminderEnabled: false,
        reminderTimes: null,
        specificDays: null,
        whyDescription: null,
        motivationQuote: null,
        cue: null,
        reward: null,
        isPublic: false,
      );

      final response = await _habitService.createHabit(request);

      if (response.isSuccess && response.data != null) {
        _habits.insert(0, response.data!);
        resetHabitForm();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'Alışkanlık başarıyla eklendi');
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Bilinmeyen hata',
          );
        }
        debugPrint('Habit creation error: ${response.errors}');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Alışkanlık eklenirken hata oluştu');
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
                ? 'Alışkanlık iptal edildi'
                : 'Harika! Alışkanlık tamamlandı 🎉',
          );
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Hata oluştu',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız oldu');
      }
      debugPrint('Toggle habit exception: $e');
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
          CustomSnackBar.showSuccess(context, 'Alışkanlık silindi');
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage ?? 'Hata oluştu',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Alışkanlık silinirken hata oluştu');
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

  Future<void> refreshAll() async {
    await Future.wait([
      loadTasks(),
      loadHabits(),
    ]);
  }
}