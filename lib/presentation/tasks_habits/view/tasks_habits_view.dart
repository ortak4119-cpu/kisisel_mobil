import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/route/app_router.gr.dart';
import '../viewmodel/tasks_habits_viewmodel.dart';

class TasksHabitsView extends StatefulWidget {
  const TasksHabitsView({super.key});

  @override
  State<TasksHabitsView> createState() => _TasksHabitsViewState();
}

class _TasksHabitsViewState extends State<TasksHabitsView> {
  int _tab = 0; // 0 = Görevler, 1 = Alışkanlıklar

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TasksHabitsViewModel()..refreshAll(),
      child: Consumer<TasksHabitsViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: AppSegmentedControl(
                      selectedIndex: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                      accent: ColorConstant.accentOrange,
                      segments: [
                        AppSegment(
                            label: 'tasks.title'.tr(),
                            icon: Icons.checklist_rounded),
                        AppSegment(
                            label: 'habits.title'.tr(),
                            icon: Icons.emoji_events_rounded),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tab == 0
                        ? _TasksTab(viewModel: viewModel)
                        : _HabitsTab(viewModel: viewModel),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'th_fab',
              onPressed: () => _tab == 0
                  ? showAddTaskSheet(context, viewModel, isDarkMode)
                  : showAddHabitSheet(context, viewModel, isDarkMode),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorConstant.accentYellow,
                      ColorConstant.accentOrange,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstant.accentOrange.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Görev ekleme sayfasını açar.
/// Üst seviyede tutuluyor ki hem FAB hem de boş durum butonu aynı yeri açsın.
void showAddTaskSheet(
    BuildContext context, TasksHabitsViewModel viewModel, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddTaskBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
    ),
  );
}

/// Alışkanlık ekleme sayfasını açar.
void showAddHabitSheet(
    BuildContext context, TasksHabitsViewModel viewModel, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddHabitBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
    ),
  );
}

// ==================== ALIŞKANLIK İKON & RENK SETİ ====================

class _HabitIcon {
  final String key;
  final IconData icon;
  const _HabitIcon(this.key, this.icon);
}

const List<_HabitIcon> kHabitIcons = [
  _HabitIcon('star', Icons.star_rounded),
  _HabitIcon('water', Icons.water_drop_rounded),
  _HabitIcon('book', Icons.menu_book_rounded),
  _HabitIcon('walk', Icons.directions_walk_rounded),
  _HabitIcon('heart', Icons.favorite_rounded),
  _HabitIcon('meditation', Icons.self_improvement_rounded),
];

IconData habitIconData(String? key) {
  for (final h in kHabitIcons) {
    if (h.key == key) return h.icon;
  }
  return Icons.star_rounded;
}

const List<String> kHabitColors = [
  '#F6C23E',
  '#F6853A',
  '#4C9AFF',
  '#9F7AEA',
  '#48BB78',
];

/// Alışkanlık düzenleme sayfasını açar.
void showEditHabitSheet(BuildContext context, TasksHabitsViewModel viewModel,
    bool isDarkMode, Habit habit) {
  viewModel.prepareEditHabit(habit);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddHabitBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
      isEditing: true,
    ),
  );
}

// ==================== ALIŞKANLIKLAR TAB ====================

class _HabitsTab extends StatelessWidget {
  final TasksHabitsViewModel viewModel;
  const _HabitsTab({super.key, required this.viewModel});

  static const _orange = Color(0xFFF6A821);
  static const _red = Color(0xFFF6524B);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);

    if (viewModel.isLoading && viewModel.habits.isEmpty) {
      return Center(child: CircularProgressIndicator(color: _orange));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadHabits(),
      color: _orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        children: [
          _weekStrip(c),
          const SizedBox(height: 16),
          _progressCard(c),
          const SizedBox(height: 22),
          _sectionRow(context, c),
          const SizedBox(height: 12),
          if (viewModel.habits.isEmpty)
            _empty(context, c)
          else
            ...viewModel.habits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _habitCard(context, c, h),
                )),
        ],
      ),
    );
  }

  // ---------- Hafta şeridi ----------
  Widget _weekStrip(AppColors c) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final shorts = 'tasks.weekShort'.tr().split(',');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = DateTime(monday.year, monday.month, monday.day + i);
          final sel = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          return Column(
            children: [
              Text(i < shorts.length ? shorts[i] : '',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : c.textMuted)),
              const SizedBox(height: 6),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? _orange : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: _orange.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
                child: Text('${day.day}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : c.textPrimary)),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------- İlerleme kartı ----------
  Widget _progressCard(AppColors c) {
    final done = viewModel.habitTodayDone;
    final total = viewModel.habitTodayTotal;
    final p = viewModel.habitDayProgress;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('tasks.progressTitle'.tr(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: p,
                        strokeWidth: 8,
                        backgroundColor: c.border.withOpacity(0.4),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_orange),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$done/$total',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: c.textPrimary)),
                        Text('common.completed'.tr(),
                            style: TextStyle(
                                fontSize: 11, color: c.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _miniStat(c, Icons.local_fire_department_rounded, _red,
                        '${viewModel.habitBestStreak}',
                        'habits.stats.streak'.tr()),
                    const SizedBox(height: 12),
                    _miniStat(c, Icons.percent_rounded, _orange,
                        '%${viewModel.habitDayPercent}',
                        'tasks.rowDailyGoal'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      AppColors c, IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Bölüm başlığı ----------
  Widget _sectionRow(BuildContext context, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: Text('habits.todaySection'.tr(),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
        ),
      ],
    );
  }

  // ---------- Alışkanlık kartı ----------
  Widget _habitCard(BuildContext context, AppColors c, Habit h) {
    final color = viewModel.getHabitColor(h.color);
    final goal = viewModel.habitGoalOf(h);
    final cur = viewModel.habitProgressOf(h);
    final done = viewModel.isHabitDoneToday(h);
    final p = goal == 0 ? 0.0 : (cur / goal).clamp(0.0, 1.0);

    return GestureDetector(
      onLongPress: () => _habitMenu(context, c, h),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: done
                  ? const Color(0xFF48BB78).withOpacity(0.6)
                  : color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF48BB78) : color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                  done ? Icons.check_rounded : habitIconData(h.icon),
                  color: Colors.white,
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: done ? c.textMuted : c.textPrimary,
                          decoration:
                              done ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  if (done)
                    Text('habits.doneToday'.tr(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF48BB78)))
                  else ...[
                    Text('$cur / $goal',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.toDouble(),
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => viewModel.tapHabit(h, context),
              child: done
                  ? const Icon(Icons.check_circle_rounded,
                      size: 30, color: Color(0xFF48BB78))
                  : Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _habitMenu(BuildContext context, AppColors c, Habit h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: _orange),
              title: Text('common.edit'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showEditHabitSheet(context, viewModel, c.isDark, h);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE53E3E)),
              title: Text('common.delete'.tr(),
                  style: const TextStyle(color: Color(0xFFE53E3E))),
              onTap: () {
                Navigator.pop(ctx);
                viewModel.deleteHabit(h.id, context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 42, color: _orange.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('habits.emptyState'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('habits.emptyStateSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ==================== KATEGORİLER ====================

class _TaskCat {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;
  const _TaskCat(this.id, this.labelKey, this.icon, this.color);
}

const List<_TaskCat> kTaskCats = [
  _TaskCat('work', 'tasks.cat.work', Icons.work_rounded, Color(0xFF9F7AEA)),
  _TaskCat('personal', 'tasks.cat.personal', Icons.person_rounded,
      Color(0xFF4C9AFF)),
  _TaskCat('finance', 'tasks.cat.finance', Icons.attach_money_rounded,
      Color(0xFF48BB78)),
  _TaskCat('health', 'tasks.cat.health', Icons.favorite_rounded,
      Color(0xFFF6524B)),
  _TaskCat('shopping', 'tasks.cat.shopping', Icons.shopping_cart_rounded,
      Color(0xFFF6A821)),
  _TaskCat('other', 'tasks.cat.other', Icons.category_rounded,
      Color(0xFF9AA0A6)),
];

_TaskCat? catById(String? id) {
  if (id == null) return null;
  for (final c in kTaskCats) {
    if (c.id == id) return c;
  }
  return null;
}

/// Görev düzenleme sayfasını açar (aynı sayfa, düzenleme modunda).
void showEditTaskSheet(BuildContext context, TasksHabitsViewModel viewModel,
    bool isDarkMode, Task task) {
  viewModel.prepareEditTask(task);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddTaskBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
      isEditing: true,
    ),
  );
}

// ==================== GÖREVLER TAB ====================

class _TasksTab extends StatelessWidget {
  final TasksHabitsViewModel viewModel;
  const _TasksTab({super.key, required this.viewModel});

  static const _orange = Color(0xFFF6A821);
  static const _purple = Color(0xFF9F7AEA);
  static const _red = Color(0xFFF6524B);
  static const _green = Color(0xFF48BB78);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);

    if (viewModel.isLoading && viewModel.tasks.isEmpty) {
      return Center(child: CircularProgressIndicator(color: _orange));
    }

    final searching = viewModel.taskSearch.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      color: _orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        children: [
          _searchBar(context, c),
          const SizedBox(height: 16),
          _statCards(context, c),
          const SizedBox(height: 18),
          if (searching)
            ..._searchBody(context, c)
          else
            ..._dayBody(context, c),
        ],
      ),
    );
  }

  // ---------- Arama ----------
  Widget _searchBar(BuildContext context, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: viewModel.setTaskSearch,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'tasks.searchHint'.tr(),
                hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- İstatistik kartları ----------
  Widget _statCards(BuildContext context, AppColors c) {
    final f = viewModel.taskStatFilter;
    return Row(
      children: [
        _statCard(c, Icons.today_rounded, 'tasks.statsToday'.tr(),
            viewModel.todayTaskCount, _orange,
            filled: f == 'today',
            onTap: () => viewModel.setTaskStatFilter('today')),
        const SizedBox(width: 10),
        _statCard(c, Icons.event_rounded, 'tasks.statsUpcoming'.tr(),
            viewModel.upcomingTaskCount, _purple,
            filled: f == 'upcoming',
            onTap: () => viewModel.setTaskStatFilter('upcoming')),
        const SizedBox(width: 10),
        _statCard(c, Icons.schedule_rounded, 'tasks.stats.overdue'.tr(),
            viewModel.overdueTaskCount, _red,
            filled: f == 'overdue',
            onTap: () => viewModel.setTaskStatFilter('overdue')),
        const SizedBox(width: 10),
        _statCard(c, Icons.check_circle_rounded, 'tasks.stats.completed'.tr(),
            viewModel.completedTaskCount, _green,
            filled: f == 'completed',
            onTap: () => viewModel.setTaskStatFilter('completed')),
      ],
    );
  }

  Widget _statCard(AppColors c, IconData icon, String label, int count,
      Color color,
      {bool filled = false, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? color : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: filled ? color : c.border.withOpacity(0.7)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: filled ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : c.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : c.textPrimary,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ---------- Gün gövdesi ----------
  List<Widget> _dayBody(BuildContext context, AppColors c) {
    final filter = viewModel.taskStatFilter;
    if (filter != 'today') {
      final list = filter == 'upcoming'
          ? viewModel.upcomingTasksList
          : filter == 'overdue'
              ? viewModel.overdueTasksList
              : viewModel.completedTasksList;
      final titleKey = filter == 'upcoming'
          ? 'tasks.statsUpcoming'
          : filter == 'overdue'
              ? 'tasks.stats.overdue'
              : 'tasks.stats.completed';
      return [
        Text(titleKey.tr(),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary)),
        const SizedBox(height: 12),
        if (list.isEmpty)
          _emptyDay(context, c)
        else
          ...list.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _taskCard(context, c, t),
              )),
      ];
    }
    final list = viewModel.sortedTasksForSelectedDay;
    final later = viewModel.laterTasks;
    return [
      _weekSelector(context, c),
      const SizedBox(height: 16),
      _progressCard(context, c),
      const SizedBox(height: 22),
      _sectionRow(context, c),
      const SizedBox(height: 12),
      if (list.isEmpty)
        _emptyDay(context, c)
      else
        ...list.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _taskCard(context, c, t),
            )),
      if (later.isNotEmpty) ...[
        const SizedBox(height: 6),
        _laterRow(context, c, later.length),
      ],
    ];
  }

  List<Widget> _searchBody(BuildContext context, AppColors c) {
    final res = viewModel.searchResults;
    return [
      if (res.isEmpty)
        _emptyDay(context, c)
      else
        ...res.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _taskCard(context, c, t),
            )),
    ];
  }

  // ---------- Hafta seçici ----------
  Widget _weekSelector(BuildContext context, AppColors c) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final shorts = 'tasks.weekShort'.tr().split(',');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        final selected = viewModel.isSameDay(day, viewModel.selectedDay);
        final hasTasks = viewModel.parentTasks.any((t) {
          final d = viewModel.dueDateOf(t);
          return d != null && viewModel.isSameDay(d, day);
        });
        return GestureDetector(
          onTap: () => viewModel.setSelectedDay(day),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Text(
                i < shorts.length ? shorts[i] : '',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasTasks && !selected
                      ? _orange
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ---------- İlerleme kartı ----------
  Widget _progressCard(BuildContext context, AppColors c) {
    final p = viewModel.dayProgress;
    final pct = (p * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('tasks.progressTitle'.tr(),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 8,
                          backgroundColor: _orange.withOpacity(0.15),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${viewModel.dayDoneCount}/${viewModel.dayTotalCount}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'tasks.progressDone'.tr(namedArgs: {'p': '$pct'}),
                  style: TextStyle(fontSize: 12.5, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: p,
                    strokeWidth: 7,
                    backgroundColor: _orange.withOpacity(0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_orange),
                  ),
                ),
                Text('%$pct',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bölüm başlığı + sıralama ----------
  Widget _sectionRow(BuildContext context, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'tasks.todaySection'.tr(),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary),
          ),
        ),
        Material(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showSortSheet(context, c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border.withOpacity(0.7)),
              ),
              child: Row(
                children: [
                  Text(_sortLabel(),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _sortLabel() {
    switch (viewModel.taskSort) {
      case 'time':
        return 'tasks.sortTime'.tr();
      case 'created':
        return 'tasks.sortCreated'.tr();
      default:
        return 'tasks.sortPriority'.tr();
    }
  }

  void _showSortSheet(BuildContext context, AppColors c) {
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
            for (final o in [
              ['priority', 'tasks.sortPriority'],
              ['time', 'tasks.sortTime'],
              ['created', 'tasks.sortCreated'],
            ])
              ListTile(
                title: Text(o[1].tr(),
                    style: TextStyle(color: c.textPrimary)),
                trailing: viewModel.taskSort == o[0]
                    ? const Icon(Icons.check_rounded, color: _orange)
                    : null,
                onTap: () {
                  viewModel.setTaskSort(o[0]);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Görev kartı ----------
  Widget _taskCard(BuildContext context, AppColors c, Task task) {
    final done = task.isCompleted;
    final subs = viewModel.subtasksOf(task.id);
    final subDone = subs.where((s) => s.isCompleted).length;
    final meta = viewModel.metaForTask(task.id);
    final cat = catById(meta.category);
    final overdue = _overdueLabel(task);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showEditTaskSheet(
              context, viewModel, c.isDark, task),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          viewModel.toggleTaskComplete(task, context),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, right: 12),
                        child: done
                            ? const Icon(Icons.check_circle_rounded,
                                size: 26, color: _green)
                            : Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: c.border, width: 2),
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: done ? c.textMuted : c.textPrimary,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: c.textMuted,
                            ),
                          ),
                          if (done && task.completedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'tasks.completedAtLabel'.tr(namedArgs: {
                                'time': _hhmm(task.completedAt!)
                              }),
                              style: TextStyle(
                                  fontSize: 12.5, color: c.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _cardMenu(context, c, task),
                  ],
                ),
                if (!done) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _priorityBadge(task.priority),
                      if (overdue != null)
                        _chip(Icons.schedule_rounded, overdue, _red,
                            _red.withOpacity(0.12))
                      else if (_timeLabel(task) != null)
                        _chip(Icons.schedule_rounded, _timeLabel(task)!,
                            _orange, _orange.withOpacity(0.12)),
                      if (cat != null)
                        _chip(cat.icon, cat.labelKey.tr(), cat.color,
                            cat.color.withOpacity(0.12)),
                      if (task.isRecurring)
                        _chip(Icons.repeat_rounded,
                            _recLabel(task.recurringPattern), _purple,
                            _purple.withOpacity(0.12)),
                    ],
                  ),
                ],
                if (subs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'tasks.subtaskProgress'.tr(namedArgs: {
                          'done': '$subDone',
                          'total': '${subs.length}'
                        }),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subs.isEmpty ? 0 : subDone / subs.length,
                            minHeight: 6,
                            backgroundColor: _orange.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (meta.attachments.isNotEmpty ||
                    meta.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (meta.attachments.isNotEmpty) ...[
                        Icon(Icons.attach_file_rounded,
                            size: 15, color: c.textMuted),
                        const SizedBox(width: 3),
                        Text('${meta.attachments.length}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: c.textMuted)),
                        const SizedBox(width: 12),
                      ],
                      if (meta.tags.isNotEmpty)
                        Expanded(
                          child: Text(
                            meta.tags.map((t) => '#$t').join('  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _purple),
                          ),
                        ),
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

  Widget _cardMenu(BuildContext context, AppColors c, Task task) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, size: 20, color: c.textMuted),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) {
        if (v == 'edit') {
          showEditTaskSheet(context, viewModel, c.isDark, task);
        } else if (v == 'delete') {
          _confirmDelete(context, c, task);
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

  void _confirmDelete(BuildContext context, AppColors c, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('tasks.deleteTask'.tr()),
        content: Text('tasks.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.deleteTask(task.id, context);
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFE53E3E))),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(int priority) {
    late Color color;
    late String label;
    late IconData icon;
    switch (priority) {
      case 2:
        color = _red;
        label = 'tasks.priority.high'.tr();
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 0:
        color = _green;
        label = 'tasks.priority.low'.tr();
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      default:
        color = _orange;
        label = 'tasks.priority.medium'.tr();
        icon = Icons.drag_handle_rounded;
    }
    return _chip(icon, label, color, color.withOpacity(0.12));
  }

  Widget _chip(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _emptyDay(BuildContext context, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded,
              size: 40, color: _orange.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('tasks.emptyDay'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('tasks.emptyDaySub'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _laterRow(BuildContext context, AppColors c, int count) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLaterSheet(context, c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 20, color: _orange),
              const SizedBox(width: 12),
              Text('tasks.later'.tr(),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(width: 6),
              Text('· ${'tasks.laterCount'.tr(namedArgs: {
                    'n': '$count'
                  })}',
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showLaterSheet(BuildContext context, AppColors c) {
    final later = viewModel.laterTasks;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('tasks.later'.tr(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: later
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _taskCard(context, c, t),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Yardımcılar ----------
  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _recLabel(String? pattern) {
    switch (pattern) {
      case 'daily':
        return 'tasks.recurrence.daily'.tr();
      case 'weekly':
        return 'tasks.recurrence.weekly'.tr();
      case 'monthly':
        return 'tasks.recurrence.monthly'.tr();
      default:
        return 'tasks.recurrence.daily'.tr();
    }
  }

  String? _timeLabel(Task task) {
    final d = viewModel.dueDateOf(task);
    if (d == null && task.dueTime == null) return null;
    final now = DateTime.now();
    final isToday = d != null && viewModel.isSameDay(d, now);
    final time = task.dueTime != null && task.dueTime!.length >= 5
        ? task.dueTime!.substring(0, 5)
        : null;
    if (isToday) {
      return time != null
          ? '${'common.today'.tr()}, $time'
          : 'common.today'.tr();
    }
    if (d != null) {
      final ds = '${d.day}.${d.month}';
      return time != null ? '$ds, $time' : ds;
    }
    return time;
  }

  String? _overdueLabel(Task task) {
    if (task.isCompleted) return null;
    final d = viewModel.dueDateOf(task);
    if (d == null) return task.isOverdue ? 'tasks.overdue'.tr() : null;
    var due = d;
    if (task.dueTime != null) {
      try {
        final p = task.dueTime!.split(':');
        due = DateTime(d.year, d.month, d.day, int.parse(p[0]),
            int.parse(p[1]));
      } catch (_) {
        due = DateTime(d.year, d.month, d.day, 23, 59);
      }
    } else {
      due = DateTime(d.year, d.month, d.day, 23, 59);
    }
    final now = DateTime.now();
    if (!due.isBefore(now)) return null;
    final diff = now.difference(due);
    if (diff.inMinutes < 60) {
      return 'tasks.overdueMin'.tr(namedArgs: {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'tasks.overdueHour'.tr(namedArgs: {'n': '${diff.inHours}'});
    }
    return 'tasks.overdueDay'.tr(namedArgs: {'n': '${diff.inDays}'});
  }
}
/// Boş durum — artık emoji yerine özel SVG illüstrasyon kullanıyor ve
/// kullanıcıyı doğrudan ilk kaydı oluşturmaya yönlendiren bir buton içeriyor.
Widget _buildEmptyState({
  required String illustration,
  required String message,
  required String subtitle,
  required Color color,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: AppEmptyState(
      illustration: illustration,
      title: message,
      message: subtitle,
      accent: color,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

// ==================== GÖREV EKLEME/DÜZENLEME BOTTOM SHEET ====================

class _AddTaskBottomSheet extends StatelessWidget {
  final TasksHabitsViewModel viewModel;
  final bool isDarkMode;
  final bool isEditing;
  const _AddTaskBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    this.isEditing = false,
  });

  static const _accent = Color(0xFFF6A821);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TasksHabitsViewModel>(
        builder: (context, vm, _) {
          final c = AppColors(isDarkMode);
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.bgColorDark
                  : const Color(0xFFF6F4EF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _topBar(context, vm, c),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _titleField(vm, c),
                        const SizedBox(height: 12),
                        _descField(vm, c),
                        const SizedBox(height: 14),
                        _quickChips(context, vm, c),
                        const SizedBox(height: 16),
                        _detailCard(context, vm, c),
                        const SizedBox(height: 20),
                        _subtasksSection(context, vm, c),
                        const SizedBox(height: 20),
                        _reminderSection(context, vm, c),
                        const SizedBox(height: 20),
                        _attachSection(context, vm, c),
                        const SizedBox(height: 16),
                        _extrasChips(context, vm, c),
                      ],
                    ),
                  ),
                  _bottomBar(context, vm, c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Üst bar ----------
  Widget _topBar(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          _iconSquare(c, Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context)),
          Expanded(
            child: Text(
              isEditing ? 'tasks.editTask'.tr() : 'tasks.newTask'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary),
            ),
          ),
          _iconSquare(c, Icons.close_rounded, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _iconSquare(AppColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border.withOpacity(0.6))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: c.textSecondary),
        ),
      ),
    );
  }

  // ---------- Başlık ----------
  Widget _titleField(TasksHabitsViewModel vm, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.border, width: 2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: vm.taskTitleController,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'tasks.titleHint'.tr(),
                hintStyle: TextStyle(color: c.textMuted, fontSize: 17),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descField(TasksHabitsViewModel vm, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: TextField(
        controller: vm.taskDescriptionController,
        minLines: 2,
        maxLines: 5,
        style: TextStyle(fontSize: 15, color: c.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'tasks.descHint'.tr(),
          hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ---------- Hızlı çipler ----------
  Widget _quickChips(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    final todaySel = vm.taskDueDate != null &&
        vm.isSameDay(vm.taskDueDate!, DateTime.now());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickChip(c, Icons.today_rounded, 'common.today'.tr(),
              active: todaySel,
              onTap: () => vm.setTaskDueDate(DateTime.now())),
          const SizedBox(width: 8),
          _quickChip(c, Icons.access_time_rounded, 'tasks.quickTime'.tr(),
              active: vm.taskDueTime != null,
              onTap: () => _pickTime(context, vm)),
          const SizedBox(width: 8),
          _quickChip(c, Icons.notifications_none_rounded,
              'tasks.quickRemind'.tr(),
              active: vm.reminderEnabled,
              onTap: () => vm.setReminderEnabled(!vm.reminderEnabled)),
          const SizedBox(width: 8),
          _quickChip(c, Icons.repeat_rounded, 'tasks.quickRepeat'.tr(),
              active: vm.taskRecurrence != 'none',
              onTap: () => _showRecurrence(context, vm, c)),
        ],
      ),
    );
  }

  Widget _quickChip(AppColors c, IconData icon, String label,
      {required bool active, required VoidCallback onTap}) {
    return Material(
      color: active ? _accent.withOpacity(0.14) : c.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: active ? _accent : c.border.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: active ? _accent : c.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: active ? _accent : c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Detay kartı ----------
  Widget _detailCard(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          _row(c, Icons.calendar_month_rounded, const Color(0xFFF6A821),
              'tasks.rowDateTime'.tr(), _dateLabel(vm),
              onTap: () => _pickDate(context, vm)),
          _divider(c),
          _row(c, Icons.flag_rounded, const Color(0xFFF6524B),
              'tasks.rowPriority'.tr(), null,
              trailing: _priorityPill(vm),
              onTap: () => _showPriority(context, vm, c)),
          _divider(c),
          _row(c, Icons.folder_rounded, const Color(0xFF9F7AEA),
              'tasks.rowCategory'.tr(), null,
              trailing: _categoryPill(vm, c),
              onTap: () => _showCategory(context, vm, c)),
          _divider(c),
          _row(c, Icons.repeat_rounded, const Color(0xFFF6A821),
              'tasks.rowRecurrence'.tr(), _recLabel(vm.taskRecurrence),
              onTap: () => _showRecurrence(context, vm, c)),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Divider(
      height: 1, thickness: 1, color: c.border.withOpacity(0.5), indent: 52);

  Widget _row(AppColors c, IconData icon, Color iconColor, String label,
      String? value,
      {Widget? trailing, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
              ),
              if (trailing != null)
                trailing
              else if (value != null)
                Text(value,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityPill(TasksHabitsViewModel vm) {
    late Color color;
    late String label;
    late IconData icon;
    switch (vm.taskPriority) {
      case 2:
        color = const Color(0xFFF6524B);
        label = 'tasks.priority.high'.tr();
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 0:
        color = const Color(0xFF48BB78);
        label = 'tasks.priority.low'.tr();
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      default:
        color = const Color(0xFFF6A821);
        label = 'tasks.priority.medium'.tr();
        icon = Icons.drag_handle_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 2),
        Icon(icon, size: 15, color: color),
      ]),
    );
  }

  Widget _categoryPill(TasksHabitsViewModel vm, AppColors c) {
    final cat = catById(vm.taskCategory);
    if (cat == null) {
      return Text('tasks.selectHint'.tr(),
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: c.textMuted));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: cat.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(cat.icon, size: 15, color: cat.color),
        const SizedBox(width: 4),
        Text(cat.labelKey.tr(),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cat.color)),
      ]),
    );
  }

  // ---------- Alt görevler ----------
  Widget _subtasksSection(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    final children = (isEditing && vm.editingTaskId != null)
        ? vm.subtasksOf(vm.editingTaskId!)
        : <Task>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('tasks.subtasks'.tr(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const Spacer(),
            InkWell(
              onTap: () => _addSubtask(context, vm),
              child: Row(children: [
                const Icon(Icons.add_rounded, size: 18, color: _accent),
                const SizedBox(width: 2),
                Text('tasks.addSubtask'.tr(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _accent)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.7)),
          ),
          child: Column(
            children: [
              // Düzenleme modundaki gerçek alt görevler
              for (final s in children)
                _subRow(c,
                    title: s.title,
                    done: s.isCompleted,
                    onToggle: () => vm.toggleSubtask(s, context),
                    onRemove: () => vm.removeSubtask(s.id)),
              // Yeni görev modundaki taslaklar
              for (int i = 0; i < vm.subtaskDrafts.length; i++)
                _subRow(c,
                    title: vm.subtaskDrafts[i],
                    done: false,
                    onToggle: null,
                    onRemove: () => vm.removeSubtaskDraft(i)),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _addSubtask(context, vm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, size: 18, color: _accent),
                        const SizedBox(width: 6),
                        Text('tasks.newSubtask'.tr(),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subRow(AppColors c,
      {required String title,
      required bool done,
      VoidCallback? onToggle,
      required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: done
                ? const Icon(Icons.check_circle_rounded,
                    size: 22, color: Color(0xFF48BB78))
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border, width: 2)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14.5,
                    color: done ? c.textMuted : c.textPrimary,
                    decoration:
                        done ? TextDecoration.lineThrough : null)),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  void _addSubtask(BuildContext context, TasksHabitsViewModel vm) {
    _textInput(context, vm, 'tasks.newSubtask'.tr(), '', (v) {
      if (v.trim().isEmpty) return;
      if (isEditing && vm.editingTaskId != null) {
        vm.addSubtaskToTask(vm.editingTaskId!, v);
      } else {
        vm.addSubtaskDraft(v);
      }
    });
  }

  // ---------- Hatırlatıcı ----------
  Widget _reminderSection(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('tasks.reminder'.tr(),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.textPrimary)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  size: 22, color: _accent),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: vm.reminderEnabled
                      ? () => _showMinutes(context, vm, c)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.reminderEnabled
                            ? 'tasks.reminderBeforeMinutes'.tr(
                                namedArgs: {'n': '${vm.reminderBeforeMinutes}'})
                            : 'tasks.reminderOff'.tr(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary),
                      ),
                      if (vm.reminderEnabled) ...[
                        const SizedBox(height: 2),
                        Text('tasks.reminderTapChange'.tr(),
                            style: TextStyle(
                                fontSize: 12, color: c.textMuted)),
                      ],
                    ],
                  ),
                ),
              ),
              Switch(
                value: vm.reminderEnabled,
                activeColor: _accent,
                onChanged: vm.setReminderEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Ekler ----------
  Widget _attachSection(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    final count = vm.taskAttachmentCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('tasks.attachTitle'.tr(),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.textPrimary)),
        const SizedBox(height: 10),
        Material(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showAttachOptions(context, vm, c),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border.withOpacity(0.7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 22, color: Color(0xFF4C9AFF)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('tasks.attachments'.tr(),
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                  ),
                  if (count > 0)
                    Text('tasks.attachCount'.tr(namedArgs: {'n': '$count'}),
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: c.textMuted),
                ],
              ),
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < vm.taskExistingAttachments.length; i++)
                _thumb(c, vm.taskExistingAttachments[i],
                    () => vm.removeTaskExistingAttachment(i)),
              for (int i = 0; i < vm.taskPickedFiles.length; i++)
                _thumb(c, vm.taskPickedFiles[i].path,
                    () => vm.removeTaskPickedFile(i)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _thumb(AppColors c, String path, VoidCallback onRemove) {
    final isImg = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(path.split('.').last.toLowerCase());
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isImg
              ? Image.file(File(path),
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fileBox(c))
              : _fileBox(c),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fileBox(AppColors c) => Container(
        width: 74,
        height: 74,
        color: c.bg,
        child: Icon(Icons.insert_drive_file_rounded,
            color: c.textMuted, size: 28),
      );

  // ---------- Ekstra çipler (konum/etiket/bağlantı) ----------
  Widget _extrasChips(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _extraChip(c, Icons.place_outlined,
                  vm.taskLocation ?? 'tasks.location'.tr(),
                  active: vm.taskLocation != null, onTap: () {
                _textInput(context, vm, 'tasks.location'.tr(),
                    vm.taskLocation ?? '', vm.setTaskLocation);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _extraChip(c, Icons.local_offer_outlined,
                  'tasks.tag'.tr(),
                  active: vm.taskTags.isNotEmpty, onTap: () {
                _textInput(context, vm, 'tasks.tag'.tr(), '',
                    (v) => vm.addTaskTag(v));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _extraChip(c, Icons.link_rounded,
                  vm.taskLink ?? 'tasks.link'.tr(),
                  active: vm.taskLink != null, onTap: () {
                _textInput(context, vm, 'tasks.link'.tr(),
                    vm.taskLink ?? '', vm.setTaskLink);
              }),
            ),
          ],
        ),
        if (vm.taskTags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < vm.taskTags.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF9F7AEA).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('#${vm.taskTags[i]}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9F7AEA))),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => vm.removeTaskTag(i),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFF9F7AEA)),
                    ),
                  ]),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _extraChip(AppColors c, IconData icon, String label,
      {required bool active, required VoidCallback onTap}) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? _accent : c.border.withOpacity(0.7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17, color: active ? _accent : c.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? _accent : c.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Alt bar ----------
  Widget _bottomBar(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: _accent.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('tasks.discard'.tr(),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () => isEditing
                      ? vm.updateTask(context)
                      : vm.createTask(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('tasks.saveTask'.tr(),
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Pickerlar ----------
  Future<void> _pickDate(
      BuildContext context, TasksHabitsViewModel vm) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: vm.taskDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) vm.setTaskDueDate(d);
  }

  Future<void> _pickTime(
      BuildContext context, TasksHabitsViewModel vm) async {
    final t = await showTimePicker(
      context: context,
      initialTime: vm.taskDueTime ?? TimeOfDay.now(),
    );
    if (t != null) {
      if (vm.taskDueDate == null) vm.setTaskDueDate(DateTime.now());
      vm.setTaskDueTime(t);
    }
  }

  void _showPriority(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    _optionSheet(context, c, 'tasks.rowPriority'.tr(), [
      [2, 'tasks.priority.high', const Color(0xFFF6524B)],
      [1, 'tasks.priority.medium', const Color(0xFFF6A821)],
      [0, 'tasks.priority.low', const Color(0xFF48BB78)],
    ], vm.taskPriority, (v) => vm.setTaskPriority(v as int));
  }

  void _showCategory(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text('tasks.rowCategory'.tr(),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 10),
            for (final cat in kTaskCats)
              ListTile(
                leading: Icon(cat.icon, color: cat.color),
                title: Text(cat.labelKey.tr(),
                    style: TextStyle(color: c.textPrimary)),
                trailing: vm.taskCategory == cat.id
                    ? Icon(Icons.check_rounded, color: cat.color)
                    : null,
                onTap: () {
                  vm.setTaskCategory(
                      vm.taskCategory == cat.id ? null : cat.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRecurrence(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    _optionSheet(context, c, 'tasks.rowRecurrence'.tr(), [
      ['none', 'tasks.noRepeat', const Color(0xFF9AA0A6)],
      ['daily', 'tasks.recurrence.daily', const Color(0xFFF6A821)],
      ['weekly', 'tasks.recurrence.weekly', const Color(0xFF9F7AEA)],
      ['monthly', 'tasks.recurrence.monthly', const Color(0xFF4C9AFF)],
    ], vm.taskRecurrence, (v) => vm.setTaskRecurrence(v as String));
  }

  void _showMinutes(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in [5, 10, 15, 30, 60, 120])
              ListTile(
                title: Text(
                    'tasks.reminderBeforeMinutes'.tr(namedArgs: {'n': '$m'}),
                    style: TextStyle(color: c.textPrimary)),
                trailing: vm.reminderBeforeMinutes == m
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () {
                  vm.setReminderBeforeMinutes(m);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _optionSheet(BuildContext context, AppColors c, String title,
      List<List<dynamic>> options, dynamic selected, void Function(dynamic) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 6),
            for (final o in options)
              ListTile(
                leading: CircleAvatar(
                    radius: 6, backgroundColor: o[2] as Color),
                title: Text((o[1] as String).tr(),
                    style: TextStyle(color: c.textPrimary)),
                trailing: selected == o[0]
                    ? Icon(Icons.check_rounded, color: o[2] as Color)
                    : null,
                onTap: () {
                  onPick(o[0]);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF4C9AFF)),
              title: Text('tasks.attachPhoto'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                vm.pickTaskImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF9F7AEA)),
              title: Text('tasks.attachCamera'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                vm.pickTaskImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded,
                  color: Color(0xFFF6A821)),
              title: Text('tasks.attachFile'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                vm.pickTaskFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _textInput(BuildContext context, TasksHabitsViewModel vm, String title,
      String initial, void Function(String) onDone) {
    final ctrl = TextEditingController(text: initial);
    final c = AppColors(isDarkMode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(title, style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: title,
            hintStyle: TextStyle(color: c.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              onDone(ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('common.save'.tr(),
                style: const TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  // ---------- Etiket yardımcıları ----------
  String _dateLabel(TasksHabitsViewModel vm) {
    if (vm.taskDueDate == null) return 'tasks.noDate'.tr();
    final d = vm.taskDueDate!;
    final ds =
        '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final t = vm.taskDueTime;
    if (t != null) {
      final ts =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      return '$ds · $ts';
    }
    return ds;
  }

  String _recLabel(String pattern) {
    switch (pattern) {
      case 'daily':
        return 'tasks.recurrence.daily'.tr();
      case 'weekly':
        return 'tasks.recurrence.weekly'.tr();
      case 'monthly':
        return 'tasks.recurrence.monthly'.tr();
      default:
        return 'tasks.noRepeat'.tr();
    }
  }
}

// ==================== ALIŞKANLIK EKLEME/DÜZENLEME BOTTOM SHEET ====================

class _AddHabitBottomSheet extends StatelessWidget {
  final TasksHabitsViewModel viewModel;
  final bool isDarkMode;
  final bool isEditing;
  const _AddHabitBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    this.isEditing = false,
  });

  static const _accent = Color(0xFFF6A821);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TasksHabitsViewModel>(
        builder: (context, vm, _) {
          final c = AppColors(isDarkMode);
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.bgColorDark
                  : const Color(0xFFF6F4EF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _topBar(context, c),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _label(c, 'habits.name'.tr()),
                        _nameField(vm, c),
                        const SizedBox(height: 20),
                        _label(c, 'habits.iconColor'.tr()),
                        _iconRow(vm, c),
                        const SizedBox(height: 12),
                        _colorRow(vm),
                        const SizedBox(height: 20),
                        _label(c, 'tasks.rowRecurrence'.tr()),
                        _recurrenceSeg(vm, c),
                        const SizedBox(height: 12),
                        _weekdayRow(vm, c),
                        const SizedBox(height: 16),
                        _detailCard(context, vm, c),
                        const SizedBox(height: 20),
                        _label(c, 'habits.motivation'.tr()),
                        _motivationField(vm, c),
                      ],
                    ),
                  ),
                  _bottomBar(context, vm, c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(AppColors c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(t,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.textPrimary)),
      );

  Widget _topBar(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          _iconSquare(c, Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context)),
          Expanded(
            child: Text(
              isEditing ? 'habits.editHabit'.tr() : 'habits.newHabit'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary),
            ),
          ),
          _iconSquare(c, Icons.close_rounded, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _iconSquare(AppColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border.withOpacity(0.6))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: c.textSecondary),
        ),
      ),
    );
  }

  Widget _nameField(TasksHabitsViewModel vm, AppColors c) {
    final color = vm.getHabitColor(vm.habitColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(habitIconData(vm.selectedIcon),
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: vm.habitTitleController,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'habits.nameHint'.tr(),
                hintStyle: TextStyle(color: c.textMuted, fontSize: 15.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconRow(TasksHabitsViewModel vm, AppColors c) {
    final color = vm.getHabitColor(vm.habitColor);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final hi in kHabitIcons)
          GestureDetector(
            onTap: () => vm.setSelectedIcon(hi.key),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: vm.selectedIcon == hi.key
                    ? color.withOpacity(0.15)
                    : c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: vm.selectedIcon == hi.key
                        ? color
                        : c.border.withOpacity(0.7),
                    width: vm.selectedIcon == hi.key ? 2 : 1),
              ),
              child: Icon(hi.icon,
                  color: vm.selectedIcon == hi.key ? color : c.textSecondary,
                  size: 26),
            ),
          ),
      ],
    );
  }

  Widget _colorRow(TasksHabitsViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final hex in kHabitColors)
          GestureDetector(
            onTap: () => vm.setHabitColor(hex),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 9),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: vm.getHabitColor(hex),
                shape: BoxShape.circle,
                border: Border.all(
                    color: vm.habitColor == hex
                        ? vm.getHabitColor(hex)
                        : Colors.transparent,
                    width: 3),
                boxShadow: vm.habitColor == hex
                    ? [
                        BoxShadow(
                            color: vm.getHabitColor(hex).withOpacity(0.5),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              child: vm.habitColor == hex
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _recurrenceSeg(TasksHabitsViewModel vm, AppColors c) {
    final items = [
      ['daily', 'habits.everyDay'],
      ['weekly', 'habits.weekly'],
      ['custom', 'habits.custom'],
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                onTap: () => vm.setHabitRecurrence(it[0]),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: vm.habitRecurrence == it[0]
                        ? const LinearGradient(colors: [
                            Color(0xFFF6C23E),
                            Color(0xFFF6A821)
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(it[1].tr(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: vm.habitRecurrence == it[0]
                              ? Colors.white
                              : c.textSecondary)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weekdayRow(TasksHabitsViewModel vm, AppColors c) {
    final shorts = 'tasks.weekShort'.tr().split(',');
    final custom = vm.habitRecurrence == 'custom';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1; // 1=Pzt
        final on = vm.habitDays.contains(day);
        return GestureDetector(
          onTap: custom ? () => vm.toggleHabitDay(day) : null,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? _accent.withOpacity(0.18) : c.card,
              shape: BoxShape.circle,
              border: Border.all(
                  color: on ? _accent : c.border.withOpacity(0.7),
                  width: on ? 1.5 : 1),
            ),
            child: Text(
              i < shorts.length && shorts[i].isNotEmpty ? shorts[i][0] : '',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: on ? _accent : c.textMuted),
            ),
          ),
        );
      }),
    );
  }

  Widget _detailCard(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          _row(c, Icons.track_changes_rounded,
              'habits.dailyGoal'.tr(),
              'habits.timesN'.tr(namedArgs: {'n': '${vm.habitGoal}'}),
              onTap: () => _pickGoal(context, vm, c)),
          _divider(c),
          _rowCustom(
            c,
            Icons.access_time_rounded,
            'tasks.reminder'.tr(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    vm.habitReminderEnabled
                        ? _fmt(vm.habitReminderTime)
                        : 'tasks.reminderOff'.tr(),
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary)),
                const SizedBox(width: 8),
                Switch(
                  value: vm.habitReminderEnabled,
                  activeColor: _accent,
                  onChanged: vm.setHabitReminderEnabled,
                ),
              ],
            ),
            onTap: vm.habitReminderEnabled
                ? () => _pickTime(context, vm)
                : null,
          ),
          _divider(c),
          _row(c, Icons.calendar_month_rounded,
              'habits.startDate'.tr(), _dateLabel(vm),
              onTap: () => _pickStart(context, vm)),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Divider(
      height: 1, thickness: 1, color: c.border.withOpacity(0.5), indent: 52);

  Widget _row(AppColors c, IconData icon, String label, String value,
      {required VoidCallback onTap}) {
    return _rowCustom(
        c,
        icon,
        label,
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
        ]),
        onTap: onTap);
  }

  Widget _rowCustom(
      AppColors c, IconData icon, String label, Widget trailing,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: _accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _motivationField(TasksHabitsViewModel vm, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: TextField(
        controller: vm.habitDescriptionController,
        minLines: 2,
        maxLines: 4,
        maxLength: 120,
        style: TextStyle(fontSize: 15, color: c.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'habits.motivationHint'.tr(),
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _bottomBar(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: _accent.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('tasks.discard'.tr(),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () => isEditing
                      ? vm.updateHabit(context)
                      : vm.createHabit(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('habits.saveHabit'.tr(),
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Pickerlar ----------
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(TasksHabitsViewModel vm) {
    final d = vm.habitStartDate;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'common.today'.tr();
    }
    return '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _pickTime(
      BuildContext context, TasksHabitsViewModel vm) async {
    final t = await showTimePicker(
        context: context, initialTime: vm.habitReminderTime);
    if (t != null) vm.setHabitReminderTime(t);
  }

  Future<void> _pickStart(
      BuildContext context, TasksHabitsViewModel vm) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: vm.habitStartDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) vm.setHabitStartDate(d);
  }

  void _pickGoal(BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text('habits.dailyGoal'.tr(),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 6),
            for (final g in [1, 2, 3, 4, 5, 6, 8, 10])
              ListTile(
                title: Text('habits.timesN'.tr(namedArgs: {'n': '$g'}),
                    style: TextStyle(color: c.textPrimary)),
                trailing: vm.habitGoal == g
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () {
                  vm.setHabitGoal(g);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Widget _buildRecurrenceChip(
  BuildContext context,
  TasksHabitsViewModel vm,
  String recurrence,
  String label,
  String emoji,
  Color color,
  bool isDarkMode,
) {
  final isSelected = vm.taskRecurrence == recurrence;
  return Expanded(
    child: GestureDetector(
      onTap: () => vm.setTaskRecurrence(recurrence),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? color
                : (isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRecurrenceBadge(String recurringPattern, bool isDarkMode) {
  Color color;
  String label;
  String emoji;

  switch (recurringPattern) {
    case 'daily':
      color = Colors.blue;
      label = 'tasks.recurrence.daily'.tr();
      emoji = '📅';
      break;
    case 'weekly':
      color = Colors.purple;
      label = 'tasks.recurrence.weekly'.tr();
      emoji = '🗓️';
      break;
    case 'monthly':
      color = Colors.orange;
      label = 'tasks.recurrence.monthly'.tr();
      emoji = '📆';
      break;
    default:
      return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
