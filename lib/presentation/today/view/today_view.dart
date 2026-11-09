import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/speed_dial_fab.dart';
import '../../../models/task/task_models.dart';
import '../../../models/habit/habit_models.dart';
import '../viewmodel/notifications_viewmodel.dart';
import '../widgets/notification_bell.dart';
import '../../tasks_habits/viewmodel/tasks_habits_viewmodel.dart';
import '../../tasks_habits/view/tasks_habits_view.dart'
    show showAddTaskSheet, showAddHabitSheet, showEditTaskSheet, showEditHabitSheet;
import '../../finance/viewmodel/finance_viewmodel.dart';
import '../../finance/view/finance_view.dart' show showFinanceFormSheet;
import '../../notes_diary/viewmodel/notes_diary_viewmodel.dart';
import '../../notes_diary/view/notes_diary_view.dart' show showAddNoteSheet;
import '../../calender/viewmodel/calender_viewmodel.dart';
import '../../calender/view/calender_view.dart' show showAddEventSheet;

/// Bugün — günlük rutin merkezi. Üstte günler şeridi (pill), animasyonlu
/// ilerleme halkası (aksiyon sayısına bölünür; hepsi bitince tebrik + konfeti),
/// bento kartlar (Görevler büyük + Alışkanlık/Ödeme yanda), günün diğer
/// aksiyonları (takvim etkinlikleri) ve sağ altta + (hızlı oluştur). Kartlardan
/// açılan listede bir öğeye dokununca "Tamamla" popup'ı animasyonla kapanır.
/// Tamamlama backend'e yazılır, diğer sekmeler açılışta tazelendiği için SENKRON.
/// [onNavigate]: Bugün=0, Notlar=1, Görev=2, Alışk=3, Takvim=4, Finans=5, Profil=6.
class TodayView extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const TodayView({super.key, this.onNavigate});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView>
    with SingleTickerProviderStateMixin {
  DateTime _selected = _dayOnly(DateTime.now());

  // Sağ üst bildirim zili: açıksa başlığın altından liste aşağı açılır.
  bool _bellOpen = false;

  // Menü açılış animasyonu: öğeler sırayla (dalga gibi) belirir.
  late final AnimationController _entrance;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isToday(DateTime d) => _sameDay(d, DateTime.now());
  bool get _selectedIsFuture => _dayOnly(_selected).isAfter(_dayOnly(DateTime.now()));
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1150))
      ..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  // Sıralı (dalga) belirme ilerlemesi: her öğe kendi gecikmesiyle açılır.
  double _stagger(int order) {
    const perItem = 0.07;
    final start = (order * perItem).clamp(0.0, 0.75);
    final raw = ((_entrance.value - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  // Bir widget'ı sıraya göre alttan kayarak + solarak açar (dalga etkisi).
  Widget _reveal(int order, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, c) {
        final t = _stagger(order);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TasksHabitsViewModel()..refreshAll()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()..refreshAll()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()..refreshData()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
      ],
      child: Scaffold(
        backgroundColor:
            isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
        body: SafeArea(
          bottom: false,
          child: Consumer3<TasksHabitsViewModel, FinanceViewModel, CalendarViewModel>(
            builder: (context, th, fin, cal, _) {
              final isToday = _isToday(_selected);
              // O güne UYGULANAN görev/alışkanlıklar (günlük tekrarlılar her gün
              // sayılır). Gelmeyen günde done=0 (yapılmadı) ama toplam görünür.
              final tasks = _dayTasks(th);
              final dayHabits = _dayHabits(th);
              final total = tasks.length + dayHabits.length;
              final done = isToday
                  ? (tasks.where((t) => t.isCompleted).length +
                      dayHabits.where((h) => th.isHabitDoneToday(h)).length)
                  : 0;
              final allDone = total > 0 && done >= total;
              final streak = th.habits.fold<int>(
                  0, (m, h) => h.currentStreak > m ? h.currentStreak : m);
              final agenda = _dayAgenda(context, th, fin, cal);
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 140),
                children: [
                  _reveal(0, _header(context, c)),
                  _notificationPanel(context, c),
                  const SizedBox(height: 14),
                  _reveal(1, _weekNav(c)),
                  const SizedBox(height: 8),
                  _reveal(2, _daysStrip(c)),
                  const SizedBox(height: 16),
                  _reveal(
                    3,
                    _HeroCard(
                      dateLabel: _heroDate(),
                      done: done,
                      total: total,
                      streak: streak,
                      allDone: allDone,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _reveal(4, _bento(context, c, th, fin)),
                  // Günlük rutin: o güne ait somut aksiyonlar (görev/ödeme/
                  // etkinlik + her gün tekrarlı görev/alışkanlık). Hiçbiri yoksa
                  // bölümü göstermeyip günü temiz bırak.
                  if (agenda.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _reveal(5, _routineHeader(c, agenda.length)),
                    const SizedBox(height: 4),
                    _timeline(context, c, agenda),
                  ],
                ],
              );
            },
          ),
        ),
        floatingActionButton: Builder(
          builder: (fabCtx) => Padding(
            padding: const EdgeInsets.only(bottom: 92),
            child: SpeedDialFab(actions: _dialActions(fabCtx, c)),
          ),
        ),
      ),
    );
  }

  // ---------------- Başlık (sağ üstte çalan bildirim zili) ----------------
  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'today.greetingMorning';
    if (h < 18) return 'today.greetingAfternoon';
    return 'today.greetingEvening';
  }

  String _heroDate() {
    final months = 'calendar.monthNames'.tr().split(',');
    final shortDays = 'today.weekdaysShort'.tr().split(',');
    final d = _selected;
    final mName = d.month <= months.length ? months[d.month - 1] : '';
    final wd = (d.weekday - 1) < shortDays.length ? shortDays[d.weekday - 1] : '';
    return '$wd · ${d.day} $mName';
  }

  Widget _header(BuildContext context, AppColors c) {
    final now = DateTime.now();
    final months = 'calendar.monthNames'.tr().split(',');
    final days = 'calendar.dayNames'.tr().split(',');
    final mName = now.month <= months.length ? months[now.month - 1] : '';
    final dName = (now.weekday - 1) < days.length ? days[now.weekday - 1] : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greetingKey().tr(),
                  style: TextStyle(
                      fontSize: 14, color: c.textMuted, fontWeight: FontWeight.w600)),
              Text('today.title'.tr(),
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                      color: c.textPrimary)),
              Text('$dName, ${now.day} $mName',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
            ],
          ),
        ),
        // Zil: okunmamış bildirim varsa sürekli çalar; basınca liste açılır.
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Consumer<NotificationsViewModel>(
            builder: (_, nvm, __) => RingingBell(
              count: nvm.unread,
              open: _bellOpen,
              c: c,
              onTap: () => setState(() => _bellOpen = !_bellOpen),
            ),
          ),
        ),
      ],
    );
  }

  // Zile basınca başlığın altından aşağı doğru açılan bildirim listesi.
  Widget _notificationPanel(BuildContext context, AppColors c) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _bellOpen
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, t, child) => Opacity(opacity: t, child: child),
              child: Consumer<NotificationsViewModel>(
                builder: (_, nvm, __) => NotificationPanel(
                  vm: nvm,
                  c: c,
                  onOpenTab: (i) => widget.onNavigate?.call(i),
                  onClose: () => setState(() => _bellOpen = false),
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  // ---------------- Günler şeridi (yuvarlak değil → dikey pill) ----------------
  // Hafta gezinme: ‹ ay yıl › — önceki/sonraki haftaya geç.
  Widget _weekNav(AppColors c) {
    final months = 'calendar.monthNames'.tr().split(',');
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final mName = monday.month <= months.length ? months[monday.month - 1] : '';
    final label = (monday.month == sunday.month)
        ? '$mName ${monday.year}'
        : '$mName – ${sunday.month <= months.length ? months[sunday.month - 1] : ''}';
    Widget arrow(IconData ic, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Color.alphaBlend(
                    c.accent.withValues(alpha: .12), c.card),
                shape: BoxShape.circle),
            child: Icon(ic, size: 20, color: c.textPrimary),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        arrow(Icons.chevron_left_rounded,
            () => setState(() => _selected = _selected.subtract(const Duration(days: 7)))),
        Text(label,
            style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
        arrow(Icons.chevron_right_rounded,
            () => setState(() => _selected = _selected.add(const Duration(days: 7)))),
      ],
    );
  }

  Widget _daysStrip(AppColors c) {
    final labels = 'today.weekdaysShort'.tr().split(',');
    final base = _selected;
    final monday = base.subtract(Duration(days: base.weekday - 1));
    final week = List.generate(
        7, (i) => DateTime(monday.year, monday.month, monday.day + i));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = week[i];
        final sel = _sameDay(d, _selected);
        final today = _isToday(d);
        return GestureDetector(
          onTap: () => setState(() => _selected = d),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel
                  ? (c.isDark ? ColorConstant.accentOrange : c.textPrimary)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: today && !sel
                  ? Border.all(color: ColorConstant.accentOrange, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(i < labels.length ? labels[i] : '',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white.withValues(alpha: .85) : c.textMuted)),
                const SizedBox(height: 6),
                Text('${d.day}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : c.textPrimary)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------- Bento kartlar (Görevler büyük + 2 kart yanda) ----------
  Widget _bento(BuildContext context, AppColors c, TasksHabitsViewModel th,
      FinanceViewModel fin) {
    // O gün gelmediyse (veya geçtiyse) "yapıldı" sayılmaz → sadece BUGÜN gerçek
    // tamamlanma gösterilir; diğer günlerde kartlar 0/N (yapılmadı) görünür
    // (günlük tekrarlı görev/alışkanlıklar gelmeyen günlerde de toplama girer).
    final isToday = _isToday(_selected);
    final tasks = _dayTasks(th);
    final dayHabits = _dayHabits(th);
    final tdone = isToday ? tasks.where((t) => t.isCompleted).length : 0;
    final ttot = tasks.length;
    final hdone =
        isToday ? dayHabits.where((h) => th.isHabitDoneToday(h)).length : 0;
    final htot = dayHabits.length;
    // Ödemeler = SEÇİLİ GÜNE ait (o gün faturalanan abonelikler); yoksa 0.
    final pay = _dayPaymentsTotal(fin, _selected);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sol: büyük Görevler kartı (yeşil)
          Expanded(
            child: _bigCard(c,
                title: 'today.tasks'.tr(),
                value: _fracValue(c, tdone, ttot, 30),
                sub: ttot == 0 ? 'today.noTasks'.tr() : 'today.routine'.tr(),
                icon: Icons.check_box_outlined,
                col: c.success,
                progress: ttot == 0 ? 0 : tdone / ttot,
                onTap: () => _showTasksSheet(context, c, th)),
          ),
          const SizedBox(width: 12),
          // Sağ: iki küçük kart (Alışkanlıklar pembe / Ödemeler mavi) alt alta
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _smallCard(c,
                      title: 'today.habits'.tr(),
                      value: _fracValue(c, hdone, htot, 18),
                      icon: Icons.local_fire_department_outlined,
                      col: c.danger,
                      onTap: () => _showHabitsSheet(context, c, th)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _smallCard(c,
                      title: 'today.payments'.tr(),
                      value: _CountText(pay,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary),
                          format: (v) => AppCurrency.format(v, decimals: 0)),
                      icon: Icons.account_balance_wallet_outlined,
                      col: const Color(0xFF7B93D8), // resimdeki gibi mavi
                      onTap: () => _showPaymentsSheet(context, c, fin)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Animasyonlu "X/Y" sayacı: X 0'dan hedefe yükselir.
  Widget _fracValue(AppColors c, int done, int total, double size) {
    final style = TextStyle(
        fontSize: size, fontWeight: FontWeight.w800, color: c.textPrimary);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _CountText(done.toDouble(), style: style),
      Text('/$total', style: style),
    ]);
  }

  // Seçili güne ait ödeme toplamı: o gün faturalanan aktif abonelikler (yoksa 0).
  double _dayPaymentsTotal(FinanceViewModel fin, DateTime day) {
    double t = 0;
    for (final s in fin.subscriptions) {
      if (s.isActive && _sameDay(s.nextBillingDate, day)) t += s.amount;
    }
    return t;
  }

  Widget _bigCard(AppColors c,
      {required String title,
      required Widget value,
      required String sub,
      required IconData icon,
      required Color col,
      required double progress,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
              color: Color.alphaBlend(
                  col.withValues(alpha: c.isDark ? .26 : .20), c.card)),
          child: Stack(
            children: [
              // Köşe süsü — açık aksan dairesi (resimdeki gibi).
              Positioned(
                right: -26,
                top: -26,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: col.withValues(alpha: c.isDark ? .18 : .16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: col.withValues(alpha: .26),
                              shape: BoxShape.circle),
                          child: Icon(icon, size: 22, color: col),
                        ),
                        const Spacer(),
                        Icon(Icons.north_east_rounded,
                            size: 18, color: c.textMuted),
                      ]),
                      const SizedBox(height: 18),
                      value,
                      const SizedBox(height: 2),
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.textSecondary)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: col.withValues(alpha: .20),
                          valueColor: AlwaysStoppedAnimation(col),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallCard(AppColors c,
      {required String title,
      required Widget value,
      required IconData icon,
      required Color col,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
              color: Color.alphaBlend(
                  col.withValues(alpha: c.isDark ? .24 : .18), c.card)),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: col.withValues(alpha: c.isDark ? .18 : .16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: col.withValues(alpha: .24),
                              shape: BoxShape.circle),
                          child: Icon(icon, size: 17, color: col),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: c.textMuted),
                      ]),
                      const Spacer(),
                      value,
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.textSecondary)),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Seçilen güne uygulanan görevler: o güne tarihli VEYA tekrarı o güne denk
  // gelen (günlük her gün; haftalık aynı hafta günü; aylık aynı gün).
  List<Task> _dayTasks(TasksHabitsViewModel th) =>
      th.tasks.where((t) => _taskOnDay(t, _selected)).toList();

  // Seçilen güne uygulanan alışkanlıklar (bkz. _habitOnDay).
  List<Habit> _dayHabits(TasksHabitsViewModel th) =>
      th.habits.where((h) => _habitOnDay(h, _selected)).toList();

  /// Görev [day] gününe düşer mi? Tarihli görev o gün; tekrarlı görev
  /// başlangıç tarihinden itibaren deseni tutan her gün (gelecek günler dahil).
  bool _taskOnDay(Task t, DateTime day) {
    final d = _parseDay(t.dueDate);
    if (d != null && _sameDay(d, day)) return true;
    if (!t.isRecurring) return false;
    if (d != null && _dayOnly(day).isBefore(d)) return false; // henüz başlamadı
    switch (t.recurringPattern) {
      case 'daily':
        return true;
      case 'weekly':
        return d == null || d.weekday == day.weekday;
      case 'monthly':
        return d == null || d.day == day.day;
      case 'yearly':
        return d != null && d.month == day.month && d.day == day.day;
      default:
        return false;
    }
  }

  /// Alışkanlık [day] gününe düşer mi? Bugün: hepsi (Alışkanlık sekmesiyle
  /// aynı). Diğer günler: oluşturulduğundan sonra ve belirli günler seçildiyse
  /// o günlerde; yoksa (günlük/haftalık hedef) her gün görünür.
  bool _habitOnDay(Habit h, DateTime day) {
    if (_isToday(day)) return true;
    final created = _dayOnly(h.createdAt.toLocal());
    if (_dayOnly(day).isBefore(created)) return false;
    final days = h.specificDays;
    if (days != null && days.isNotEmpty) return days.contains(day.weekday);
    return true;
  }

  /// Alışkanlık tekrar etiketi: seçili günler / haftalık / her gün.
  String _habitRecurLabel(Habit h) {
    final days = h.specificDays;
    if (days != null && days.isNotEmpty && days.length < 7) {
      final names = 'today.weekdaysShort'.tr().split(',');
      final sorted = [...days]..sort();
      return sorted
          .map((d) => (d >= 1 && d <= names.length) ? names[d - 1] : '$d')
          .join(' · ');
    }
    if (h.timePeriod == 'weekly') return 'tasks.recurrence.weekly'.tr();
    return 'tasks.recurrence.daily'.tr();
  }


  // ---------------- Seçim listeleri (kartlardan açılır) ----------------
  void _sheet(BuildContext context, AppColors c, Widget Function(BuildContext) body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: body(ctx),
        ),
      ),
    );
  }

  Widget _sheetHandle(AppColors c) => Center(
        child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
      );

  Widget _sheetHead(AppColors c, String title, {VoidCallback? onAdd}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const Spacer(),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: ColorConstant.accentOrange.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 17, color: ColorConstant.accentOrange),
                  const SizedBox(width: 3),
                  Text('today.add'.tr(),
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorConstant.accentOrange)),
                ]),
              ),
            ),
        ]),
      );

  Widget _selectRow(AppColors c,
      {required String title,
      required String subtitle,
      required bool done,
      required IconData icon,
      required Color color,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.isDark ? Colors.white.withValues(alpha: .03) : c.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: done ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? color : c.border, width: 2)),
                child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? c.textMuted : c.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                ]),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sheetEmpty(AppColors c, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(child: Text(text, style: TextStyle(fontSize: 13.5, color: c.textMuted))),
      );

  void _showTasksSheet(BuildContext context, AppColors c, TasksHabitsViewModel th) {
    final isDark = c.isDark;
    _sheet(context, c, (ctx) {
      return AnimatedBuilder(
        animation: th,
        builder: (_, __) {
          final tasks = _dayTasks(th);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(c),
            _sheetHead(c, 'today.tasks'.tr(), onAdd: () {
              Navigator.pop(ctx);
              showAddTaskSheet(context, th, isDark);
            }),
            if (tasks.isEmpty)
              _sheetEmpty(c, 'today.noTasks'.tr())
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in tasks)
                      _selectRow(c,
                          title: t.title,
                          subtitle: _fmtTime(t.dueTime ?? ''),
                          done: t.isCompleted,
                          icon: Icons.check_box_outlined,
                          color: _priorityColor(c, t.priority),
                          onTap: () => _completeDialog(context, c,
                              title: t.title,
                              subtitle: _fmtTime(t.dueTime ?? ''),
                              icon: Icons.check_box_outlined,
                              color: _priorityColor(c, t.priority),
                              alreadyDone: t.isCompleted,
                              onAction: () async => th.toggleTaskComplete(t, context))),
                  ],
                ),
              ),
          ]);
        },
      );
    });
  }

  void _showHabitsSheet(BuildContext context, AppColors c, TasksHabitsViewModel th) {
    final isDark = c.isDark;
    final today = _isToday(_selected);
    _sheet(context, c, (ctx) {
      return AnimatedBuilder(
        animation: th,
        builder: (_, __) {
          final habits = th.habits;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(c),
            _sheetHead(c, 'today.habits'.tr(), onAdd: () {
              Navigator.pop(ctx);
              showAddHabitSheet(context, th, isDark);
            }),
            if (habits.isEmpty)
              _sheetEmpty(c, 'today.noHabits'.tr())
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final h in habits)
                      _selectRow(c,
                          title: h.title,
                          subtitle: h.currentStreak > 0
                              ? '🔥 ${h.currentStreak}'
                              : 'today.addHabit'.tr(),
                          done: today && th.isHabitDoneToday(h),
                          icon: Icons.local_fire_department_outlined,
                          color: ColorConstant.accentOrange,
                          onTap: today
                              ? () => _completeDialog(context, c,
                                  title: h.title,
                                  subtitle: h.currentStreak > 0 ? '🔥 ${h.currentStreak}' : '',
                                  icon: Icons.local_fire_department_outlined,
                                  color: ColorConstant.accentOrange,
                                  alreadyDone: th.isHabitDoneToday(h),
                                  onAction: () async => th.toggleHabitComplete(h, context))
                              : null),
                  ],
                ),
              ),
          ]);
        },
      );
    });
  }

  void _showPaymentsSheet(BuildContext context, AppColors c, FinanceViewModel fin) {
    final isDark = c.isDark;
    _sheet(context, c, (ctx) {
      return AnimatedBuilder(
        animation: fin,
        builder: (_, __) {
          final now = DateTime.now();
          final limit = now.add(const Duration(days: 7));
          final subs = fin.subscriptions
              .where((s) =>
                  s.isActive && !s.nextBillingDate.isBefore(now) && s.nextBillingDate.isBefore(limit))
              .toList();
          final insts = fin.installments.where((i) => !i.isDone).toList();
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(c),
            _sheetHead(c, 'today.payments'.tr(), onAdd: () {
              Navigator.pop(ctx);
              showFinanceFormSheet(context, fin, isDark);
            }),
            if (subs.isEmpty && insts.isEmpty)
              _sheetEmpty(c, 'today.noPayments'.tr())
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final i in insts)
                      _selectRow(c,
                          title: i.name,
                          subtitle: '${AppCurrency.format(i.monthlyAmount, decimals: 0)} · ${i.remainingCount}',
                          done: false,
                          icon: Icons.credit_card_rounded,
                          color: c.warning,
                          onTap: () => _completeDialog(context, c,
                              title: i.name,
                              subtitle: AppCurrency.format(i.monthlyAmount, decimals: 0),
                              icon: Icons.credit_card_rounded,
                              color: c.warning,
                              alreadyDone: false,
                              onAction: () async => fin.markInstallmentPaid(i.id))),
                    for (final s in subs)
                      _selectRow(c,
                          title: s.name,
                          subtitle: '${AppCurrency.format(s.amount, decimals: 0)} · ${_dateLabel(s.nextBillingDate)}',
                          done: false,
                          icon: Icons.autorenew_rounded,
                          color: c.success,
                          onTap: () => _completeDialog(context, c,
                              title: s.name,
                              subtitle: '${AppCurrency.format(s.amount, decimals: 0)} · ${_dateLabel(s.nextBillingDate)}',
                              icon: Icons.autorenew_rounded,
                              color: c.success,
                              alreadyDone: false,
                              onAction: null)),
                  ],
                ),
              ),
          ]);
        },
      );
    });
  }

  // ---------------- "Tamamla" popup (animasyonlu) ----------------
  Future<void> _completeDialog(BuildContext context, AppColors c,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool alreadyDone,
      required Future<void> Function()? onAction}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: .5),
      builder: (dctx) => _CompleteDialog(
        c: c,
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        alreadyDone: alreadyDone,
        onAction: onAction,
      ),
    );
  }

  String _dateLabel(DateTime d) {
    final months = 'calendar.monthNames'.tr().split(',');
    final mName = d.month <= months.length ? months[d.month - 1] : '';
    return '${d.day} $mName';
  }

  // ---------------- Günün diğer aksiyonları (takvim etkinlikleri) ----------
  Widget _routineHeader(AppColors c, int total) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
        child: Row(children: [
          Text('today.routine'.tr(),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const Spacer(),
          if (total > 0)
            Text('$total',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorConstant.accentOrange)),
        ]),
      );

  /// Seçilen güne ait TÜM aksiyonlar (zaman sıralı): takvim etkinlikleri,
  /// o güne tarihli veya her gün tekrarlı görevler, günlük alışkanlıklar ve
  /// o gün faturalanan abonelik ödemeleri. Boşsa bölüm hiç gösterilmez.
  List<_RoutineItem> _dayAgenda(BuildContext context, TasksHabitsViewModel th,
      FinanceViewModel fin, CalendarViewModel cal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _isToday(_selected);
    final out = <_RoutineItem>[];

    // Takvim etkinlikleri
    for (final e in cal.eventsForDate(_selected)) {
      out.add(_RoutineItem(
        title: e.title,
        subtitle: (e.location ?? '').toString(),
        done: false,
        time: _fmtTime(e.eventTime ?? ''),
        icon: Icons.event_rounded,
        color: const Color(0xFF9D8DF1), // mor (etkinlik)
        typeLabel: 'today.typeEvent'.tr(),
        recurLabel: '',
        onEdit: () => showAddEventSheet(context, cal, isDark, edit: e),
        onToggle: null,
        onOpen: () => widget.onNavigate?.call(4),
      ));
    }

    // Görevler: o güne tarihli VEYA her gün tekrarlı (hergün görünür).
    // Görev de alışkanlık gibi YALNIZ bugün işaretlenebilir; gelmeyen/geçen
    // günde görünür ama boş (yapılmadı) ve seçilemez.
    for (final t in th.tasks) {
      if (!_taskOnDay(t, _selected)) continue;
      out.add(_RoutineItem(
        title: t.title,
        subtitle: 'tasks.priority.${t.priority == 2 ? 'high' : t.priority == 0 ? 'low' : 'medium'}'.tr(),
        done: isToday && t.isCompleted,
        time: _fmtTime(t.dueTime ?? ''),
        icon: Icons.check_box_outlined,
        color: const Color(0xFF68B37A), // yeşil (görev)
        typeLabel: 'today.typeTask'.tr(),
        recurLabel: t.isRecurring ? _recurName(t.recurringPattern) : 'today.once'.tr(),
        completable: true,
        shared: th.isTaskShared(t.id),
        onToggle: isToday ? () => th.toggleTaskComplete(t, context) : null,
        onEdit: () => showEditTaskSheet(context, th, isDark, t),
        onOpen: () => widget.onNavigate?.call(2),
      ));
    }

    // Alışkanlıklar: her gün (daily) olanlar her gün görünür. Alışkanlık YALNIZ
    // o gün (bugün) işaretlenebilir; geçmiş/gelecek günlerde boş daire görünür
    // (o gün gelmediği/geçtiği için işaretli sayılmaz).
    for (final h in th.habits) {
      if (!_habitOnDay(h, _selected)) continue;
      out.add(_RoutineItem(
        title: h.title,
        subtitle: h.currentStreak > 0 ? '🔥 ${h.currentStreak}' : '',
        done: isToday && th.isHabitDoneToday(h),
        time: '',
        icon: Icons.local_fire_department_outlined,
        color: ColorConstant.accentOrange,
        typeLabel: 'today.typeHabit'.tr(),
        recurLabel: _habitRecurLabel(h),
        completable: true,
        shared: h.sharedHabitId != null,
        onToggle: isToday ? () => th.toggleHabitComplete(h, context) : null,
        onEdit: () => showEditHabitSheet(context, th, isDark, h),
        onOpen: () => widget.onNavigate?.call(3),
      ));
    }

    // Ödemeler: o gün faturalanan aktif abonelikler
    for (final s in fin.subscriptions) {
      if (!s.isActive) continue;
      if (!_sameDay(s.nextBillingDate, _selected)) continue;
      out.add(_RoutineItem(
        title: s.name,
        subtitle: AppCurrency.format(s.amount, decimals: 0),
        done: false,
        time: '',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF7B93D8), // mavi (ödeme)
        typeLabel: 'today.typePayment'.tr(),
        recurLabel: _recurName(s.billingCycle),
        completable: false,
        onToggle: null,
        onOpen: () => widget.onNavigate?.call(5),
      ));
    }

    // Zaman sıralı (saati olanlar önce)
    out.sort((a, b) =>
        (a.time.isEmpty ? '99:99' : a.time).compareTo(b.time.isEmpty ? '99:99' : b.time));
    return out;
  }


  Widget _timeline(BuildContext context, AppColors c, List<_RoutineItem> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _reveal(
            6 + i,
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _routineCard(context, c, items[i]),
            ),
          ),
      ],
    );
  }

  // Renkli zemin + köşe blob + büyük soluk arka plan simgesi olan rutin kartı.
  Widget _routineCard(BuildContext context, AppColors c, _RoutineItem it) {
    final bg = Color.alphaBlend(
        it.color.withValues(alpha: c.isDark ? .22 : .16), c.card);
    final trailing = it.time.isNotEmpty
        ? it.time
        : (it.recurLabel.isNotEmpty ? it.recurLabel : it.subtitle);
    return GestureDetector(
      onTap: () => _showItemDetail(context, c, it),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(color: bg),
          child: Stack(
            children: [
              // Köşe blob (daha koyu daire).
              Positioned(
                right: -24,
                bottom: -30,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: it.color.withValues(alpha: c.isDark ? .22 : .20)),
                ),
              ),
              // Arka plandaki büyük soluk simge.
              Positioned(
                right: 16,
                bottom: -8,
                child: Icon(it.icon,
                    size: 58, color: it.color.withValues(alpha: .20)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  // Simge kutusu (açık zemin + renkli simge).
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: c.isDark
                            ? Colors.white.withValues(alpha: .10)
                            : Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(14)),
                    child: it.done
                        ? Icon(Icons.check_rounded, color: it.color, size: 24)
                        : Icon(it.icon, color: it.color, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(it.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      decoration: it.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: it.done
                                          ? c.textMuted
                                          : c.textPrimary)),
                            ),
                            if (it.shared)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.group_rounded,
                                    size: 15, color: it.color),
                              ),
                          ]),
                          const SizedBox(height: 2),
                          Text(it.typeLabel,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textMuted)),
                        ]),
                  ),
                  const SizedBox(width: 8),
                  if (trailing.isNotEmpty)
                    Text(trailing,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: it.done ? c.textMuted : c.textSecondary)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Aksiyon detay popup'ı — tüm detaylar + Tamamla / Düzenle butonları.
  void _showItemDetail(BuildContext context, AppColors c, _RoutineItem it) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: it.color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(it.icon, color: it.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary)),
                      if (it.typeLabel.isNotEmpty)
                        Text(it.typeLabel,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textMuted)),
                    ]),
              ),
              if (it.shared)
                Icon(Icons.group_rounded, size: 20, color: it.color),
            ]),
            const SizedBox(height: 16),
            // Detaylar (etiketli satırlar).
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (it.recurLabel.isNotEmpty)
                _detailPill(c, Icons.repeat_rounded, it.recurLabel, it.color),
              if (it.time.isNotEmpty)
                _detailPill(c, Icons.schedule_rounded, it.time, it.color),
              if (it.completable)
                _detailPill(
                    c,
                    it.done
                        ? Icons.check_circle_rounded
                        : (_selectedIsFuture
                            ? Icons.schedule_rounded
                            : Icons.radio_button_unchecked_rounded),
                    it.done
                        ? 'today.completed'.tr()
                        : (_selectedIsFuture
                            ? 'today.upcoming'.tr()
                            : 'today.pending'.tr()),
                    it.done
                        ? const Color(0xFF2E9E6B)
                        : (_selectedIsFuture ? it.color : c.textMuted)),
              if (it.subtitle.isNotEmpty)
                _detailPill(c, Icons.info_outline_rounded, it.subtitle, it.color),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              if (it.completable && it.onToggle != null) ...[
                Expanded(
                  child: _detailBtn(
                    label: it.done ? 'today.undo'.tr() : 'today.complete'.tr(),
                    icon: it.done ? Icons.undo_rounded : Icons.check_rounded,
                    filled: true,
                    color: it.color,
                    onTap: () {
                      Navigator.pop(ctx);
                      it.onToggle?.call();
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _detailBtn(
                  label: 'common.edit'.tr(),
                  icon: Icons.edit_rounded,
                  filled: false,
                  color: it.color,
                  onTap: () {
                    Navigator.pop(ctx);
                    (it.onEdit ?? it.onOpen)?.call();
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _detailPill(AppColors c, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _detailBtn(
      {required String label,
      required IconData icon,
      required bool filled,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: filled ? null : Border.all(color: color, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 19, color: filled ? Colors.white : color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : color)),
        ]),
      ),
    );
  }

  // ---------------- Hızlı oluştur (+ Notlar tarzı) ----------------
  // + hızlı oluşturucu: speed-dial öğeleri (yukarı doğru açılır kartlar).
  List<DialAction> _dialActions(BuildContext context, AppColors c) {
    final isDark = c.isDark;
    final th = context.read<TasksHabitsViewModel>();
    final fin = context.read<FinanceViewModel>();
    return [
      DialAction(
        icon: Icons.check_box_outlined,
        label: 'today.addTask'.tr(),
        color: c.success,
        onTap: () => showAddTaskSheet(context, th, isDark),
      ),
      DialAction(
        icon: Icons.local_fire_department_outlined,
        label: 'today.addHabit'.tr(),
        color: c.danger,
        onTap: () => showAddHabitSheet(context, th, isDark),
      ),
      DialAction(
        icon: Icons.sticky_note_2_outlined,
        label: 'today.addNote'.tr(),
        color: c.accentCool,
        onTap: () => showAddNoteSheet(context, NotesDiaryViewModel()..refreshAll(), isDark),
      ),
      DialAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'today.addExpense'.tr(),
        color: c.info,
        onTap: () => showFinanceFormSheet(context, fin, isDark),
      ),
    ];
  }

  // ---------------- Yardımcılar ----------------
  DateTime? _parseDay(String? s) {
    if (s == null || s.isEmpty) return null;
    final d = DateTime.tryParse(s);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  String _fmtTime(String t) {
    if (t.isEmpty) return '';
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    return m != null ? '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}' : '';
  }

  Color _priorityColor(AppColors c, int p) {
    switch (p) {
      case 3:
        return c.danger;
      case 2:
        return c.warning;
      case 1:
        return c.info;
      default:
        return c.accent;
    }
  }

  String _recurName(String? pattern) {
    switch (pattern) {
      case 'daily':
        return 'tasks.recurrence.daily'.tr();
      case 'weekly':
        return 'tasks.recurrence.weekly'.tr();
      case 'monthly':
        return 'tasks.recurrence.monthly'.tr();
      case 'yearly':
        return 'today.once'.tr();
      default:
        return 'today.once'.tr();
    }
  }
}

class _RoutineItem {
  final String title;
  final String subtitle;
  final bool done;
  final String time;
  final IconData icon;
  final Color color;
  final String typeLabel; // "Görev" / "Alışkanlık" / "Ödeme" / "Etkinlik"
  final String recurLabel; // "Hergün" / "Haftalık" / "Aylık" / "Tek sefer"
  final bool completable; // görev/alışkanlık → tamamlanabilir
  final bool shared; // paylaşımlı mı (grup ikonu)
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit; // düzenle sayfasını aç
  _RoutineItem({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.time,
    required this.icon,
    required this.color,
    this.typeLabel = '',
    this.recurLabel = '',
    this.completable = false,
    this.shared = false,
    this.onToggle,
    this.onOpen,
    this.onEdit,
  });
}

/// "Tamamla" popup'ı — Tamamla'ya basınca "Tamamlanıyor…" → animasyonlu
/// "Tamamlandı ✓" gösterip kendini kapatır. Zaten tamamlıysa "Geri al".
class _CompleteDialog extends StatefulWidget {
  final AppColors c;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool alreadyDone;
  final Future<void> Function()? onAction;
  const _CompleteDialog({
    required this.c,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.alreadyDone,
    required this.onAction,
  });

  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  // 0 = bekliyor, 1 = işleniyor, 2 = tamamlandı
  int _phase = 0;

  Future<void> _run() async {
    if (widget.onAction == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _phase = 1);
    try {
      await widget.onAction!();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    // Geri al akışında kutlama yok; direkt kapat.
    if (widget.alreadyDone) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _phase = 2);
    await Future.delayed(const Duration(milliseconds: 950));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // İkon / durum göstergesi
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (ch, an) => ScaleTransition(scale: an, child: ch),
            child: _phase == 2
                ? Container(
                    key: const ValueKey('done'),
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(color: Color(0xFF2E9E6B), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  )
                : Container(
                    key: const ValueKey('icon'),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: widget.color.withValues(alpha: .16), shape: BoxShape.circle),
                    child: Icon(widget.icon, color: widget.color, size: 34),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _phase == 2 ? 'today.completed'.tr() : widget.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          if (_phase != 2 && widget.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.textMuted)),
          ],
          const SizedBox(height: 22),
          // Aksiyon alanı
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _buildAction(c),
          ),
          if (_phase == 0) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('common.cancel'.tr(),
                  style: TextStyle(fontSize: 13.5, color: c.textMuted, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildAction(AppColors c) {
    if (_phase == 1) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: widget.color.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(widget.color)),
          ),
          const SizedBox(width: 10),
          Text('today.completing'.tr(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.color)),
        ]),
      );
    }
    if (_phase == 2) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: const Color(0xFF2E9E6B).withValues(alpha: .16), borderRadius: BorderRadius.circular(15)),
        child: Text('today.completed'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2E9E6B))),
      );
    }
    // phase 0
    final label = widget.onAction == null
        ? 'common.close'.tr()
        : (widget.alreadyDone ? 'today.undo'.tr() : 'today.complete'.tr());
    return ElevatedButton(
      onPressed: _run,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.alreadyDone ? c.textMuted : widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.alreadyDone ? Icons.undo_rounded : Icons.check_rounded, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// Su dolum halkası: dairenin içinde su, tamamlanma oranı kadar yükselir ve
/// dalgalı yüzey animasyonuyla dalgalanır. Siyah kart yok — sayfa zemini.
/// Sağda selamlama + tarih + X/Y tamam.
class _HeroCard extends StatefulWidget {
  final String dateLabel;
  final int done;
  final int total;
  final int streak;
  final bool allDone;
  const _HeroCard({
    required this.dateLabel,
    required this.done,
    required this.total,
    required this.streak,
    required this.allDone,
  });
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  String _greetingKey() {
    if (widget.total == 0 || widget.done == 0) return 'today.heroStart';
    if (widget.done >= widget.total) return 'today.heroDone';
    return 'today.heroGoing';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);
    final frac =
        widget.total == 0 ? 0.0 : (widget.done / widget.total).clamp(0.0, 1.0);
    final textOnGauge =
        frac > 0.5 ? Colors.white : const Color(0xFF2F6B4C);
    final status =
        '${widget.dateLabel} · ${widget.done}/${widget.total} ${'today.done'.tr()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: frac),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, f, __) => AnimatedBuilder(
                  animation: _wave,
                  builder: (_, __) => CustomPaint(
                    size: const Size(104, 104),
                    painter:
                        _WaterGaugePainter(fill: f, wave: _wave.value, dark: isDark),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _CountText(widget.done.toDouble(),
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: textOnGauge)),
                    Text('/${widget.total}',
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: textOnGauge)),
                  ]),
                  Text('today.done'.tr().toUpperCase(),
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: textOnGauge.withValues(alpha: 0.85))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greetingKey().tr(),
                  style: TextStyle(
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
              const SizedBox(height: 6),
              Text(status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.textMuted)),
              if (widget.streak > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: ColorConstant.accentOrange.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(9)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14, color: ColorConstant.accentOrange),
                    const SizedBox(width: 4),
                    Text('${widget.streak}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ColorConstant.accentOrange)),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

class _WaterGaugePainter extends CustomPainter {
  final double fill; // 0..1 (animasyonlu su seviyesi)
  final double wave; // 0..1 dalga fazı
  final bool dark;
  _WaterGaugePainter({required this.fill, required this.wave, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2 - 3;

    // Zemin (boş) daire — açık yeşil/gri.
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = dark ? const Color(0x18FFFFFF) : const Color(0xFFE4EFE4));

    // Daireye kırp, suyu çiz.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    if (fill > 0.001) {
      final level = h - h * fill; // su yüzeyi y
      final amp = fill >= 0.995 ? 0.0 : 3.5;
      void drawWave(Color col, double phase, double dy) {
        final p = Path()..moveTo(0, h);
        p.lineTo(0, level + dy);
        const steps = 26;
        for (int i = 0; i <= steps; i++) {
          final x = w * i / steps;
          final y = level +
              dy +
              math.sin((i / steps) * 2 * math.pi * 1.4 + phase) * amp;
          p.lineTo(x, y);
        }
        p.lineTo(w, h);
        p.close();
        canvas.drawPath(p, Paint()..color = col);
      }

      drawWave(const Color(0x55A6D9B6), wave * 2 * math.pi + 1.2, 4);
      drawWave(const Color(0xFF7FBF95), wave * 2 * math.pi, 0);
    }
    canvas.restore();

    // Kenarlık.
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFF9FCBA8));
  }

  @override
  bool shouldRepaint(covariant _WaterGaugePainter old) =>
      old.fill != fill || old.wave != wave || old.dark != dark;
}

/// Sayıyı 0'dan (ilk oluşturmada) hedefe animasyonla sayan metin. Değer sonradan
/// değişirse eski değerden yeni değere yumuşak geçer.
class _CountText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String Function(double)? format;
  const _CountText(this.value, {required this.style, this.format});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        format != null ? format!(v) : v.round().toString(),
        style: style,
      ),
    );
  }
}
