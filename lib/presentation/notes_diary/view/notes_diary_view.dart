import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
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
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              child: Column(
                children: [
                  // Header with Toggle
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Actions
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isNotesView ? 'notes.title'.tr() : 'diary.title'.tr(),
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
                            // Premium Button
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColorConstant.accentYellow,
                                    ColorConstant.accentOrange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstant.accentYellow.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => context.router.push(const PaywallRoute()),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.workspace_premium_rounded,
                                      color: ColorConstant.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_isNotesView)
                              IconButton(
                                onPressed: () => viewModel.toggleViewMode(),
                                icon: Icon(
                                  viewModel.notesViewMode == NotesViewMode.grid
                                      ? Icons.view_list_rounded
                                      : Icons.grid_view_rounded,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                                tooltip: viewModel.notesViewMode == NotesViewMode.grid
                                    ? 'notes.listView'.tr()
                                    : 'notes.cardView'.tr(),
                              ),
                            // Filter/Options button
                            if (_isNotesView)
                              IconButton(
                                onPressed: () => _showNotesFilter(context, viewModel, isDarkMode),
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                              ),
                            if (!_isNotesView)
                              IconButton(
                                onPressed: () => _showDiaryCalendar(context, viewModel, isDarkMode),
                                icon: Icon(
                                  Icons.calendar_today_rounded,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Modern Toggle Switch
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isNotesView = true);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: _isNotesView
                                        ? LinearGradient(
                                      colors: [
                                        const Color(0xFFB794F6),
                                        const Color(0xFF9B6FE8),
                                      ],
                                    )
                                        : null,
                                    color: _isNotesView
                                        ? null
                                        : (isDarkMode
                                        ? ColorConstant.cardColorDark
                                        : ColorConstant.bgColorLight),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: _isNotesView
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFFB794F6)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.note_rounded,
                                        color: _isNotesView
                                            ? ColorConstant.white
                                            : (isDarkMode
                                            ? ColorConstant.textSecondaryDark
                                            : ColorConstant.textSecondaryLight),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'notes.notes'.tr(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _isNotesView
                                              ? ColorConstant.white
                                              : (isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant.textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isNotesView = false);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: !_isNotesView
                                        ? LinearGradient(
                                      colors: [
                                        const Color(0xFFFFA07A),
                                        const Color(0xFFFF8A5C),
                                      ],
                                    )
                                        : null,
                                    color: !_isNotesView
                                        ? null
                                        : (isDarkMode
                                        ? ColorConstant.cardColorDark
                                        : ColorConstant.bgColorLight),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: !_isNotesView
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFFFFA07A)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book_rounded,
                                        color: !_isNotesView
                                            ? ColorConstant.white
                                            : (isDarkMode
                                            ? ColorConstant.textSecondaryDark
                                            : ColorConstant.textSecondaryLight),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'diary.title'.tr(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: !_isNotesView
                                              ? ColorConstant.white
                                              : (isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant.textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content with Animation
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isNotesView
                          ? _NotesContent(
                        key: const ValueKey('notes'),
                        viewModel: viewModel,
                      )
                          : _DiaryContent(
                        key: const ValueKey('diary'),
                        viewModel: viewModel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'notes_diary_fab',
              onPressed: () {
                if (_isNotesView) {
                  _showAddNoteDialog(context, viewModel, isDarkMode);
                } else {
                  _showAddDiaryDialog(context, viewModel, isDarkMode);
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isNotesView
                        ? [
                      const Color(0xFFB794F6),
                      const Color(0xFF9B6FE8),
                    ]
                        : [
                      const Color(0xFFFFA07A),
                      const Color(0xFFFF8A5C),
                    ],
                  ),
                  shape: BoxShape.circle,  // ← Yuvarlak yapar
                  boxShadow: [
                    BoxShadow(
                      color: (_isNotesView
                          ? const Color(0xFFB794F6)
                          : const Color(0xFFFFA07A))
                          .withOpacity(0.4),
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
      ) {
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

  void _showAddDiaryDialog(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
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
        child: CircularProgressIndicator(
          color: const Color(0xFFB794F6),
        ),
      );
    }

    final filteredNotes = viewModel.getFilteredNotes();

    return RefreshIndicator(
      onRefresh: () => viewModel.loadNotes(),
      color: const Color(0xFFB794F6),
      child: filteredNotes.isNotEmpty
          ? (viewModel.notesViewMode == NotesViewMode.grid
          ? _buildGridView(context, filteredNotes, isDarkMode)
          : _buildListView(context, filteredNotes, isDarkMode))
          : _buildEmptyState(
        icon: Icons.note_add_rounded,
        message: 'notes.emptyState'.tr(),
        color: const Color(0xFFB794F6),
        isDarkMode: isDarkMode,
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Note> notes, bool isDarkMode) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
      orElse: () => NoteCategory(
        id: 0,
        name: '',
        notesCount: 0,
        orderIndex: 0,
      ),
    )
        : null;

    final noteColor = _getNoteColor(note.color ?? '#B794F6');

    return GestureDetector(
      onTap: () {
        if (note.isLocked) {
          _showUnlockDialog(context, note, viewModel, isDarkMode);
        } else {
          _showEditNoteDialog(context, note, viewModel, isDarkMode);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              noteColor.withOpacity(0.25),
              noteColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: noteColor.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: noteColor.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dekoratif top-right circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: noteColor.withOpacity(0.1),
                ),
              ),
            ),

            // Ana içerik
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst bar: Kategori emoji (sol üst) + Menu (sağ üst)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kategori emoji - sadece emoji
                      if (category != null &&
                          category.icon != null &&
                          category.icon!.isNotEmpty)
                        Text(
                          category.icon!,
                          style: const TextStyle(fontSize: 20),
                        )
                      else
                        const SizedBox(width: 20),

                      // Menu button
                      // Menu button
                      PopupMenuButton(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: noteColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: noteColor.withOpacity(0.9),
                          ),
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
                                Text(note.isPinned
                                    ? 'notes.unpinNote'.tr()
                                    : 'notes.pinNote'.tr()),
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
                                Text(note.isLocked
                                    ? 'notes.unlockNote'.tr()
                                    : 'notes.lockNote'.tr()),
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
                                Text(note.isArchived
                                    ? 'notes.unarchiveNote'.tr()
                                    : 'notes.archiveNote'.tr()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () => _showDeleteNoteDialog(
                                    context, note.id, viewModel),
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
                  const SizedBox(height: 14),

                  // Başlık
                  Text(
                    note.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // İçerik (blurred if locked)
                  Expanded(
                    child: note.isLocked
                        ? Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: noteColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 28,
                              color: noteColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'notes.lockedNoteDialog'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: noteColor,
                            ),
                          ),
                        ],
                      ),
                    )
                        : Text(
                      note.content ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lock indicator corner (if locked)
            if (note.isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        noteColor,
                        noteColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: noteColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditNoteBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
        note: note,
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
        icon: Icons.menu_book_rounded,
        message: 'diary.emptyState'.tr(),
        color: const Color(0xFFFFA07A),
        isDarkMode: isDarkMode,
      ),
    );
  }

  Widget _buildDiaryCard(
      BuildContext context,
      Diary entry,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? ColorConstant.borderColorDark
              : ColorConstant.borderColorLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showDiaryDetail(context, viewModel, entry, isDarkMode);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Date and Mood
                Row(
                  children: [
                    // Date Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFA07A),
                            const Color(0xFFFF8A5C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatDiaryDate(entry.diaryDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorConstant.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Mood
                    if (entry.moodIcon != null)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA07A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            entry.moodIcon!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                if (entry.title != null && entry.title!.isNotEmpty) ...[
                  Text(
                    entry.title!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Content Preview
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),

                // Weather & Images
                if (entry.weather != null ||
                    (entry.imageUrls?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (entry.weather != null) ...[
                        Icon(
                          _getWeatherIcon(entry.weather!),
                          size: 16,
                          color: isDarkMode
                              ? ColorConstant.textMutedDark
                              : ColorConstant.textMutedLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getWeatherLabel(entry.weather!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight,
                          ),
                        ),
                      ],
                      if (entry.imageUrls?.isNotEmpty ?? false) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.image_rounded,
                          size: 16,
                          color: isDarkMode
                              ? ColorConstant.textMutedDark
                              : ColorConstant.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.imageUrls!.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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

// ==================== NOT EKLEME BOTTOM SHEET ====================
class _AddNoteBottomSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _AddNoteBottomSheet({
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
                          'notes.newNote'.tr(),
                          style: TextStyle(
                            color: isDarkMode
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
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),

                        // Category Selection
                        if (vm.categories.isNotEmpty) ...[
                          Text(
                            'notes.category'.tr(),
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
                                                  : (isDarkMode
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
                                                : (isDarkMode
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
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'notes.noteTitle'.tr(),
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

                        // Note Content
                        TextField(
                          controller: vm.noteContentController,
                          maxLines: 10,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'notes.noteContent'.tr(),
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
                                  vm.resetNoteForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                onPressed: () => vm.createNote(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB794F6),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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

Widget _buildEmptyState({
  required IconData icon,
  required String message,
  required Color color,
  required bool isDarkMode,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: color.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
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
    ),
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
          'Not Rengi',
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
