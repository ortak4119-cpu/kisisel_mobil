import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
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

class _TasksHabitsViewState extends State<TasksHabitsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              child: Column(
                children: [
                  // Header with Toggle
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with emoji
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'tasks.title'.tr(),
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
                            // Premium Button - kullanıcı yüklendikten sonra, sadece premium değilse göster
                            if (viewModel.isUserLoaded &&
                                !PremiumHelper.isPremiumUser(
                                    viewModel.currentUser))
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
                                      color: ColorConstant.accentYellow
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.router
                                        .push(const PaywallRoute()),
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
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Segment değiştirici — ortak tasarım sistemi bileşeni.
                        // Eskiden 134 satırlık iki ayrı AnimatedContainer vardı;
                        // artık her ekranda aynı görünen tek bir kontrol.
                        AppSegmentedControl(
                          selectedIndex: _tabController.index,
                          onChanged: (i) => _tabController.animateTo(i),
                          accent: _tabController.index == 0
                              ? ColorConstant.accentOrange
                              : ColorConstant.accentBlue,
                          segments: [
                            AppSegment(
                              label: 'habits.title'.tr(),
                              icon: Icons.emoji_events_rounded,
                            ),
                            AppSegment(
                              label: 'tasks.title'.tr(),
                              icon: Icons.task_rounded,
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
                      child: TabBarView(
                        key: ValueKey<int>(_tabController.index),
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _HabitsTab(
                            key: const ValueKey('habits'),
                            viewModel: viewModel,
                          ),
                          _TasksTab(
                            key: const ValueKey('tasks'),
                            viewModel: viewModel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'tasks_habits_fab',
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddHabitDialog(context, viewModel, isDarkMode);
                } else {
                  _showAddTaskDialog(context, viewModel, isDarkMode);
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
                    colors: _tabController.index == 0
                        ? [
                            ColorConstant.accentYellow,
                            ColorConstant.accentOrange,
                          ]
                        : [
                            ColorConstant.accentBlue,
                            ColorConstant.accentBlue.withValues(alpha: 0.8),
                          ],
                  ),
                  shape: BoxShape.circle, // Yuvarlak
                  boxShadow: [
                    BoxShadow(
                      color: (_tabController.index == 0
                              ? ColorConstant.accentYellow
                              : ColorConstant.accentBlue)
                          .withValues(alpha: 0.4),
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

  void _showAddTaskDialog(
    BuildContext context,
    TasksHabitsViewModel viewModel,
    bool isDarkMode,
  ) =>
      showAddTaskSheet(context, viewModel, isDarkMode);

  void _showAddHabitDialog(
    BuildContext context,
    TasksHabitsViewModel viewModel,
    bool isDarkMode,
  ) =>
      showAddHabitSheet(context, viewModel, isDarkMode);
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

// ==================== ALIŞKANLIKLAR TAB ====================

class _HabitsTab extends StatelessWidget {
  final TasksHabitsViewModel viewModel;

  const _HabitsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: ColorConstant.accentYellow,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadHabits(),
      color: ColorConstant.accentYellow,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // İstatistikler — emoji yerine ortak AppStatTile bileşeni
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  icon: Icons.track_changes_rounded,
                  value:
                      '${viewModel.completedTodayCount}/${viewModel.habits.length}',
                  label: 'common.today'.tr(),
                  accent: ColorConstant.accentOrange,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${viewModel.longestStreak}',
                  label: 'habits.stats.streak'.tr(),
                  accent: ColorConstant.accentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Alışkanlıklar
          if (viewModel.habits.isNotEmpty)
            ...viewModel.habits.map(
              (habit) => _buildHabitCard(context, habit, viewModel, isDarkMode),
            )
          else
            _buildEmptyState(
              illustration: 'empty_habits.svg',
              message: 'habits.emptyState'.tr(),
              subtitle: 'habits.emptyStateSubtitle'.tr(),
              color: ColorConstant.accentOrange,
              actionLabel: 'habits.newHabit'.tr(),
              onAction: () => showAddHabitSheet(context, viewModel, isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    habit,
    TasksHabitsViewModel viewModel,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key('habit_${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstant.errorRed.withValues(alpha: 0.8),
              ColorConstant.errorRed,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: ColorConstant.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'common.delete'.tr(),
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Text('🗑️ ', style: TextStyle(fontSize: 24)),
                Expanded(
                  child: Text(
                    'habits.deleteHabit'.tr(),
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'habits.deleteConfirm'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
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
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'common.delete'.tr(),
                  style: TextStyle(color: ColorConstant.errorRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        viewModel.deleteHabit(habit.id, context);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: habit.completedToday
                  ? ColorConstant.accentGreen
                  : (isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight),
              width: habit.completedToday ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
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
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Animated Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  viewModel
                                      .getHabitColor(habit.color)
                                      .withValues(alpha: 0.2),
                                  viewModel
                                      .getHabitColor(habit.color)
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: viewModel
                                    .getHabitColor(habit.color)
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                habit.icon ?? '⭐',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildFunDifficultyBadge(
                                  habit.difficultyLevel, isDarkMode),
                              _buildInfoChip(
                                Icons.local_fire_department_rounded,
                                '${habit.currentStreak}',
                                ColorConstant.accentOrange,
                                isDarkMode,
                              ),
                              _buildInfoChip(
                                Icons.check_circle_rounded,
                                '${habit.totalCompletions}',
                                ColorConstant.accentGreen,
                                isDarkMode,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Animated Check button
                    GestureDetector(
                      onTap: () =>
                          viewModel.toggleHabitComplete(habit, context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: habit.completedToday
                              ? LinearGradient(
                                  colors: [
                                    ColorConstant.accentGreen,
                                    ColorConstant.accentGreen
                                        .withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: habit.completedToday
                              ? null
                              : (isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.bgColorLight),
                          border: Border.all(
                            color: habit.completedToday
                                ? ColorConstant.accentGreen
                                : (isDarkMode
                                    ? ColorConstant.borderColorDark
                                    : ColorConstant.borderColorLight),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: habit.completedToday
                              ? [
                                  BoxShadow(
                                    color: ColorConstant.accentGreen
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          habit.completedToday
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                          color: habit.completedToday
                              ? ColorConstant.white
                              : (isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunDifficultyBadge(String difficulty, bool isDarkMode) {
    Color color;
    String label;
    IconData badgeIcon;

    switch (difficulty) {
      case 'beginner':
        color = ColorConstant.accentGreen;
        label = 'habits.difficulty.easy'.tr();
        badgeIcon = Icons.eco_rounded;
        break;
      case 'intermediate':
        color = ColorConstant.accentYellow;
        label = 'habits.difficulty.medium'.tr();
        badgeIcon = Icons.fitness_center_rounded;
        break;
      case 'advanced':
        color = ColorConstant.errorRed;
        label = 'habits.difficulty.hard'.tr();
        badgeIcon = Icons.rocket_launch_rounded;
        break;
      default:
        color = ColorConstant.accentGreen;
        label = 'habits.difficulty.easy'.tr();
        badgeIcon = Icons.eco_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Bilgi rozeti — metne emoji gömmek yerine gerçek ikon alır.
  Widget _buildInfoChip(
      IconData icon, String text, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GÖREVLER TAB ====================

// ==================== GÖREVLER TAB ====================

class _TasksTab extends StatelessWidget {
  final TasksHabitsViewModel viewModel;

  const _TasksTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: ColorConstant.accentBlue,
        ),
      );
    }

    return Column(
      children: [
        // Filter Tabs
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _buildFilterTab(
                context,
                viewModel,
                TaskFilter.all,
                'tasks.stats.all'.tr(),
                '📋',
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildFilterTab(
                context,
                viewModel,
                TaskFilter.pending,
                'tasks.stats.pending'.tr(),
                '⏳',
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildFilterTab(
                context,
                viewModel,
                TaskFilter.completed,
                'tasks.stats.completed'.tr(),
                '✅',
                isDarkMode,
              ),
            ],
          ),
        ),

        // Task List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.loadTasks(),
            color: ColorConstant.accentBlue,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Filtered Tasks
                if (viewModel.filteredTasks.isNotEmpty)
                  ...viewModel.filteredTasks.map(
                    (task) =>
                        _buildTaskCard(context, task, viewModel, isDarkMode),
                  ),

                // Boş durum
                if (viewModel.filteredTasks.isEmpty)
                  _buildEmptyState(
                    illustration: 'empty_tasks.svg',
                    message: _getEmptyStateMessage(viewModel.currentTaskFilter),
                    subtitle:
                        _getEmptyStateSubtitle(viewModel.currentTaskFilter),
                    color: ColorConstant.accentBlue,
                    actionLabel: 'tasks.newTask'.tr(),
                    onAction: () =>
                        showAddTaskSheet(context, viewModel, isDarkMode),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    TasksHabitsViewModel vm,
    TaskFilter filter,
    String label,
    String emoji,
    bool isDarkMode,
  ) {
    final isSelected = vm.currentTaskFilter == filter;

    Color getFilterColor() {
      switch (filter) {
        case TaskFilter.all:
          return ColorConstant.accentBlue;
        case TaskFilter.pending:
          return ColorConstant.accentYellow;
        case TaskFilter.completed:
          return ColorConstant.accentGreen;
      }
    }

    int getCount() {
      switch (filter) {
        case TaskFilter.all:
          return vm.tasks.length;
        case TaskFilter.pending:
          return vm.pendingCount;
        case TaskFilter.completed:
          return vm.completedCount;
      }
    }

    final color = getFilterColor();
    final count = getCount();

    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setTaskFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : (isDarkMode
                    ? ColorConstant.cardColorDark.withValues(alpha: 0.3)
                    : ColorConstant.bgColorLight),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: isSelected ? 16 : 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? color
                          : (isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? color
                      : (isDarkMode
                          ? ColorConstant.textMutedDark
                          : ColorConstant.textMutedLight),
                  fontWeight: FontWeight.w900,
                  fontSize: isSelected ? 18 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _getEmptyStateEmoji kaldırıldı: boş durumlar artık emoji yerine
  // assets/images/ altındaki SVG illüstrasyonları kullanıyor.

  String _getEmptyStateMessage(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'tasks.emptyState'.tr();
      case TaskFilter.pending:
        return 'tasks.emptyPending'.tr();
      case TaskFilter.completed:
        return 'tasks.emptyCompleted'.tr();
    }
  }

  String _getEmptyStateSubtitle(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'tasks.emptyStateSubtitle'.tr();
      case TaskFilter.pending:
        return 'tasks.emptyPendingSubtitle'.tr();
      case TaskFilter.completed:
        return 'tasks.emptyCompletedSubtitle'.tr();
    }
  }

  Widget _buildTaskCard(
    BuildContext context,
    task,
    TasksHabitsViewModel viewModel,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstant.errorRed.withValues(alpha: 0.8),
              ColorConstant.errorRed,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: ColorConstant.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'common.delete'.tr(),
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Text('🗑️ ', style: TextStyle(fontSize: 24)),
                Expanded(
                  child: Text(
                    'tasks.deleteTask'.tr(),
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'tasks.deleteConfirm'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
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
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'common.delete'.tr(),
                  style: TextStyle(color: ColorConstant.errorRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        viewModel.deleteTask(task.id, context);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
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
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Animated Checkbox
                    GestureDetector(
                      onTap: () => viewModel.toggleTaskComplete(task, context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: task.isCompleted
                              ? LinearGradient(
                                  colors: [
                                    ColorConstant.accentGreen,
                                    ColorConstant.accentGreen
                                        .withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: task.isCompleted ? null : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? ColorConstant.accentGreen
                                : (isDarkMode
                                    ? ColorConstant.borderColorDark
                                    : ColorConstant.borderColorLight),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: task.isCompleted
                              ? [
                                  BoxShadow(
                                    color: ColorConstant.accentGreen
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: task.isCompleted
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: ColorConstant.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: task.isCompleted
                                        ? (isDarkMode
                                            ? ColorConstant.textMutedDark
                                            : ColorConstant.textMutedLight)
                                        : (isDarkMode
                                            ? ColorConstant.textPrimaryDark
                                            : ColorConstant.textPrimaryLight),
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildFunPriorityBadge(task.priority, isDarkMode),
                              if (task.isRecurring &&
                                  task.recurringPattern != null &&
                                  task.recurringPattern != 'none')
                                _buildRecurrenceBadge(
                                    task.recurringPattern!, isDarkMode),
                              if (task.dueDate != null)
                                _buildInfoChip(
                                  '📅 ${task.dueDate}',
                                  isDarkMode
                                      ? ColorConstant.textMutedDark
                                      : ColorConstant.textMutedLight,
                                  isDarkMode,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunPriorityBadge(int priority, bool isDarkMode) {
    Color color;
    String label;
    String emoji;

    switch (priority) {
      case 0:
        color = ColorConstant.accentGreen;
        label = 'tasks.priority.low'.tr();
        emoji = '😌';
        break;
      case 1:
        color = ColorConstant.accentYellow;
        label = 'tasks.priority.medium'.tr();
        emoji = '👀';
        break;
      case 2:
        color = ColorConstant.errorRed;
        label = 'tasks.priority.high'.tr();
        emoji = '🔥';
        break;
      default:
        color = ColorConstant.accentBlue;
        label = 'tasks.priority.normal'.tr();
        emoji = '📌';
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

  Widget _buildInfoChip(String text, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
// ==================== YARDIMCI WIDGET'LAR ====================

// _buildFunMiniStat kaldırıldı: istatistikler artık ortak AppStatTile
// bileşenini kullanıyor (emoji yerine gerçek ikon).

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TasksHabitsViewModel>(
        builder: (context, vm, _) {
          return Container(
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
                        // Handle bar
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

                        // Title with emoji
                        Row(
                          children: [
                            Text(
                              isEditing ? '✏️' : '✨',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing
                                  ? 'tasks.editTask'.tr()
                                  : 'tasks.newTask'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Task Title
                        AppTextField(
                          controller: vm.taskTitleController,
                          hint: 'tasks.taskTitle'.tr(),
                          accent: ColorConstant.accentBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        AppTextField(
                          controller: vm.taskDescriptionController,
                          hint: 'tasks.description'.tr(),
                          accent: ColorConstant.accentBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),

                        // Priority
                        Text(
                          'tasks.priorityLevel'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPriorityChip(
                              context,
                              vm,
                              0,
                              'tasks.priority.low'.tr(),
                              '😌',
                              ColorConstant.accentGreen,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityChip(
                              context,
                              vm,
                              1,
                              'tasks.priority.medium'.tr(),
                              '👀',
                              ColorConstant.accentYellow,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityChip(
                              context,
                              vm,
                              2,
                              'tasks.priority.high'.tr(),
                              '🔥',
                              ColorConstant.errorRed,
                              isDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Recurrence Type
                        Text(
                          'tasks.recurrenceFrequency'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRecurrenceChip(
                              context,
                              vm,
                              'none',
                              'tasks.recurrence.once'.tr(),
                              '📌',
                              ColorConstant.accentBlue,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildRecurrenceChip(
                              context,
                              vm,
                              'daily',
                              'tasks.recurrence.daily'.tr(),
                              '📅',
                              Colors.blue,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildRecurrenceChip(
                              context,
                              vm,
                              'weekly',
                              'tasks.recurrence.weekly'.tr(),
                              '🗓️',
                              Colors.purple,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildRecurrenceChip(
                              context,
                              vm,
                              'monthly',
                              'tasks.recurrence.monthly'.tr(),
                              '📆',
                              Colors.orange,
                              isDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Reminder Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: vm.reminderEnabled
                                  ? ColorConstant.accentBlue
                                  : (isDarkMode
                                      ? ColorConstant.borderColorDark
                                      : ColorConstant.borderColorLight),
                              width: vm.reminderEnabled ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_rounded,
                                    color: vm.reminderEnabled
                                        ? ColorConstant.accentBlue
                                        : (isDarkMode
                                            ? ColorConstant.textSecondaryDark
                                            : ColorConstant.textSecondaryLight),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'tasks.reminder'.tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: vm.reminderEnabled
                                            ? ColorConstant.accentBlue
                                            : (isDarkMode
                                                ? ColorConstant
                                                    .textSecondaryDark
                                                : ColorConstant
                                                    .textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: vm.reminderEnabled,
                                    onChanged: (value) =>
                                        vm.setReminderEnabled(value),
                                    activeThumbColor: ColorConstant.accentBlue,
                                  ),
                                ],
                              ),
                              if (vm.reminderEnabled) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'tasks.reminderTime'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime:
                                          vm.reminderTime ?? TimeOfDay.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: ColorConstant.accentBlue,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (pickedTime != null) {
                                      vm.setReminderTime(pickedTime);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? ColorConstant.borderColorDark
                                          : ColorConstant.borderColorLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: vm.reminderTime != null
                                            ? ColorConstant.accentBlue
                                            : (isDarkMode
                                                ? ColorConstant.borderColorDark
                                                : ColorConstant
                                                    .borderColorLight),
                                        width: vm.reminderTime != null ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          color: vm.reminderTime != null
                                              ? ColorConstant.accentBlue
                                              : (isDarkMode
                                                  ? ColorConstant
                                                      .textSecondaryDark
                                                  : ColorConstant
                                                      .textSecondaryLight),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            vm.reminderTime != null
                                                ? '${vm.reminderTime!.hour.toString().padLeft(2, '0')}:${vm.reminderTime!.minute.toString().padLeft(2, '0')}'
                                                : 'tasks.hints.selectTime'.tr(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: vm.reminderTime != null
                                                  ? ColorConstant.accentBlue
                                                  : (isDarkMode
                                                      ? ColorConstant
                                                          .textSecondaryDark
                                                      : ColorConstant
                                                          .textSecondaryLight),
                                            ),
                                          ),
                                        ),
                                        if (vm.reminderTime != null)
                                          IconButton(
                                            onPressed: () =>
                                                vm.setReminderTime(null),
                                            icon: Icon(
                                              Icons.close_rounded,
                                              color: ColorConstant
                                                  .textSecondaryDark,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetTaskForm();
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
                                onPressed: () => isEditing
                                    ? vm.updateTask(context)
                                    : vm.createTask(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.accentBlue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isEditing
                                      ? 'common.update'.tr()
                                      : 'common.create'.tr(),
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

  Widget _buildPriorityChip(
    BuildContext context,
    TasksHabitsViewModel vm,
    int priority,
    String label,
    String emoji,
    Color color,
    bool isDarkMode,
  ) {
    final isSelected = vm.taskPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setTaskPriority(priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Text(emoji, style: const TextStyle(fontSize: 20)),
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
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  final List<String> _icons = const [
    '⭐',
    '🎯',
    '💪',
    '🧘',
    '📚',
    '💧',
    '🏃',
    '🥗',
    '😴',
    '🎨',
    '🎵',
    '✍️',
    '🧠',
    '❤️',
    '🌟',
    '🔥'
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<TasksHabitsViewModel>(
        builder: (context, vm, _) {
          return Container(
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
                        // Handle bar
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

                        // Başlık — emoji yerine renkli ikon rozeti
                        AppSectionHeader(
                          icon: isEditing
                              ? Icons.edit_rounded
                              : Icons.auto_awesome_rounded,
                          title: isEditing
                              ? 'habits.editHabit'.tr()
                              : 'habits.newHabit'.tr(),
                          accent: ColorConstant.accentOrange,
                        ),
                        const SizedBox(height: 24),

                        // Icon Selection
                        Text(
                          'habits.selectIcon'.tr(),
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
                            itemCount: _icons.length,
                            itemBuilder: (context, index) {
                              final icon = _icons[index];
                              final isSelected = vm.selectedIcon == icon;
                              return GestureDetector(
                                onTap: () => vm.setSelectedIcon(icon),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              ColorConstant.accentYellow
                                                  .withValues(alpha: 0.2),
                                              ColorConstant.accentOrange
                                                  .withValues(alpha: 0.1),
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : (isDarkMode
                                            ? ColorConstant.bgColorDark
                                            : ColorConstant.bgColorLight),
                                    border: Border.all(
                                      color: isSelected
                                          ? ColorConstant.accentYellow
                                          : (isDarkMode
                                              ? ColorConstant.borderColorDark
                                              : ColorConstant.borderColorLight),
                                      width: isSelected ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      icon,
                                      style: TextStyle(
                                        fontSize: isSelected ? 36 : 32,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Habit Title
                        AppTextField(
                          controller: vm.habitTitleController,
                          hint: 'habits.habitTitle'.tr(),
                          accent: ColorConstant.accentOrange,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        AppTextField(
                          controller: vm.habitDescriptionController,
                          hint: 'habits.hints.description'.tr(),
                          accent: ColorConstant.accentOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),

                        // Difficulty
                        Text(
                          'habits.difficultyLevel'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildDifficultyChip(
                              context,
                              vm,
                              'beginner',
                              'habits.difficulty.easy'.tr(),
                              '🌱',
                              ColorConstant.accentGreen,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildDifficultyChip(
                              context,
                              vm,
                              'intermediate',
                              'habits.difficulty.medium'.tr(),
                              '💪',
                              ColorConstant.accentYellow,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildDifficultyChip(
                              context,
                              vm,
                              'advanced',
                              'habits.difficulty.hard'.tr(),
                              '🚀',
                              ColorConstant.errorRed,
                              isDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Time Period Selection
                        Text(
                          'habits.reminderTime'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTimePeriodChip(
                              context,
                              vm,
                              'morning',
                              'habits.time.morning'.tr(),
                              '🌅',
                              '09:00',
                              ColorConstant.accentYellow,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildTimePeriodChip(
                              context,
                              vm,
                              'noon',
                              'habits.time.noon'.tr(),
                              '☀️',
                              '13:00',
                              ColorConstant.accentOrange,
                              isDarkMode,
                            ),
                            const SizedBox(width: 8),
                            _buildTimePeriodChip(
                              context,
                              vm,
                              'evening',
                              'habits.time.evening'.tr(),
                              '🌙',
                              '17:00',
                              ColorConstant.primaryPurple,
                              isDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Butonlar — ortak tasarım sistemi bileşenleri.
                        // Onay butonu daha geniş (flex 2) ki birincil eylem
                        // görsel olarak öne çıksın.
                        Row(
                          children: [
                            Expanded(
                              child: AppGhostButton(
                                label: 'common.cancel'.tr(),
                                onPressed: () {
                                  vm.resetHabitForm();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: AppPrimaryButton(
                                label: isEditing
                                    ? 'common.update'.tr()
                                    : 'common.create'.tr(),
                                icon: isEditing
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                accent: ColorConstant.accentOrange,
                                onPressed: () => isEditing
                                    ? vm.updateHabit(context)
                                    : vm.createHabit(context),
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

  Widget _buildDifficultyChip(
    BuildContext context,
    TasksHabitsViewModel vm,
    String value,
    String label,
    String emoji,
    Color color,
    bool isDarkMode,
  ) {
    final isSelected = vm.habitDifficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setHabitDifficulty(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Text(emoji, style: const TextStyle(fontSize: 20)),
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
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePeriodChip(
    BuildContext context,
    TasksHabitsViewModel vm,
    String value,
    String label,
    String emoji,
    String time,
    Color color,
    bool isDarkMode,
  ) {
    final isSelected = vm.habitTimePeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setHabitTimePeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Text(emoji, style: const TextStyle(fontSize: 20)),
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
                  fontSize: 11,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : (isDarkMode
                          ? ColorConstant.textMutedDark
                          : ColorConstant.textMutedLight),
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
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
