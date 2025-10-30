import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/init/locator.dart';
import '../../../models/calender/calendar_models.dart';
import '../../../service/calender/calendar_service.dart';
import '../../../service/note/note_service.dart';
import '../../../service/diary/diary_service.dart';
import '../../../service/task/task_service.dart';
import '../../../service/subscription/subscription_service.dart';
import '../../../service/expense/expense_service.dart';
import '../../../models/note/note_models.dart';
import '../../../models/diary/diary_models.dart';
import '../../../models/task/task_models.dart';
import '../../../models/subscription/subscription_models.dart';
import '../../../models/budget/buget_models.dart';

enum CalendarViewType { month, week }

class CalendarViewModel extends ChangeNotifier {
  final INoteService _noteService = locator.get<INoteService>();
  final IDiaryService _diaryService = locator.get<IDiaryService>();
  final ITaskService _taskService = locator.get<ITaskService>();
  final ISubscriptionService _subscriptionService = locator.get<ISubscriptionService>();
  final IExpenseService _expenseService = locator.get<IExpenseService>();
  final ICalendarService _calendarService = locator.get<ICalendarService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  DateTime _focusedMonth = DateTime.now();
  DateTime get focusedMonth => _focusedMonth;

  CalendarViewType _calendarViewType = CalendarViewType.month;
  CalendarViewType get calendarViewType => _calendarViewType;

  // Tüm veriler
  List<Note> _notes = [];
  List<Diary> _diaryEntries = [];
  List<Task> _tasks = [];
  List<Subscription> _subscriptions = [];
  List<Expense> _expenses = [];
  List<CalendarEvent> _calendarEvents = [];

  // Calendar events getter
  List<CalendarEvent> get calendarEvents => _calendarEvents;

  // Seçili güne ait calendar events
  List<CalendarEvent> get calendarEventsForSelectedDate {
    final filtered = _calendarEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event.eventDate);
        return eventDate.year == _selectedDate.year &&
            eventDate.month == _selectedDate.month &&
            eventDate.day == _selectedDate.day;
      } catch (e) {
        debugPrint('⚠️ Calendar: Invalid event date format: ${event.eventDate}');
        return false;
      }
    }).toList();

    debugPrint('📅 Calendar: Calendar events for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  // Event type'a göre filtrele
  List<CalendarEvent> getCalendarEventsByType(String eventType) {
    return calendarEventsForSelectedDate
        .where((event) => event.eventType == eventType)
        .toList();
  }

  // Seçili güne ait veriler
  List<Note> get notesForSelectedDate {
    final filtered = _notes.where((note) {
      final noteDate = note.createdAt;
      return noteDate.year == _selectedDate.year &&
          noteDate.month == _selectedDate.month &&
          noteDate.day == _selectedDate.day;
    }).toList();

    debugPrint('📝 Calendar: Notes for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  // Seçili güne ait kilit olmayan notlar
  List<Note> get unlockedNotesForSelectedDate {
    final filtered = notesForSelectedDate.where((note) => !note.isLocked).toList();
    debugPrint('🔓 Calendar: Unlocked notes for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  // Seçili güne ait kilitli notlar
  List<Note> get lockedNotesForSelectedDate {
    final filtered = notesForSelectedDate.where((note) => note.isLocked).toList();
    debugPrint('🔒 Calendar: Locked notes for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  Diary? get diaryForSelectedDate {
    try {
      final diary = _diaryEntries.firstWhere((diary) {
        final diaryDate = diary.diaryDate;
        return diaryDate.year == _selectedDate.year &&
            diaryDate.month == _selectedDate.month &&
            diaryDate.day == _selectedDate.day;
      });
      debugPrint('📔 Calendar: Diary found for ${_selectedDate.day}/${_selectedDate.month}');
      return diary;
    } catch (e) {
      debugPrint('📔 Calendar: No diary for ${_selectedDate.day}/${_selectedDate.month}');
      return null;
    }
  }

  List<Task> get tasksForSelectedDate {
    final filtered = _tasks.where((task) {
      if (task.dueDate == null) return false;
      try {
        // dueDate String formatında (YYYY-MM-DD)
        final taskDate = DateTime.parse(task.dueDate!);
        return taskDate.year == _selectedDate.year &&
            taskDate.month == _selectedDate.month &&
            taskDate.day == _selectedDate.day;
      } catch (e) {
        debugPrint('⚠️ Calendar: Invalid task date format: ${task.dueDate}');
        return false;
      }
    }).toList();

    debugPrint('✅ Calendar: Tasks for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  List<Expense> get expensesForSelectedDate {
    final filtered = _expenses.where((expense) {
      final expenseDate = expense.expenseDate;
      return expenseDate.year == _selectedDate.year &&
          expenseDate.month == _selectedDate.month &&
          expenseDate.day == _selectedDate.day;
    }).toList();

    debugPrint('💰 Calendar: Expenses for ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  List<Subscription> get subscriptionsForSelectedDate {
    // Abonelikler - seçili günde ödeme günü olanlar (tüm aktif abonelikler her ayda gösterilir)
    final filtered = _subscriptions.where((sub) {
      if (!sub.isActive) return false;
      return sub.billingDate == _selectedDate.day;
    }).toList();

    debugPrint('💳 Calendar: Subscriptions due on ${_selectedDate.day}/${_selectedDate.month}: ${filtered.length}');
    return filtered;
  }

  // Aya göre event'lerin olduğu günler
  Map<DateTime, List<String>> getEventsForMonth() {
    final events = <DateTime, List<String>>{};

    // Calendar events'leri ekle
    for (var event in _calendarEvents) {
      try {
        final eventDateTime = DateTime.parse(event.eventDate);
        final date = DateTime(
          eventDateTime.year,
          eventDateTime.month,
          eventDateTime.day,
        );
        if (!events.containsKey(date)) {
          events[date] = [];
        }
        if (!events[date]!.contains('calendar_${event.eventType}')) {
          events[date]!.add('calendar_${event.eventType}');
        }
      } catch (e) {
        debugPrint('⚠️ Calendar: Invalid event date: ${event.eventDate}');
      }
    }

    // Notları ekle (hem kilitli hem kilitsiz)
    for (var note in _notes) {
      final date = DateTime(
        note.createdAt.year,
        note.createdAt.month,
        note.createdAt.day,
      );
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      // Kilitli notları ayrı işaretle
      if (note.isLocked) {
        if (!events[date]!.contains('locked_note')) {
          events[date]!.add('locked_note');
        }
      } else {
        if (!events[date]!.contains('note')) {
          events[date]!.add('note');
        }
      }
    }

    // Günlükleri ekle
    for (var diary in _diaryEntries) {
      final date = DateTime(
        diary.diaryDate.year,
        diary.diaryDate.month,
        diary.diaryDate.day,
      );
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      if (!events[date]!.contains('diary')) {
        events[date]!.add('diary');
      }
    }

    // Görevleri ekle
    for (var task in _tasks) {
      if (task.dueDate == null) continue;
      try {
        final taskDate = DateTime.parse(task.dueDate!);
        final date = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
        );
        if (!events.containsKey(date)) {
          events[date] = [];
        }
        if (!events[date]!.contains('task')) {
          events[date]!.add('task');
        }
      } catch (e) {
        debugPrint('⚠️ Calendar: Invalid task date: ${task.dueDate}');
      }
    }

    // Harcamaları ekle
    for (var expense in _expenses) {
      final date = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      if (!events[date]!.contains('expense')) {
        events[date]!.add('expense');
      }
    }

    // Abonelikleri ekle (her ayda billingDate'e göre göster)
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    for (var subscription in _subscriptions) {
      if (!subscription.isActive) continue;

      final billingDay = subscription.billingDate;
      if (billingDay >= 1 && billingDay <= monthEnd.day) {
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, billingDay);
        if (!events.containsKey(date)) {
          events[date] = [];
        }
        if (!events[date]!.contains('subscription')) {
          events[date]!.add('subscription');
        }
      }
    }

    debugPrint('📅 Calendar: Total event days in month: ${events.length}');
    return events;
  }

  // Belirli bir gün için kilit durumunu kontrol et
  bool hasLockedNotesOnDate(DateTime date) {
    return _notes.any((note) {
      final noteDate = note.createdAt;
      return note.isLocked &&
          noteDate.year == date.year &&
          noteDate.month == date.month &&
          noteDate.day == date.day;
    });
  }

  // Belirli bir gün için kilitsiz not durumunu kontrol et
  bool hasUnlockedNotesOnDate(DateTime date) {
    return _notes.any((note) {
      final noteDate = note.createdAt;
      return !note.isLocked &&
          noteDate.year == date.year &&
          noteDate.month == date.month &&
          noteDate.day == date.day;
    });
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    debugPrint('📆 Calendar: Selected date: ${date.day}/${date.month}/${date.year}');
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    debugPrint('📅 Calendar: Focused month: ${month.month}/${month.year}');
    loadDataForMonth(month.year, month.month);
  }

  void toggleCalendarViewType() {
    _calendarViewType = _calendarViewType == CalendarViewType.month
        ? CalendarViewType.week
        : CalendarViewType.month;
    debugPrint('🔄 Calendar: Toggled view type to: ${_calendarViewType.name}');
    _saveCalendarViewType();
    notifyListeners();
  }

  Future<void> _loadCalendarViewType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString('calendar_view_type');
      if (savedType != null) {
        _calendarViewType = savedType == 'week'
            ? CalendarViewType.week
            : CalendarViewType.month;
        debugPrint('💾 Calendar: Loaded view type: ${_calendarViewType.name}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading calendar view type: $e');
    }
  }

  Future<void> _saveCalendarViewType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'calendar_view_type',
        _calendarViewType == CalendarViewType.week ? 'week' : 'month',
      );
      debugPrint('💾 Calendar: Saved view type: ${_calendarViewType.name}');
    } catch (e) {
      debugPrint('❌ Calendar: Error saving calendar view type: $e');
    }
  }

  Future<void> loadDataForMonth(int year, int month) async {
    try {
      debugPrint('🔄 Calendar: Loading data for $month/$year');
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        _loadNotes(),
        _loadDiaryEntries(year, month),
        _loadTasks(),
        _loadSubscriptions(),
        _loadExpenses(year, month),
        _loadCalendarEvents(year, month),
      ]);

      debugPrint('✅ Calendar: Data loaded successfully');
      debugPrint('   - Notes: ${_notes.length}');
      debugPrint('   - Locked Notes: ${_notes.where((n) => n.isLocked).length}');
      debugPrint('   - Unlocked Notes: ${_notes.where((n) => !n.isLocked).length}');
      debugPrint('   - Diaries: ${_diaryEntries.length}');
      debugPrint('   - Tasks: ${_tasks.length}');
      debugPrint('   - Subscriptions: ${_subscriptions.length}');
      debugPrint('   - Expenses: ${_expenses.length}');
      debugPrint('   - Calendar Events: ${_calendarEvents.length}');
    } catch (e) {
      debugPrint('❌ Calendar: Error loading calendar data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotes() async {
    try {
      final response = await _noteService.getAllNotes();
      if (response.isSuccess && response.data != null) {
        _notes = response.data!;
        debugPrint('📝 Calendar: Loaded ${_notes.length} notes');
      } else {
        debugPrint('⚠️ Calendar: Failed to load notes: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading notes: $e');
    }
  }

  Future<void> _loadDiaryEntries(int year, int month) async {
    try {
      final response = await _diaryService.getAllDiaries(
        year: year,
        month: month,
      );
      if (response.isSuccess && response.data != null) {
        _diaryEntries = response.data!.data;
        debugPrint('📔 Calendar: Loaded ${_diaryEntries.length} diary entries');
      } else {
        debugPrint('⚠️ Calendar: Failed to load diary entries: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading diary entries: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final response = await _taskService.getAllTasks();
      if (response.isSuccess && response.data != null) {
        _tasks = response.data!;
        debugPrint('✅ Calendar: Loaded ${_tasks.length} tasks');
        // Task tarihlerini debug edelim
        for (var task in _tasks) {
          debugPrint('   Task: ${task.title} - dueDate: ${task.dueDate}');
        }
      } else {
        debugPrint('⚠️ Calendar: Failed to load tasks: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading tasks: $e');
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final response = await _subscriptionService.getAllSubscriptions();
      if (response.isSuccess && response.data != null) {
        _subscriptions = response.data!;
        debugPrint('💳 Calendar: Loaded ${_subscriptions.length} subscriptions');
        // Abonelik detaylarını debug edelim
        for (var sub in _subscriptions) {
          debugPrint('   Subscription: ${sub.name} - billingDate: ${sub.billingDate}, isActive: ${sub.isActive}');
        }
      } else {
        debugPrint('⚠️ Calendar: Failed to load subscriptions: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading subscriptions: $e');
    }
  }

  Future<void> _loadExpenses(int year, int month) async {
    try {
      // Seçili ayın tüm harcamalarını getir
      final response = await _expenseService.getAllExpenses(
        perPage: 100, // Ayda max 100 harcama varsayımı
      );
      if (response.isSuccess && response.data != null) {
        // Sadece seçili ayın harcamalarını filtrele
        _expenses = response.data!.data.where((expense) {
          return expense.expenseDate.year == year &&
              expense.expenseDate.month == month;
        }).toList();
        debugPrint('💰 Calendar: Loaded ${_expenses.length} expenses for $month/$year');
      } else {
        debugPrint('⚠️ Calendar: Failed to load expenses: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading expenses: $e');
    }
  }

  Future<void> _loadCalendarEvents(int year, int month) async {
    try {
      // Ayın başlangıç ve bitiş tarihlerini hesapla
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await _calendarService.getAllEvents(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      if (response.isSuccess && response.data != null) {
        _calendarEvents = response.data!;
        debugPrint('📅 Calendar: Loaded ${_calendarEvents.length} calendar events');
        // Event detaylarını debug edelim
        for (var event in _calendarEvents) {
          debugPrint('   Event: ${event.title} - type: ${event.eventType}, date: ${event.eventDate}');
        }
      } else {
        debugPrint('⚠️ Calendar: Failed to load calendar events: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error loading calendar events: $e');
    }
  }

  // Calendar Event CRUD operations
  Future<bool> createCalendarEvent(CalendarEventRequest request) async {
    try {
      debugPrint('➕ Calendar: Creating new event: ${request.title}');
      final response = await _calendarService.createEvent(request);

      if (response.isSuccess && response.data != null) {
        _calendarEvents.add(response.data!);
        notifyListeners();
        debugPrint('✅ Calendar: Event created successfully');
        return true;
      } else {
        debugPrint('❌ Calendar: Failed to create event: ${response.errorMessage}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Calendar: Error creating event: $e');
      return false;
    }
  }

  Future<bool> updateCalendarEvent(int eventId, CalendarEventUpdateRequest request) async {
    try {
      debugPrint('✏️ Calendar: Updating event: $eventId');
      final response = await _calendarService.updateEvent(eventId, request);

      if (response.isSuccess && response.data != null) {
        final index = _calendarEvents.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _calendarEvents[index] = response.data!;
          notifyListeners();
          debugPrint('✅ Calendar: Event updated successfully');
          return true;
        }
      }

      debugPrint('❌ Calendar: Failed to update event: ${response.errorMessage}');
      return false;
    } catch (e) {
      debugPrint('❌ Calendar: Error updating event: $e');
      return false;
    }
  }

  Future<bool> deleteCalendarEvent(int eventId) async {
    try {
      debugPrint('🗑️ Calendar: Deleting event: $eventId');
      final response = await _calendarService.deleteEvent(eventId);

      if (response.isSuccess) {
        _calendarEvents.removeWhere((e) => e.id == eventId);
        notifyListeners();
        debugPrint('✅ Calendar: Event deleted successfully');
        return true;
      }

      debugPrint('❌ Calendar: Failed to delete event: ${response.errorMessage}');
      return false;
    } catch (e) {
      debugPrint('❌ Calendar: Error deleting event: $e');
      return false;
    }
  }

  Future<void> refreshData() async {
    debugPrint('🔄 Calendar: Refreshing all data');
    await _loadCalendarViewType();
    await loadDataForMonth(_focusedMonth.year, _focusedMonth.month);
  }

  void nextMonth() {
    final newMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
    );
    setFocusedMonth(newMonth);
  }

  void previousMonth() {
    final newMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
    );
    setFocusedMonth(newMonth);
  }

  void goToToday() {
    final today = DateTime.now();
    debugPrint('🏠 Calendar: Going to today');
    setSelectedDate(today);
    setFocusedMonth(today);
  }

  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool isSelectedDate(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  bool hasEvents(DateTime date) {
    final events = getEventsForMonth();
    return events.containsKey(date) && events[date]!.isNotEmpty;
  }

  int getTotalEventsForSelectedDate() {
    int count = 0;
    if (diaryForSelectedDate != null) count++;
    count += notesForSelectedDate.length;
    count += tasksForSelectedDate.length;
    count += expensesForSelectedDate.length;
    count += subscriptionsForSelectedDate.length;
    count += calendarEventsForSelectedDate.length;

    debugPrint('📊 Calendar: Total events for selected date: $count');
    return count;
  }

  // Seçili gün için kilitli ve kilitsiz not sayısını ayrı ayrı getir
  Map<String, int> getNotesCountForSelectedDate() {
    final locked = lockedNotesForSelectedDate.length;
    final unlocked = unlockedNotesForSelectedDate.length;

    return {
      'locked': locked,
      'unlocked': unlocked,
      'total': locked + unlocked,
    };
  }

  // Kilitli notu aç
  Future<bool> unlockNote(int noteId, String pin) async {
    try {
      debugPrint('🔑 Calendar: Attempting to unlock note $noteId');
      final response = await _noteService.unlockNote(noteId, pin);

      if (response.isSuccess && response.data != null) {
        // Backend hala is_locked: true dönüyorsa, yanlış PIN demektir
        if (response.data!.isLocked) {
          debugPrint('❌ Calendar: Wrong PIN for note $noteId');
          return false;
        }

        // Kilidi açıldı, notu güncelle
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = response.data!;
          notifyListeners();
          debugPrint('✅ Calendar: Note $noteId unlocked successfully');
          return true;
        }
      }

      debugPrint('❌ Calendar: Failed to unlock note $noteId');
      return false;
    } catch (e) {
      debugPrint('❌ Calendar: Error unlocking note: $e');
      return false;
    }
  }

  // Belirli bir notu ID'ye göre bul
  Note? getNoteById(int noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      debugPrint('⚠️ Calendar: Note with id $noteId not found');
      return null;
    }
  }

  // Belirli bir calendar event'i ID'ye göre bul
  CalendarEvent? getCalendarEventById(int eventId) {
    try {
      return _calendarEvents.firstWhere((event) => event.id == eventId);
    } catch (e) {
      debugPrint('⚠️ Calendar: Calendar event with id $eventId not found');
      return null;
    }
  }
}