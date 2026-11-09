import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../../../core/design/app_design.dart';
import '../../../core/design/app_loader.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/widgets/animated_save_button.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/nl_task_parser.dart';
import '../../../core/utils/animation_prefs.dart';
import '../../share/share_with_friends_sheet.dart';
import '../../share/shared_hub_sheet.dart';
import '../../share/shared_item_editor_sheet.dart';
import '../../../models/share/shared_item_models.dart';
import '../viewmodel/tasks_habits_viewmodel.dart';

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

  // Görevler sekmesinde FAB'ın alt boşluğu: çekmece açılınca yukarı kayar.
  final ValueNotifier<double> _taskFabBottom = ValueNotifier<double>(92);

  bool get _showToggle => widget.mode == 'both';

  @override
  void initState() {
    super.initState();
    _tab = widget.mode == 'habits' ? 1 : 0;
  }

  @override
  void dispose() {
    _taskFabBottom.dispose();
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
              bottom: false,
              child: Column(
                children: [
                  // Not: tek-mod başlıkları artık sekmelerin kendi üst menüsünde
                  // (Görevler _headerBlock, Alışkanlıklar _habitsHeader).
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
                        ? _TasksTab(
                            viewModel: viewModel, fabBottom: _taskFabBottom)
                        : _HabitsTab(viewModel: viewModel),
                  ),
                ],
              ),
            ),
            floatingActionButton: ValueListenableBuilder<double>(
              valueListenable: _taskFabBottom,
              builder: (context, taskBottom, child) {
                // FAB cam alt menünün üstünde; Görevler'de çekmece açılınca
                // animasyonla yukarı kayar (hiçbir şeyin üstüne gelmez).
                return AnimatedPadding(
                  duration: AnimationPrefs.isOn
                      ? const Duration(milliseconds: 320)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  // Alışkanlıklar'da da Görevler'deki ferah boşluk (alt menüye
                  // yapışmasın). Görevler'de çekmece açılınca ayrıca yukarı kayar.
                  padding:
                      EdgeInsets.only(bottom: _tab == 0 ? taskBottom : 92),
                  child: child,
                );
              },
              child: _ThFab(
                onOpen: () => _tab == 0
                    ? showAddTaskSheet(context, viewModel, isDarkMode)
                    : showAddHabitSheet(context, viewModel, isDarkMode),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// FAB: dokununca + simgesi × olacak şekilde döner; ekleme sayfası açıkken döner.
class _ThFab extends StatefulWidget {
  final Future<void> Function() onOpen;
  const _ThFab({required this.onOpen});
  @override
  State<_ThFab> createState() => _ThFabState();
}

class _ThFabState extends State<_ThFab> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'th_fab',
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () async {
        setState(() => _open = true);
        await widget.onOpen();
        if (mounted) setState(() => _open = false);
      },
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
        child: AnimatedRotation(
          turns: (_open && AnimationPrefs.isOn) ? 0.125 : 0, // 45° → + yerine ×
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

// Kök katmana geçici bir overlay ekler (kutlama animasyonları için).
void _showRootOverlay(
    OverlayState overlay, Widget Function(VoidCallback remove) builder) {
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => builder(() {
        if (entry.mounted) entry.remove();
      }));
  overlay.insert(entry);
}

/// Alışkanlık tamamlanınca seri kutlaması: alev rozeti zıplayarak belirir,
/// kıvılcımlar saçılır, altında güncel seri (gün) yazar.
class _StreakCelebrationOverlay extends StatefulWidget {
  final int streak;
  final VoidCallback onDone;
  const _StreakCelebrationOverlay(
      {required this.streak, required this.onDone});
  @override
  State<_StreakCelebrationOverlay> createState() =>
      _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<_StreakCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const List<Offset> _sparks = [
    Offset(-72, -46),
    Offset(70, -38),
    Offset(-54, 42),
    Offset(60, 48),
    Offset(0, -78),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final appear = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
          final out = ((t - 0.82) / 0.18).clamp(0.0, 1.0);
          final flick = 1 + 0.05 * math.sin(t * 40);
          final sparkT = ((t - 0.28) / 0.34).clamp(0.0, 1.0);
          final sparkOp = math.sin(sparkT * math.pi).clamp(0.0, 1.0);
          return Center(
            child: Opacity(
              opacity: (1 - out).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: appear.clamp(0.0, 1.2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          for (final o in _sparks)
                            Transform.translate(
                              offset: Offset.lerp(Offset.zero, o,
                                  Curves.easeOut.transform(sparkT))!,
                              child: Opacity(
                                opacity: sparkOp,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFF4C06A),
                                  ),
                                ),
                              ),
                            ),
                          Transform.scale(
                            scale: flick,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: Alignment(0, -0.2),
                                  colors: [Color(0xFFFBE2B8), Color(0xFFF4A024)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x66E08C1E),
                                      blurRadius: 30,
                                      spreadRadius: 2),
                                ],
                              ),
                              child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.white,
                                  size: 62),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0893C),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'habits.streakN'
                            .tr(namedArgs: {'n': '${widget.streak}'}),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

/// Filtre menüsü öğesi: açılırken kademeli (soldan kayarak + belirerek) gelir.
class _MenuItemIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _MenuItemIn({required this.index, required this.child});
  @override
  State<_MenuItemIn> createState() => _MenuItemInState();
}

class _MenuItemInState extends State<_MenuItemIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    if (!AnimationPrefs.isOn) {
      _c.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: widget.index * 45), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset((1 - v) * 16, 0), child: child),
        );
      },
    );
  }
}

/// Tamamlanan görevin karttan çekmeceye uçan küçük kopyası (overlay).
/// Hafif bir yay çizip küçülerek ve solarak çekmecenin içine düşer.
class _FlyChip extends StatefulWidget {
  final Offset from;
  final Offset to;
  final String label;
  final Color accent;
  final VoidCallback onDone;
  const _FlyChip({
    required this.from,
    required this.to,
    required this.label,
    required this.accent,
    required this.onDone,
  });
  @override
  State<_FlyChip> createState() => _FlyChipState();
}

class _FlyChipState extends State<_FlyChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 620));
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInCubic);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        final dx = widget.from.dx + (widget.to.dx - widget.from.dx) * v;
        final hop = -32 * math.sin(v * math.pi); // ortada yukarı zıpla
        final dy =
            widget.from.dy + (widget.to.dy - widget.from.dy) * v + hop;
        final scale = 1.0 - 0.72 * v;
        final opacity =
            v < 0.15 ? 1.0 : (1.0 - (v - 0.15) / 0.85).clamp(0.0, 1.0);
        return Positioned(
          left: dx - 70,
          top: dy - 18,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: 0.12 * v,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF48BB78),
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3A3326)),
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
      },
    );
  }
}

/// Görev ekleme sayfasını açar.
/// Üst seviyede tutuluyor ki hem FAB hem de boş durum butonu aynı yeri açsın.
Future<void> showAddTaskSheet(
    BuildContext context, TasksHabitsViewModel viewModel, bool isDarkMode) {
  viewModel.resetTaskForm(); // temiz form + varsayılan bugün tarihi
  return showModalBottomSheet<void>(
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
Future<void> showAddHabitSheet(
    BuildContext context, TasksHabitsViewModel viewModel, bool isDarkMode) {
  return showModalBottomSheet<void>(
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
  // Backend enum değerlerini doğrudan eşle (gönderilen 4 alanın tersi).
  switch (c) {
    case 'social_relationships':
      return kLifeAreas[0]; // relationships
    case 'personal_development':
      return kLifeAreas[1]; // learning
    case 'other':
      return kLifeAreas[2]; // mind
    case 'health_fitness':
      return kLifeAreas[3]; // health
  }
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
  final String? selected; // seçili (filtrelenen) alan
  _AreaDonutPainter({
    required this.ratio,
    required this.hasHabits,
    required this.hole,
    this.selected,
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
      final filled = hasHabits[a.key] ?? false;
      final r = (ratio[a.key] ?? 0).clamp(0.0, 1.0);
      final isDone = filled && r >= 0.999;
      // Boş alan: soğuk/açık. Dolu alan: biraz koyu. Tamamlanınca daha koyu.
      final bg = !filled
          ? a.soft
          : (isDone
              ? Color.lerp(a.soft, a.main, 0.42)!
              : Color.lerp(a.soft, a.main, 0.16)!);
      canvas.drawArc(rect, start, sweep, true, Paint()..color = bg);
      // Seçili alan vurgusu — dilim kenarına ince parlak çizgi.
      if (selected == a.key) {
        canvas.drawArc(
            rect,
            start,
            sweep,
            true,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..color = a.main);
      }
      if (filled && r > 0) {
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
      // Tamamlanınca animasyonlu ✓ rozeti (son %20 dolarken büyür).
      final checkT = filled ? ((r - 0.8) / 0.2).clamp(0.0, 1.0) : 0.0;
      if (checkT > 0) {
        final midRad = (_starts[a.key]! + 45.0) * d2r;
        final cr = radius * 0.64;
        final pos = Offset(center.dx + cr * math.cos(midRad),
            center.dy + cr * math.sin(midRad));
        final badgeR = 13.0 * checkT;
        canvas.drawCircle(pos, badgeR + 2, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(pos, badgeR, Paint()..color = a.main);
        if (checkT > 0.25) {
          final s = badgeR;
          final path = Path()
            ..moveTo(pos.dx - s * 0.45, pos.dy + s * 0.02)
            ..lineTo(pos.dx - s * 0.1, pos.dy + s * 0.4)
            ..lineTo(pos.dx + s * 0.5, pos.dy - s * 0.38);
          canvas.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFFFFFFFF));
        }
      }
    }
    // Delik küçük tutulur ki renkli halka içe doğru uzasın ve çeyrek
    // etiketleri (aynı konumda) renkli alanın içinde kalsın.
    canvas.drawCircle(center, radius * 0.40, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(covariant _AreaDonutPainter old) =>
      old.ratio != ratio ||
      old.hasHabits != hasHabits ||
      old.hole != hole ||
      old.selected != selected;
}

/// Çeyrek-donut'u animasyonlu çizer: tamamlanma yayları eski orandan yeni
/// orana doğru büyüyerek dolar (ilk açılışta 0'dan). Alışkanlık işaretleyince
/// ilgili dilim yumuşakça dolar.
class _AnimatedAreaDonut extends StatefulWidget {
  final Map<String, double> ratio;
  final Map<String, bool> hasHabits;
  final Color hole;
  final String? selected;
  const _AnimatedAreaDonut({
    required this.ratio,
    required this.hasHabits,
    required this.hole,
    this.selected,
  });
  @override
  State<_AnimatedAreaDonut> createState() => _AnimatedAreaDonutState();
}

class _AnimatedAreaDonutState extends State<_AnimatedAreaDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Map<String, double> _from;
  late Map<String, double> _to;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _from = {for (final a in kLifeAreas) a.key: 0.0};
    _to = Map<String, double>.from(widget.ratio);
    if (AnimationPrefs.isOn) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  bool _sameRatios(Map<String, double> a, Map<String, double> b) {
    for (final k in a.keys) {
      if (((a[k] ?? 0) - (b[k] ?? 0)).abs() > 0.0001) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant _AnimatedAreaDonut old) {
    super.didUpdateWidget(old);
    if (!_sameRatios(old.ratio, widget.ratio)) {
      final t = _c.value;
      _from = {
        for (final a in kLifeAreas)
          a.key: (_from[a.key] ?? 0) +
              ((_to[a.key] ?? 0) - (_from[a.key] ?? 0)) * t
      };
      _to = Map<String, double>.from(widget.ratio);
      if (AnimationPrefs.isOn) {
        _c.forward(from: 0);
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final cur = {
          for (final a in kLifeAreas)
            a.key: (_from[a.key] ?? 0) +
                ((_to[a.key] ?? 0) - (_from[a.key] ?? 0)) * t
        };
        return CustomPaint(
          painter: _AreaDonutPainter(
              ratio: cur,
              hasHabits: widget.hasHabits,
              hole: widget.hole,
              selected: widget.selected),
        );
      },
    );
  }
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

class _HabitsTab extends StatefulWidget {
  final TasksHabitsViewModel viewModel;
  const _HabitsTab({required this.viewModel});
  @override
  State<_HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends State<_HabitsTab> {
  TasksHabitsViewModel get viewModel => widget.viewModel;

  // Seçili yaşam alanı (pasta diliminden) — null = tümü (sırayla listele).
  String? _selectedArea;
  // Alışkanlık arama metni (üst menüdeki arama ikonu).
  String _search = '';
  bool _searchOpen = false;

  // Alışkanlıklar modül aksanı + tamamlanan rengi — seçili temadan türetilir.
  Color get _orange => AppPalette.accent;
  Color get _green => AppPalette.success;

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
      return const Center(child: AppLoader());
    }

    final grouped = _grouped();
    final q = _search.trim().toLowerCase();
    bool matchSearch(Habit h) =>
        q.isEmpty || h.title.toLowerCase().contains(q);

    final filled =
        kLifeAreas.where((a) => grouped[a.key]!.any(matchSearch)).toList();
    // Seçili alan varsa yalnız onu göster; yoksa tüm dolu alanlar sırayla.
    final shown = _selectedArea == null
        ? filled
        : filled.where((a) => a.key == _selectedArea).toList();

    return RefreshIndicator(
      onRefresh: () => viewModel.loadHabits(),
      color: _orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
        children: [
          // Üst menü — notlardaki gibi: başlık + paylaşım + arama
          _habitsHeader(context, c),
          if (_searchOpen) ...[
            const SizedBox(height: 10),
            _habitSearchField(c),
          ],
          const SizedBox(height: 12),
          _areaDonutCard(c, grouped),
          const SizedBox(height: 14),
          if (_selectedArea != null) _activeFilterChip(c),
          for (final a in shown)
            for (final h in grouped[a.key]!.where(matchSearch))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _habitCard(context, c, h, a),
              ),
          // Boş alan "ekle" satırları kaldırıldı — ekleme yalnızca sağ-alt + ile.
        ],
      ),
    );
  }

  // ---------- Üst menü (başlık + paylaşım + arama) ----------
  Widget _habitsHeader(BuildContext context, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: Text('habits.title'.tr(),
              style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: c.isDark
                      ? ColorConstant.textPrimaryDark
                      : const Color(0xFF3A3326))),
        ),
        _hdrIcon(c, Icons.diversity_3_rounded,
            () => showSharedHubSheet(context, kind: 'habit')),
        const SizedBox(width: 8),
        _hdrIcon(c, _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            () => setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _search = '';
                })),
      ],
    );
  }

  Widget _hdrIcon(AppColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border.withOpacity(0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: c.textPrimary)),
      ),
    );
  }

  Widget _habitSearchField(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withOpacity(0.6)),
      ),
      child: TextField(
        autofocus: true,
        onChanged: (v) => setState(() => _search = v),
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: 'habits.searchHint'.tr(),
          hintStyle: TextStyle(color: c.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _activeFilterChip(AppColors c) {
    final area = kLifeAreas.firstWhere((a) => a.key == _selectedArea,
        orElse: () => kLifeAreas[0]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => setState(() => _selectedArea = null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: area.main.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(area.icon, size: 15, color: area.main),
                const SizedBox(width: 6),
                Text(area.labelKey.tr(),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: area.main)),
                const SizedBox(width: 6),
                Icon(Icons.close_rounded, size: 15, color: area.main),
              ],
            ),
          ),
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _onDonutTap(d.localPosition),
          child: SizedBox(
          width: 236,
          height: 236,
          child: Stack(
            children: [
              Positioned.fill(
                child: _AnimatedAreaDonut(
                    ratio: ratio,
                    hasHabits: hasH,
                    hole: c.card,
                    selected: _selectedArea),
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
      ),
    );
  }

  // Pasta diliminden alan seç/kaldır (merkezden açıya göre çeyrek).
  void _onDonutTap(Offset local) {
    const size = 236.0;
    final dx = local.dx - size / 2;
    final dy = local.dy - size / 2;
    final dist = math.sqrt(dx * dx + dy * dy);
    // Orta delik veya dış kenar dışında → yok say.
    if (dist < size / 2 * 0.42 || dist > size / 2) return;
    final key = dx < 0
        ? (dy < 0 ? 'relationships' : 'mind')
        : (dy < 0 ? 'learning' : 'health');
    setState(() => _selectedArea = _selectedArea == key ? null : key);
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

    final String sub;
    if (h.skippedToday) {
      sub = 'habits.skippedShort'.tr();
    } else if (streak > 0) {
      sub = '$cur/$goal · ${'habits.streakN'.tr(namedArgs: {'n': '$streak'})}';
    } else {
      sub = '$cur/$goal';
    }

    return GestureDetector(
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
              const SizedBox(width: 12),
              // ---- Checkbox: dokun = tamamla / artır ----
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final wasDone = viewModel.isHabitDoneToday(h);
                    final overlay = Overlay.of(context, rootOverlay: true);
                    await viewModel.tapHabit(h, context);
                    // Yeni tamamlandıysa seri kutlaması oynat.
                    if (!wasDone &&
                        AnimationPrefs.isOn &&
                        viewModel.isHabitDoneToday(h)) {
                      final fresh = viewModel.habits.firstWhere(
                          (x) => x.id == h.id,
                          orElse: () => h);
                      final streak = fresh.currentStreak > 0
                          ? fresh.currentStreak
                          : h.currentStreak + 1;
                      _showRootOverlay(
                        overlay,
                        (remove) => _StreakCelebrationOverlay(
                            streak: streak, onDone: remove),
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedSwitcher(
                    duration: AnimationPrefs.isOn
                        ? const Duration(milliseconds: 280)
                        : Duration.zero,
                    transitionBuilder: (ch, anim) =>
                        ScaleTransition(scale: anim, child: ch),
                    child: done
                        ? Container(
                            key: const ValueKey('h-done'),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _green,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                          )
                        : Container(
                            key: const ValueKey('h-todo'),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: area.main, width: 2),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.labelKey.tr(),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: area.main)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(h.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        done ? c.textMuted : c.textPrimary,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null)),
                          ),
                          // Paylaşımlı alışkanlık rozeti (notlardaki gibi).
                          if (h.sharedHabitId != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _orange,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.group_rounded,
                                  size: 11, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: done ? _green : c.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ---- Geçmiş ısı haritası / menü ikonu ----
              // Dokununca uzun-bas menüsünü açar (geçmiş, düzenle, atla, sil).
              Center(
                child: GestureDetector(
                  onTap: () => _habitMenu(context, c, h),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 12),
                    child: Icon(Icons.grid_view_rounded,
                        size: 20, color: c.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Boş yaşam alanı istemi ----------
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
              leading: Icon(Icons.grid_view_rounded, color: _orange),
              title: Text('habits.history'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showHabitHistory(context, c, h);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: _orange),
              title: Text('common.edit'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showEditHabitSheet(context, viewModel, c.isDark, h);
              },
            ),
            ListTile(
              leading: Icon(Icons.group_add_rounded, color: _orange),
              title: Text('share.shareWithFriend'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              subtitle: Text('share.canEdit'.tr() + ' / ' + 'share.viewOnly'.tr(),
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                // Yeni arkadaş-davet modeli (ortak alışkanlık + ısı haritası).
                showShareWithFriendsSheet(context, kind: 'habit', itemId: h.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.diversity_3_rounded, color: _orange),
              title: Text('share.sharedWithMe'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showSharedHubSheet(context, kind: 'habit');
              },
            ),
            if (!viewModel.isHabitDoneToday(h) && !h.skippedToday)
              ListTile(
                leading: Icon(Icons.fast_forward_rounded, color: _orange),
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

  // Not: Eski kod-tabanlı alışkanlık paylaşımı (katılım kodu) kaldırıldı.
  // Artık notlar/görevler gibi arkadaş-davet modeli kullanılıyor
  // (showShareWithFriendsSheet / showSharedHubSheet, kind: 'habit').

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

class _HabitHistorySheetState extends State<_HabitHistorySheet>
    with SingleTickerProviderStateMixin {
  static const int _weeks = 8;
  bool _loading = true;
  HabitStats? _stats;
  final Map<String, int> _status = {}; // 1 yapıldı, 2 atlandı
  final Map<String, String> _notes = {};
  late final AnimationController _reveal; // ısı haritası hücre girişi

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _load();
  }

  @override
  void dispose() {
    _reveal.dispose();
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
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
      // Veri gelince ısı haritası hücreleri kademeli belirir.
      if (AnimationPrefs.isOn) {
        _reveal.forward(from: 0);
      } else {
        _reveal.value = 1;
      }
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
      return AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) {
          final rev = _reveal.value;
          final cols = <Widget>[];
          for (var w = 0; w < _weeks; w++) {
            // Sütun sütun (haftalar) soldan sağa kademeli belirir.
            final start = (w / _weeks) * 0.55;
            final v = Curves.easeOut
                .transform(((rev - start) / 0.45).clamp(0.0, 1.0));
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
                child: Opacity(
                  opacity: v,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * v,
                    child: Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(3),
                          border: bd),
                    ),
                  ),
                ),
              ));
            }
            cols.add(Column(children: cells));
          }
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: cols);
        },
      );
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

class _TasksTab extends StatefulWidget {
  final TasksHabitsViewModel viewModel;
  final ValueNotifier<double> fabBottom;
  const _TasksTab({required this.viewModel, required this.fabBottom});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  TasksHabitsViewModel get viewModel => widget.viewModel;

  // Filtre: all | recurring | daily | weekly | monthly | once | high
  String _filter = 'all';
  bool _taskSearchOpen = false; // üst menü arama ikonu

  // Açık bölümler (varsayılan hepsi AÇIK).
  final Set<String> _expandedSections = {'overdue', 'today', 'upcoming'};
  // Her bölümün sayfa indeksi (2 sütun × 3 satır = sayfa başı 6 görev).
  final Map<String, int> _sectionPage = {};

  // === Pano: "Tamamlanan görevler" çekmecesi ===
  bool _drawerOpen = false;
  final GlobalKey _cavityKey = GlobalKey(); // uçuş hedefi (çekmece içi)
  final Set<int> _flyingTaskIds = {}; // uçarken karttaki kopyayı gizle
  int _drawerCloseToken = 0; // otomatik kapanmayı iptal için

  // Aktif filtreye göre görevi gösterelim mi?
  bool _matchesFilter(Task t) {
    switch (_filter) {
      case 'recurring':
        return t.isRecurring;
      case 'daily':
        return t.isRecurring && t.recurringPattern == 'daily';
      case 'weekly':
        return t.isRecurring && t.recurringPattern == 'weekly';
      case 'monthly':
        return t.isRecurring && t.recurringPattern == 'monthly';
      case 'once':
        return !t.isRecurring;
      case 'high':
        return t.priority == 2;
      default:
        return true;
    }
  }

  // Filtre etiketleri (değer -> çeviri anahtarı).
  static const List<List<String>> _filters = [
    ['all', 'tasks.scopeAll'],
    ['recurring', 'tasks.filterRecurring'],
    ['daily', 'tasks.recurrence.daily'],
    ['weekly', 'tasks.recurrence.weekly'],
    ['monthly', 'tasks.recurrence.monthly'],
    ['once', 'tasks.recurrence.once'],
    ['high', 'tasks.filterHighPriority'],
  ];
  String get _filterLabelKey =>
      _filters.firstWhere((f) => f[0] == _filter, orElse: () => _filters[0])[1];

  // Modül + semantik renkleri artık seçili temadan türetilir (soft/uyumlu).
  // _orange = modül aksanı (bugün), _purple = yaklaşan, _red = gecikmiş,
  // _green = tamamlanan. Hepsi temaya göre otomatik değişir.
  Color get _orange => AppPalette.accent;
  Color get _purple => AppPalette.accentCool;
  Color get _red => AppPalette.danger;
  Color get _green => AppPalette.success;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);

    if (viewModel.isLoading && viewModel.tasks.isEmpty) {
      return const Center(child: AppLoader());
    }

    final searching =
        _taskSearchOpen || viewModel.taskSearch.trim().isNotEmpty;
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
    return _sectionsLayout(context, c, isDark);
  }

  // ==================== BÖLÜMLÜ GÖRÜNÜM (Gecikmiş / Bugün / Yakında) ====================
  Widget _sectionsLayout(BuildContext context, AppColors c, bool isDark) {
    // Tek kaynak sınıflandırma (VM) + aktif filtre (ayrık gruplar).
    final overdue =
        viewModel.pastOverdueTasks.where(_matchesFilter).toList();
    final todayOpen = viewModel.todayTasks.where(_matchesFilter).toList();
    // Yaklaşan = ileri tarihli + tarihsiz görevler (3 bölüm: Gecikmiş/Bugün/Yaklaşan).
    final upcoming = [
      ...viewModel.upcomingTasksList.where(_matchesFilter),
      ...viewModel.undatedTasks.where(_matchesFilter),
    ];
    final completed =
        viewModel.completedTasksList.where(_matchesFilter).toList();

    // Ana ekranın cam alt menüsü (extendBody) içeriğin altını kaplıyor:
    // çekmece ve liste bu kadar yukarıdan başlasın.
    final navClear = MediaQuery.of(context).viewPadding.bottom + 70;

    final list = RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      color: _orange,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 2, 20, navClear + 80),
        children: [
          _headerBlock(c),
          const SizedBox(height: 14),
          _filterRow(context, c, isDark),
          const SizedBox(height: 18),
          // Benimle paylaşılan görevler.
          if (viewModel.sharedWithMeTasks.isNotEmpty) ...[
            _sharedTasksStrip(context, c),
            const SizedBox(height: 18),
          ],
          _sectionRail(
            context,
            c,
            sectionKey: 'overdue',
            title: 'tasks.allOverdue'.tr(),
            tasks: overdue,
            accent: _red,
            emptyText: 'tasks.allEmpty'.tr(),
            trailing: overdue.length >= 2 ? _bulkMoveBtn(context) : null,
          ),
          _sectionRail(
            context,
            c,
            sectionKey: 'today',
            title: 'tasks.allToday'.tr(),
            tasks: todayOpen,
            accent: _orange,
            emptyText: 'tasks.todayEmptyHint'.tr(),
          ),
          _sectionRail(
            context,
            c,
            sectionKey: 'upcoming',
            title: 'tasks.upcomingSection'.tr(),
            tasks: upcoming,
            accent: _purple,
            emptyText: 'tasks.upcomingEmpty'.tr(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: list),
        Positioned(
          left: 12,
          right: 12,
          // Alt menüden biraz daha yukarı: kapak yazısı rahat okunsun.
          bottom: navClear + 18,
          child: _completedDrawer(context, c, completed),
        ),
      ],
    );
  }

  // Bölüm: renkli hap + yatay ray. AÇILIR-KAPANIR (varsayılan KAPALI):
  // hapa dokununca açılır/kapanır; içinde aynı anda ~3 kart, gerisi için kaydır.
  Widget _sectionRail(
    BuildContext context,
    AppColors c, {
    required String sectionKey,
    required String title,
    required List<Task> tasks,
    required Color accent,
    String? emptyText,
    Widget? trailing,
  }) {
    final expanded = _expandedSections.contains(sectionKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (expanded) {
                _expandedSections.remove(sectionKey);
              } else {
                _expandedSections.add(sectionKey);
              }
            }),
            child: Row(
              children: [
                _pill(title, tasks.length, accent),
                const Spacer(),
                if (expanded && tasks.length > 3)
                  Icon(Icons.swipe_rounded, size: 17, color: c.textMuted),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: AnimationPrefs.isOn
                      ? const Duration(milliseconds: 240)
                      : Duration.zero,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22, color: c.textMuted),
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: AnimationPrefs.isOn
                  ? const Duration(milliseconds: 240)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 11),
                        if (tasks.isEmpty)
                          _sectionEmpty(
                              c, emptyText ?? 'tasks.allEmpty'.tr())
                        else
                          _sectionGrid(context, c, sectionKey, tasks, accent),
                        if (trailing != null) ...[
                          const SizedBox(height: 10),
                          trailing,
                        ],
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  // 2 sütun × en çok 3 satır (sayfa başı 6 görev); fazlaysa sayfalama.
  Widget _sectionGrid(BuildContext context, AppColors c, String sectionKey,
      List<Task> tasks, Color accent) {
    const perPage = 6;
    final pageCount = (tasks.length / perPage).ceil();
    int page = _sectionPage[sectionKey] ?? 0;
    if (page > pageCount - 1) page = pageCount - 1;
    if (page < 0) page = 0;
    final slice = tasks.skip(page * perPage).take(perPage).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 98,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slice.length,
          itemBuilder: (_, i) => _gridTaskCard(context, c, slice[i], accent),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 10),
          _gridPager(c, sectionKey, page, pageCount, accent),
        ],
      ],
    );
  }

  Widget _gridPager(
      AppColors c, String sectionKey, int page, int pageCount, Color accent) {
    Widget arrow(IconData ic, bool on, VoidCallback onTap) => InkWell(
          onTap: on ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(ic,
                size: 22,
                color: on ? accent : c.textMuted.withValues(alpha: 0.4)),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        arrow(Icons.chevron_left_rounded, page > 0,
            () => setState(() => _sectionPage[sectionKey] = page - 1)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999)),
          child: Text('${page + 1} / $pageCount',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
        ),
        arrow(Icons.chevron_right_rounded, page < pageCount - 1,
            () => setState(() => _sectionPage[sectionKey] = page + 1)),
      ],
    );
  }

  // Detaylı görev kartı (ızgarada): başlık + öncelik + alt görev + tarih + tamamla.
  Widget _gridTaskCard(
      BuildContext context, AppColors c, Task task, Color accent) {
    final flying = _flyingTaskIds.contains(task.id);
    final subs = viewModel.subtasksOf(task.id);
    final subDone = subs.where((s) => s.isCompleted).length;
    final pr = task.priority;
    final prColor = pr == 2 ? _red : (pr == 1 ? _orange : c.info);
    final prKey =
        'tasks.priority.${pr == 2 ? 'high' : pr == 0 ? 'low' : 'medium'}';
    final sub = _railSubtitle(task);
    return Opacity(
      opacity: flying ? 0 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withValues(alpha: 0.7)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showEditTaskSheet(context, viewModel, c.isDark, task),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: accent),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _miniTag(prKey.tr(), prColor),
                      if (subs.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _miniIconTag(Icons.checklist_rounded,
                            '$subDone/${subs.length}', c.textMuted),
                      ],
                      const Spacer(),
                      Builder(
                        builder: (ctx) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _completeWithAnim(ctx, task, accent),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.border, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7)),
        child: Text(text,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _miniIconTag(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(text,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      );

  Widget _pill(String title, int count, Color accent) {
    // Koyu/doygun hap yerine SOFT tint: açık aksan zemini + aksan metin.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1),
          ),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 17),
            height: 17,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.30 : 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  String _railSubtitle(Task task) {
    final od = _overdueLabel(task);
    if (od != null) return od;
    final tl = _timeLabel(task);
    if (tl != null) return tl;
    final d = viewModel.dueDateOf(task);
    if (d != null) return '${d.day}.${d.month}';
    return 'tasks.allUndated'.tr();
  }

  // ===== Tamamlanan görevler: gerçek (öne açılan) çekmece =====
  // Çekmece açık yüksekliği (en az 2, en çok 3 satır not + kapak/kulp).
  static const double _drawerOpenHeight = 256;

  Widget _completedDrawer(
      BuildContext context, AppColors c, List<Task> completed) {
    final open = _drawerOpen;
    final isDark = c.isDark;
    return SizedBox(
      height: _drawerOpenHeight,
      child: Stack(
        children: [
          // İç göz — ön kapak öne devrilince görünür.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 44,
            child: IgnorePointer(
              ignoring: !open,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: AnimationPrefs.isOn
                    ? const Duration(milliseconds: 260)
                    : Duration.zero,
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: open ? 1 : 0.96,
                  alignment: Alignment.bottomCenter,
                  duration: AnimationPrefs.isOn
                      ? const Duration(milliseconds: 300)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  child: _drawerInside(context, c, completed, isDark),
                ),
              ),
            ),
          ),
          // Ön kapak — dokununca aç/kapat.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _drawerLid(context, c, completed.length, open, isDark),
          ),
        ],
      ),
    );
  }

  Widget _drawerInside(
      BuildContext context, AppColors c, List<Task> completed, bool isDark) {
    // Çekmece içi — seçili temaya uyumlu soft yüzey (karta aksanlı hafif tint).
    final woodIn = Color.alphaBlend(
        c.accent.withValues(alpha: isDark ? 0.10 : 0.12), c.card);
    final woodBr = c.border;
    final grip = c.textMuted;
    return Container(
      key: _cavityKey,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 22),
      decoration: BoxDecoration(
        color: woodIn,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: woodBr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kapatma kulpu — çekmeceyi kapatır (dönüşmeyen alanda, her zaman tıklanır).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleDrawer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                        color: grip, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: grip),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: completed.isEmpty
                ? Center(
                    child: Text('tasks.allEmpty'.tr(),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                  )
                : _doneColumns(context, c, completed),
          ),
        ],
      ),
    );
  }

  // Tamamlananlar: 2 SATIRLI yatay grid — aynı anda ~3 sütun görünür
  // (1 satırda en çok 3 not), diğerleri için YANA kaydırılır.
  Widget _doneColumns(BuildContext context, AppColors c, List<Task> completed) {
    final items =
        completed.length > 30 ? completed.sublist(0, 30) : completed;
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 satır (yatay kaydırmada çapraz eksen = satır)
        mainAxisExtent: 126, // her hücrenin genişliği → ~3 sütun görünür
        crossAxisSpacing: 8, // satırlar arası dikey boşluk
        mainAxisSpacing: 8, // sütunlar arası yatay boşluk
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _doneChip(context, c, items[i], i),
    );
  }

  // Tamamlanan görev — dağınık not kağıdı (hafif eğik). Dokununca düzenle/
  // yeniden planla sayfası açılır. Yeşil onay normal görevlerdeki gibi (22px dolu).
  Widget _doneChip(BuildContext context, AppColors c, Task t, int i) {
    final angle = (((t.id.hashCode % 7) - 3) / 3.0) * 0.05;
    // Tamamlanan not kağıdı — seçili temaya uyumlu açık yüzey.
    final paper = Color.alphaBlend(
        c.accent.withValues(alpha: c.isDark ? 0.06 : 0.05), c.card);
    return Transform.rotate(
      angle: angle,
      child: InkWell(
        onTap: () => showEditTaskSheet(context, viewModel, c.isDark, t),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 5,
                  offset: const Offset(1, 3)),
            ],
          ),
          child: Row(
            children: [
              // Normal görevlerdeki onay dairesi gibi (22px), tamamlandı = dolu yeşil.
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _green),
                child: const Icon(Icons.check_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerLid(
      BuildContext context, AppColors c, int count, bool open, bool isDark) {
    // Çekmece kapağı — seçili temaya uyumlu soft yüzey (aksanlı hafif tint).
    final lid1 = Color.alphaBlend(
        c.accent.withValues(alpha: isDark ? 0.12 : 0.14), c.card);
    final lid2 = Color.alphaBlend(
        c.accent.withValues(alpha: isDark ? 0.18 : 0.22), c.card);
    final woodBr = c.border;
    final grip = c.textMuted;
    return GestureDetector(
      onTap: _toggleDrawer,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: open ? 1.0 : 0.0),
        duration: AnimationPrefs.isOn
            ? const Duration(milliseconds: 380)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, v, child) {
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0013)
              ..rotateX(-1.2 * v),
            child: child,
          );
        },
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [lid1, lid2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: woodBr),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.14),
                blurRadius: 14,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Çekmece kulpu — tutup aç/kapa (gerçek çekmece tutamağı gibi).
              Container(
                width: 48,
                height: 7,
                margin: const EdgeInsets.only(top: 6, bottom: 5),
                decoration: BoxDecoration(
                  color: grip,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              Padding(
                // Sağda + FAB var; sayaç/ok onun altına girmesin diye sağ boşluk.
                padding: const EdgeInsets.fromLTRB(15, 0, 72, 0),
                child: Row(
                  children: [
                    Icon(Icons.dns_rounded, size: 19, color: _green),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'tasks.allCompleted'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _green)),
                    ),
                    const SizedBox(width: 6),
                    // Aç/kapa göstergesi: kapalıyken ▲ (aç), açıkken ▼ (kapat).
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: AnimationPrefs.isOn
                          ? const Duration(milliseconds: 300)
                          : Duration.zero,
                      child: Icon(Icons.keyboard_arrow_up_rounded,
                          size: 22, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Çekmece açıkken FAB'ı çekmecenin üstüne kaydır (hiçbir şeyin üstüne gelmez).
  void _syncFabBottom() {
    if (!mounted) return;
    final navClear = MediaQuery.of(context).viewPadding.bottom + 70;
    widget.fabBottom.value =
        _drawerOpen ? (navClear + _drawerOpenHeight + 10) : 92.0;
  }

  void _toggleDrawer() {
    _drawerCloseToken++;
    setState(() => _drawerOpen = !_drawerOpen);
    _syncFabBottom();
  }

  void _scheduleDrawerClose() {
    final token = ++_drawerCloseToken;
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _drawerCloseToken == token && _drawerOpen) {
        setState(() => _drawerOpen = false);
        _syncFabBottom();
      }
    });
  }

  // Görevi tamamla + karttan çekmeceye uçan animasyon.
  void _completeWithAnim(BuildContext tapCtx, Task task, Color accent) {
    if (!AnimationPrefs.isOn) {
      viewModel.toggleTaskComplete(task, context);
      return;
    }
    final box = tapCtx.findRenderObject() as RenderBox?;
    final cavity = _cavityKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context);
    if (box == null || !box.attached || cavity == null) {
      viewModel.toggleTaskComplete(task, context);
      return;
    }
    final from = box.localToGlobal(box.size.center(Offset.zero));
    final to = cavity.localToGlobal(cavity.size.center(Offset.zero));
    setState(() {
      _drawerOpen = true;
      _flyingTaskIds.add(task.id);
    });
    _syncFabBottom();
    _drawerCloseToken++; // açılışı sabit tut
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyChip(
        from: from,
        to: to,
        label: task.title,
        accent: accent,
        onDone: () {
          if (entry.mounted) entry.remove();
          if (!mounted) return;
          setState(() => _flyingTaskIds.remove(task.id));
          viewModel.toggleTaskComplete(task, context);
          _scheduleDrawerClose();
        },
      ),
    );
    overlay.insert(entry);
  }

  // Tarih + "Görevler" + "X / Y tamam".
  // Notlardaki gibi yuvarlak üst-menü ikon butonu.
  Widget _headerIcon(AppColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.05),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 21, color: c.textSecondary),
        ),
      ),
    );
  }

  Widget _headerBlock(AppColors c) {
    final now = DateTime.now();
    final days = 'calendar.dayNames'.tr().split(',');
    final months = 'calendar.monthNames'.tr().split(',');
    final dayName =
        (now.weekday >= 1 && now.weekday <= days.length) ? days[now.weekday - 1] : '';
    final monthName =
        (now.month >= 1 && now.month <= months.length) ? months[now.month - 1] : '';
    final dateStr = '$dayName, ${now.day} $monthName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateStr,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: c.textSecondary)),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('tasks.title'.tr(),
                style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: c.isDark
                        ? ColorConstant.textPrimaryDark
                        : const Color(0xFF3A3326))),
            const Spacer(),
            // Paylaşım + Arama — notlardaki gibi en sağda (yuvarlak).
            _headerIcon(c, Icons.diversity_3_rounded,
                () => showSharedHubSheet(context, kind: 'task')),
            const SizedBox(width: 8),
            _headerIcon(c, Icons.search_rounded, () {
              widget.fabBottom.value = 92;
              setState(() => _taskSearchOpen = true);
            }),
          ],
        ),
      ],
    );
  }

  // Kapsam seçici + "Tüm Görevler" + "+" .
  Widget _filterRow(BuildContext context, AppColors c, bool isDark) {
    return Row(
      children: [
        _filterChip(c),
        const SizedBox(width: 10),
        Expanded(child: _allTasksBtn(context, isDark)),
      ],
    );
  }

  // Tekrarlama/öncelik bazlı filtre seçici (default "Tümü").
  Widget _filterChip(AppColors c) {
    final active = _filter != 'all';
    return PopupMenuButton<String>(
      onSelected: (v) => setState(() => _filter = v),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (var i = 0; i < _filters.length; i++)
          PopupMenuItem(
            value: _filters[i][0],
            child: _MenuItemIn(
              index: i,
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: _filters[i][0] == _filter
                        ? Icon(Icons.check_rounded,
                            size: 18, color: _orange)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(_filters[i][1].tr()),
                ],
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? _orange.withOpacity(0.12) : c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active
                  ? _orange.withOpacity(0.5)
                  : c.border.withOpacity(0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                size: 18, color: active ? _orange : c.textMuted),
            const SizedBox(width: 6),
            Text(_filterLabelKey.tr(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? _orange : c.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _allTasksBtn(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _openAllTasks(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: _orange),
            const SizedBox(width: 6),
            Flexible(
              child: Text('tasks.allTitle'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _orange)),
            ),
          ],
        ),
      ),
    );
  }

  // Gecikmiş bölümünde (2+ görev) tüm gecikenleri bugüne taşır.
  Widget _bulkMoveBtn(BuildContext context) => GestureDetector(
        onTap: () => viewModel.carryOverdueToToday(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('tasks.planner.moveOverdue'.tr(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _orange)),
        ),
      );

  Widget _sectionEmpty(AppColors c, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5, height: 1.4, color: c.textSecondary)),
      );

  // Liste tonları ("Tüm Görevler" sayfası + görev satırı).
  static const _ink = Color(0xFF4A3F2E);
  static const _inkMuted = Color(0xFF9B8A6E);

  // ---------- Tüm Görevler sayfası (gruplu) ----------
  void _openAllTasks(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: Consumer<TasksHabitsViewModel>(
          builder: (ctx, vm, _) {
            // Ana ekranla aynı tek kaynak sınıflandırma.
            final overdue = vm.pastOverdueTasks;
            final todayList = vm.todayTasks;
            final upcoming = vm.upcomingTasksList;
            final undated = vm.undatedTasks;
            final completed = vm.completedTasksList;
            final groups = <List<dynamic>>[
              ['tasks.allOverdue', overdue, true],
              ['tasks.allToday', todayList, false],
              ['tasks.allUpcoming', upcoming, false],
              ['tasks.allUndated', undated, false],
              ['tasks.allCompleted', completed, false],
            ];
            final anything = groups.any((g) => (g[1] as List).isNotEmpty);
            return Scaffold(
              backgroundColor: c.bg,
              appBar: AppBar(
                backgroundColor: c.bg,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                foregroundColor: _ink,
                title: Text('tasks.allTitle'.tr(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              body: !anything
                  ? Center(
                      child: Text('tasks.allEmpty'.tr(),
                          style: TextStyle(color: _inkMuted)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (final g in groups)
                          if ((g[1] as List<Task>).isNotEmpty)
                            _allGroupCard(ctx, isDark, (g[0] as String).tr(),
                                g[1] as List<Task>, g[2] as bool),
                      ],
                    ),
            );
          },
        ),
      ),
    ));
  }

  Widget _allGroupCard(BuildContext context, bool isDark, String title,
      List<Task> tasks, bool overdue) {
    final c = AppColors(isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBB89A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              Text('${tasks.length}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _inkMuted)),
            ],
          ),
          const SizedBox(height: 6),
          for (final t in tasks)
            _taskLine(context, isDark, t,
                overdue: overdue, showDelete: true),
        ],
      ),
    );
  }

  Widget _taskLine(BuildContext context, bool isDark, Task t,
      {bool overdue = false, bool showDelete = false}) {
    final mark = t.isCompleted ? '×' : (overdue || t.isOverdue ? '!' : '·');
    final color =
        t.isCompleted ? _green : (overdue || t.isOverdue ? _red : _ink);
    String trailing = '';
    if (overdue && t.dueDate != null) {
      final d = DateTime.tryParse(t.dueDate!);
      if (d != null) trailing = ' — ${d.day}.${d.month}';
    }
    // Sol işaret: dokun = tamamla/geri al. Başlık ve kalem: dokun = düzenle.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => viewModel.toggleTaskComplete(t, context),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 22,
              child: Text(mark,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => showEditTaskSheet(context, viewModel, isDark, t),
              behavior: HitTestBehavior.opaque,
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
          ),
          GestureDetector(
            onTap: () => showEditTaskSheet(context, viewModel, isDark, t),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 1),
              child: Icon(Icons.edit_outlined,
                  size: showDelete ? 18 : 15,
                  color: showDelete ? _orange : _inkMuted.withOpacity(0.7)),
            ),
          ),
          if (showDelete)
            GestureDetector(
              onTap: () => _confirmDelete(context, AppColors(isDark), t),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 12, top: 1),
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFE53E3E)),
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
          GestureDetector(
            onTap: () {
              viewModel.setTaskSearch('');
              setState(() => _taskSearchOpen = false);
            },
            child: Icon(Icons.close_rounded, size: 20, color: c.textMuted),
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
  /// Benimle paylaşılan görevler — yatay şerit.
  Widget _sharedTasksStrip(BuildContext context, AppColors c) {
    final items = viewModel.sharedWithMeTasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.group_rounded,
                  size: 16, color: ColorConstant.accentOrange),
              const SizedBox(width: 6),
              Text('share.sharedWithMe'.tr(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
            ],
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _sharedWithMeTaskCard(context, c, items[i]),
          ),
        ),
      ],
    );
  }

  Widget _sharedWithMeTaskCard(
      BuildContext context, AppColors c, SharedTaskItem item) {
    final doneCount = item.participants.where((p) => p.isCompleted).length;
    final total = item.participants.length;
    return SizedBox(
      width: 170,
      child: GestureDetector(
        onTap: () async {
          await showSharedTaskEditor(context, item: item);
          viewModel.loadSharedTasksInfo();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: ColorConstant.accentOrange.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item.task?.title ?? '').isNotEmpty
                    ? item.task!.title
                    : '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary),
              ),
              const Spacer(),
              Text(
                '${item.owner?.name ?? '—'} · $doneCount/$total ✓',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        child: AnimatedSwitcher(
                          duration: AnimationPrefs.isOn
                              ? const Duration(milliseconds: 280)
                              : Duration.zero,
                          transitionBuilder: (ch, anim) =>
                              ScaleTransition(scale: anim, child: ch),
                          child: done
                              ? Icon(Icons.check_circle_rounded,
                                  key: const ValueKey('t-done'),
                                  size: 26,
                                  color: _green)
                              : Container(
                                  key: const ValueKey('t-todo'),
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
                    if (viewModel.isTaskShared(task.id))
                      Padding(
                        padding: const EdgeInsets.only(right: 2, top: 2),
                        child: Icon(Icons.group_rounded,
                            size: 16, color: ColorConstant.accentOrange),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
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
        } else if (v == 'share') {
          showShareWithFriendsSheet(context, kind: 'task', itemId: task.id);
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
          value: 'share',
          child: Row(children: [
            const Icon(Icons.group_add_rounded, size: 20),
            const SizedBox(width: 12),
            Text('share.shareWithFriend'.tr()),
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

  // Editör aksanı — seçili temadan (not editörüyle tutarlı).
  Color get _accent => ColorConstant.accentOrange;

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
          _row(c, Icons.calendar_month_rounded, ColorConstant.accentOrange,
              'tasks.rowDateTime'.tr(), _dateLabel(vm),
              onTap: () => _pickDate(context, vm)),
          _divider(c),
          _row(c, Icons.flag_rounded, const Color(0xFFF6524B),
              'tasks.rowPriority'.tr(), null,
              trailing: _priorityPill(vm),
              onTap: () => _showPriority(context, vm, c)),
          _divider(c),
          _row(c, Icons.folder_rounded, ColorConstant.accentOrange,
              'tasks.rowCategory'.tr(), null,
              trailing: _categoryPill(vm, c),
              onTap: () => _showCategory(context, vm, c)),
          _divider(c),
          _row(c, Icons.repeat_rounded, ColorConstant.accentOrange,
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
                Icon(Icons.add_rounded, size: 18, color: _accent),
                const SizedBox(width: 2),
                Text('tasks.addSubtask'.tr(),
                    style: TextStyle(
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
                        Icon(Icons.add_rounded, size: 18, color: _accent),
                        const SizedBox(width: 6),
                        Text('tasks.newSubtask'.tr(),
                            style: TextStyle(
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
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      size: 22, color: _accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      vm.reminderEnabled
                          ? (vm.reminderTime != null
                              ? 'tasks.reminderAtTime'.tr(namedArgs: {
                                  'time': _fmtTod(vm.reminderTime!)
                                })
                              : 'tasks.reminderBeforeMinutes'.tr(namedArgs: {
                                  'n': '${vm.reminderBeforeMinutes}'
                                }))
                          : 'tasks.reminderOff'.tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary),
                    ),
                  ),
                  Switch(
                    value: vm.reminderEnabled,
                    activeColor: _accent,
                    onChanged: vm.setReminderEnabled,
                  ),
                ],
              ),
              // Mod seçimi: "X dk önce" veya belirli "Saat".
              if (vm.reminderEnabled) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 36),
                    _reminderModeChip(
                      c,
                      icon: Icons.timelapse_rounded,
                      label: 'tasks.reminderBeforeMinutes'
                          .tr(namedArgs: {'n': '${vm.reminderBeforeMinutes}'}),
                      active: vm.reminderTime == null,
                      onTap: () {
                        vm.setReminderTime(null);
                        _showMinutes(context, vm, c);
                      },
                    ),
                    const SizedBox(width: 8),
                    _reminderModeChip(
                      c,
                      icon: Icons.schedule_rounded,
                      label: vm.reminderTime != null
                          ? _fmtTod(vm.reminderTime!)
                          : 'tasks.reminderPickTime'.tr(),
                      active: vm.reminderTime != null,
                      onTap: () => _pickReminderTime(context, vm),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _reminderModeChip(AppColors c,
      {required IconData icon,
      required String label,
      required bool active,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? _accent.withOpacity(0.55) : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? _accent : c.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? _accent : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderTime(
      BuildContext context, TasksHabitsViewModel vm) async {
    final t = await showTimePicker(
      context: context,
      initialTime: vm.reminderTime ?? TimeOfDay.now(),
    );
    if (t != null) vm.setReminderTime(t);
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
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Builder(builder: (_) {
              final reschedule = isEditing && vm.editingTaskCompleted;
              return AnimatedSaveButton(
                color: reschedule ? const Color(0xFF48BB78) : _accent,
                height: 54,
                enabled: !vm.isLoading,
                icon: reschedule
                    ? Icons.event_repeat_rounded
                    : Icons.check_rounded,
                label: reschedule
                    ? 'tasks.reschedule'.tr()
                    : 'tasks.saveTask'.tr(),
                onPressed: () => isEditing
                    ? vm.updateTask(context, reschedule: reschedule)
                    : vm.createTask(context),
              );
            }),
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
                    ? Icon(Icons.check_rounded, color: _accent)
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
                style: TextStyle(color: _accent)),
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

  // Editör aksanı — seçili temadan (not editörüyle tutarlı).
  Color get _accent => ColorConstant.accentOrange;

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
                        // Gün seçici yalnızca "Özel" tekrarda anlamlı; diğer
                        // modlarda pasif/boş görünüp kafa karıştırıyordu.
                        if (vm.habitRecurrence == 'custom') ...[
                          const SizedBox(height: 12),
                          _weekdayRow(vm, c),
                        ],
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
                    ? Icon(Icons.check_rounded, color: _accent)
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
                  _timeChip(
                    c,
                    _fmt(vm.habitReminderTimes[i]),
                    () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: vm.habitReminderTimes[i]);
                      if (t != null) vm.updateHabitReminderTimeAt(i, t);
                    },
                    () => vm.removeHabitReminderTimeAt(i),
                  ),
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

  Widget _timeChip(
      AppColors c, String label, VoidCallback onEdit, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Etikete dokununca saati düzenle.
          GestureDetector(
            onTap: onEdit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 13, color: _accent),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _accent)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: _accent),
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
            Icon(Icons.add_rounded, size: 16, color: _accent),
            const SizedBox(width: 4),
            Text('habits.addReminderTime'.tr(),
                style: TextStyle(
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
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AnimatedSaveButton(
              color: _accent,
              height: 54,
              enabled: !vm.isLoading,
              label: 'habits.saveHabit'.tr(),
              onPressed: () =>
                  isEditing ? vm.updateHabit(context) : vm.createHabit(context),
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
                    ? Icon(Icons.check_rounded, color: _accent)
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


