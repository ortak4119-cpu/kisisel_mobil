import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../models/diary/diary_models.dart';
import '../../../models/note/note_models.dart';
import '../viewmodel/notes_diary_viewmodel.dart';

@RoutePage()
class NotesDiaryView extends StatefulWidget {
  const NotesDiaryView({super.key});

  @override
  State<NotesDiaryView> createState() => _NotesDiaryViewState();
}

class _NotesDiaryViewState extends State<NotesDiaryView> {
  bool _isNotesView = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesDiaryViewModel()..refreshAll(),
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            // Not sekmesi için sıcak krem zemin (Stitch "Sunny Script" dili).
            // Sadece bu sekmeyi etkiler; diğer sekmeler kendi Scaffold'unu kullanır.
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : const Color(0xFFFFF9ED),
            body: SafeArea(
              child: Column(
                children: [
                  // Başlık
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'notes.title'.tr(),
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _NotesContent(viewModel: viewModel),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'notes_diary_fab',
              onPressed: () =>
                  _showAddChooser(context, viewModel, isDarkMode),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB794F6).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: ColorConstant.white,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotesFilter(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,  // ← BU SATIRI EKLE
      builder: (context) => _NotesFilterSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showDiaryCalendar(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DiaryCalendarSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
      ),
    );
  }

  void _showAddNoteDialog(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) =>
      showAddNoteSheet(context, viewModel, isDarkMode);

  /// FAB seçici: Klasör Ekle / Not Ekle (açıklamalı).
  void _showAddChooser(BuildContext context, NotesDiaryViewModel viewModel,
      bool isDarkMode) {
    final c = AppColors(isDarkMode);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              _chooserCard(
                c,
                icon: Icons.note_add_rounded,
                accent: const Color(0xFFB794F6),
                title: 'notes.add.noteTitle'.tr(),
                desc: 'notes.add.noteDesc'.tr(),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddNoteSheet(context, viewModel, isDarkMode);
                },
              ),
              const SizedBox(height: 12),
              _chooserCard(
                c,
                icon: Icons.create_new_folder_rounded,
                accent: const Color(0xFF9F7AEA),
                title: 'notes.add.folderTitle'.tr(),
                desc: 'notes.add.folderDesc'.tr(),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddFolderDialog(context, viewModel, isDarkMode);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooserCard(AppColors c,
      {required IconData icon,
      required Color accent,
      required String title,
      required String desc,
      required VoidCallback onTap}) {
    return Material(
      color: accent.withOpacity(c.isDark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary)),
                    const SizedBox(height: 3),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Klasör (kategori) oluşturma diyaloğu.
  void _showAddFolderDialog(BuildContext context,
          NotesDiaryViewModel viewModel, bool isDarkMode,
          {NoteCategory? editing}) =>
      showFolderDialog(context, viewModel, isDarkMode, editing: editing);

  void _showAddDiaryDialog(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) =>
      showAddDiarySheet(context, viewModel, isDarkMode);
}

/// Not ekleme sayfasını açar.
/// Üst seviyede tutuluyor ki hem FAB hem de boş durum butonu aynı yeri açsın.
void showAddNoteSheet(
    BuildContext context, NotesDiaryViewModel viewModel, bool isDarkMode) {
  // Yeni not her zaman temiz/boş açılsın (önceki düzenlemeden kalan içerik olmasın).
  viewModel.resetNoteForm();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddNoteBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
    ),
  );
}

/// Klasör ekleme/düzenleme sayfası (üst seviye — hem FAB hem klasör kartı kullanır).
void showFolderDialog(BuildContext context,
    NotesDiaryViewModel viewModel, bool isDarkMode,
    {NoteCategory? editing}) {
  final c = AppColors(isDarkMode);
  final nameController = TextEditingController(text: editing?.name ?? '');
  const icons = ['📁', '🔒', '🎂', '💼', '💡', '❤️', '✈️', '🛒', '📚', '🏠'];
  String selectedIcon = (editing?.icon != null && icons.contains(editing!.icon))
      ? editing.icon!
      : icons.first;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(editing != null
                    ? 'notes.folders.editTitle'.tr()
                    : 'notes.add.folderTitle'.tr(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 4),
            Text('notes.folders.hint'.tr(),
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final ic in icons)
                    GestureDetector(
                      onTap: () => setState(() => selectedIcon = ic),
                      child: Container(
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedIcon == ic
                              ? const Color(0xFF9F7AEA).withOpacity(0.2)
                              : c.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selectedIcon == ic
                                  ? const Color(0xFF9F7AEA)
                                  : c.border),
                        ),
                        child: Text(ic,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'notes.folders.nameHint'.tr(),
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: editing != null
                  ? 'common.save'.tr()
                  : 'common.create'.tr(),
              icon: editing != null ? Icons.check_rounded : Icons.add_rounded,
              accent: const Color(0xFF9F7AEA),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                if (editing != null) {
                  viewModel.updateCategory(context, editing.id,
                      nameController.text.trim(), selectedIcon, '#9F7AEA');
                } else {
                  viewModel.createCategory(context,
                      nameController.text.trim(), selectedIcon, '#9F7AEA');
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Günlük girişi ekleme sayfasını açar.
void showAddDiarySheet(
    BuildContext context, NotesDiaryViewModel viewModel, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddDiaryBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
    ),
  );
}

// ==================== NOTLAR FİLTRE SHEET ====================

class _NotesFilterSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _NotesFilterSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Row(
                        children: [
                          Text(
                            'notes.filters'.tr(),
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => vm.clearFilters(),
                            child: Text(
                              'notes.clear'.tr(),
                              style: TextStyle(
                                color: const Color(0xFFB794F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quick Filters
                      _buildFilterChip(
                        context,
                        icon: Icons.push_pin_rounded,
                        label: 'notes.pinned'.tr(),
                        isSelected: vm.filterPinned == true,
                        onTap: () {
                          vm.setFilterPinned(vm.filterPinned == true ? null : true);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFilterChip(
                        context,
                        icon: Icons.lock_rounded,
                        label: 'notes.locked'.tr(),
                        isSelected: vm.filterLocked == true,
                        onTap: () {
                          vm.setFilterLocked(vm.filterLocked == true ? null : true);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFilterChip(
                        context,
                        icon: Icons.archive_rounded,
                        label: 'notes.archived'.tr(),
                        isSelected: vm.filterArchived == true,
                        onTap: () {
                          vm.setFilterArchived(vm.filterArchived == true ? null : true);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Categories
                      if (vm.categories.isNotEmpty) ...[
                        Text(
                          'notes.categories'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: vm.categories.map((cat) {
                              final isSelected = vm.selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    vm.setSelectedCategory(
                                        isSelected ? null : cat.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFB794F6).withOpacity(0.2)
                                          : (isDarkMode
                                          ? ColorConstant.bgColorDark
                                          : ColorConstant.bgColorLight),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFB794F6)
                                            : (isDarkMode
                                            ? ColorConstant.borderColorDark
                                            : ColorConstant.borderColorLight),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (cat.icon != null && cat.icon!.isNotEmpty)
                                          Text(
                                            cat.icon!,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        if (cat.icon != null && cat.icon!.isNotEmpty)
                                          const SizedBox(width: 6),
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFB794F6)
                                                : (isDarkMode
                                                ? ColorConstant.textSecondaryDark
                                                : ColorConstant
                                                .textSecondaryLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Manage Categories Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Pop tamamlandıktan sonra yeni sheet'i aç
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showCategoryManager(context, vm, isDarkMode);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          side: BorderSide(
                            color: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          Icons.category_rounded,
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                          size: 20,
                        ),
                        label: Text(
                          'notes.manageCategories'.tr(),
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB794F6).withOpacity(0.2)
              : (isDarkMode
              ? ColorConstant.bgColorDark
              : ColorConstant.bgColorLight),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB794F6)
                : (isDarkMode
                ? ColorConstant.borderColorDark
                : ColorConstant.borderColorLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFB794F6)
                  : (isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFB794F6)
                    : (isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFFB794F6),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoryManager(
      BuildContext context,
      NotesDiaryViewModel vm,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryManagerSheet(
        viewModel: vm,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

// ==================== KATEGORİ YÖNETİMİ SHEET ====================

class _CategoryManagerSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _CategoryManagerSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Row(
                          children: [
                            Text(
                              'notes.categories'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                _showAddCategoryDialog(context, vm, isDarkMode);
                              },
                              icon: Icon(
                                Icons.add_circle_rounded,
                                color: const Color(0xFFB794F6),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Categories List
                  Expanded(
                    child: vm.categories.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 60,
                            color: const Color(0xFFB794F6).withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'notes.noCategories'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: vm.categories.length,
                      itemBuilder: (context, index) {
                        final category = vm.categories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category.color ?? '#B794F6')
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  category.icon ?? '📁',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                            subtitle: Text(
                              '${category.notesCount} not',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? ColorConstant.textMutedDark
                                    : ColorConstant.textMutedLight,
                              ),
                            ),
                            trailing: PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                          () => _showEditCategoryDialog(
                                        context,
                                        vm,
                                        isDarkMode,
                                        category,
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 20,
                                        color: isDarkMode
                                            ? ColorConstant.textSecondaryDark
                                            : ColorConstant.textSecondaryLight,
                                      ),
                                      const SizedBox(width: 12),
                                      Text('common.edit'.tr()),
                                    ],
                                  ),
                                ),

                                PopupMenuItem(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                          () => _showDeleteCategoryDialog(
                                        context,
                                        vm,
                                        category.id,
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children:  [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'common.delete'.tr(),
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (e) {
      return const Color(0xFFB794F6);
    }
  }

  void _showAddCategoryDialog(
      BuildContext context,
      NotesDiaryViewModel vm,
      bool isDarkMode,
      ) {
    final nameController = TextEditingController();
    String selectedIcon = '📁';
    String selectedColor = '#B794F6';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor:
          isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'notes.newCategory'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'notes.categoryName'.tr(),
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textMutedDark
                        : ColorConstant.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? ColorConstant.bgColorDark
                      : ColorConstant.bgColorLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Icon Selection
              Wrap(
                spacing: 8,
                children: ['📁', '💼', '🎯', '📚', '💡', '🎨', '⚡', '🌟']
                    .map((icon) => GestureDetector(
                  onTap: () => setState(() => selectedIcon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon
                          ? const Color(0xFFB794F6).withOpacity(0.2)
                          : (isDarkMode
                          ? ColorConstant.bgColorDark
                          : ColorConstant.bgColorLight),
                      border: Border.all(
                        color: selectedIcon == icon
                            ? const Color(0xFFB794F6)
                            : (isDarkMode
                            ? ColorConstant.borderColorDark
                            : ColorConstant.borderColorLight),
                        width: selectedIcon == icon ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  vm.createCategory(
                    context,
                    nameController.text.trim(),
                    selectedIcon,
                    selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child:  Text(
                'notes.create'.tr(),
                style: TextStyle(
                  color: Color(0xFFB794F6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(
      BuildContext context,
      NotesDiaryViewModel vm,
      bool isDarkMode,
      NoteCategory category,
      ) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon ?? '📁';
    String selectedColor = category.color ?? '#B794F6';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor:
          isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'notes.editCategory'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'notes.categoryName'.tr(),
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textMutedDark
                        : ColorConstant.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? ColorConstant.bgColorDark
                      : ColorConstant.bgColorLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Icon Selection
              Wrap(
                spacing: 8,
                children: ['📁', '💼', '🎯', '📚', '💡', '🎨', '⚡', '🌟']
                    .map((icon) => GestureDetector(
                  onTap: () => setState(() => selectedIcon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon
                          ? const Color(0xFFB794F6).withOpacity(0.2)
                          : (isDarkMode
                          ? ColorConstant.bgColorDark
                          : ColorConstant.bgColorLight),
                      border: Border.all(
                        color: selectedIcon == icon
                            ? const Color(0xFFB794F6)
                            : (isDarkMode
                            ? ColorConstant.borderColorDark
                            : ColorConstant.borderColorLight),
                        width: selectedIcon == icon ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  vm.updateCategory(
                    context,
                    category.id,
                    nameController.text.trim(),
                    selectedIcon,
                    selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child:  Text(
                'common.update'.tr(),
                style: TextStyle(
                  color: Color(0xFFB794F6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(
      BuildContext context,
      NotesDiaryViewModel vm,
      int categoryId,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'notes.deleteCategory'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'notes.deleteCategoryConfirm'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              vm.deleteCategory(context, categoryId);
              Navigator.pop(context);
            },
            child: const Text(
              'Sil',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GÜNLÜK TAKVİM SHEET ====================

class _DiaryCalendarSheet extends StatefulWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _DiaryCalendarSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  State<_DiaryCalendarSheet> createState() => _DiaryCalendarSheetState();
}

class _DiaryCalendarSheetState extends State<_DiaryCalendarSheet> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Month Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                });
                                vm.loadDiaryEntriesByMonth(
                                  _selectedMonth.month,
                                  _selectedMonth.year,
                                );
                              },
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: widget.isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: widget.isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                });
                                vm.loadDiaryEntriesByMonth(
                                  _selectedMonth.month,
                                  _selectedMonth.year,
                                );
                              },
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: widget.isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calendar Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _getDaysInMonth(_selectedMonth),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month,
                          day,
                        );
                        final hasEntry = vm.diaryEntries.any(
                              (d) =>
                          d.diaryDate.year == date.year &&
                              d.diaryDate.month == date.month &&
                              d.diaryDate.day == date.day,
                        );
                        final isToday = DateTime.now().year == date.year &&
                            DateTime.now().month == date.month &&
                            DateTime.now().day == date.day;

                        return GestureDetector(
                          onTap: hasEntry
                              ? () {
                            final entry = vm.diaryEntries.firstWhere(
                                  (d) =>
                              d.diaryDate.year == date.year &&
                                  d.diaryDate.month == date.month &&
                                  d.diaryDate.day == date.day,
                            );
                            Navigator.pop(context);
                            _showDiaryDetail(
                                context, vm, entry, widget.isDarkMode);
                          }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: hasEntry
                                  ? const Color(0xFFFFA07A).withOpacity(0.2)
                                  : (isToday
                                  ? const Color(0xFFB794F6).withOpacity(0.1)
                                  : null),
                              border: Border.all(
                                color: isToday
                                    ? const Color(0xFFB794F6)
                                    : (hasEntry
                                    ? const Color(0xFFFFA07A)
                                    : (widget.isDarkMode
                                    ? ColorConstant.borderColorDark
                                    : ColorConstant.borderColorLight)),
                                width: isToday || hasEntry ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  hasEntry ? FontWeight.w700 : FontWeight.w500,
                                  color: hasEntry
                                      ? const Color(0xFFFFA07A)
                                      : (isToday
                                      ? const Color(0xFFB794F6)
                                      : (widget.isDarkMode
                                      ? ColorConstant.textPrimaryDark
                                      : ColorConstant.textPrimaryLight)),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Legend
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          context,
                          const Color(0xFFFFA07A),
                          'diary.hasEntry'.tr(),
                        ),
                        const SizedBox(width: 24),
                        _buildLegendItem(
                          context,
                          const Color(0xFFB794F6),
                          'common.today'.tr(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'common.months.january'.tr();
      case 2:
        return 'common.months.february'.tr();
      case 3:
        return 'common.months.march'.tr();
      case 4:
        return 'common.months.april'.tr();
      case 5:
        return 'common.months.may'.tr();
      case 6:
        return 'common.months.june'.tr();
      case 7:
        return 'common.months.july'.tr();
      case 8:
        return 'common.months.august'.tr();
      case 9:
        return 'common.months.september'.tr();
      case 10:
        return 'common.months.october'.tr();
      case 11:
        return 'common.months.november'.tr();
      case 12:
        return 'common.months.december'.tr();
      default:
        return '';
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  void _showDiaryDetail(
      BuildContext context,
      NotesDiaryViewModel vm,
      Diary entry,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiaryDetailSheet(
        viewModel: vm,
        diary: entry,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

// ==================== GÜNLÜK DETAY SHEET ====================

class _DiaryDetailSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final Diary diary;
  final bool isDarkMode;

  const _DiaryDetailSheet({
    required this.viewModel,
    required this.diary,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? ColorConstant.borderColorDark
                          : ColorConstant.borderColorLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date & Mood
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA07A),
                              const Color(0xFFFF8A5C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatFullDate(diary.diaryDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (diary.moodIcon != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA07A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            diary.moodIcon!,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      const SizedBox(width: 12),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [

                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () {
                                  Navigator.pop(context);
                                  _showEditDiaryDialog(
                                      context, viewModel, isDarkMode, diary);
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                                const SizedBox(width: 12),
                                Text('common.edit'.tr()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () {
                                  Navigator.pop(context);
                                  _showDeleteDiaryDialog(
                                    context,
                                    diary.diaryDate
                                        .toIso8601String()
                                        .split('T')[0],
                                    viewModel,
                                  );
                                },
                              );
                            },
                            child: Row(
                              children:  [
                                Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'common.delete'.tr(),
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    if (diary.title != null && diary.title!.isNotEmpty) ...[
                      Text(
                        diary.title!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content
                    Text(
                      diary.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),

                    // Weather
                    if (diary.weather != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? ColorConstant.bgColorDark
                              : ColorConstant.bgColorLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getWeatherIcon(diary.weather!),
                              color: const Color(0xFFFFA07A),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hava: ${_getWeatherLabel(diary.weather!)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'common.monthsShort.january'.tr();
      case 2:
        return 'common.monthsShort.february'.tr();
      case 3:
        return 'common.monthsShort.march'.tr();
      case 4:
        return 'common.monthsShort.april'.tr();
      case 5:
        return 'common.monthsShort.may'.tr();
      case 6:
        return 'common.monthsShort.june'.tr();
      case 7:
        return 'common.monthsShort.july'.tr();
      case 8:
        return 'common.monthsShort.august'.tr();
      case 9:
        return 'common.monthsShort.september'.tr();
      case 10:
        return 'common.monthsShort.october'.tr();
      case 11:
        return 'common.monthsShort.november'.tr();
      case 12:
        return 'common.monthsShort.december'.tr();
      default:
        return '';
    }
  }


  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'rainy':
        return Icons.water_drop_rounded;
      case 'snowy':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  String _getWeatherLabel(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return 'common.weather.sunny'.tr();
      case 'cloudy':
        return 'common.weather.cloudy'.tr();
      case 'rainy':
        return 'common.weather.rainy'.tr();
      case 'snowy':
        return 'common.weather.snowy'.tr();
      default:
        return weather;
    }
  }

  void _showEditDiaryDialog(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      Diary diary,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDiaryBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
        diary: diary,
      ),
    );
  }

  void _showDeleteDiaryDialog(
      BuildContext context,
      String date,
      NotesDiaryViewModel viewModel,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'diary.deleteDiary'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'diary.deleteConfirm'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteDiary(date, context);
            },
            child: const Text(
              'Sil',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DEVAM EDİYOR - Şimdi NotesContent ve DiaryContent classlarını güncelleyeceğim...
// Dosya çok uzun olduğu için ikinci artifact'ta devam edeceğim.
// ==================== NOTLAR İÇERİĞİ ====================

// ==================== NOTLAR İÇERİĞİ ====================
// ==================== NOTLAR İÇERİĞİ ====================
// ==================== TAM _NotesContent CLASS'I ====================
// Bu kodu mevcut _NotesContent class'ınızın yerine koyun

class _NotesContent extends StatelessWidget {
  final NotesDiaryViewModel viewModel;

  const _NotesContent({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFFB794F6)),
      );
    }

    final all = viewModel
        .applyNoteSearch(viewModel.notes.where((n) => !n.isArchived).toList());
    final pinned = all.where((n) => n.isPinned).toList();
    // Son notlar: sabitlenmiş notlar burada TEKRAR gösterilmez.
    final recent = all.where((n) => !n.isPinned).toList();
    final archived = viewModel
        .applyNoteSearch(viewModel.notes.where((n) => n.isArchived).toList());
    final tab = viewModel.notesFilter; // all | pinned | folders | archive
    const orange = Color(0xFFF6A821);
    const purple = Color(0xFF9F7AEA);
    const green = Color(0xFF48BB78);

    return RefreshIndicator(
      onRefresh: () => viewModel.loadNotes(),
      color: const Color(0xFFB794F6),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          _searchBar(context, isDarkMode),
          const SizedBox(height: 16),
          // İstatistik kartları = tıklanabilir filtreler
          Row(
            children: [
              _statCard(Icons.notes_rounded, 'notes.stats.all'.tr(),
                  '${all.length}', orange, isDarkMode,
                  filled: tab == 'all',
                  onTap: () => viewModel.setNotesFilter('all')),
              const SizedBox(width: 10),
              _statCard(Icons.push_pin_rounded, 'notes.stats.pinned'.tr(),
                  '${pinned.length}', orange, isDarkMode,
                  filled: tab == 'pinned',
                  onTap: () => viewModel.setNotesFilter('pinned')),
              const SizedBox(width: 10),
              _statCard(Icons.folder_rounded, 'notes.stats.folders'.tr(),
                  '${viewModel.categories.length}', purple, isDarkMode,
                  filled: tab == 'folders',
                  onTap: () => viewModel.setNotesFilter('folders')),
              const SizedBox(width: 10),
              _statCard(Icons.archive_rounded, 'notes.stats.archive'.tr(),
                  '${archived.length}', green, isDarkMode,
                  filled: tab == 'archive',
                  onTap: () => viewModel.setNotesFilter('archive')),
            ],
          ),
          const SizedBox(height: 20),
          ..._notesBody(context, isDarkMode, tab, all, pinned, recent, archived),
        ],
      ),
    );
  }

  /// Seçili istatistik sekmesine göre gövde.
  List<Widget> _notesBody(
      BuildContext context,
      bool isDarkMode,
      String tab,
      List<Note> all,
      List<Note> pinned,
      List<Note> recent,
      List<Note> archived) {
    // Arama aktifse: sabitlenen/normal ayırmadan tüm eşleşen notları göster.
    if (viewModel.noteSearchQuery.trim().isNotEmpty) {
      // Aynı not iki kez görünmesin (id'ye göre tekilleştir).
      final seen = <int>{};
      final results = <Note>[
        for (final n in [...all, ...archived])
          if (seen.add(n.id)) n
      ];
      return [
        _sectionRow('${'notes.searchHint'.tr()} · ${results.length}',
            isDarkMode: isDarkMode),
        const SizedBox(height: 10),
        results.isEmpty
            ? _inlineEmpty(context, isDarkMode)
            : _notesGrid(context, results, isDarkMode),
      ];
    }
    switch (tab) {
      case 'pinned':
        return [
          _sectionRow('notes.pinnedSection'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          pinned.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : _notesGrid(context, pinned, isDarkMode),
        ];
      case 'archive':
        return [
          _sectionRow('notes.stats.archive'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          archived.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : _notesGrid(context, archived, isDarkMode),
        ];
      case 'folders':
        final catId = viewModel.selectedCategoryId;
        if (catId != null) {
          final inCat = all.where((n) => n.categoryId == catId).toList();
          return [
            _sectionRow('notes.stats.folders'.tr(), isDarkMode: isDarkMode),
            const SizedBox(height: 12),
            inCat.isEmpty
                ? _inlineEmpty(context, isDarkMode)
                : _notesGrid(context, inCat, isDarkMode),
          ];
        }
        return [
          _sectionRow('notes.stats.folders'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          if (viewModel.categories.isEmpty)
            _foldersEmpty(context, isDarkMode)
          else
            ...viewModel.categories.map((cat) {
              final count =
                  all.where((n) => n.categoryId == cat.id).length;
              return _folderCard(context, cat, count, isDarkMode);
            }),
        ];
      default: // all
        return [
          if (pinned.isNotEmpty) ...[
            _sectionRow('notes.pinnedSection'.tr(),
                trailing: 'notes.seeAll'.tr(),
                onTrailing: () => viewModel.setNotesFilter('pinned'),
                isDarkMode: isDarkMode),
            const SizedBox(height: 10),
            // Sabitlenenler: yatay kaydırmalı, ekranda 3 kart yan yana sığar.
            Builder(builder: (context) {
              final w = MediaQuery.of(context).size.width;
              final cardW = ((w - 32 - 20) / 3).clamp(96.0, 150.0);
              return SizedBox(
                height: 146,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pinned.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _buildPinnedCard(
                      context, pinned[i], viewModel, isDarkMode,
                      width: cardW),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          _sectionRow('notes.recentSection'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 10),
          recent.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : _notesGrid(context, recent, isDarkMode),
        ];
    }
  }

  /// Klasör (kategori) kartı — dokununca o klasörün notlarını gösterir.
  Widget _folderCard(BuildContext context, NoteCategory cat, int count,
      bool isDark) {
    final c = AppColors(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => viewModel.setSelectedCategory(cat.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Text((cat.icon ?? '📁'),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                ),
                Text('$count',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted)),
                _folderMenu(context, cat, isDark, c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Klasör kartı ⋯ menüsü — düzenle / sil.
  Widget _folderMenu(BuildContext context, NoteCategory cat, bool isDark,
      AppColors c) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz_rounded, size: 20, color: c.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) {
        if (v == 'edit') {
          showFolderDialog(context, viewModel, isDark, editing: cat);
        } else if (v == 'delete') {
          _confirmDeleteFolder(context, cat, c);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_rounded, size: 20),
            const SizedBox(width: 12),
            Text('common.edit'.tr()),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline_rounded,
                size: 20, color: Color(0xFFE53E3E)),
            const SizedBox(width: 12),
            Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFE53E3E))),
          ]),
        ),
      ],
    );
  }

  void _confirmDeleteFolder(
      BuildContext context, NoteCategory cat, AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('notes.folders.deleteTitle'.tr()),
        content: Text('notes.folders.deleteConfirm'
            .tr(namedArgs: {'name': cat.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.deleteCategory(context, cat.id);
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFE53E3E))),
          ),
        ],
      ),
    );
  }

  Widget _foldersEmpty(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded,
              size: 40, color: const Color(0xFF9F7AEA).withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('notes.folders.emptyTitle'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('notes.folders.emptyDesc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }

  /// Not ızgarası boşken gösterilen kompakt satır içi boş durum.
  Widget _inlineEmpty(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.note_add_rounded,
              size: 36, color: const Color(0xFFB794F6).withOpacity(0.6)),
          const SizedBox(height: 10),
          Text('notes.emptyState'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 14),
          _emptyHint(c, Icons.note_add_rounded,
              const Color(0xFFB794F6), 'notes.add.noteDesc'.tr()),
          const SizedBox(height: 8),
          _emptyHint(c, Icons.create_new_folder_rounded,
              const Color(0xFF9F7AEA), 'notes.add.folderDesc'.tr()),
        ],
      ),
    );
  }

  Widget _emptyHint(AppColors c, IconData icon, Color accent, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
        ),
      ],
    );
  }

  /// Arama çubuğu (görsel amaçlı).
  Widget _searchBar(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: viewModel.setNoteSearchQuery,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'notes.searchHint'.tr(),
                hintStyle: TextStyle(fontSize: 15, color: c.textMuted),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showNotesFilterSheet(context, isDark),
            child: Icon(Icons.tune_rounded, size: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Filtre alt sayfası: sekmelere göre hızlı filtre.
  void _showNotesFilterSheet(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    final items = [
      ['all', Icons.notes_rounded, 'notes.stats.all'.tr()],
      ['pinned', Icons.push_pin_rounded, 'notes.stats.pinned'.tr()],
      ['folders', Icons.folder_rounded, 'notes.stats.folders'.tr()],
      ['archive', Icons.archive_rounded, 'notes.stats.archive'.tr()],
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            for (final it in items)
              ListTile(
                leading: Icon(it[1] as IconData, color: c.textSecondary),
                title: Text(it[2] as String),
                trailing: viewModel.notesFilter == it[0]
                    ? const Icon(Icons.check_rounded, color: Color(0xFFF6A821))
                    : null,
                onTap: () {
                  viewModel.setNotesFilter(it[0] as String);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String count, Color color,
      bool isDark,
      {bool filled = false, VoidCallback? onTap}) {
    final c = AppColors(isDark);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(isDark ? 0.16 : 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color:
                      filled ? Colors.white.withOpacity(0.9) : c.textSecondary,
                )),
            Text(count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: filled ? Colors.white : c.textPrimary,
                )),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionRow(String title,
      {String? trailing, VoidCallback? onTrailing, required bool isDarkMode}) {
    final c = AppColors(isDarkMode);
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: c.textPrimary,
            )),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Row(
              children: [
                Text(trailing,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF6A821),
                    )),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFFF6A821)),
              ],
            ),
          ),
      ],
    );
  }

  /// 3 sütunlu kompakt ızgara — sabit yükseklik, taşma yok.
  Widget _notesGrid(BuildContext context, List<Note> notes, bool isDarkMode) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 146,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) =>
          _buildPinnedCard(context, notes[i], viewModel, isDarkMode),
    );
  }

  Widget _buildGridView(BuildContext context, List<Note> notes, bool isDarkMode) {
    // Sticky-note ızgarası: 2 sütun, kartlar daha büyük ve okunur.
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(context, note, viewModel, isDarkMode);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<Note> notes, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteListItem(context, note, viewModel, isDarkMode);
      },
    );
  }

  Widget _buildNoteListItem(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final category = note.categoryId != null
        ? viewModel.categories.firstWhere(
          (c) => c.id == note.categoryId,
      orElse: () => NoteCategory(
        id: 0,
        name: '',
        notesCount: 0,
        orderIndex: 0,
      ),
    )
        : null;

    final noteColor = _getNoteColor(note.color ?? '#B794F6');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            noteColor.withOpacity(0.12),
            noteColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: noteColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: noteColor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
        // Dekoratif background circles
        Positioned(
        top: -30,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: noteColor.withOpacity(0.06),
          ),
        ),
      ),
      Positioned(
        bottom: -20,
        left: -20,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: noteColor.withOpacity(0.04),
          ),
        ),
      ),

      // Ana içerik
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (note.isLocked) {
              _showUnlockDialog(context, note, viewModel, isDarkMode);
            } else {
              _showEditNoteDialog(context, note, viewModel, isDarkMode);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
              // Sol taraf - İkon ve kategori
              Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    noteColor.withOpacity(0.3),
                    noteColor.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: noteColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Dekoratif pattern
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: noteColor.withOpacity(0.12),
                      ),
                    ),
                  ),
                  // Ana ikon
                  Center(
                    child: note.isLocked
                        ? Icon(
                      Icons.lock_rounded,
                      color: noteColor.withOpacity(0.9),
                      size: 26,
                    )
                        : (category != null &&
                        category.icon != null &&
                        category.icon!.isNotEmpty)
                        ? Text(
                      category.icon!,
                      style: const TextStyle(fontSize: 26),
                    )
                        : Icon(
                      Icons.note_rounded,
                      color: noteColor.withOpacity(0.9),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Orta - Başlık ve içerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık satırı
                  Row(
                    children: [
                      if (note.isPinned)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: noteColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: noteColor,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          note.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // İçerik
                  Text(
                    note.isLocked ? 'notes.lockedNote'.tr() : (note.content ?? ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tarih ve badges
                  Row(
                    children: [
                      Text(
                        _formatDate(note.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? ColorConstant.textMutedDark
                              : ColorConstant.textMutedLight,
                        ),
                      ),
                      if (note.isArchived) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark.withOpacity(0.2)
                                  : ColorConstant.textMutedLight.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.archive_rounded,
                                size: 11,
                                color: isDarkMode
                                    ? ColorConstant.textMutedDark
                                    : ColorConstant.textMutedLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'notes.archive'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? ColorConstant.textMutedDark
                                      : ColorConstant.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Sağ taraf - Menu button
            // Sağ taraf - Menu button
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: noteColor.withOpacity(0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: noteColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: noteColor.withOpacity(0.9),
                ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () => viewModel.togglePin(note.id, context),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        note.isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(note.isPinned ? 'notes.unpinNote'.tr() : 'notes.pinNote'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () => viewModel.copyNoteToClipboard(note, context),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.content_copy_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text('common.copy'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () {
                        if (note.isLocked) {
                          _showUnlockDialog(
                              context, note, viewModel, isDarkMode);
                        } else {
                          _showLockDialog(
                              context, note, viewModel, isDarkMode);
                        }
                      },
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        note.isLocked
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(note.isLocked ? 'notes.unlockNote'.tr() : 'notes.lockNote'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () => viewModel.toggleArchive(note.id, context),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        note.isArchived
                            ? Icons.unarchive_rounded
                            : Icons.archive_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(note.isArchived ? 'notes.unarchiveNote'.tr() : 'notes.archiveNote'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () => _showDeleteNoteDialog(context, note.id, viewModel),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(
                        Icons.delete_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Sil',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            )],
        ),
      ),
    ),
    ),

    // Lock indicator badge (if locked)
    if (note.isLocked)
    Positioned(
    top: 10,
    right: 10,
    child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [
    noteColor,
    noteColor.withOpacity(0.8),
    ],
    ),
    borderRadius: BorderRadius.circular(6),
    boxShadow: [
    BoxShadow(
    color: noteColor.withOpacity(0.3),
    blurRadius: 6,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(
    Icons.lock_rounded,
    size: 10,
    color: Colors.white,
    ),
    const SizedBox(width: 3),
    Text(
    'notes.locked'.tr(),
    style: TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    ),
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    );
  }

  Widget _buildNoteCard(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final category = note.categoryId != null
        ? viewModel.categories.firstWhere(
            (c) => c.id == note.categoryId,
            orElse: () =>
                NoteCategory(id: 0, name: '', notesCount: 0, orderIndex: 0),
          )
        : null;

    final noteColor = _getNoteColor(note.color ?? '#B794F6');
    final c = AppColors(isDarkMode);
    final cardBg = isDarkMode
        ? Color.alphaBlend(
            noteColor.withOpacity(0.12), ColorConstant.cardColorDark)
        : Color.alphaBlend(noteColor.withOpacity(0.07), Colors.white);

    // İçeriği checklist / düz metin olarak ayrıştır (orijinal satır indeksiyle)
    final rawLines = (note.content ?? '').split('\n');
    final checkItems = <List<dynamic>>[]; // [origIndex, checked, text]
    final otherLines = <String>[];
    for (var i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      if (l.startsWith('☐ ') || l.startsWith('☑ ')) {
        checkItems.add([i, l.startsWith('☑ '), l.substring(2)]);
      } else if (l.trim().isNotEmpty) {
        otherLines.add(l.startsWith('• ') ? l.substring(2) : l);
      }
    }
    final total = checkItems.length;
    final done = checkItems.where((e) => e[1] as bool).length;
    const hasImage = false;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: noteColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.0 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (note.isLocked) {
              _showUnlockDialog(context, note, viewModel, isDarkMode);
            } else {
              _showEditNoteDialog(context, note, viewModel, isDarkMode);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst satır: başlık + (pin) + menü (başlık boşluğu doldurur)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          (note.title ?? '').isNotEmpty
                              ? note.title!
                              : (category?.name ?? ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.2,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Icon(Icons.push_pin_rounded,
                            size: 14, color: noteColor.withOpacity(0.9)),
                      ),
                    _cardMenu(context, note, viewModel, isDarkMode, c),
                  ],
                ),
                const SizedBox(height: 6),

                // Gövde
                if (note.isLocked)
                  Row(
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 15, color: c.textMuted),
                      const SizedBox(width: 6),
                      Text('notes.lockedNote'.tr(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textMuted)),
                    ],
                  )
                else if (total > 0) ...[
                  for (int k = 0; k < checkItems.length && k < 4; k++)
                    _cardCheckRow(
                      context,
                      viewModel,
                      note,
                      checkItems[k][0] as int,
                      checkItems[k][1] as bool,
                      checkItems[k][2] as String,
                      c,
                    ),
                  if (total > 4)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Text('+${total - 4}',
                          style: TextStyle(
                              fontSize: 12,
                              color: c.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 8),
                  // İlerleme çubuğu
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 6,
                            backgroundColor: noteColor.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(noteColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$done/$total',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.textSecondary)),
                    ],
                  ),
                ] else if (otherLines.isNotEmpty)
                  Text(
                    otherLines.join('\n'),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),

                const SizedBox(height: 8),
                // Alt satır: zaman + hatırlatıcı
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: c.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatDate(note.updatedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted),
                      ),
                    ),
                    if (note.reminderDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48BB78).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                size: 11, color: Color(0xFF2F9E5E)),
                            const SizedBox(width: 3),
                            Text(
                              '${note.reminderDate!.day}.${note.reminderDate!.month}',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2F9E5E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sabitlenenler satırındaki kompakt kart — sabit yükseklik, taşma yok.
  /// Gövde Expanded + ClipRect ile kırpılır; içerik ne kadar uzun olursa olsun
  /// kart sabit yüksekliği aşmaz (hata göstergesi çıkmaz).
  Widget _buildPinnedCard(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode, {
      double? width,
      }) {
    final category = note.categoryId != null
        ? viewModel.categories.firstWhere(
            (c) => c.id == note.categoryId,
            orElse: () =>
                NoteCategory(id: 0, name: '', notesCount: 0, orderIndex: 0),
          )
        : null;
    final noteColor = _getNoteColor(note.color ?? '#B794F6');
    final c = AppColors(isDarkMode);
    final cardBg = isDarkMode
        ? Color.alphaBlend(
            noteColor.withOpacity(0.12), ColorConstant.cardColorDark)
        : Color.alphaBlend(noteColor.withOpacity(0.07), Colors.white);

    final rawLines = (note.content ?? '').split('\n');
    final checkItems = <List<dynamic>>[];
    final otherLines = <String>[];
    for (var i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      if (l.startsWith('☐ ') || l.startsWith('☑ ')) {
        checkItems.add([i, l.startsWith('☑ '), l.substring(2)]);
      } else if (l.trim().isNotEmpty) {
        otherLines.add(l.startsWith('• ') ? l.substring(2) : l);
      }
    }
    final total = checkItems.length;
    final done = checkItems.where((e) => e[1] as bool).length;
    final imgs = viewModel.imagesForNote(note.id);

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: noteColor.withOpacity(0.25)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (note.isLocked) {
                _showUnlockDialog(context, note, viewModel, isDarkMode);
              } else {
                _showEditNoteDialog(context, note, viewModel, isDarkMode);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            (note.title ?? '').isNotEmpty
                                ? note.title!
                                : (category?.name ?? ' '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.2,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (note.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 3),
                          child: Icon(Icons.push_pin_rounded,
                              size: 11, color: noteColor.withOpacity(0.9)),
                        ),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: _cardMenu(
                            context, note, viewModel, isDarkMode, c),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Küçük görsel önizleme (varsa).
                  if (imgs.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imgs.first),
                        height: 32,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Gövde — kırpılır, asla taşmaz.
                  Expanded(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: note.isLocked
                            ? Row(children: [
                                Icon(Icons.lock_rounded,
                                    size: 12, color: c.textMuted),
                                const SizedBox(width: 4),
                                Text('notes.lockedNote'.tr(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: c.textMuted)),
                              ])
                            : total > 0
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int k = 0;
                                          k < checkItems.length && k < 3;
                                          k++)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 3),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => viewModel
                                                .toggleChecklistLine(note,
                                                    checkItems[k][0] as int),
                                            child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                  (checkItems[k][1] as bool)
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons
                                                          .radio_button_unchecked,
                                                  size: 12,
                                                  color: (checkItems[k][1]
                                                          as bool)
                                                      ? const Color(
                                                          0xFF48BB78)
                                                      : c.textMuted),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  checkItems[k][2] as String,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    height: 1.2,
                                                    color: (checkItems[k][1]
                                                            as bool)
                                                        ? c.textMuted
                                                        : c.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text('$done/$total',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: c.textSecondary)),
                                    ],
                                  )
                                : Text(
                                    otherLines.join('\n'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.3,
                                      color: c.textSecondary,
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 11, color: c.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _formatDate(note.updatedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kart içindeki işaretlenebilir checklist satırı.
  Widget _cardCheckRow(BuildContext context, NotesDiaryViewModel viewModel,
      Note note, int lineIndex, bool checked, String text, AppColors c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => viewModel.toggleChecklistLine(note, lineIndex),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? const Color(0xFF48BB78) : Colors.transparent,
                shape: BoxShape.circle,
                border: checked
                    ? null
                    : Border.all(color: c.border, width: 1.6),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: checked ? c.textMuted : c.textPrimary,
                  decoration:
                      checked ? TextDecoration.lineThrough : null,
                  decorationColor: c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kart köşesindeki ⋯ menüsü (pin/kopya/kilit/arşiv/sil).
  Widget _cardMenu(BuildContext context, Note note,
      NotesDiaryViewModel viewModel, bool isDarkMode, AppColors c) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: c.textMuted),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.togglePin(note.id, context)),
          child: Row(children: [
            Icon(note.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded, size: 20),
            const SizedBox(width: 12),
            Text(note.isPinned
                ? 'notes.unpinNote'.tr()
                : 'notes.pinNote'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.copyNoteToClipboard(note, context)),
          child: Row(children: [
            const Icon(Icons.content_copy_rounded, size: 20),
            const SizedBox(width: 12),
            Text('common.copy'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100), () {
            if (note.isLocked) {
              _showUnlockDialog(context, note, viewModel, isDarkMode);
            } else {
              _showLockDialog(context, note, viewModel, isDarkMode);
            }
          }),
          child: Row(children: [
            Icon(note.isLocked
                ? Icons.lock_open_rounded
                : Icons.lock_rounded, size: 20),
            const SizedBox(width: 12),
            Text(note.isLocked
                ? 'notes.unlockNote'.tr()
                : 'notes.lockNote'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.toggleArchive(note.id, context)),
          child: Row(children: [
            Icon(note.isArchived
                ? Icons.unarchive_rounded
                : Icons.archive_rounded, size: 20),
            const SizedBox(width: 12),
            Text(note.isArchived
                ? 'notes.unarchiveNote'.tr()
                : 'notes.archiveNote'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => _showDeleteNoteDialog(context, note.id, viewModel)),
          child: Row(children: [
            const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Text('common.delete'.tr(),
                style: const TextStyle(color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  void _showLockDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'notes.lockNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '4 haneli bir PIN kodu girin',
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(context);
                viewModel.lockNote(note.id, pinController.text, context);
              }
            },
            child:  Text(
              'common.lock'.tr(),
              style: TextStyle(
                color: Color(0xFFB794F6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'notes.unlockNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'notes.enterPin'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                final pin = pinController.text;
                Navigator.pop(context);

                viewModel.unlockNote(
                  note.id,
                  pin,
                  context,
                      () {
                    Future.delayed(
                      const Duration(milliseconds: 300),
                          () {
                        if (context.mounted) {
                          _showEditNoteDialog(context, note, viewModel, isDarkMode);
                        }
                      },
                    );
                  },
                );
              }
            },
            child: Text(
              'common.open'.tr(),
              style: const TextStyle(
                color: Color(0xFFB794F6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    // Düzenleme de aynı zengin editörle yapılır.
    viewModel.setNoteForEdit(note);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddNoteBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
        isEditing: true,
      ),
    );
  }

  void _showDeleteNoteDialog(
      BuildContext context,
      int noteId,
      NotesDiaryViewModel viewModel,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'notes.deleteNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'notes.deleteNoteConfirm'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteNote(noteId, context);
            },
            child: const Text(
              'Sil',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (e) {
      return const Color(0xFFB794F6);
    }
  }

  // Sticky-note yardımcıları artık dosya sonunda top-level fonksiyon
  // (hem not hem günlük kartları paylaşıyor): _stickyFill/_stickyFold/_stickyInk

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'common.today'.tr();
    } else if (difference.inDays == 1) {
      return 'common.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'common.daysAgo'.tr(namedArgs: {'count': '${difference.inDays}'});
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

// ==================== GÜNLÜK İÇERİĞİ ====================

class _DiaryContent extends StatelessWidget {
  final NotesDiaryViewModel viewModel;

  const _DiaryContent({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFFFA07A),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadDiaryEntries(),
      color: const Color(0xFFFFA07A),
      child: viewModel.diaryEntries.isNotEmpty
          ? ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: viewModel.diaryEntries.length,
        itemBuilder: (context, index) {
          final entry = viewModel.diaryEntries[index];
          return _buildDiaryCard(context, entry, viewModel, isDarkMode);
        },
      )
          : _buildEmptyState(
        illustration: 'empty_notes.svg',
        message: 'diary.emptyState'.tr(),
        subtitle: 'diary.emptyStateSubtitle'.tr(),
        color: const Color(0xFFFFA07A),
        actionLabel: 'diary.newEntry'.tr(),
        onAction: () => showAddDiarySheet(context, viewModel, isDarkMode),
      ),
    );
  }

  // Günlük kartı — Stitch "Günlüğüm" dili: tam genişlik renkli kart
  // (tarih + ruh hali emoji + başlık + metin + opsiyonel görsel).
  Widget _buildDiaryCard(
      BuildContext context,
      Diary entry,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final color = _diaryColor(entry, isDarkMode);
    final ink = _stickyInk(color, isDarkMode);
    final hasImage = entry.imageUrls?.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDarkMode ? 0.25 : 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _showDiaryDetail(context, viewModel, entry, isDarkMode),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDiaryDate(entry.diaryDate).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: ink.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    if (entry.moodIcon != null && entry.moodIcon!.isNotEmpty)
                      Text(entry.moodIcon!,
                          style: const TextStyle(fontSize: 22))
                    else if (entry.weather != null)
                      Icon(_getWeatherIcon(entry.weather!),
                          size: 20, color: ink.withOpacity(0.7)),
                  ],
                ),
                const SizedBox(height: 12),
                if (entry.title != null && entry.title!.isNotEmpty) ...[
                  Text(
                    entry.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  entry.content,
                  maxLines: hasImage ? 3 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: ink.withOpacity(0.78),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      entry.imageUrls!.first,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (c, child, prog) => prog == null
                          ? child
                          : Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ink.withOpacity(0.5),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Günlük kartının rengi — ruh haline göre; yoksa id'ye göre sabit palet.
  Color _diaryColor(Diary entry, bool isDark) {
    const moodColors = {
      '😊': Color(0xFFFCE255),
      '😔': Color(0xFF7EC8F5),
      '😌': Color(0xFF81C784),
      '😍': Color(0xFFF48FB1),
      '😡': Color(0xFFFF8A65),
      '😴': Color(0xFFB39DDB),
    };
    const palette = [
      Color(0xFFFCE255),
      Color(0xFF7EC8F5),
      Color(0xFFF48FB1),
      Color(0xFF81C784),
      Color(0xFFB39DDB),
    ];
    final base = moodColors[entry.moodIcon] ?? palette[entry.id % palette.length];
    return _stickyFill(base, isDark);
  }

  void _showDiaryDetail(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      Diary entry,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiaryDetailSheet(
        viewModel: viewModel,
        diary: entry,
        isDarkMode: isDarkMode,
      ),
    );
  }

  String _formatDiaryDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'common.today'.tr();
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'common.yesterday'.tr();
    }
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'common.monthsShort.january'.tr();
      case 2:
        return 'common.monthsShort.february'.tr();
      case 3:
        return 'common.monthsShort.march'.tr();
      case 4:
        return 'common.monthsShort.april'.tr();
      case 5:
        return 'common.monthsShort.may'.tr();
      case 6:
        return 'common.monthsShort.june'.tr();
      case 7:
        return 'common.monthsShort.july'.tr();
      case 8:
        return 'common.monthsShort.august'.tr();
      case 9:
        return 'common.monthsShort.september'.tr();
      case 10:
        return 'common.monthsShort.october'.tr();
      case 11:
        return 'common.monthsShort.november'.tr();
      case 12:
        return 'common.monthsShort.december'.tr();
      default:
        return '';
    }
  }

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'rainy':
        return Icons.water_drop_rounded;
      case 'snowy':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  String _getWeatherLabel(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return 'common.weather.sunny'.tr();
      case 'cloudy':
        return 'common.weather.cloudy'.tr();
      case 'rainy':
        return 'common.weather.rainy'.tr();
      case 'snowy':
        return 'common.weather.snowy'.tr();
      default:
        return weather;
    }
  }
}

/// İçerik alanına imleç konumundan yeni bir satır olarak işaret ekler
/// (☐ checklist, • madde işareti). Backend değişikliği gerektirmez —
/// checklist metnin içinde unicode işaretlerle saklanır.
void insertNotePrefix(TextEditingController c, String prefix) {
  final text = c.text;
  final sel = c.selection;
  final pos = (sel.isValid && sel.baseOffset >= 0)
      ? sel.baseOffset
      : text.length;
  final needsNewline = pos > 0 && text[pos - 1] != '\n';
  final insert = '${needsNewline ? '\n' : ''}$prefix';
  final newText = text.replaceRange(pos, pos, insert);
  c.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: pos + insert.length),
  );
}

/// Editör alt çubuğundaki ekleme çipi (checklist / madde işareti).
class _InsertChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _InsertChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withOpacity(0.14),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== NOT EKLEME BOTTOM SHEET ====================
class _AddNoteBottomSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;
  final bool isEditing;

  const _AddNoteBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    this.isEditing = false,
  });

  static const Color _accent = Color(0xFFF6A821);
  static const Color _accentDark = Color(0xFFEE8B00);
  static const Color _green = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          final c = AppColors(isDarkMode);
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.bgColorDark
                  : const Color(0xFFF6F4EF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _topBar(context, vm, c),
                  _metaChips(context, vm, c),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: _editorCard(context, vm, c),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _toolbarAdd(context, vm, c),
                        _toolbarFormat(context, vm, c),
                        _actionChips(context, vm, c),
                        _bottomBar(context, vm, c),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Üst çubuk ----------
  Widget _topBar(BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new_rounded, c, () {
            vm.resetNoteForm();
            Navigator.pop(context);
          }),
          Expanded(
            child: Text(
              isEditing ? 'notes.editor.editNote'.tr() : 'notes.newNote'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          // Sabitle — kaydedince notu sabitler
          _circleBtn(
            vm.notePinned ? Icons.push_pin : Icons.push_pin_outlined,
            c,
            () {
              vm.toggleNotePinned();
              _toast(context,
                  vm.notePinned ? 'notes.editor.willPin'.tr() : 'notes.editor.unpinned'.tr());
            },
            active: vm.notePinned,
          ),
          const SizedBox(width: 8),
          _circleBtn(Icons.more_horiz_rounded, c,
              () => _toast(context, 'notes.editor.moreOptions'.tr())),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, AppColors c, VoidCallback onTap,
      {bool active = false}) {
    return Material(
      color: active ? _accent.withOpacity(0.15) : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: active ? _accent : c.border.withOpacity(0.7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 19, color: active ? _accentDark : c.textPrimary),
        ),
      ),
    );
  }

  // ---------- Klasör / kilit / durum çipleri ----------
  Widget _metaChips(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    // Seçili kategorinin adı (yoksa "Kişisel")
    String folderLabel = 'notes.editor.personal'.tr();
    if (vm.selectedCategoryForNote != null) {
      final cat = vm.categories.where(
          (e) => e.id == vm.selectedCategoryForNote);
      if (cat.isNotEmpty) folderLabel = cat.first.name;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Row(
        children: [
          _metaChip(Icons.folder_rounded, folderLabel, c,
              trailing: true, onTap: () => _pickCategory(context, vm)),
          const SizedBox(width: 8),
          _metaChip(
            vm.noteLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            vm.noteLocked
                ? 'notes.editor.locked'.tr()
                : 'notes.editor.unlocked'.tr(),
            c,
            trailing: true,
            active: vm.noteLocked,
            onTap: () {
              vm.toggleNoteLocked();
              _toast(context, vm.noteLocked ? 'notes.editor.willLock'.tr() : 'notes.editor.lockRemoved'.tr());
            },
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'notes.editor.editingNow'.tr(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, AppColors c,
      {bool trailing = false, bool active = false, VoidCallback? onTap}) {
    return Material(
      color: active ? _accent.withOpacity(0.14) : c.card,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: active ? _accent : c.border.withOpacity(0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15,
                  color: active ? _accentDark : c.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? _accentDark : c.textPrimary,
                ),
              ),
              if (trailing) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: c.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Kategori seçimi (klasör) — alt sayfa.
  void _pickCategory(BuildContext context, NotesDiaryViewModel vm) {
    final c = AppColors(isDarkMode);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.folder_open_rounded, color: c.textSecondary),
              title: Text('notes.editor.noCategory'.tr()),
              trailing: vm.selectedCategoryForNote == null
                  ? const Icon(Icons.check_rounded, color: _accentDark)
                  : null,
              onTap: () {
                vm.setSelectedCategoryForNote(null);
                Navigator.pop(ctx);
              },
            ),
            for (final cat in vm.categories)
              ListTile(
                leading: Text(cat.icon ?? '📁',
                    style: const TextStyle(fontSize: 20)),
                title: Text(cat.name),
                trailing: vm.selectedCategoryForNote == cat.id
                    ? const Icon(Icons.check_rounded, color: _accentDark)
                    : null,
                onTap: () {
                  vm.setSelectedCategoryForNote(cat.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Hatırlatıcı — tarih + saat seçimi.
  Future<void> _pickReminder(
      BuildContext context, NotesDiaryViewModel vm) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
    vm.setNoteReminder(dt);
    if (context.mounted) {
      _toast(context,
          'notes.editor.reminderSet'.tr(namedArgs: {
        'date':
            '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
      }));
    }
  }

  // ---------- Editör kartı ----------
  Widget _editorCard(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.0 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık (işlevsel)
          TextField(
            controller: vm.noteTitleController,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: c.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'notes.noteTitle'.tr(),
              hintStyle: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: c.textMuted.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: c.border.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            _todayLabel(),
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          const SizedBox(height: 16),

          // Notun mevcut (kayıtlı) görselleri — düzenlemede gösterilir.
          if (vm.editingExistingImages.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < vm.editingExistingImages.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(vm.editingExistingImages[i]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: c.card,
                            child: Icon(Icons.broken_image_rounded,
                                color: c.textMuted),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => vm.removeExistingImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Eklenen görseller (Fotoğraf/Kamera ile seçilenler)
          if (vm.pickedImages.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < vm.pickedImages.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          vm.pickedImages[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => vm.removePickedImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Ses kaydı durumu / kaydedilmiş ses notu
          if (vm.isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF5350)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('notes.editor.recording'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF5350))),
                  ),
                  GestureDetector(
                    onTap: () => vm.toggleRecording(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('notes.editor.stop'.tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (vm.voiceNotePath != null) ...[
            _VoiceNoteChip(
              path: vm.voiceNotePath!,
              onRemove: () => vm.removeVoiceNote(),
            ),
            const SizedBox(height: 16),
          ],

          // Eklenen dosyalar
          if (vm.pickedFiles.isNotEmpty) ...[
            for (int i = 0; i < vm.pickedFiles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border.withOpacity(0.8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_rounded,
                          size: 18, color: c.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vm.pickedFiles[i].path.split(Platform.pathSeparator).last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => vm.removePickedFile(i),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // Gerçek, işlevsel içerik alanı. Araç çubuğundaki liste/onay-kutusu
          // butonları buraya madde ekler; kaydedilince kartta işaretlenebilir.
          TextField(
            controller: vm.noteContentController,
            focusNode: vm.noteContentFocus,
            maxLines: null,
            minLines: 10,
            cursorColor: _accent,
            style: TextStyle(fontSize: 16, height: 1.55, color: c.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText:
                  'notes.editor.startWriting'.tr(),
              hintStyle: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: c.textMuted.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _checkRow(AppColors c, bool done, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: done ? _green : Colors.transparent,
              shape: BoxShape.circle,
              border: done
                  ? null
                  : Border.all(color: c.border, width: 2),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: done ? c.textMuted : c.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(List<Color> colors) {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.image_rounded,
        color: Colors.white.withOpacity(0.6),
        size: 30,
      ),
    );
  }

  Widget _voicePlayer(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 2),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: _accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(38, (i) {
                  final h = 5.0 + ((i * 13) % 20);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.4),
                    child: Container(
                      width: 2.6,
                      height: h,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '00:38',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Araç çubuğu 1 (Ekle/Kamera/...) — işlevsel ----------
  Widget _toolbarAdd(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    final items = <List<dynamic>>[
      [Icons.camera_alt_outlined, 'camera', 'notes.editor.camera'.tr(), c.textSecondary],
      [Icons.image_outlined, 'photo', 'notes.editor.photo'.tr(), c.textSecondary],
      [Icons.attach_file_rounded, 'file', 'notes.editor.file'.tr(), c.textSecondary],
      [Icons.gesture_rounded, 'draw', 'notes.editor.draw'.tr(), c.textSecondary],
      [Icons.document_scanner_outlined, 'scan', 'notes.editor.scan'.tr(), c.textSecondary],
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: items.map((it) {
            final id = it[1] as String;
            final label = it[2] as String;
            return InkWell(
              onTap: () {
                if (id == 'add') {
                  vm.noteContentFocus.requestFocus();
                } else if (id == 'link') {
                  vm.noteContentFocus.requestFocus();
                  insertNotePrefix(vm.noteContentController, '🔗 https://');
                } else if (id == 'photo') {
                  vm.pickNoteImage(ImageSource.gallery);
                } else if (id == 'camera' || id == 'scan') {
                  vm.pickNoteImage(ImageSource.camera);
                } else if (id == 'draw') {
                  _openDrawingPad(context, vm);
                } else if (id == 'file') {
                  _pickFile(context, vm);
                } else if (id == 'voice') {
                  vm.toggleRecording();
                } else {
                  _toast(context,
                      'notes.editor.comingSoon'.tr(namedArgs: {'label': label}));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(it[0] as IconData, size: 24, color: it[3] as Color),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------- Araç çubuğu 2 (zengin metin) — işlevsel ----------
  Widget _toolbarFormat(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    // Her buton: [ikon, aksiyon]. Liste/onay/madde/alıntı gerçekten
    // içeriğe eklenir; kalın/italik seçimi işaretlerle sarar.
    final buttons = <List<dynamic>>[
      [Icons.format_list_bulleted_rounded, () => _insert(vm, '• ')],
      [Icons.format_list_numbered_rounded, () => _insertNumbered(vm)],
      [Icons.check_box_outlined, () => _insert(vm, '☐ ')],
      [Icons.format_quote_rounded, () => _insert(vm, '> ')],
      [Icons.undo_rounded, () => _toast(context, 'notes.editor.undo'.tr())],
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: List.generate(buttons.length, (i) {
            return InkWell(
              onTap: buttons[i][1] as VoidCallback,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Icon(
                  buttons[i][0] as IconData,
                  size: 22,
                  color: i == 0 ? _accent : c.textSecondary,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// İçerik alanına odaklanıp satır başına işaret ekler.
  void _insert(NotesDiaryViewModel vm, String prefix) {
    vm.noteContentFocus.requestFocus();
    insertNotePrefix(vm.noteContentController, prefix);
  }

  /// Numaralı liste: mevcut en büyük numarayı bulur, bir sonrakini ekler (1, 2, 3…).
  void _insertNumbered(NotesDiaryViewModel vm) {
    final text = vm.noteContentController.text;
    var maxN = 0;
    for (final line in text.split('\n')) {
      final m = RegExp(r'^(\d+)\.\s').firstMatch(line.trimLeft());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > maxN) maxN = n;
      }
    }
    _insert(vm, '${maxN + 1}. ');
  }

  /// İmleçteki seçili metni verilen işaretle sarar (**kalın**, *italik*).
  void _wrapSel(NotesDiaryViewModel vm, String marker) {
    final c = vm.noteContentController;
    final sel = c.selection;
    final text = c.text;
    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final wrapped = '$marker$selected$marker';
      c.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, wrapped),
        selection: TextSelection.collapsed(offset: sel.start + wrapped.length),
      );
    } else {
      final pos = sel.isValid ? sel.baseOffset : text.length;
      final ins = '$marker$marker';
      c.value = TextEditingValue(
        text: text.replaceRange(pos, pos, ins),
        selection: TextSelection.collapsed(offset: pos + marker.length),
      );
    }
    vm.noteContentFocus.requestFocus();
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Çizim tuvalini açar; kaydedilen çizim görsel olarak nota eklenir.
  Future<void> _openDrawingPad(
      BuildContext context, NotesDiaryViewModel vm) async {
    final File? file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const _DrawingPadPage()),
    );
    if (file != null) vm.addPickedImageFile(file);
  }

  /// Dosya seçici — seçilen dosyayı nota ekler.
  Future<void> _pickFile(BuildContext context, NotesDiaryViewModel vm) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (path != null) vm.addPickedFile(File(path));
    } catch (_) {
      if (context.mounted) _toast(context, 'notes.editor.fileError'.tr());
    }
  }

  // ---------- Etiket / Hatırlatıcı / Paylaş — işlevsel ----------
  Widget _actionChips(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: _actionChip(
                vm.noteReminder != null
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                vm.noteReminder != null
                    ? '${vm.noteReminder!.day}.${vm.noteReminder!.month} ${vm.noteReminder!.hour.toString().padLeft(2, '0')}:${vm.noteReminder!.minute.toString().padLeft(2, '0')}'
                    : 'notes.editor.reminder'.tr(),
                c,
                () => _pickReminder(context, vm)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionChip(Icons.people_alt_outlined, 'notes.editor.share'.tr(), c, () {
              final title = vm.noteTitleController.text.trim();
              final body = vm.noteContentController.text.trim();
              final text = [title, body].where((s) => s.isNotEmpty).join('\n\n');
              if (text.isEmpty) {
                _toast(context, 'notes.editor.shareEmpty'.tr());
              } else {
                Share.share(text);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(
      IconData icon, String label, AppColors c, VoidCallback onTap) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: c.border.withOpacity(0.8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: c.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Alt kaydet çubuğu ----------
  Widget _bottomBar(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () =>
                  isEditing ? vm.updateNote(context) : vm.createNote(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accentDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'notes.editor.update'.tr() : 'notes.editor.saveNote'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    // Dil-nötr sayısal tarih (her dilde doğru görünür).
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$dd.$mo.${now.year} · $hh:$mm';
  }
}

/// Not editöründe kullanılan kompakt renk noktası.
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final Color ringColor;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.ringColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? ringColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

// DEVAM EDECEK - Part 3'te EditNoteBottomSheet, AddDiary ve EditDiary ekleyeceğim

// DEVAM EDECEK - Part 3'te EditNoteBottomSheet, AddDiary ve EditDiary ekleyeceğim

// ==================== NOT DÜZENLEME BOTTOM SHEET ====================

class _EditNoteBottomSheet extends StatefulWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;
  final Note note;

  const _EditNoteBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    required this.note,
  });

  @override
  State<_EditNoteBottomSheet> createState() => _EditNoteBottomSheetState();
}

class _EditNoteBottomSheetState extends State<_EditNoteBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.setNoteForEdit(widget.note);
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'notes.editNote'.tr(),
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Renk Seçici
                        _ColorPicker(
                          selectedColor: vm.selectedNoteColor,
                          onColorSelected: (color) => vm.setSelectedNoteColor(color),
                          isDarkMode: widget.isDarkMode,
                        ),
                        const SizedBox(height: 24),

                        // Category Selection
                        if (vm.categories.isNotEmpty) ...[
                          Text(
                            'notes.category'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: vm.categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isSelected = vm.selectedCategoryForNote == null;
                                  return GestureDetector(
                                    onTap: () => vm.setSelectedCategoryForNote(null),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFB794F6).withOpacity(0.2)
                                            : (widget.isDarkMode
                                            ? ColorConstant.bgColorDark
                                            : ColorConstant.bgColorLight),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFB794F6)
                                              : (widget.isDarkMode
                                              ? ColorConstant.borderColorDark
                                              : ColorConstant.borderColorLight),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '📝',
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'notes.general'.tr(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFFB794F6)
                                                  : (widget.isDarkMode
                                                  ? ColorConstant.textSecondaryDark
                                                  : ColorConstant.textSecondaryLight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final category = vm.categories[index - 1];
                                final isSelected = vm.selectedCategoryForNote == category.id;
                                return GestureDetector(
                                  onTap: () => vm.setSelectedCategoryForNote(category.id),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFB794F6).withOpacity(0.2)
                                          : (widget.isDarkMode
                                          ? ColorConstant.bgColorDark
                                          : ColorConstant.bgColorLight),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFB794F6)
                                            : (widget.isDarkMode
                                            ? ColorConstant.borderColorDark
                                            : ColorConstant.borderColorLight),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        if (category.icon != null)
                                          Text(
                                            category.icon!,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        if (category.icon != null)
                                          const SizedBox(width: 8),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFB794F6)
                                                : (widget.isDarkMode
                                                ? ColorConstant.textSecondaryDark
                                                : ColorConstant.textSecondaryLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Note Title
                        TextField(
                          controller: vm.noteTitleController,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'notes.noteTitle'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Note Content
                        TextField(
                          controller: vm.noteContentController,
                          maxLines: 10,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'notes.noteContent'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetNoteForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: widget.isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.updateNote(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB794F6),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.update'.tr(),
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== GÜNLÜK EKLEME BOTTOM SHEET ====================

class _AddDiaryBottomSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _AddDiaryBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  List<Map<String, String>> get _moods => [
    {'emoji': '😊', 'label': 'common.moods.happy'.tr()},
    {'emoji': '😔', 'label': 'common.moods.sad'.tr()},
    {'emoji': '😌', 'label': 'common.moods.calm'.tr()},
    {'emoji': '😍', 'label': 'common.moods.inLove'.tr()},
    {'emoji': '😡', 'label': 'common.moods.angry'.tr()},
    {'emoji': '😴', 'label': 'common.moods.tired'.tr()},
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'diary.todayDiary'.tr(),
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mood Selection
                        Text(
                          'diary.howDoYouFeel'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _moods.length,
                            itemBuilder: (context, index) {
                              final mood = _moods[index];
                              final isSelected =
                                  vm.selectedMood == mood['emoji'];
                              return GestureDetector(
                                onTap: () => vm.setSelectedMood(mood['emoji']!),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFA07A)
                                        .withOpacity(0.2)
                                        : (isDarkMode
                                        ? ColorConstant.bgColorDark
                                        : ColorConstant.bgColorLight),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFA07A)
                                          : (isDarkMode
                                          ? ColorConstant.borderColorDark
                                          : ColorConstant.borderColorLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mood['emoji']!,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mood['label']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFFFFA07A)
                                              : (isDarkMode
                                              ? ColorConstant.textMutedDark
                                              : ColorConstant
                                              .textMutedLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Diary Title
                        TextField(
                          controller: vm.diaryTitleController,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.titleOptional'.tr(),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Diary Content
                        TextField(
                          controller: vm.diaryContentController,
                          maxLines: 10,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.hints.todayContent'.tr(),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetDiaryForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.createDiary(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA07A),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.save'.tr(),
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== GÜNLÜK DÜZENLEME BOTTOM SHEET ====================

class _EditDiaryBottomSheet extends StatefulWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;
  final Diary diary;

  const _EditDiaryBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    required this.diary,
  });

  @override
  State<_EditDiaryBottomSheet> createState() => _EditDiaryBottomSheetState();
}

class _EditDiaryBottomSheetState extends State<_EditDiaryBottomSheet> {
  List<Map<String, String>> get _moods => [
    {'emoji': '😊', 'label': 'common.moods.happy'.tr()},
    {'emoji': '😔', 'label': 'common.moods.sad'.tr()},
    {'emoji': '😌', 'label': 'common.moods.calm'.tr()},
    {'emoji': '😍', 'label': 'common.moods.inLove'.tr()},
    {'emoji': '😡', 'label': 'common.moods.angry'.tr()},
    {'emoji': '😴', 'label': 'common.moods.tired'.tr()},
  ];

  @override
  void initState() {
    super.initState();
    widget.viewModel.setDiaryForEdit(widget.diary);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'diary.editDiary'.tr(),
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mood Selection
                        Text(
                          'diary.moodQuestion'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _moods.length,
                            itemBuilder: (context, index) {
                              final mood = _moods[index];
                              final isSelected =
                                  vm.selectedMood == mood['emoji'];
                              return GestureDetector(
                                onTap: () => vm.setSelectedMood(mood['emoji']!),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFA07A)
                                        .withOpacity(0.2)
                                        : (widget.isDarkMode
                                        ? ColorConstant.bgColorDark
                                        : ColorConstant.bgColorLight),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFA07A)
                                          : (widget.isDarkMode
                                          ? ColorConstant.borderColorDark
                                          : ColorConstant.borderColorLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mood['emoji']!,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mood['label']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFFFFA07A)
                                              : (widget.isDarkMode
                                              ? ColorConstant.textMutedDark
                                              : ColorConstant
                                              .textMutedLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Diary Title
                        TextField(
                          controller: vm.diaryTitleController,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.titleOptional'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Diary Content
                        TextField(
                          controller: vm.diaryContentController,
                          maxLines: 10,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.hints.thatDayContent'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetDiaryForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: widget.isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.updateDiary(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA07A),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.update'.tr(),
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

/// Boş durum — soluk ikon yerine SVG illüstrasyon ve kullanıcıyı ilk kaydı
/// oluşturmaya yönlendiren bir aksiyon butonu.
Widget _buildEmptyState({
  required String illustration,
  required String message,
  required String subtitle,
  required Color color,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return AppEmptyState(
    illustration: illustration,
    title: message,
    message: subtitle,
    accent: color,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
class _ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final Function(String) onColorSelected;
  final bool isDarkMode;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
    required this.isDarkMode,
  });

  // Renk paleti
  static List<Map<String, dynamic>> get noteColors => [
    {'color': '#B794F6', 'name': 'notes.colors.purple'.tr()},
    {'color': '#E4B4E8', 'name': 'notes.colors.pink'.tr()},
    {'color': '#7EC8F5', 'name': 'notes.colors.blue'.tr()},
    {'color': '#81C784', 'name': 'notes.colors.green'.tr()},
    {'color': '#FFD54F', 'name': 'notes.colors.yellow'.tr()},
    {'color': '#FFB74D', 'name': 'notes.colors.orange'.tr()},
    {'color': '#FF7676', 'name': 'notes.colors.red'.tr()},
    {'color': '#A0AEC0', 'name': 'notes.colors.gray'.tr()},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'notes.noteColor'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: noteColors.length,
            itemBuilder: (context, index) {
              final colorData = noteColors[index];
              final colorHex = colorData['color'] as String;
              final color = _getColor(colorHex);
              final isSelected = selectedColor == colorHex;

              return GestureDetector(
                onTap: () => onColorSelected(colorHex),
                child: Container(
                  width: 56,
                  margin: EdgeInsets.only(
                    right: index < noteColors.length - 1 ? 12 : 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 52 : 48,
                        height: isSelected ? 52 : 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              color.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : (isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight),
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        colorData['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? color
                              : (isDarkMode
                              ? ColorConstant.textMutedDark
                              : ColorConstant.textMutedLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (e) {
      return ColorConstant.primaryPurple;
    }
  }
}

/// Sticky-note kartının sağ alt köşesindeki katlanma (dog-ear) efekti.
/// İki üçgen çizer: köşeyi "kesen" arka plan üçgeni + katın alt yüzü.
class _NoteFoldPainter extends CustomPainter {
  final Color fillColor;
  final Color foldColor;

  _NoteFoldPainter({required this.fillColor, required this.foldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Katın alt yüzü (biraz koyu) — köşeden içeri kıvrılan üçgen.
    final fold = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(
      fold,
      Paint()
        ..color = foldColor
        ..style = PaintingStyle.fill,
    );

    // İnce gölge çizgisi — kıvrımın kenarı.
    canvas.drawLine(
      Offset(0, h),
      Offset(w, 0),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _NoteFoldPainter old) =>
      old.fillColor != fillColor || old.foldColor != foldColor;
}

/// Not kartındaki içerik önizlemesi.
/// İçeriği satırlara ayırır: `☐ `/`☑ ` → işaretlenebilir kutu, `• ` → madde
/// işareti, diğerleri → düz metin. Böylece yapılacaklar listeleri kartta
/// tıklanıp işaretlenebilir görünür (Stitch "Bakkaliye" notu gibi).
class _NoteContentPreview extends StatelessWidget {
  final String content;
  final Color ink;
  final int maxLines;
  final ValueChanged<int> onToggle;

  const _NoteContentPreview({
    required this.content,
    required this.ink,
    required this.maxLines,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final allLines = content.split('\n');
    final rows = <Widget>[];
    for (var i = 0; i < allLines.length && rows.length < maxLines; i++) {
      final line = allLines[i];
      if (line.trim().isEmpty) continue;
      final lineIndex = i;

      if (line.startsWith('☐ ') || line.startsWith('☑ ')) {
        final checked = line.startsWith('☑ ');
        final text = line.substring(2);
        rows.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(lineIndex),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: ink.withOpacity(checked ? 0.85 : 0.55),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: ink.withOpacity(checked ? 0.5 : 0.8),
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (line.startsWith('• ')) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6, left: 2),
                  child: Icon(Icons.circle, size: 5, color: ink.withOpacity(0.6)),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: ink.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: ink.withOpacity(0.72),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

// ==================== STICKY-NOTE RENK YARDIMCILARI (top-level) ====================
// Not ve günlük kartları tarafından paylaşılır.

/// Kartın düz dolgu rengi. Açık temada renk canlı, koyu temada koyulaştırılır.
Color _stickyFill(Color base, bool isDark) {
  if (!isDark) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
      .toColor();
}

/// Katlanmış köşenin alt yüzü — dolgunun biraz koyu tonu.
Color _stickyFold(Color base, bool isDark) {
  final fill = _stickyFill(base, isDark);
  final hsl = HSLColor.fromColor(fill);
  return hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
}

/// Renkli zemin üzerindeki metin rengi (koyu / açık mürekkep, kontrasta göre).
Color _stickyInk(Color base, bool isDark) {
  final fill = _stickyFill(base, isDark);
  return fill.computeLuminance() > 0.5
      ? const Color(0xFF2A2620)
      : Colors.white.withOpacity(0.95);
}

// ==================== ÇİZİM TUVALİ ====================
/// Saf Flutter çizim tuvali. Çizimi PNG'ye dönüştürüp File olarak döndürür.
class _DrawingPadPage extends StatefulWidget {
  const _DrawingPadPage();

  @override
  State<_DrawingPadPage> createState() => _DrawingPadPageState();
}

class _DrawingPadPageState extends State<_DrawingPadPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFF2A2620);
  double _width = 4;
  bool _saving = false;

  static const List<Color> _palette = [
    Color(0xFF2A2620),
    Color(0xFFF6A821),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
  ];

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        setState(() => _saving = false);
        return;
      }
      final dir = Directory.systemTemp;
      final file = File(
          '${dir.path}/cizim_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2A2620)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('notes.editor.draw'.tr(),
            style: const TextStyle(
                color: Color(0xFF2A2620), fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFF2A2620)),
            onPressed: () => setState(() => _strokes.clear()),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('common.save'.tr(),
                style: const TextStyle(
                    color: Color(0xFFEE8B00),
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      onPanStart: (d) {
                        setState(() {
                          _strokes.add(_Stroke(
                              color: _color,
                              width: _width,
                              points: [d.localPosition]));
                        });
                      },
                      onPanUpdate: (d) {
                        setState(() {
                          _strokes.last.points.add(d.localPosition);
                        });
                      },
                      child: CustomPaint(
                        painter: _DrawPainter(_strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Renk + kalınlık çubuğu
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  for (final col in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = col),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == col
                                ? const Color(0xFFEE8B00)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.brush_rounded, size: 18),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: _width,
                      min: 2,
                      max: 16,
                      activeColor: const Color(0xFFF6A821),
                      onChanged: (v) => setState(() => _width = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke({required this.color, required this.width, required this.points});
}

class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], paint);
      }
      if (s.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawPainter old) => true;
}

// ==================== SES NOTU CALAR ====================
/// Kaydedilmiş ses notunu çalan/duraklatan kompakt bileşen.
class _VoiceNoteChip extends StatefulWidget {
  final String path;
  final VoidCallback onRemove;
  const _VoiceNoteChip({required this.path, required this.onRemove});

  @override
  State<_VoiceNoteChip> createState() => _VoiceNoteChipState();
}

class _VoiceNoteChipState extends State<_VoiceNoteChip> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(DeviceFileSource(widget.path));
      setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF6A821);
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: accent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(28, (i) {
                final h = 5.0 + ((i * 13) % 18);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.4),
                  child: Container(
                    width: 2.6,
                    height: h,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text('notes.editor.voiceNote'.tr(),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
