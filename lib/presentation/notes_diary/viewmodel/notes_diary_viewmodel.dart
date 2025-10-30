import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/init/locator.dart';
import '../../../service/note/note_service.dart';
import '../../../service/diary/diary_service.dart';
import '../../../models/note/note_models.dart';
import '../../../models/diary/diary_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotesViewMode { grid, list }
class NotesDiaryViewModel extends ChangeNotifier {
  final INoteService _noteService = locator.get<INoteService>();
  final IDiaryService _diaryService = locator.get<IDiaryService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Notes
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // Diary
  List<Diary> _diaryEntries = [];
  List<Diary> get diaryEntries => _diaryEntries;

  // Categories
  List<NoteCategory> _categories = [];
  List<NoteCategory> get categories => _categories;
  NotesViewMode _notesViewMode = NotesViewMode.grid;
  NotesViewMode get notesViewMode => _notesViewMode;

  // Note Form State
  final TextEditingController noteTitleController = TextEditingController();
  final TextEditingController noteContentController = TextEditingController();
  int? _editingNoteId;
  int? _selectedCategoryForNote;
  int? get selectedCategoryForNote => _selectedCategoryForNote;
  String _selectedNoteColor = '#B794F6'; // Default mor renk
  String get selectedNoteColor => _selectedNoteColor;

  // Diary Form State
  final TextEditingController diaryTitleController = TextEditingController();
  final TextEditingController diaryContentController = TextEditingController();
  String _selectedMood = '😊';
  String get selectedMood => _selectedMood;
  String? _editingDiaryDate;

  // Filter States
  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;
  bool? _filterPinned;
  bool? get filterPinned => _filterPinned;
  bool? _filterLocked;
  bool? get filterLocked => _filterLocked;
  bool? _filterArchived;
  bool? get filterArchived => _filterArchived;

  // Filter Methods
  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setFilterPinned(bool? value) {
    _filterPinned = value;
    notifyListeners();
  }

  void setFilterLocked(bool? value) {
    _filterLocked = value;
    notifyListeners();
  }

  void setFilterArchived(bool? value) {
    _filterArchived = value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _filterPinned = null;
    _filterLocked = null;
    _filterArchived = null;
    notifyListeners();
  }

  List<Note> getFilteredNotes() {
    var filtered = _notes;

    // ÖNEMLI: Arşivlenmiş notları default olarak gizle
    // Sadece arşiv filtresi aktif olduğunda göster
    if (_filterArchived == null) {
      filtered = filtered.where((n) => !n.isArchived).toList();
    } else {
      filtered = filtered.where((n) => n.isArchived == _filterArchived).toList();
    }

    if (_selectedCategoryId != null) {
      filtered = filtered.where((n) => n.categoryId == _selectedCategoryId).toList();
    }

    if (_filterPinned != null) {
      filtered = filtered.where((n) => n.isPinned == _filterPinned).toList();
    }

    if (_filterLocked != null) {
      filtered = filtered.where((n) => n.isLocked == _filterLocked).toList();
    }

    // Sort: pinned first, then by date
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  void setSelectedMood(String mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  void setSelectedCategoryForNote(int? categoryId) {
    _selectedCategoryForNote = categoryId;
    notifyListeners();
  }

  void setSelectedNoteColor(String color) {
    _selectedNoteColor = color;
    notifyListeners();
  }

  void resetNoteForm() {
    noteTitleController.clear();
    noteContentController.clear();
    _editingNoteId = null;
    _selectedCategoryForNote = null;
    _selectedNoteColor = '#B794F6'; // Rengi de resetle
    notifyListeners();
  }

  void resetDiaryForm() {
    diaryTitleController.clear();
    diaryContentController.clear();
    _selectedMood = '😊';
    _editingDiaryDate = null;
    notifyListeners();
  }

  void setNoteForEdit(Note note) {
    _editingNoteId = note.id;
    noteTitleController.text = note.title ?? '';
    noteContentController.text = note.content ?? '';
    _selectedCategoryForNote = note.categoryId;
    _selectedNoteColor = note.color ?? '#B794F6'; // Notun rengini yükle
    notifyListeners();
  }

  void setDiaryForEdit(Diary diary) {
    _editingDiaryDate = diary.diaryDate.toIso8601String().split('T')[0];
    diaryTitleController.text = diary.title ?? '';
    diaryContentController.text = diary.content ?? '';
    _selectedMood = diary.moodIcon ?? '😊';
    notifyListeners();
  }

  String _cleanMessage(String? message) {
    if (message == null || message.isEmpty) {
      return '';
    }

    if (message.startsWith('{') && message.contains('"message"')) {
      try {
        final regex = RegExp(r'"message"\s*:\s*"([^"]+)"');
        final match = regex.firstMatch(message);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? '';
        }
      } catch (e) {
        debugPrint('Message parse error: $e');
      }
    }

    return message;
  }

  @override
  void dispose() {
    noteTitleController.dispose();
    noteContentController.dispose();
    diaryTitleController.dispose();
    diaryContentController.dispose();
    super.dispose();
  }

  // ==================== NOTES ====================

  Future<void> loadNotes() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _noteService.getAllNotes();

      if (response.isSuccess && response.data != null) {
        _notes = response.data!;
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNote(BuildContext context) async {
    if (noteTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Not başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = NoteRequest(
        title: noteTitleController.text.trim(),
        content: noteContentController.text.trim(),
        categoryId: _selectedCategoryForNote,
        templateType: null,
        color: _selectedNoteColor, // Seçilen rengi gönder
        reminderDate: null,
        isLocked: false,
        isPinned: false,
      );

      final response = await _noteService.createNote(request);

      if (response.isSuccess && response.data != null) {
        _notes.insert(0, response.data!);
        resetNoteForm();
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not başarıyla eklendi',
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not eklenemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Not eklenirken hata oluştu');
      }
      debugPrint('Note creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(BuildContext context) async {
    if (_editingNoteId == null) {
      CustomSnackBar.showError(context, 'Düzenlenecek not bulunamadı');
      return;
    }

    if (noteTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Not başlığı boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Mevcut notu bul
      final currentNote = _notes.firstWhere((n) => n.id == _editingNoteId);

      final request = NoteRequest(
        title: noteTitleController.text.trim(),
        content: noteContentController.text.trim(),
        categoryId: _selectedCategoryForNote,
        templateType: null,
        color: _selectedNoteColor, // Seçilen rengi gönder
        reminderDate: null,
        isLocked: currentNote.isLocked, // Mevcut kilit durumunu koru
        isPinned: currentNote.isPinned, // Mevcut pin durumunu koru
      );

      final response = await _noteService.updateNote(_editingNoteId!, request);

      if (response.isSuccess && response.data != null) {
        final index = _notes.indexWhere((n) => n.id == _editingNoteId);
        if (index != -1) {
          _notes[index] = response.data!;
        }
        resetNoteForm();
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not güncellendi',
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not güncellenemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Not güncellenirken hata oluştu');
      }
      debugPrint('Note update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(int noteId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _noteService.deleteNote(noteId);

      if (response.isSuccess) {
        _notes.removeWhere((n) => n.id == noteId);
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not silindi',
          );
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not silinemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Not silinirken hata oluştu');
      }
      debugPrint('Note deletion exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePin(int noteId, BuildContext context) async {
    try {
      final note = _notes.firstWhere((n) => n.id == noteId);
      final response = note.isPinned
          ? await _noteService.unpinNote(noteId)
          : await _noteService.pinNote(noteId);

      if (response.isSuccess) {
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = Note(
            id: note.id,
            title: note.title,
            content: note.content,
            categoryId: note.categoryId,
            templateType: note.templateType,
            color: note.color,
            reminderDate: note.reminderDate,
            isLocked: note.isLocked,
            isPinned: !note.isPinned,
            isArchived: note.isArchived,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            wordCount: note.wordCount,
            characterCount: note.characterCount,
            orderIndex: note.orderIndex,
            version: note.version,
            reminderEnabled: note.reminderEnabled,
          );
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty
                  ? cleanMsg
                  : (note.isPinned ? 'Sabitleme kaldırıldı' : 'Not sabitlendi'),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız');
      }
      debugPrint('Toggle pin exception: $e');
    }
  }
  Future<void> loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('notes_view_mode');
      if (savedMode != null) {
        _notesViewMode = savedMode == 'list' ? NotesViewMode.list : NotesViewMode.grid;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading view mode: $e');
    }
  }

  Future<void> toggleViewMode() async {
    try {
      _notesViewMode = _notesViewMode == NotesViewMode.grid
          ? NotesViewMode.list
          : NotesViewMode.grid;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notes_view_mode',
        _notesViewMode == NotesViewMode.list ? 'list' : 'grid',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling view mode: $e');
    }
  }


  Future<void> lockNote(int noteId, String pin, BuildContext context) async {
    try {
      final response = await _noteService.lockNote(noteId, pin);

      if (response.isSuccess) {
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          final note = _notes[index];
          _notes[index] = Note(
            id: note.id,
            title: note.title,
            content: note.content,
            categoryId: note.categoryId,
            templateType: note.templateType,
            color: note.color,
            reminderDate: note.reminderDate,
            isLocked: true,
            isPinned: note.isPinned,
            isArchived: note.isArchived,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            wordCount: note.wordCount,
            characterCount: note.characterCount,
            orderIndex: note.orderIndex,
            version: note.version,
            reminderEnabled: note.reminderEnabled,
          );
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'Not kilitlendi',
            );
          }
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Not kilitlenemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız');
      }
      debugPrint('Lock note exception: $e');
    }
  }

  Future<void> unlockNote(
      int noteId,
      String pin,
      BuildContext context,
      VoidCallback? onSuccess,
      ) async {
    try {
      final response = await _noteService.unlockNote(noteId, pin);

      debugPrint('🔑 Unlock response in ViewModel - Success: ${response.isSuccess}');
      debugPrint('🔑 Unlock response data: ${response.data}');
      debugPrint('🔑 Note is still locked: ${response.data?.isLocked}');

      if (response.isSuccess && response.data != null) {
        // Backend hala is_locked: true dönüyorsa, yanlış PIN demektir
        if (response.data!.isLocked) {
          if (context.mounted) {
            CustomSnackBar.showError(
              context,
              'Yanlış PIN kodu',
            );
          }
          return;
        }

        // Kilidi açıldı, notu güncelle
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = response.data!;
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'Not kilidi açıldı',
            );
          }

          // onSuccess callback'ini çağır (eğer null değilse)
          if (onSuccess != null) {
            onSuccess();
          }
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Yanlış PIN kodu',
          );
        }
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız: $e');
      }
      debugPrint('❌ Unlock note exception: $e');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> toggleArchive(int noteId, BuildContext context) async {
    try {
      final note = _notes.firstWhere((n) => n.id == noteId);
      final response = note.isArchived
          ? await _noteService.unarchiveNote(noteId)
          : await _noteService.archiveNote(noteId);

      if (response.isSuccess) {
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = Note(
            id: note.id,
            title: note.title,
            content: note.content,
            categoryId: note.categoryId,
            templateType: note.templateType,
            color: note.color,
            reminderDate: note.reminderDate,
            isLocked: note.isLocked,
            isPinned: note.isPinned,
            isArchived: !note.isArchived,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            wordCount: note.wordCount,
            characterCount: note.characterCount,
            orderIndex: note.orderIndex,
            version: note.version,
            reminderEnabled: note.reminderEnabled,
          );
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty
                  ? cleanMsg
                  : (note.isArchived
                  ? 'Arşivden çıkarıldı'
                  : 'Arşivlendi'),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'İşlem başarısız');
      }
      debugPrint('Toggle archive exception: $e');
    }
  }

  // ==================== CATEGORIES ====================

  Future<void> loadCategories() async {
    try {
      debugPrint('📂 Loading categories...');
      final response = await _noteService.getCategories();

      debugPrint('📂 Categories response - Success: ${response.isSuccess}');
      debugPrint('📂 Categories response - Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        _categories = response.data!;
        debugPrint('📂 Categories loaded: ${_categories.length} categories');
        for (var cat in _categories) {
          debugPrint('   - ${cat.name} (${cat.icon})');
        }
        notifyListeners();
        debugPrint('📂 notifyListeners() called');
      } else {
        debugPrint('📂 ❌ Failed to load categories');
      }
    } catch (e) {
      debugPrint('📂 ❌ Error loading categories: $e');
    }
  }

  Future<void> createCategory(
      BuildContext context,
      String name,
      String icon,
      String color,
      ) async {
    try {
      debugPrint('➕ Creating category: $name ($icon)');

      final request = NoteCategoryRequest(
        name: name,
        icon: icon,
        color: color,
      );

      final response = await _noteService.createCategory(request);

      debugPrint('➕ Create response - Success: ${response.isSuccess}');
      debugPrint('➕ Create response - Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        debugPrint('➕ Category created successfully, reloading categories...');

        // Önce kategorileri yeniden yükle
        await loadCategories();

        debugPrint('➕ Categories reloaded, current count: ${_categories.length}');

        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Kategori oluşturuldu',
          );
        }
      } else {
        debugPrint('➕ ❌ Failed to create category');
      }
    } catch (e) {
      debugPrint('➕ ❌ Create category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Kategori oluşturulamadı');
      }
    }
  }

  Future<void> updateCategory(
      BuildContext context,
      int categoryId,
      String name,
      String icon,
      String color,
      ) async {
    try {
      debugPrint('✏️ Updating category: $categoryId -> $name ($icon)');

      final request = NoteCategoryRequest(
        name: name,
        icon: icon,
        color: color,
      );

      final response = await _noteService.updateCategory(categoryId, request);

      debugPrint('✏️ Update response - Success: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        debugPrint('✏️ Category updated successfully, reloading categories...');

        // Önce kategorileri yeniden yükle
        await loadCategories();

        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Kategori güncellendi',
          );
        }
      } else {
        debugPrint('✏️ ❌ Failed to update category');
      }
    } catch (e) {
      debugPrint('✏️ ❌ Update category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Kategori güncellenemedi');
      }
    }
  }

  Future<void> deleteCategory(BuildContext context, int categoryId) async {
    try {
      debugPrint('🗑️ Deleting category: $categoryId');

      final response = await _noteService.deleteCategory(categoryId);

      debugPrint('🗑️ Delete response - Success: ${response.isSuccess}');

      if (response.isSuccess) {
        debugPrint('🗑️ Category deleted successfully, reloading categories...');

        // Önce kategorileri yeniden yükle
        await loadCategories();

        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Kategori silindi',
          );
        }
      } else {
        debugPrint('🗑️ ❌ Failed to delete category');
      }
    } catch (e) {
      debugPrint('🗑️ ❌ Delete category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Kategori silinemedi');
      }
    }
  }

  // ==================== DIARY ====================

  Future<void> loadDiaryEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _diaryService.getAllDiaries();

      if (response.isSuccess && response.data != null) {
        _diaryEntries = response.data!.data;
      }
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // ==================== COPY TO CLIPBOARD ====================

// ==================== COPY TO CLIPBOARD ====================

  Future<void> copyNoteToClipboard(Note note, BuildContext context) async {
    try {
      // Sadece içeriği kopyala
      String textToCopy = note.content ?? '';

      if (textToCopy.isEmpty) {
        if (context.mounted) {
          CustomSnackBar.showError(context, 'Not içeriği boş');
        }
        return;
      }

      // Clipboard'a kopyala
      await Clipboard.setData(ClipboardData(text: textToCopy));

      if (context.mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Not içeriği kopyalandı',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Kopyalama başarısız');
      }
      debugPrint('Copy to clipboard exception: $e');
    }
  }
  Future<void> loadDiaryEntriesByMonth(int month, int year) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _diaryService.getAllDiaries(
        month: month,
        year: year,
      );

      if (response.isSuccess && response.data != null) {
        _diaryEntries = response.data!.data;
      }
    } catch (e) {
      debugPrint('Error loading diary entries by month: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createDiary(BuildContext context) async {
    if (diaryContentController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Günlük içeriği boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = DiaryRequest(
        diaryDate: DateTime.now().toIso8601String().split('T')[0],
        title: diaryTitleController.text.trim().isEmpty
            ? null
            : diaryTitleController.text.trim(),
        content: diaryContentController.text.trim(),
        mood: _getMoodLabel(_selectedMood),
        moodIcon: _selectedMood,
        weather: null,
        imageUrls: null,
      );

      final response = await _diaryService.createDiary(request);

      if (response.isSuccess && response.data != null) {
        _diaryEntries.insert(0, response.data!);
        resetDiaryForm();
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük başarıyla eklendi',
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük eklenemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Günlük eklenirken hata oluştu');
      }
      debugPrint('Diary creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDiary(BuildContext context) async {
    if (_editingDiaryDate == null) {
      CustomSnackBar.showError(context, 'Düzenlenecek günlük bulunamadı');
      return;
    }

    if (diaryContentController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'Günlük içeriği boş olamaz');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final request = DiaryRequest(
        diaryDate: _editingDiaryDate!,
        title: diaryTitleController.text.trim().isEmpty
            ? null
            : diaryTitleController.text.trim(),
        content: diaryContentController.text.trim(),
        mood: _getMoodLabel(_selectedMood),
        moodIcon: _selectedMood,
        weather: null,
        imageUrls: null,
      );

      final response =
      await _diaryService.updateDiary(_editingDiaryDate!, request);

      if (response.isSuccess && response.data != null) {
        final index = _diaryEntries.indexWhere(
              (d) =>
          d.diaryDate.toIso8601String().split('T')[0] == _editingDiaryDate,
        );
        if (index != -1) {
          _diaryEntries[index] = response.data!;
        }
        resetDiaryForm();
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük güncellendi',
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük güncellenemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Günlük güncellenirken hata oluştu');
      }
      debugPrint('Diary update exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDiary(String date, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _diaryService.deleteDiary(date);

      if (response.isSuccess) {
        _diaryEntries.removeWhere(
              (d) => d.diaryDate.toIso8601String().split('T')[0] == date,
        );
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük silindi',
          );
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'Günlük silinemedi',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Günlük silinirken hata oluştu');
      }
      debugPrint('Diary deletion exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getMoodLabel(String emoji) {
    switch (emoji) {
      case '😊':
        return 'happy';
      case '😔':
        return 'sad';
      case '😌':
        return 'calm';
      case '😍':
        return 'loved';
      case '😡':
        return 'angry';
      case '😴':
        return 'tired';
      default:
        return 'happy';
    }
  }

  // ==================== COMMON ====================
  Future<void> refreshAll() async {
    await Future.wait([
      loadNotes(),
      loadDiaryEntries(),
      loadCategories(),
      loadViewMode(), // Bu satırı ekleyin
    ]);
  }
}