import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/nl_task_parser.dart';
import 'shared_habits_view.dart';
import '../viewmodel/tasks_habits_viewmodel.dart';

/// Kesikli yuvarlak dikdörtgen kenar — "Gecikenleri bugüne taşı" butonu.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TasksHabitsView extends StatefulWidget {
  /// 'both' = görev/alışkanlık toggle'lı; 'tasks' = sadece görevler;
  /// 'habits' = sadece alışkanlıklar (alt menüde ayrı sekmeler için).
  final String mode;
  const TasksHabitsView({super.key, this.mode = 'both'});

  @override
  State<TasksHabitsView> createState() => _TasksHabitsViewState();
}

class _TasksHabitsViewState extends State<TasksHabitsView> {
  late int _tab; // 0 = Görevler, 1 = Alışkanlıklar

  bool get _showToggle => widget.mode == 'both';

  @override
  void initState() {
    super.initState();
    _tab = widget.mode == 'habits' ? 1 : 0;
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
              bottom: false,
              child: Column(
                children: [
                  if (!_showToggle)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _tab == 0 ? 'tasks.title'.tr() : 'habits.title'.tr(),
                          style: TextStyle(fontFamily: 'JosefinSans',
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : const Color(0xFF3A3326),
                          ),
                        ),
                      ),
                    ),
                  if (_showToggle)
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

// ==================== YAŞAM ALANLARI ====================
// Alışkanlıklar 4 yaşam alanına ayrılır: İlişkiler, Öğrenme, Zihin, Sağlık.
// Çeyrek-donut grafiği bu alanları gösterir; her alanın kendi rengi vardır.
class _LifeArea {
  final String key;
  final String labelKey;
  final Color main;
  final Color soft;
  final IconData icon;
  const _LifeArea(this.key, this.labelKey, this.main, this.soft, this.icon);
}

const List<_LifeArea> kLifeAreas = [
  _LifeArea('relationships', 'habits.area.relationships', Color(0xFF8E7CC9),
      Color(0xFFEBE5F7), Icons.favorite_rounded),
  _LifeArea('learning', 'habits.area.learning', Color(0xFF4E88C7),
      Color(0xFFE1ECF8), Icons.menu_book_rounded),
  _LifeArea('mind', 'habits.area.mind', Color(0xFFE0893C), Color(0xFFFAEEDD),
      Icons.self_improvement_rounded),
  _LifeArea('health', 'habits.area.health', Color(0xFF46A46B),
      Color(0xFFE0F1E7), Icons.spa_rounded),
];

/// Kayıtlı kategori metnini (eski ya da yeni) bir yaşam alanına eşler.
_LifeArea lifeAreaFor(String? category) {
  final c = (category ?? '').toLowerCase();
  bool has(List<String> ks) => ks.any((k) => c.contains(k));
  if (has(const [
    'relation',
    'social',
    'family',
    'friend',
    'ilişk',
    'iliski',
    'love',
    'sevgi',
    'aile'
  ])) {
    return kLifeAreas[0];
  }
  if (has(const [
    'learn',
    'study',
    'educat',
    'öğren',
    'ogren',
    'read',
    'book',
    'kitap',
    'skill',
    'language',
    'dil',
    'course',
    'eğitim'
  ])) {
    return kLifeAreas[1];
  }
  if (has(const [
    'mind',
    'mental',
    'medit',
    'zihin',
    'calm',
    'journal',
    'günlük',
    'spirit',
    'focus',
    'odak',
    'nefes',
    'breath',
    'ruh'
  ])) {
    return kLifeAreas[2];
  }
  return kLifeAreas[3]; // sağlık (varsayılan)
}

/// Çeyrek-donut: 4 yaşam alanı pastel renklerle; tamamlanma oranına göre
/// dış kenarda doygun bir yay çizilir. Ortada beyaz delik bırakılır.
class _AreaDonutPainter extends CustomPainter {
  final Map<String, double> ratio; // alan -> 0..1 tamamlanma
  final Map<String, bool> hasHabits; // alan -> alışkanlık var mı
  final Color hole;
  _AreaDonutPainter({
    required this.ratio,
    required this.hasHabits,
    required this.hole,
  });

  // Çeyreklerin başlangıç açıları (derece). 0° = doğu, saat yönü +.
  static const Map<String, double> _starts = {
    'relationships': 180.0, // sol üst
    'learning': -90.0, // sağ üst
    'mind': 90.0, // sol alt
    'health': 0.0, // sağ alt
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    const gapDeg = 3.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const d2r = math.pi / 180.0;
    for (final a in kLifeAreas) {
      final start = (_starts[a.key]! + gapDeg / 2) * d2r;
      final sweep = (90.0 - gapDeg) * d2r;
      canvas.drawArc(
          rect, start, sweep, true, Paint()..color = a.soft);
      final r = (ratio[a.key] ?? 0).clamp(0.0, 1.0);
      if ((hasHabits[a.key] ?? false) && r > 0) {
        final arcRect = Rect.fromCircle(center: center, radius: radius - 7);
        canvas.drawArc(
          arcRect,
          start,
          sweep * r,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = a.main,
        );
      }
    }
    canvas.drawCircle(center, radius * 0.56, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(covariant _AreaDonutPainter old) =>
      old.ratio != ratio || old.hasHabits != hasHabits || old.hole != hole;
}

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
  const _HabitsTab({required this.viewModel});

  static const _orange = Color(0xFFF6A821);
  static const _green = Color(0xFF46A46B);

  /// Alışkanlıkları yaşam alanına göre grupla (alan sırası sabit).
  Map<String, List<Habit>> _grouped() {
    final map = {for (final a in kLifeAreas) a.key: <Habit>[]};
    for (final h in viewModel.habits) {
      map[lifeAreaFor(h.category).key]!.add(h);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);

    if (viewModel.isLoading && viewModel.habits.isEmpty) {
      return Center(child: CircularProgressIndicator(color: _orange));
    }

    final grouped = _grouped();
    final filled = kLifeAreas.where((a) => grouped[a.key]!.isNotEmpty).toList();
    final empty = kLifeAreas.where((a) => grouped[a.key]!.isEmpty).toList();

    return RefreshIndicator(
      onRefresh: () => viewModel.loadHabits(),
      color: _orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _sharedChip(context, c),
          ),
          const SizedBox(height: 6),
          _areaDonutCard(c, grouped),
          const SizedBox(height: 18),
          for (final a in filled)
            for (final h in grouped[a.key]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _habitCard(context, c, h, a),
              ),
          for (final a in empty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _emptyAreaRow(context, c, a),
            ),
        ],
      ),
    );
  }

  // ---------- Paylaşılan alışkanlıklar kısayolu ----------
  Widget _sharedChip(BuildContext context, AppColors c) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SharedHabitsPage(isDark: c.isDark))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, size: 18, color: _orange),
            const SizedBox(width: 5),
            Text('habits.shared.short'.tr(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _orange)),
          ],
        ),
      ),
    );
  }

  // ---------- Çeyrek-donut kartı (4 yaşam alanı) ----------
  Widget _areaDonutCard(AppColors c, Map<String, List<Habit>> grouped) {
    double ratioOf(String k) {
      final list = grouped[k]!;
      if (list.isEmpty) return 0;
      final done = list.where(viewModel.isHabitDoneToday).length;
      return done / list.length;
    }

    final ratio = {for (final a in kLifeAreas) a.key: ratioOf(a.key)};
    final hasH = {for (final a in kLifeAreas) a.key: grouped[a.key]!.isNotEmpty};
    final totalDone = viewModel.habitTodayDone;
    final total = viewModel.habits.length;

    String areaValue(String k) {
      final list = grouped[k]!;
      if (list.isEmpty) return 'habits.areaEmpty'.tr();
      final done = list.where(viewModel.isHabitDoneToday).length;
      return '$done/${list.length}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border.withOpacity(0.6)),
      ),
      child: Center(
        child: SizedBox(
          width: 236,
          height: 236,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AreaDonutPainter(
                      ratio: ratio, hasHabits: hasH, hole: c.card),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$totalDone/$total',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text('habits.today'.tr(),
                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ),
              _quadLabel(const Alignment(-0.54, -0.5), kLifeAreas[0],
                  areaValue('relationships')),
              _quadLabel(const Alignment(0.54, -0.5), kLifeAreas[1],
                  areaValue('learning')),
              _quadLabel(const Alignment(-0.54, 0.5), kLifeAreas[2],
                  areaValue('mind')),
              _quadLabel(const Alignment(0.54, 0.5), kLifeAreas[3],
                  areaValue('health')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quadLabel(Alignment al, _LifeArea a, String value) {
    return Align(
      alignment: al,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(a.labelKey.tr(),
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: a.main)),
          const SizedBox(height: 1),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: a.main.withOpacity(0.75))),
        ],
      ),
    );
  }

  // ---------- Alışkanlık kartı (alan renkli sol çubuk) ----------
  Widget _habitCard(
      BuildContext context, AppColors c, Habit h, _LifeArea area) {
    final done = viewModel.isHabitDoneToday(h);
    final goal = viewModel.habitGoalOf(h);
    final cur = viewModel.habitProgressOf(h);
    final streak = h.currentStreak;
    final barColor = done ? _green : area.main;

    final String trailing;
    if (h.skippedToday) {
      trailing = 'habits.skippedShort'.tr();
    } else if (streak > 0) {
      trailing =
          '$cur/$goal · ${'habits.streakN'.tr(namedArgs: {'n': '$streak'})}';
    } else {
      trailing = '$cur/$goal';
    }

    return GestureDetector(
      onTap: () => viewModel.tapHabit(h, context),
      onLongPress: () => _habitMenu(context, c, h),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.55)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.labelKey.tr(),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: area.main)),
                      const SizedBox(height: 3),
                      Text(h.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: done ? c.textMuted : c.textPrimary,
                              decoration:
                                  done ? TextDecoration.lineThrough : null)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_circle_rounded,
                          color: _green, size: 24)
                      : Text(trailing,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Boş yaşam alanı istemi ----------
  Widget _emptyAreaRow(BuildContext context, AppColors c, _LifeArea area) {
    return GestureDetector(
      onTap: () {
        viewModel.resetHabitForm();
        viewModel.setHabitCategory(area.key);
        showAddHabitSheet(context, viewModel, c.isDark);
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: area.main.withOpacity(0.35)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: area.main.withOpacity(0.45),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'habits.areaEmptyPrompt'
                        .tr(namedArgs: {'area': area.labelKey.tr()}),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: area.soft, shape: BoxShape.circle),
                    child: Icon(Icons.add_rounded, color: area.main, size: 19),
                  ),
                ),
              ),
            ],
          ),
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
              leading: const Icon(Icons.grid_view_rounded, color: _orange),
              title: Text('habits.history'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showHabitHistory(context, c, h);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: _orange),
              title: Text('common.edit'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showEditHabitSheet(context, viewModel, c.isDark, h);
              },
            ),
            if (!viewModel.isHabitDoneToday(h) && !h.skippedToday)
              ListTile(
                leading: const Icon(Icons.fast_forward_rounded, color: _orange),
                title: Text('habits.skipToday'.tr(),
                    style: TextStyle(color: c.textPrimary)),
                subtitle: Text('habits.skipHint'.tr(),
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  viewModel.skipHabitToday(h, context);
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

  void _showHabitHistory(BuildContext context, AppColors c, Habit h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HabitHistorySheet(
          viewModel: viewModel, habit: h, isDark: c.isDark),
    );
  }
}


// ==================== ALIŞKANLIK GEÇMİŞİ (ISI HARİTASI) ====================

class _HabitHistorySheet extends StatefulWidget {
  final TasksHabitsViewModel viewModel;
  final Habit habit;
  final bool isDark;
  const _HabitHistorySheet(
      {required this.viewModel, required this.habit, required this.isDark});

  @override
  State<_HabitHistorySheet> createState() => _HabitHistorySheetState();
}

class _HabitHistorySheetState extends State<_HabitHistorySheet> {
  static const int _weeks = 8;
  bool _loading = true;
  bool _savingNote = false;
  HabitStats? _stats;
  final Map<String, int> _status = {}; // 1 yapıldı, 2 atlandı
  final Map<String, String> _notes = {};
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final days = _weeks * 7;
    final results = await Future.wait([
      widget.viewModel.fetchHabitStats(widget.habit.id, days: days),
      widget.viewModel.fetchHabitLogs(widget.habit.id, days: days),
    ]);
    final stats = results[0] as HabitStats?;
    final logs = results[1] as List<HabitLog>;
    for (final l in logs) {
      final k = _key(l.logDate);
      if (l.completed) {
        _status[k] = 1;
      } else if (l.skipped) {
        _status[k] = 2;
      }
      if ((l.notes ?? '').trim().isNotEmpty) _notes[k] = l.notes!.trim();
    }
    _noteCtrl.text = _notes[_key(DateTime.now())] ?? '';
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    final ok = await widget.viewModel
        .setHabitTodayNote(widget.habit.id, _noteCtrl.text);
    if (!mounted) return;
    setState(() => _savingNote = false);
    if (ok) {
      _notes[_key(DateTime.now())] = _noteCtrl.text.trim();
      _status[_key(DateTime.now())] = 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('habits.noteSaved'.tr())),
      );
    }
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = AppColors(widget.isDark);
    final color = widget.viewModel.getHabitColor(widget.habit.color);
    const done = Color(0xFF1BAF7A);
    const skipped = Color(0xFFEDA100);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final gridStart = thisMonday.subtract(const Duration(days: 7 * (_weeks - 1)));

    final rawRate = _stats?.completionRate ?? 0;
    final pct = (rawRate <= 1.0 ? rawRate * 100 : rawRate).round();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(10)),
                  child: Icon(habitIconData(widget.habit.icon),
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary)),
                      Text('habits.history'.tr(),
                          style: TextStyle(
                              fontSize: 12.5, color: c.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 44),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Row(
                children: [
                  _stat(c, '${_stats?.currentStreak ?? 0}',
                      'habits.currentStreak'.tr()),
                  const SizedBox(width: 10),
                  _stat(c, '${_stats?.longestStreak ?? 0}',
                      'habits.longestStreak'.tr()),
                  const SizedBox(width: 10),
                  _stat(c, '%$pct', 'habits.completionRate'.tr()),
                ],
              ),
              const SizedBox(height: 18),
              _heatmap(c, gridStart, today, done, skipped),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _legend(done, 'habits.legendDone'.tr(), c),
                  _legend(skipped, 'habits.legendSkipped'.tr(), c),
                  _legend(c.bg, 'habits.legendMissed'.tr(), c, border: true),
                ],
              ),
              const SizedBox(height: 18),
              Text('habits.todayNote'.tr(),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        controller: _noteCtrl,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 3,
                        style: TextStyle(fontSize: 14.5, color: c.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          counterText: '',
                          hintText: 'habits.todayNoteHint'.tr(),
                          hintStyle:
                              TextStyle(color: c.textMuted, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _savingNote ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6A821),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _savingNote
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('common.save'.tr()),
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

  Widget _stat(AppColors c, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
            color: c.bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label, AppColors c, {bool border = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: border ? Border.all(color: c.border) : null),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ],
    );
  }

  Widget _heatmap(AppColors c, DateTime gridStart, DateTime today, Color done,
      Color skipped) {
    return LayoutBuilder(builder: (context, cons) {
      const gap = 4.0;
      final cell =
          ((cons.maxWidth - gap * (_weeks - 1)) / _weeks).clamp(10.0, 26.0);
      final cols = <Widget>[];
      for (var w = 0; w < _weeks; w++) {
        final cells = <Widget>[];
        for (var d = 0; d < 7; d++) {
          final date = gridStart.add(Duration(days: w * 7 + d));
          Color fill;
          Border? bd;
          if (date.isAfter(today)) {
            fill = Colors.transparent;
            bd = Border.all(color: c.border.withOpacity(0.4));
          } else {
            final s = _status[_key(date)];
            if (s == 1) {
              fill = done;
            } else if (s == 2) {
              fill = skipped;
            } else {
              fill = c.bg;
              bd = Border.all(color: c.border);
            }
          }
          cells.add(Padding(
            padding: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
            child: Container(
              width: cell,
              height: cell,
              decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(3),
                  border: bd),
            ),
          ));
        }
        cols.add(Column(children: cells));
      }
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: cols);
    });
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
  const _TasksTab({required this.viewModel});

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
    if (searching) {
      return RefreshIndicator(
        onRefresh: () => viewModel.refreshAll(),
        color: _orange,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
          children: [
            _searchBar(context, c),
            const SizedBox(height: 16),
            ..._searchBody(context, c),
          ],
        ),
      );
    }
    return _planner(context, c, isDark);
  }

  // ==================== HAFTALIK PLANLAYICI (defter) ====================
  static const _ink = Color(0xFF4A3F2E);
  static const _inkMuted = Color(0xFF9B8A6E);

  Widget _planner(BuildContext context, AppColors c, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.add(Duration(days: 7 - now.weekday)); // haftanın pazarı
    final sections = <Widget>[_legend(), const SizedBox(height: 12)];
    // Bugün her zaman kendi bölümünde (gecikmiş + ekle + taşı ile).
    sections.add(_daySection(context, c, isDark, today, today, isToday: true));
    final weekend = <DateTime>[];
    for (DateTime d = today.add(const Duration(days: 1));
        !d.isAfter(sunday);
        d = d.add(const Duration(days: 1))) {
      if (d.weekday >= 5) {
        weekend.add(d);
      } else {
        sections.add(_daySection(context, c, isDark, d, today));
      }
    }
    if (weekend.isNotEmpty) {
      sections.add(_weekendSection(context, c, isDark, weekend));
    }
    sections.add(const SizedBox(height: 10));
    sections.add(_weekSummary(c));
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      color: _orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 140),
        children: sections,
      ),
    );
  }

  Widget _legend() {
    Widget item(String mark, String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mark,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(fontFamily: 'JosefinSans',
                    fontSize: 15, color: _inkMuted, fontWeight: FontWeight.w600)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item('·', 'tasks.planner.legendTask'.tr(), _ink),
        item('×', 'tasks.planner.legendDone'.tr(), _green),
        item('>', 'tasks.planner.legendMoved'.tr(), _orange),
        item('!', 'tasks.planner.legendOverdue'.tr(), _red),
      ],
    );
  }

  List<Task> _tasksForDay(DateTime day) {
    return viewModel.tasks.where((t) {
      if (t.parentTaskId != null) return false;
      if (t.dueDate == null) return false;
      final d = DateTime.tryParse(t.dueDate!);
      return d != null && viewModel.isSameDay(d, day);
    }).toList();
  }

  String _dayShort(int weekday) {
    final names = 'tasks.weekShort'.tr().split(',');
    return (weekday >= 1 && weekday <= names.length) ? names[weekday - 1] : '';
  }

  Widget _dayHeader(String text, {String? todaySuffix, String? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'JosefinSans',
                    fontSize: 23, fontWeight: FontWeight.w700, color: _ink)),
          ),
          if (todaySuffix != null) ...[
            const SizedBox(width: 6),
            Text('· $todaySuffix',
                style: TextStyle(fontFamily: 'JosefinSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _orange)),
          ],
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(count,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _inkMuted)),
          ],
        ],
      ),
    );
  }

  Widget _rule() => Container(
      height: 1.3,
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFCBB89A));

  Widget _taskLine(BuildContext context, bool isDark, Task t,
      {bool overdue = false}) {
    final mark = t.isCompleted ? '×' : (overdue || t.isOverdue ? '!' : '·');
    final color =
        t.isCompleted ? _green : (overdue || t.isOverdue ? _red : _ink);
    String trailing = '';
    if (overdue && t.dueDate != null) {
      final d = DateTime.tryParse(t.dueDate!);
      if (d != null) trailing = ' — ${d.day}.${d.month}';
    }
    return InkWell(
      onTap: () => viewModel.toggleTaskComplete(t, context),
      onLongPress: () => showEditTaskSheet(context, viewModel, isDark, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              child: Text(mark,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${t.title}$trailing',
                style: TextStyle(fontFamily: 'JosefinSans',
                  fontSize: 18.5,
                  height: 1.15,
                  color: t.isCompleted ? _inkMuted : _ink,
                  decoration:
                      t.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daySection(BuildContext context, AppColors c, bool isDark,
      DateTime day, DateTime today,
      {bool isToday = false}) {
    final dayTasks = _tasksForDay(day);
    final overdue = isToday ? viewModel.overdueTasksList : const <Task>[];
    final doneT = dayTasks.where((t) => t.isCompleted).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayHeader('${_dayShort(day.weekday)} ${day.day}',
              todaySuffix: isToday ? 'tasks.planner.today'.tr() : null,
              count: isToday ? '$doneT/${dayTasks.length}' : null),
          _rule(),
          for (final t in overdue) _taskLine(context, isDark, t, overdue: true),
          for (final t in dayTasks) _taskLine(context, isDark, t),
          if (isToday) ...[
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () {
                viewModel.setSelectedDay(day);
                showAddTaskSheet(context, viewModel, isDark);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('tasks.planner.tapToAdd'.tr(),
                    style: TextStyle(fontFamily: 'JosefinSans',
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: _inkMuted)),
              ),
            ),
            if (overdue.isNotEmpty) ...[
              const SizedBox(height: 6),
              _moveOverdueBtn(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _moveOverdueBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => viewModel.carryOverdueToToday(context),
      child: CustomPaint(
        painter: _DashedRectPainter(color: _orange),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('> ',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _orange)),
              Text('tasks.planner.moveOverdue'.tr(),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _orange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekendSection(BuildContext context, AppColors c, bool isDark,
      List<DateTime> days) {
    final label = days
        .map((d) => '${_dayShort(d.weekday)} ${d.day}')
        .join(' · ');
    final tasks = <Task>[];
    for (final d in days) {
      tasks.addAll(_tasksForDay(d));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayHeader(label),
          _rule(),
          if (tasks.isEmpty)
            Text('— ${'tasks.planner.noUpcoming'.tr()}',
                style: TextStyle(fontFamily: 'JosefinSans',
                    fontSize: 18, fontStyle: FontStyle.italic, color: _inkMuted))
          else
            for (final t in tasks) _taskLine(context, isDark, t),
        ],
      ),
    );
  }

  Widget _weekSummary(AppColors c) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.add(Duration(days: 7 - now.weekday));
    int done = 0, upcoming = 0;
    for (final t in viewModel.tasks) {
      if (t.parentTaskId != null || t.dueDate == null) continue;
      final d = DateTime.tryParse(t.dueDate!);
      if (d == null) continue;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isBefore(today)) continue;
      if (dd.isAfter(sunday)) continue;
      if (t.isCompleted) {
        done++;
      } else if (dd.isAfter(today)) {
        upcoming++;
      }
    }
    final overdue = viewModel.overdueTaskCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBB89A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('tasks.planner.weekSummary'.tr(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(
                  '$done ${'tasks.planner.done'.tr()} · $overdue ${'tasks.planner.overdue'.tr()} · $upcoming ${'tasks.planner.upcoming'.tr()}',
                  style: const TextStyle(fontSize: 14, color: _inkMuted),
                ),
              ],
            ),
          ),
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


  // ---------- Gün gövdesi ----------

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

  // ---------- İlerleme kartı ----------

  // ---------- Bölüm başlığı + sıralama ----------



  /// "Elle" sıralama modunda sürükle-bırak görev listesi.

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
    final box = Container(
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
              onChanged: (_) => vm.onTaskTitleChanged(),
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
    final p = vm.nlPreview;
    if (!p.hasAny) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [box, const SizedBox(height: 8), _nlPreviewBar(vm, c, p)],
    );
  }

  /// Doğal dil önizleme çubuğu: başlıkta algılanan tarih/saat/öncelik/etiket.
  Widget _nlPreviewBar(TasksHabitsViewModel vm, AppColors c, ParsedTask p) {
    final chips = <Widget>[];
    String two(int n) => n.toString().padLeft(2, '0');
    if (p.dueDate != null) {
      chips.add(_nlChip(Icons.event_rounded,
          '${two(p.dueDate!.day)}.${two(p.dueDate!.month)}'));
    }
    if (p.dueTime != null) {
      chips.add(_nlChip(Icons.schedule_rounded,
          '${two(p.dueTime!.hour)}:${two(p.dueTime!.minute)}'));
    }
    if (p.priority != null) {
      chips.add(_nlChip(
          Icons.flag_rounded,
          'tasks.priority.${p.priority == 2 ? 'high' : p.priority == 0 ? 'low' : 'medium'}'
              .tr()));
    }
    for (final t in p.tags) {
      chips.add(_nlChip(Icons.tag_rounded, '#$t'));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 15, color: Color(0xFF9F7AEA)),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: chips),
          ),
        ],
      ),
    );
  }

  Widget _nlChip(IconData icon, String label) {
    const purple = Color(0xFF9F7AEA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: purple.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: purple),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: purple)),
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
    // Backend eki (URL) ya da yerel dosya yolu olabilir.
    final isNetwork = path.startsWith('http');
    final ext = path.split('?').first.split('.').last.toLowerCase();
    final isImg = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isImg
              ? (isNetwork
                  ? Image.network(path,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fileBox(c))
                  : Image.file(File(path),
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fileBox(c)))
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
                        _label(c, 'habits.areaLabel'.tr()),
                        _areaPicker(vm, c),
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
                        const SizedBox(height: 20),
                        _label(c, 'habits.cue'.tr()),
                        _habitLineField(
                            vm.habitCueController, 'habits.cueHint'.tr(), c),
                        const SizedBox(height: 20),
                        _label(c, 'habits.reward'.tr()),
                        _habitLineField(vm.habitRewardController,
                            'habits.rewardHint'.tr(), c),
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

  // Yaşam alanı seçici: İlişkiler / Öğrenme / Zihin / Sağlık.
  Widget _areaPicker(TasksHabitsViewModel vm, AppColors c) {
    final sel = lifeAreaFor(vm.habitCategory);
    return Row(
      children: [
        for (int i = 0; i < kLifeAreas.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => vm.setHabitCategory(kLifeAreas[i].key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: sel.key == kLifeAreas[i].key
                      ? kLifeAreas[i].soft
                      : c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel.key == kLifeAreas[i].key
                        ? kLifeAreas[i].main
                        : c.border.withOpacity(0.7),
                    width: sel.key == kLifeAreas[i].key ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(kLifeAreas[i].icon,
                        color: kLifeAreas[i].main, size: 20),
                    const SizedBox(height: 6),
                    Text(kLifeAreas[i].labelKey.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: sel.key == kLifeAreas[i].key
                                ? kLifeAreas[i].main
                                : c.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
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
          _row(c, Icons.track_changes_rounded, 'habits.targetLabel'.tr(),
              'habits.timesN'.tr(namedArgs: {'n': '${vm.habitGoal}'}),
              onTap: () => _pickGoal(context, vm, c)),
          _divider(c),
          _row(c, Icons.repeat_rounded, 'habits.frequency'.tr(),
              _freqLabel(vm),
              onTap: () => _pickFreqType(context, vm, c)),
          _divider(c),
          _reminderSection(context, vm, c),
          _divider(c),
          _row(c, Icons.calendar_month_rounded, 'habits.startDate'.tr(),
              _dateLabel(vm),
              onTap: () => _pickStart(context, vm)),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Divider(
      height: 1, thickness: 1, color: c.border.withOpacity(0.5), indent: 52);

  String _freqLabel(TasksHabitsViewModel vm) {
    switch (vm.habitFreqType) {
      case 'days_per_week':
        return 'habits.perWeek'.tr();
      case 'continuous':
        return 'habits.continuous'.tr();
      default:
        return 'habits.perDay'.tr();
    }
  }

  void _pickFreqType(
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
            for (final o in const [
              ['times_per_day', 'habits.perDay'],
              ['days_per_week', 'habits.perWeek'],
              ['continuous', 'habits.continuous'],
            ])
              ListTile(
                title: Text(o[1].tr(), style: TextStyle(color: c.textPrimary)),
                trailing: vm.habitFreqType == o[0]
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () {
                  vm.setHabitFreqType(o[0]);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Çoklu hatırlatıcı bölümü: aç/kapa + saat çipleri + saat ekle.
  Widget _reminderSection(
      BuildContext context, TasksHabitsViewModel vm, AppColors c) {
    return Column(
      children: [
        _rowCustom(
          c,
          Icons.access_time_rounded,
          'tasks.reminder'.tr(),
          Switch(
            value: vm.habitReminderEnabled,
            activeColor: _accent,
            onChanged: vm.setHabitReminderEnabled,
          ),
        ),
        if (vm.habitReminderEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 0, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < vm.habitReminderTimes.length; i++)
                  _timeChip(c, _fmt(vm.habitReminderTimes[i]),
                      () => vm.removeHabitReminderTimeAt(i)),
                _addTimeChip(c, () async {
                  final t = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (t != null) vm.addHabitReminderTime(t);
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _timeChip(AppColors c, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _accent)),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 16, color: _accent),
          ),
        ],
      ),
    );
  }

  Widget _addTimeChip(AppColors c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: _accent),
            const SizedBox(width: 4),
            Text('habits.addReminderTime'.tr(),
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _accent)),
          ],
        ),
      ),
    );
  }

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

  /// Tek satırlık alışkanlık metin alanı (ipucu / ödül için).
  Widget _habitLineField(
      TextEditingController controller, String hint, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: TextField(
        controller: controller,
        maxLength: 120,
        style: TextStyle(fontSize: 15, color: c.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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


