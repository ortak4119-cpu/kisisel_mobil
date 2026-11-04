import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../../core/init/locator.dart';
import '../../../service/note/note_service.dart';
import '../../../service/diary/diary_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../service/share/share_service.dart';
import '../../../models/share/shared_item_models.dart';
import '../../../models/note/note_models.dart';
import '../../../models/diary/diary_models.dart';
import '../../../models/auth/auth_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/premium_helper.dart';
import '../view/markdown_note_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotesViewMode { grid, list }
class NotesDiaryViewModel extends ChangeNotifier {
  final INoteService _noteService = locator.get<INoteService>();
  final IDiaryService _diaryService = locator.get<IDiaryService>();
  final IProfileService _profileService = locator.get<IProfileService>();
  final IShareService _shareService = locator.get<IShareService>();

  // Paylaşım bilgisi: sahibi olduğum paylaşılmış not id'leri (rozet için) +
  // benimle paylaşılan notlar (ana listede "Paylaşılanlar" bölümü için).
  final Set<int> _sharedOwnedNoteIds = {};
  // noteId -> paylaşıldığı kişi sayısı (katılımcılar).
  final Map<int, int> _sharedOwnedNoteParticipants = {};
  List<SharedNoteItem> _sharedWithMeNotes = [];
  Set<int> get sharedOwnedNoteIds => _sharedOwnedNoteIds;
  List<SharedNoteItem> get sharedWithMeNotes => _sharedWithMeNotes;
  bool isNoteShared(int id) => _sharedOwnedNoteIds.contains(id);
  int sharedParticipantCount(int id) => _sharedOwnedNoteParticipants[id] ?? 0;

  // Bekleyen not davetleri (sağ üstteki paylaşım butonu rozeti için).
  int _noteInviteCount = 0;
  int get noteInviteCount => _noteInviteCount;

  Future<void> loadSharedNotesInfo() async {
    try {
      final r = await _shareService.getSharedNotes();
      if (r.isSuccess && r.data != null) {
        _sharedOwnedNoteIds.clear();
        _sharedOwnedNoteParticipants.clear();
        final withMe = <SharedNoteItem>[];
        for (final s in r.data!) {
          if (s.isOwner && s.note != null) {
            _sharedOwnedNoteIds.add(s.note!.id);
            _sharedOwnedNoteParticipants[s.note!.id] = s.participants.length;
          } else if (!s.isOwner && s.note != null) {
            withMe.add(s);
          }
        }
        _sharedWithMeNotes = withMe;
      }
      // Bekleyen davet sayısını da tazele (rozet).
      try {
        final inv = await _shareService.getNoteInvites();
        if (inv.isSuccess && inv.data != null) {
          _noteInviteCount = inv.data!.length;
        }
      } catch (_) {}
      notifyListeners();
    } catch (_) {
      // Paylaşım bilgisi alınamazsa sessiz geç (ana akışı bozmaz).
    }
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUserLoaded = false;
  bool get isUserLoaded => _isUserLoaded;

  // Notes
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // Diary
  List<Diary> _diaryEntries = [];
  List<Diary> get diaryEntries => _diaryEntries;

  // Categories
  List<NoteCategory> _categories = [];
  List<NoteCategory> get categories => _categories;

  // ---- Klasör (kategori) kilidi — istemci tarafı (backend desteklemiyor) ----
  // Kategori id -> PIN. SharedPreferences'ta JSON olarak saklanır.
  static const String _folderPinsKey = 'note_folder_pins';
  Map<int, String> _folderPins = {};
  bool isFolderLocked(int id) => _folderPins.containsKey(id);
  String? folderPin(int id) => _folderPins[id];

  Future<void> _loadFolderPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_folderPinsKey);
      if (raw == null || raw.isEmpty) {
        _folderPins = {};
        return;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _folderPins = decoded
          .map((k, v) => MapEntry(int.tryParse(k) ?? -1, v.toString()))
        ..removeWhere((k, v) => k < 0);
    } catch (_) {
      _folderPins = {};
    }
  }

  Future<void> _persistFolderPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _folderPins.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_folderPinsKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> setFolderLock(int id, String pin) async {
    _folderPins[id] = pin;
    notifyListeners();
    await _persistFolderPins();
  }

  Future<void> removeFolderLock(int id) async {
    _folderPins.remove(id);
    notifyListeners();
    await _persistFolderPins();
  }

  // ---- Paylaşımlı notta KİŞİYE ÖZEL kilit (yerel) ----
  // Paylaşılan bir notu kilitlemek onu DİĞER katılımcılarda kilitlemez;
  // kilit yalnızca bu cihazda/kullanıcıda geçerlidir. noteId -> PIN.
  static const String _localNotePinsKey = 'note_local_pins';
  Map<int, String> _localNotePins = {};
  bool isNoteLockedLocally(int id) => _localNotePins.containsKey(id);
  String? localNotePin(int id) => _localNotePins[id];

  /// Bir not BU kullanıcı için kilitli mi? (yerel kişiye-özel kilit VEYA
  /// backend kilidi — paylaşımsız notlarda backend, paylaşımlıda yerel.)
  bool isNoteLockedForMe(Note n) =>
      n.isLocked || _localNotePins.containsKey(n.id);

  Future<void> _loadLocalNotePins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localNotePinsKey);
      if (raw == null || raw.isEmpty) {
        _localNotePins = {};
        return;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _localNotePins = decoded
          .map((k, v) => MapEntry(int.tryParse(k) ?? -1, v.toString()))
        ..removeWhere((k, v) => k < 0);
    } catch (_) {
      _localNotePins = {};
    }
  }

  Future<void> _persistLocalNotePins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _localNotePins.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_localNotePinsKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> setLocalNoteLock(int id, String pin) async {
    _localNotePins[id] = pin;
    notifyListeners();
    await _persistLocalNotePins();
  }

  Future<void> removeLocalNoteLock(int id) async {
    _localNotePins.remove(id);
    notifyListeners();
    await _persistLocalNotePins();
  }

  // ---- Not boyutlandırma (kişiye özel, yerel) ----
  // noteId -> [genişlik, yükseklik]. SharedPreferences'ta JSON saklanır.
  static const String _noteSizesKey = 'note_sizes';
  Map<int, List<double>> _noteSizes = {};
  List<double>? noteSize(int id) => _noteSizes[id];

  // Hangi not şu an boyutlandırılıyor (null = hiçbiri).
  int? _resizingNoteId;
  int? get resizingNoteId => _resizingNoteId;

  void startResizingNote(int id,
      {double defaultW = 150, double defaultH = 132}) {
    _resizingNoteId = id;
    _noteSizes.putIfAbsent(id, () => [defaultW, defaultH]);
    notifyListeners();
  }

  void stopResizingNote() {
    _resizingNoteId = null;
    notifyListeners();
    _persistNoteSizes();
  }

  // Sürükleme sırasında (anlık, kalıcı yazma yok — bitince persist edilir).
  void updateNoteSize(int id, double w, double h) {
    _noteSizes[id] = [w, h];
    notifyListeners();
  }

  // Sürükleme bitince boyutu diske yaz (resize modundan çıkmadan).
  void persistNoteSizes() {
    _persistNoteSizes();
  }

  Future<void> _loadNoteSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_noteSizesKey);
      if (raw == null || raw.isEmpty) {
        _noteSizes = {};
        return;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _noteSizes = decoded.map((k, v) {
        final id = int.tryParse(k) ?? -1;
        final list =
            (v as List).map((e) => (e as num).toDouble()).toList();
        return MapEntry(id, list);
      })..removeWhere((k, v) => k < 0 || v.length < 2);
    } catch (_) {
      _noteSizes = {};
    }
  }

  Future<void> _persistNoteSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _noteSizes.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_noteSizesKey, jsonEncode(map));
    } catch (_) {}
  }

  NotesViewMode _notesViewMode = NotesViewMode.grid;
  NotesViewMode get notesViewMode => _notesViewMode;

  // Note Form State
  final TextEditingController noteTitleController = TextEditingController();
  // Canlı markdown gösterimi için özel controller (kalın/italik editörde görünür).
  final MarkdownEditingController noteContentController =
      MarkdownEditingController();

  /// İçerik alanının odak düğümü — checklist/madde çipine basıldığında
  /// klavye odağını içeriğe taşımak için kullanılır.
  final FocusNode noteContentFocus = FocusNode();
  int? _editingNoteId;
  int? _selectedCategoryForNote;
  int? get selectedCategoryForNote => _selectedCategoryForNote;
  String _selectedNoteColor = '#B794F6'; // Default mor renk
  String get selectedNoteColor => _selectedNoteColor;

  // Editördeki etiketler (serbest biçimli).
  final List<String> _editTags = [];
  List<String> get editTags => List.unmodifiable(_editTags);
  void addTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t.length > 40) return;
    if (_editTags.any((e) => e.toLowerCase() == t.toLowerCase())) return;
    _editTags.add(t);
    notifyListeners();
  }

  void removeTag(String tag) {
    _editTags.removeWhere((e) => e == tag);
    notifyListeners();
  }

  // Editör form durumları (kilit / sabitleme / hatırlatıcı)
  bool _noteLocked = false;
  bool get noteLocked => _noteLocked;
  bool _notePinned = false;
  bool get notePinned => _notePinned;

  // Editörde kilit açılırken girilen PIN; kayıttan sonra lockNote ile uygulanır.
  String? _notePendingLockPin;

  /// Editörde PIN ile kilitle. [pin] null ise kilidi (yerel olarak) kaldırır.
  void setNoteLockPin(String? pin) {
    _notePendingLockPin = pin;
    _noteLocked = pin != null;
    notifyListeners();
  }
  DateTime? _noteReminder;
  DateTime? get noteReminder => _noteReminder;

  // --- Editör biçimlendirme modu (araç çubuğundaki aç/kapa düğmeleri) ---
  // Kalın/italik/altı-çizili "aktif" modları: açıkken imleç işaretçi çiftinin
  // (**..**, *..*, _.._) içinde durur; böylece yazılan metin o biçimde olur.
  bool _boldMode = false;
  bool _italicMode = false;
  bool _underlineMode = false;
  bool get boldMode => _boldMode;
  bool get italicMode => _italicMode;
  bool get underlineMode => _underlineMode;

  void setFormatMode({bool? bold, bool? italic, bool? underline}) {
    if (bold != null) _boldMode = bold;
    if (italic != null) _italicMode = italic;
    if (underline != null) _underlineMode = underline;
    notifyListeners();
  }

  void clearFormatModes() {
    if (!_boldMode && !_italicMode && !_underlineMode) return;
    _boldMode = false;
    _italicMode = false;
    _underlineMode = false;
    notifyListeners();
  }

  // Editöre eklenen görseller (image_picker ile seçilir, editörde gösterilir)
  final List<File> _pickedImages = [];
  List<File> get pickedImages => _pickedImages;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickNoteImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _imagePicker.pickMultiImage(imageQuality: 80);
        for (final f in files) {
          _pickedImages.add(File(f.path));
        }
      } else {
        final f = await _imagePicker.pickImage(
            source: source, imageQuality: 80);
        if (f != null) _pickedImages.add(File(f.path));
      }
      notifyListeners();
    } catch (_) {
      // İzin reddi / iptal — sessizce geç
    }
  }

  /// Çizim veya başka kaynaktan üretilen bir görsel dosyasını ekler.
  void addPickedImageFile(File file) {
    _pickedImages.add(file);
    notifyListeners();
  }

  // ==================== NOT GÖRSELLERİ (yerel kalıcı) ====================
  // Not görselleri backend'de tutulmuyor; cihazda kalıcı klasöre kopyalanır
  // ve not id'siyle eşlenip SharedPreferences'ta saklanır. Kartta küçük
  // önizleme olarak gösterilir. (Not: cihazlar arası senkron olmaz.)
  static const String _kNoteImagesKey = 'note_images_v1';
  final Map<int, List<String>> _noteImages = {};
  List<String> imagesForNote(int id) => _noteImages[id] ?? const [];

  // Düzenlenen notun mevcut (kayıtlı) görselleri — editörde gösterilir.
  List<String> _editingExistingImages = [];
  List<String> get editingExistingImages => _editingExistingImages;
  void removeExistingImage(int index) {
    if (index >= 0 && index < _editingExistingImages.length) {
      _editingExistingImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> loadNoteImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kNoteImagesKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _noteImages.clear();
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is List) {
          // Sadece hâlâ diskte var olan görselleri tut.
          final paths = v
              .cast<String>()
              .where((p) => File(p).existsSync())
              .toList();
          if (paths.isNotEmpty) _noteImages[id] = paths;
        }
      });
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistNoteImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _noteImages
          .map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_kNoteImagesKey, jsonEncode(map));
    } catch (_) {}
  }

  // NOT: Görseller artık yalnız backend'e yüklenir (tek doğruluk kaynağı).
  // Eski yerel görsel önbelleği (imagesForNote) yalnız geriye dönük okuma için
  // korunur; yeni kayıtlar yerel kopya üretmez.

  /// Editörde seçilen ekleri (görsel/ses/dosya) backend'e yükler. Her yükleme
  /// ayrı try/catch ile korunur; biri başarısız olursa kayıt bozulmaz.
  /// En az bir ek yüklendiyse notlar tazelenir (ekler sunucudan gelir).
  Future<void> _uploadPickedAttachments(int noteId) async {
    var uploaded = false;

    for (final img in _pickedImages) {
      try {
        final r = await _noteService.uploadNoteAttachment(noteId, img);
        if (r.isSuccess) uploaded = true;
      } catch (e) {
        debugPrint('Attachment (image) upload failed: $e');
      }
    }

    for (final f in _pickedFiles) {
      try {
        final r = await _noteService.uploadNoteAttachment(noteId, f);
        if (r.isSuccess) uploaded = true;
      } catch (e) {
        debugPrint('Attachment (file) upload failed: $e');
      }
    }

    if (_voiceNotePath != null) {
      try {
        final vf = File(_voiceNotePath!);
        if (vf.existsSync()) {
          final r = await _noteService.uploadNoteAttachment(noteId, vf,
              durationSeconds: _voiceDurationSeconds);
          if (r.isSuccess) uploaded = true;
        }
      } catch (e) {
        debugPrint('Attachment (voice) upload failed: $e');
      }
    }

    if (uploaded) {
      try {
        await loadNotes();
      } catch (_) {}
    }
  }

  /// Bir notun eklerini döndürür (görünümde kullanım için).
  List<NoteAttachment> attachmentsFor(Note n) => n.attachments;

  /// Düzenlenen notun id'si (editörde backend eklerini göstermek için).
  int? get editingNoteId => _editingNoteId;

  /// Düzenlenen notun backend ekleri (editörde gösterilir). Not bulunamazsa boş.
  List<NoteAttachment> get editingNoteAttachments {
    if (_editingNoteId == null) return const [];
    final i = _notes.indexWhere((n) => n.id == _editingNoteId);
    return i == -1 ? const [] : _notes[i].attachments;
  }

  /// Note immutable olduğundan ekleri güncellenmiş yeni bir kopya üretir.
  Note _noteWithAttachments(Note n, List<NoteAttachment> attachments) {
    return Note(
      id: n.id,
      title: n.title,
      content: n.content,
      categoryId: n.categoryId,
      templateType: n.templateType,
      color: n.color,
      reminderDate: n.reminderDate,
      isLocked: n.isLocked,
      isPinned: n.isPinned,
      isArchived: n.isArchived,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
      wordCount: n.wordCount,
      characterCount: n.characterCount,
      orderIndex: n.orderIndex,
      version: n.version,
      reminderEnabled: n.reminderEnabled,
      attachments: attachments,
      tags: n.tags,
    );
  }

  /// Bir eki siler ve bellekteki nottan çıkarır.
  Future<void> removeAttachment(
      int noteId, int attachmentId, BuildContext context) async {
    try {
      final response = await _noteService.deleteNoteAttachment(attachmentId);
      if (response.isSuccess) {
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          final note = _notes[index];
          final updated =
              note.attachments.where((a) => a.id != attachmentId).toList();
          _notes[index] = _noteWithAttachments(note, updated);
          notifyListeners();
        }
      } else if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Remove attachment exception: $e');
    }
  }

  void removePickedImage(int index) {
    if (index >= 0 && index < _pickedImages.length) {
      _pickedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Eklenen dosyalar (file_picker)
  final List<File> _pickedFiles = [];
  List<File> get pickedFiles => _pickedFiles;
  void addPickedFile(File f) {
    _pickedFiles.add(f);
    notifyListeners();
  }

  void removePickedFile(int index) {
    if (index >= 0 && index < _pickedFiles.length) {
      _pickedFiles.removeAt(index);
      notifyListeners();
    }
  }

  // Ses kaydı (record 7.x)
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  String? _voiceNotePath;
  String? get voiceNotePath => _voiceNotePath;

  // Kayıt süresi (saniye) — backend'e duration_seconds olarak gönderilir.
  DateTime? _recordStart;
  int? _voiceDurationSeconds;
  int? get voiceDurationSeconds => _voiceDurationSeconds;

  Future<void> toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        if (path != null) _voiceNotePath = path;
        if (_recordStart != null) {
          final secs = DateTime.now().difference(_recordStart!).inSeconds;
          _voiceDurationSeconds = secs > 0 ? secs : 1;
          _recordStart = null;
        }
        notifyListeners();
      } else {
        if (await _recorder.hasPermission()) {
          final dir = Directory.systemTemp;
          final path =
              '${dir.path}/ses_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _recorder.start(const RecordConfig(), path: path);
          _isRecording = true;
          _recordStart = DateTime.now();
          _voiceDurationSeconds = null;
          notifyListeners();
        }
      }
    } catch (_) {
      _isRecording = false;
      notifyListeners();
    }
  }

  void removeVoiceNote() {
    _voiceNotePath = null;
    _voiceDurationSeconds = null;
    _recordStart = null;
    notifyListeners();
  }


  void toggleNoteLocked() {
    _noteLocked = !_noteLocked;
    notifyListeners();
  }

  void toggleNotePinned() {
    _notePinned = !_notePinned;
    notifyListeners();
  }

  void setNoteReminder(DateTime? value) {
    _noteReminder = value;
    notifyListeners();
  }

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

  // Not arama sorgusu (başlık + içerik)
  String _noteSearchQuery = '';
  String get noteSearchQuery => _noteSearchQuery;
  void setNoteSearchQuery(String v) {
    _noteSearchQuery = v;
    notifyListeners();
  }

  List<Note> applyNoteSearch(List<Note> list) {
    final q = _noteSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((n) =>
            (n.title ?? '').toLowerCase().contains(q) ||
            (n.content ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Seçili etikete göre listeyi süzer (seçili etiket yoksa aynen döner).
  List<Note> applyTagFilter(List<Note> list) {
    final tag = _selectedTag;
    if (tag == null) return list;
    return list
        .where((n) =>
            n.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .toList();
  }

  // İstatistik kartı sekmesi: 'all' | 'pinned' | 'folders' | 'archive'
  String _notesFilter = 'all';
  String get notesFilter => _notesFilter;
  void setNotesFilter(String value) {
    _notesFilter = value;
    if (value != 'folders') _selectedCategoryId = null;
    notifyListeners();
  }

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

  // Etikete göre filtre (liste)
  String? _selectedTag;
  String? get selectedTag => _selectedTag;
  void setSelectedTag(String? tag) {
    _selectedTag = (_selectedTag == tag) ? null : tag;
    notifyListeners();
  }

  /// Tüm notlardaki benzersiz etiketler (filtre çipleri için).
  List<String> get allTags {
    final set = <String>{};
    for (final n in _notes) {
      for (final t in n.tags) {
        if (t.trim().isNotEmpty) set.add(t);
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _filterPinned = null;
    _filterLocked = null;
    _filterArchived = null;
    _selectedTag = null;
    notifyListeners();
  }

  /// Sürükle-bırak sıralama yalnız arama/etiket filtresi yokken anlamlıdır
  /// (görünen liste tüm "son notlar" olur). Aksi halde statik ızgara gösterilir.
  bool get canReorderNotes =>
      _noteSearchQuery.trim().isEmpty && _selectedTag == null;

  /// "Son notlar" (arşivlenmemiş + sabitlenmemiş) listesinde sürükle-bırak
  /// sıralaması. reorderable_grid_view konvansiyonu: oldIndex'i çıkar, newIndex'e
  /// ekle. Yerel sırayı anında günceller, sonra sunucuya kalıcı yazar.
  Future<void> reorderRecentNotes(int oldIndex, int newIndex) async {
    final recent =
        _notes.where((n) => !n.isArchived && !n.isPinned).toList();
    if (oldIndex < 0 || oldIndex >= recent.length) return;
    newIndex = newIndex.clamp(0, recent.length - 1);
    if (oldIndex == newIndex) return;

    final moved = recent.removeAt(oldIndex);
    recent.insert(newIndex, moved);

    // _notes içindeki "recent" slotlarını yeni sırayla doldur; sabitlenen ve
    // arşivlenen notların yeri korunur (türetilen liste sırayı korur).
    final recentIds = recent.map((n) => n.id).toSet();
    final queue = List<Note>.from(recent);
    _notes = [
      for (final n in _notes)
        if (recentIds.contains(n.id)) queue.removeAt(0) else n,
    ];
    notifyListeners();

    // Sunucuya kalıcı yaz; hata olursa bir sonraki yüklemede sunucu sırası esas.
    try {
      await _noteService.reorderNotes(recent.map((n) => n.id).toList());
    } catch (_) {}
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

    if (_selectedTag != null) {
      filtered = filtered
          .where((n) => n.tags
              .any((t) => t.toLowerCase() == _selectedTag!.toLowerCase()))
          .toList();
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
    _noteLocked = false;
    _notePendingLockPin = null;
    _notePinned = false;
    _noteReminder = null;
    _pickedImages.clear();
    _pickedFiles.clear();
    _editingExistingImages = [];
    _voiceNotePath = null;
    _voiceDurationSeconds = null;
    _recordStart = null;
    _editTags.clear();
    _boldMode = false;
    _italicMode = false;
    _underlineMode = false;
    if (_isRecording) {
      _recorder.stop();
      _isRecording = false;
    }
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
    _noteLocked = note.isLocked;
    _notePinned = note.isPinned;
    _noteReminder = note.reminderDate;
    _pickedImages.clear();
    _pickedFiles.clear();
    _editingExistingImages = List<String>.from(_noteImages[note.id] ?? const []);
    _voiceNotePath = null;
    _voiceDurationSeconds = null;
    _recordStart = null;
    _editTags
      ..clear()
      ..addAll(note.tags);
    notifyListeners();
  }

  void setDiaryForEdit(Diary diary) {
    _editingDiaryDate = diary.diaryDate.toIso8601String().split('T')[0];
    diaryTitleController.text = diary.title ?? '';
    diaryContentController.text = diary.content;
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

  // ==================== USER & PREMIUM ====================

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

  // ==================== NOTES ====================

  Future<void> loadNotes() async {
    try {
      _isLoading = true;
      notifyListeners();

      // User bilgisini çek (premium kontrolü için)
      await _loadCurrentUser();

      final response = await _noteService.getAllNotes();

      if (response.isSuccess && response.data != null) {
        _notes = response.data!;
      }
      await loadNoteImages();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni not başarıyla eklendiğinde view katmanının bir kez okuyup
  // kutlama animasyonunu oynatması için tek seferlik bayrak.
  bool _justCreated = false;
  bool consumeJustCreated() {
    final v = _justCreated;
    _justCreated = false;
    return v;
  }

  // "Bitti"ye birden fazla basınca aynı notu çoğaltmayı önler.
  // Kaydetme sürerken butona tekrar basılsa bile ikinci istek atılmaz.
  bool _savingNote = false;
  bool get isSavingNote => _savingNote;

  Future<void> createNote(BuildContext context) async {
    if (_savingNote) return; // zaten kaydediliyor — çift kayıt engeli
    if (noteTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.noteTitleEmpty'.tr());
      return;
    }

    // Premium limit kontrolü
    final canCreate = await PremiumHelper.checkNoteLimit(
      context: context,
      user: _currentUser,
      currentNoteCount: _notes.where((note) => !note.isArchived).length,
    );

    if (!canCreate) {
      return; // Limit aşıldı, paywall gösterildi
    }

    try {
      _savingNote = true;
      _isLoading = true;
      notifyListeners();

      final request = NoteRequest(
        title: noteTitleController.text.trim(),
        content: cleanNoteMarkers(noteContentController.text.trim()),
        categoryId: _selectedCategoryForNote,
        templateType: null,
        color: _selectedNoteColor, // Seçilen rengi gönder
        reminderDate: _noteReminder,
        isLocked: _noteLocked,
        isPinned: _notePinned,
        reminderEnabled: _noteReminder != null,
        tags: _editTags.isEmpty ? null : List<String>.from(_editTags),
      );

      final response = await _noteService.createNote(request);

      if (response.isSuccess && response.data != null) {
        _notes.insert(0, response.data!);
        _justCreated = true; // kaydetme kutlaması animasyonu için
        // Tüm ekleri (görsel/ses/dosya) backend'e yükle — tek doğruluk kaynağı.
        await _uploadPickedAttachments(response.data!.id);
        // Editörde PIN ile kilitlendiyse: kaydettikten sonra PIN ile kilitle
        // (lockNote yerel listeyi de kilitli olarak günceller).
        final willLock = _noteLocked && _notePendingLockPin != null;
        final lockPin = _notePendingLockPin;
        final newId = response.data!.id;
        resetNoteForm();
        if (context.mounted) {
          if (willLock) {
            await lockNote(newId, lockPin!, context);
          } else {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'success.noteAdded'.tr(),
            );
          }
          if (context.mounted) Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.noteAddFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.noteAddFailed'.tr());
      }
      debugPrint('Note creation exception: $e');
    } finally {
      _savingNote = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bir notun içeriğindeki checklist satırını işaretler/kaldırır (☐ ↔ ☑)
  /// ve değişikliği backend'e kaydeder. Kart üzerinden hızlı işaretleme için.
  Future<void> toggleChecklistLine(Note note, int lineIndex) async {
    final lines = (note.content ?? '').split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    final line = lines[lineIndex];
    if (line.startsWith('☐ ')) {
      lines[lineIndex] = '☑ ${line.substring(2)}';
    } else if (line.startsWith('☑ ')) {
      lines[lineIndex] = '☐ ${line.substring(2)}';
    } else {
      return;
    }
    final newContent = lines.join('\n');
    final idx = _notes.indexWhere((n) => n.id == note.id);

    // Anında geri bildirim (alışveriş listesi gibi hızlı işaretleme için):
    // önce yereli güncelle, sonra backend'e yaz; hata olursa geri al.
    final Note? previous = idx != -1 ? _notes[idx] : null;
    if (idx != -1) {
      _notes[idx] = _notes[idx].copyWith(content: newContent);
      notifyListeners();
    }

    try {
      final request = NoteRequest(
        title: note.title ?? '',
        content: newContent,
        categoryId: note.categoryId,
        templateType: null,
        color: note.color,
        // Checklist işaretlemesi notun hatırlatıcısını silmemeli.
        reminderDate: note.reminderDate,
        isLocked: note.isLocked,
        isPinned: note.isPinned,
        reminderEnabled: note.reminderDate != null,
      );
      final response = await _noteService.updateNote(note.id, request);
      if (response.isSuccess && response.data != null && idx != -1) {
        _notes[idx] = response.data!;
        notifyListeners();
      }
    } catch (_) {
      // Ağ hatası: iyimser değişikliği geri al — sonraki yenilemede senkron olur.
      if (idx != -1 && previous != null) {
        _notes[idx] = previous;
        notifyListeners();
      }
    }
  }

  Future<void> updateNote(BuildContext context) async {
    if (_savingNote) return; // zaten kaydediliyor — çift kayıt engeli
    if (_editingNoteId == null) {
      CustomSnackBar.showError(context, 'errors.noteNotFound'.tr());
      return;
    }

    if (noteTitleController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.noteTitleEmpty'.tr());
      return;
    }

    try {
      _savingNote = true;
      _isLoading = true;
      notifyListeners();


      final request = NoteRequest(
        title: noteTitleController.text.trim(),
        content: cleanNoteMarkers(noteContentController.text.trim()),
        categoryId: _selectedCategoryForNote,
        templateType: null,
        color: _selectedNoteColor, // Seçilen rengi gönder
        reminderDate: _noteReminder,
        // Paylaşımlı notta kilit KİŞİYE ÖZEL (yerel) → backend'e kilit gönderme,
        // yoksa diğer katılımcılar da kilitlenir. (lockNote yereli uygular.)
        isLocked: isNoteShared(_editingNoteId!) ? false : _noteLocked,
        isPinned: _notePinned,
        reminderEnabled: _noteReminder != null,
        tags: _editTags.isEmpty ? null : List<String>.from(_editTags),
      );

      final response = await _noteService.updateNote(_editingNoteId!, request);

      if (response.isSuccess && response.data != null) {
        final index = _notes.indexWhere((n) => n.id == _editingNoteId);
        if (index != -1) {
          _notes[index] = response.data!;
        }
        await _uploadPickedAttachments(_editingNoteId!);
        // Editörde PIN ile kilitlendiyse: PIN ile kilitle (yerel liste de güncellenir).
        final willLock = _noteLocked && _notePendingLockPin != null;
        final lockPin = _notePendingLockPin;
        final noteId = _editingNoteId!;
        resetNoteForm();
        if (context.mounted) {
          if (willLock) {
            await lockNote(noteId, lockPin!, context);
          } else {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'success.noteUpdated'.tr(),
            );
          }
          if (context.mounted) Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.noteUpdateFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.noteUpdateFailed'.tr());
      }
      debugPrint('Note update exception: $e');
    } finally {
      _savingNote = false;
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
        if (_noteImages.remove(noteId) != null) {
          await _persistNoteImages();
        }
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showSuccess(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'success.noteDeleted'.tr(),
          );
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.noteDeleteFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.noteDeleteFailed'.tr());
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
            attachments: note.attachments,
            tags: note.tags,
          );
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty
                  ? cleanMsg
                  : (note.isPinned ? 'success.noteUnpinned'.tr() : 'success.notePinned'.tr()),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
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


  Future<void> lockNote(int noteId, String pin, BuildContext context,
      {bool silent = false}) async {
    // Paylaşımlı not → kilit KİŞİYE ÖZEL (yerel): backend'e dokunma,
    // böylece diğer katılımcılar kilitlenmez.
    if (isNoteShared(noteId)) {
      await setLocalNoteLock(noteId, pin);
      if (!silent && context.mounted) {
        CustomSnackBar.showSuccess(context, 'success.noteLocked'.tr());
      }
      return;
    }
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
            attachments: note.attachments,
            tags: note.tags,
          );
          notifyListeners();

          if (!silent && context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'success.noteLocked'.tr(),
            );
          }
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.noteLockFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Lock note exception: $e');
    }
  }

  Future<void> unlockNote(
      int noteId,
      String pin,
      BuildContext context,
      VoidCallback? onSuccess, {
      bool silent = false,
      }) async {
    // Yerel (kişiye özel) kilit → PIN'i cihazda doğrula; doğruysa kilidi kaldır.
    // (Geçici görüntülemede çağıran taraf çıkışta tekrar kilitler.)
    if (isNoteLockedLocally(noteId)) {
      if (localNotePin(noteId) == pin) {
        await removeLocalNoteLock(noteId);
        onSuccess?.call();
      } else if (!silent && context.mounted) {
        CustomSnackBar.showError(context, 'errors.invalidPin'.tr());
      }
      return;
    }
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
              'errors.invalidPin'.tr(),
            );
          }
          return;
        }

        // Kilidi açıldı, notu güncelle
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = response.data!;
          notifyListeners();

          if (!silent && context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty ? cleanMsg : 'success.noteUnlocked'.tr(),
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
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.invalidPin'.tr(),
          );
        }
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        CustomSnackBar.showError(context, '${'errors.general'.tr()}: $e');
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
            attachments: note.attachments,
            tags: note.tags,
          );
          notifyListeners();

          if (context.mounted) {
            final cleanMsg = _cleanMessage(response.message);
            CustomSnackBar.showSuccess(
              context,
              cleanMsg.isNotEmpty
                  ? cleanMsg
                  : (note.isArchived
                  ? 'success.noteUnarchived'.tr()
                  : 'success.noteArchived'.tr()),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Toggle archive exception: $e');
    }
  }

  // ==================== CATEGORIES ====================

  Future<void> loadCategories() async {
    try {
      await _loadFolderPins();
      await _loadLocalNotePins();
      await _loadNoteSizes();
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.categoryCreated'.tr(),
          );
        }
      } else {
        debugPrint('➕ ❌ Failed to create category');
      }
    } catch (e) {
      debugPrint('➕ ❌ Create category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.categoryCreateFailed'.tr());
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.categoryUpdated'.tr(),
          );
        }
      } else {
        debugPrint('✏️ ❌ Failed to update category');
      }
    } catch (e) {
      debugPrint('✏️ ❌ Update category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.categoryUpdateFailed'.tr());
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.categoryDeleted'.tr(),
          );
        }
      } else {
        debugPrint('🗑️ ❌ Failed to delete category');
      }
    } catch (e) {
      debugPrint('🗑️ ❌ Delete category exception: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.categoryDeleteFailed'.tr());
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
          CustomSnackBar.showError(context, 'errors.noteContentEmpty'.tr());
        }
        return;
      }

      // Clipboard'a kopyala
      await Clipboard.setData(ClipboardData(text: textToCopy));

      if (context.mounted) {
        CustomSnackBar.showSuccess(
          context,
          'success.noteCopied'.tr(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.copyFailed'.tr());
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
      CustomSnackBar.showError(context, 'errors.diaryContentEmpty'.tr());
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.diaryAdded'.tr(),
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.diaryAddFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.diaryAddFailed'.tr());
      }
      debugPrint('Diary creation exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDiary(BuildContext context) async {
    if (_editingDiaryDate == null) {
      CustomSnackBar.showError(context, 'errors.diaryNotFound'.tr());
      return;
    }

    if (diaryContentController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, 'errors.diaryContentEmpty'.tr());
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.diaryUpdated'.tr(),
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.diaryUpdateFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.diaryUpdateFailed'.tr());
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
            cleanMsg.isNotEmpty ? cleanMsg : 'success.diaryDeleted'.tr(),
          );
        }
      } else {
        if (context.mounted) {
          final cleanMsg = _cleanMessage(response.message);
          CustomSnackBar.showError(
            context,
            cleanMsg.isNotEmpty ? cleanMsg : 'errors.diaryDeleteFailed'.tr(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.diaryDeleteFailed'.tr());
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
      loadSharedNotesInfo(),
    ]);
  }
}