import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/subscription_icons.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../models/calender/calendar_models.dart';
import '../../../models/note/note_models.dart';
import '../viewmodel/calender_viewmodel.dart';

// ==================== ETKİNLİK KATEGORİLERİ ====================

class _EvCat {
  final String id;
  final String labelKey;
  final Color color;
  const _EvCat(this.id, this.labelKey, this.color);
}

const List<_EvCat> kEvCats = [
  _EvCat('is', 'calendar.cat.work', Color(0xFF9F7AEA)),
  _EvCat('kisisel', 'calendar.cat.personal', Color(0xFF4C9AFF)),
  _EvCat('saglik', 'calendar.cat.health', Color(0xFF48BB78)),
  _EvCat('diger', 'calendar.cat.other', Color(0xFFF6A821)),
];

_EvCat evCatById(String? id) {
  for (final c in kEvCats) {
    if (c.id == id) return c;
  }
  return kEvCats.last;
}

class _EvKind {
  final String id;
  final String labelKey;
  final IconData icon;
  const _EvKind(this.id, this.labelKey, this.icon);
}

const List<_EvKind> kEvKinds = [
  _EvKind('meeting', 'calendar.kind.meeting', Icons.groups_rounded),
  _EvKind('reminder', 'calendar.kind.reminder', Icons.notifications_rounded),
  _EvKind('birthday', 'calendar.kind.birthday', Icons.cake_rounded),
  _EvKind('focus', 'calendar.kind.focus', Icons.center_focus_strong_rounded),
];

_EvKind evKindById(String? id) {
  for (final k in kEvKinds) {
    if (k.id == id) return k;
  }
  return kEvKinds.first;
}

const _cOrange = Color(0xFFF6A821);

Color eventColor(CalendarViewModel vm, CalendarEvent e) {
  final m = vm.metaForEvent(e.id);
  if (m.color != null && m.color!.isNotEmpty) {
    try {
      return Color(int.parse(m.color!.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {}
  }
  return evCatById(m.category).color;
}

String _monthName(int m) {
  final names = 'calendar.monthNames'.tr().split(',');
  return (m >= 1 && m <= names.length) ? names[m - 1] : '';
}

String _dayName(int weekday) {
  final names = 'calendar.dayNames'.tr().split(','); // Pzt..Paz (1..7)
  return (weekday >= 1 && weekday <= names.length) ? names[weekday - 1] : '';
}

String longDate(DateTime d) =>
    '${d.day} ${_monthName(d.month)} ${d.year}, ${_dayName(d.weekday)}';
String midDate(DateTime d) =>
    '${d.day} ${_monthName(d.month)}, ${_dayName(d.weekday)}';

/// Etkinlik ekleme/düzenleme sayfasını açar.
void showAddEventSheet(BuildContext context, CalendarViewModel vm, bool isDark,
    {CalendarEvent? edit, DateTime? date}) {
  if (edit != null) {
    vm.prepareEditEvent(edit);
  } else {
    vm.resetEventForm(date: date);
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EventFormSheet(
      viewModel: vm,
      isDarkMode: isDark,
      isEditing: edit != null,
    ),
  );
}

@RoutePage()
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  String _query = '';
  bool _searchOpen = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel()..refreshData(),
      child: Consumer<CalendarViewModel>(
        builder: (context, vm, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final c = AppColors(isDark);
          return Scaffold(
            backgroundColor: isDark
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(context, vm, c),
                  _tabsRow(context, vm, c),
                  Expanded(
                    child: vm.isLoading && vm.calendarEvents.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(color: _cOrange))
                        : _content(context, vm, c),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'calendar_fab',
              onPressed: () =>
                  showAddEventSheet(context, vm, isDark, date: vm.selectedDate),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6C23E), _cOrange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _cOrange.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
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

  // ---------- Başlık ----------
  Widget _header(BuildContext context, CalendarViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('calendar.screenTitle'.tr(),
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(longDate(vm.selectedDate),
                        style:
                            TextStyle(fontSize: 14, color: c.textSecondary)),
                  ],
                ),
              ),
              _iconBtn(c, _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  () => setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) _query = '';
                      })),
              const SizedBox(width: 10),
              _iconBtn(c, Icons.notifications_none_rounded,
                  () => _showUpcoming(context, vm, c)),
            ],
          ),
          if (_searchOpen) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border.withOpacity(0.7)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Icon(Icons.search_rounded, size: 20, color: c.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: c.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'calendar.searchHint'.tr(),
                      hintStyle: TextStyle(color: c.textMuted),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn(AppColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border.withOpacity(0.6))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: c.textSecondary),
        ),
      ),
    );
  }

  // ---------- Görünüm sekmeleri + Bugün ----------
  Widget _tabsRow(BuildContext context, CalendarViewModel vm, AppColors c) {
    final items = [
      [CalendarViewType.month, 'calendar.viewMonth'],
      [CalendarViewType.week, 'calendar.viewWeek'],
      [CalendarViewType.day, 'calendar.viewDay'],
      [CalendarViewType.agenda, 'calendar.viewAgenda'],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border.withOpacity(0.7)),
              ),
              child: Row(
                children: [
                  for (final it in items)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => vm.setCalendarViewType(
                            it[0] as CalendarViewType),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: vm.calendarViewType == it[0]
                                ? _cOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text((it[1] as String).tr(),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: vm.calendarViewType == it[0]
                                      ? Colors.white
                                      : c.textSecondary)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => vm.goToToday(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border.withOpacity(0.7))),
                child: Row(children: [
                  const Icon(Icons.today_rounded, size: 18, color: _cOrange),
                  const SizedBox(width: 5),
                  Text('common.today'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _cOrange)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- İçerik ----------
  Widget _content(BuildContext context, CalendarViewModel vm, AppColors c) {
    if (_query.trim().isNotEmpty) return _searchResults(context, vm, c);
    switch (vm.calendarViewType) {
      case CalendarViewType.agenda:
        return _agenda(context, vm, c);
      case CalendarViewType.day:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            _dayHero(vm, c),
            const SizedBox(height: 16),
            ..._dayEventsSection(context, vm, c, vm.selectedDate,
                showAdd: true),
          ],
        );
      case CalendarViewType.week:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            _weekStrip(vm, c),
            const SizedBox(height: 16),
            ..._dayEventsSection(context, vm, c, vm.selectedDate,
                showAdd: true),
            const SizedBox(height: 12),
            _tomorrowRow(context, vm, c),
          ],
        );
      case CalendarViewType.month:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            _monthCard(vm, c),
            const SizedBox(height: 16),
            ..._dayEventsSection(context, vm, c, vm.selectedDate,
                showAdd: true),
            const SizedBox(height: 12),
            _tomorrowRow(context, vm, c),
          ],
        );
    }
  }

  // ---------- Ay kartı ----------
  Widget _monthCard(CalendarViewModel vm, AppColors c) {
    final fm = vm.focusedMonth;
    final first = DateTime(fm.year, fm.month, 1);
    final lead = first.weekday - 1; // Pzt=0
    final daysInMonth = DateTime(fm.year, fm.month + 1, 0).day;
    final dots = vm.eventCategoryDots();
    final shorts = 'tasks.weekShort'.tr().split(',');
    final cells = <Widget>[];
    for (int i = 0; i < lead; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(fm.year, fm.month, day);
      final sel = vm.isSelectedDate(date);
      final today = vm.isToday(date);
      final cats = dots[date] ?? const <String>{};
      cells.add(GestureDetector(
        onTap: () => vm.setSelectedDate(date),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? _cOrange : Colors.transparent,
                shape: BoxShape.circle,
                border: today && !sel
                    ? Border.all(color: _cOrange, width: 1.5)
                    : null,
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: _cOrange.withOpacity(0.45),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
              child: Text('$day',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? Colors.white
                          : (today ? _cOrange : c.textPrimary))),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final cat in cats.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                          color: sel ? Colors.white : evCatById(cat).color,
                          shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _navBtn(c, Icons.chevron_left_rounded, vm.previousMonth),
              Expanded(
                child: Text('${_monthName(fm.month)} ${fm.year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ),
              _navBtn(c, Icons.chevron_right_rounded, vm.nextMonth),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(i < shorts.length ? shorts[i] : '',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.72,
            children: cells,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: c.bg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final cat in kEvCats.take(3)) _legend(cat, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(AppColors c, IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: c.textSecondary, size: 26),
          ),
        ),
      );

  Widget _legend(_EvCat cat, AppColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: cat.color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(cat.labelKey.tr(),
              style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
        ],
      );

  // ---------- Hafta şeridi ----------
  Widget _weekStrip(CalendarViewModel vm, AppColors c) {
    final sel = vm.selectedDate;
    final monday = sel.subtract(Duration(days: sel.weekday - 1));
    final shorts = 'tasks.weekShort'.tr().split(',');
    final dots = vm.eventCategoryDots();
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
          final d = DateTime(monday.year, monday.month, monday.day + i);
          final s = vm.isSelectedDate(d);
          final cats = dots[d] ?? const <String>{};
          return GestureDetector(
            onTap: () => vm.setSelectedDate(d),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(i < shorts.length ? shorts[i] : '',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: s ? Colors.white : c.textMuted)),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s ? _cOrange : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${d.day}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: s ? Colors.white : c.textPrimary)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final cat in cats.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                            color: evCatById(cat).color,
                            shape: BoxShape.circle),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _dayHero(CalendarViewModel vm, AppColors c) {
    final d = vm.selectedDate;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF6C23E), _cOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${d.day}',
                  style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1)),
              Text('${_monthName(d.month)} ${d.year}',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_dayName(d.weekday),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                  'calendar.eventCount'.tr(namedArgs: {
                    'n': '${vm.eventsForDate(d).length}'
                  }),
                  style: const TextStyle(fontSize: 13, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Seçili gün etkinlik bölümü ----------
  List<Widget> _dayEventsSection(BuildContext context, CalendarViewModel vm,
      AppColors c, DateTime date,
      {bool showAdd = false}) {
    final events = vm.eventsForDate(date);
    final allDay = events.where((e) => vm.metaForEvent(e.id).allDay).toList();
    final timed = events.where((e) => !vm.metaForEvent(e.id).allDay).toList();
    return [
      Row(
        children: [
          Expanded(
            child: Text(midDate(date),
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
          ),
          if (showAdd)
            InkWell(
              onTap: () => showAddEventSheet(context, vm, c.isDark, date: date),
              child: Row(children: [
                const Icon(Icons.add_rounded, size: 18, color: _cOrange),
                const SizedBox(width: 2),
                Text('calendar.addEvent'.tr(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _cOrange)),
              ]),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (events.isEmpty)
        _emptyDay(c)
      else ...[
        for (final e in allDay) ...[
          _allDayCard(context, vm, c, e),
          const SizedBox(height: 10),
        ],
        for (final e in timed) ...[
          _timedCard(context, vm, c, e),
          const SizedBox(height: 12),
        ],
      ],
    ];
  }

  Widget _emptyDay(AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(children: [
        Icon(Icons.event_available_rounded,
            size: 38, color: _cOrange.withOpacity(0.6)),
        const SizedBox(height: 10),
        Text('calendar.emptyDay'.tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary)),
      ]),
    );
  }

  Widget _allDayCard(BuildContext context, CalendarViewModel vm, AppColors c,
      CalendarEvent e) {
    final color = eventColor(vm, e);
    return GestureDetector(
      onTap: () => showAddEventSheet(context, vm, c.isDark, edit: e),
      onLongPress: () => _eventMenu(context, vm, c, e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.7)),
        ),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text('calendar.allDay'.tr(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('· ${e.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ),
          Icon(Icons.notifications_active_rounded,
              size: 18, color: color),
        ]),
      ),
    );
  }

  Widget _timedCard(BuildContext context, CalendarViewModel vm, AppColors c,
      CalendarEvent e) {
    final m = vm.metaForEvent(e.id);
    final color = eventColor(vm, e);
    final kind = evKindById(m.kind);
    final start = e.eventTime != null && e.eventTime!.length >= 5
        ? e.eventTime!.substring(0, 5)
        : '';
    final end = m.endTime ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(start,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary)),
          ),
          Container(
            width: 4,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => showAddEventSheet(context, vm, c.isDark, edit: e),
              onLongPress: () => _eventMenu(context, vm, c, e),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border.withOpacity(0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              end.isNotEmpty ? '$start – $end' : start,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textMuted)),
                        ),
                        if (m.reminders.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.notifications_active_rounded,
                                  size: 13, color: color),
                              const SizedBox(width: 3),
                              Text(_reminderShort(m.reminders.first),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(e.title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary)),
                    if (e.description != null &&
                        e.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(e.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: c.textSecondary)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniChip(kind.icon, kind.labelKey.tr(), color),
                        if (m.location != null)
                          _miniChip(Icons.place_outlined, m.location!,
                              c.textMuted),
                        if (m.recurrence != 'none')
                          _miniChip(Icons.repeat_rounded,
                              'calendar.rec.${m.recurrence}'.tr(),
                              c.textMuted),
                        if (m.tag != null)
                          _miniChip(Icons.local_offer_outlined, '#${m.tag}',
                              c.textMuted),
                      ],
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

  Widget _miniChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  String _reminderShort(int m) {
    if (m == 0) return 'calendar.rem.onTime'.tr();
    if (m % 1440 == 0) {
      return 'calendar.rem.day'.tr(namedArgs: {'n': '${m ~/ 1440}'});
    }
    if (m % 60 == 0) {
      return 'calendar.rem.hour'.tr(namedArgs: {'n': '${m ~/ 60}'});
    }
    return 'calendar.rem.min'.tr(namedArgs: {'n': '$m'});
  }

  void _eventMenu(
      BuildContext context, CalendarViewModel vm, AppColors c, CalendarEvent e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: _cOrange),
            title:
                Text('common.edit'.tr(), style: TextStyle(color: c.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              showAddEventSheet(context, vm, c.isDark, edit: e);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFE53E3E)),
            title: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFE53E3E))),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await vm.deleteCalendarEvent(e.id);
              if (ok && context.mounted) {
                CustomSnackBar.showSuccess(
                    context, 'success.eventDeleted'.tr());
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ---------- Yarın satırı ----------
  Widget _tomorrowRow(BuildContext context, CalendarViewModel vm, AppColors c) {
    final tomorrow = vm.selectedDate.add(const Duration(days: 1));
    final count = vm.eventsForDate(tomorrow).length;
    if (count == 0) return const SizedBox();
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => vm.setSelectedDate(tomorrow),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withOpacity(0.7))),
          child: Row(children: [
            const Icon(Icons.event_rounded, size: 20, color: _cOrange),
            const SizedBox(width: 12),
            Text('calendar.tomorrow'.tr(),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(width: 6),
            Text(
                '· ${'calendar.eventCount'.tr(namedArgs: {'n': '$count'})}',
                style: TextStyle(fontSize: 14, color: c.textMuted)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ]),
        ),
      ),
    );
  }

  // ---------- Ajanda ----------
  Widget _agenda(BuildContext context, CalendarViewModel vm, AppColors c) {
    final now = DateTime.now();
    final events = List<CalendarEvent>.from(vm.calendarEvents);
    final upcoming = events.where((e) {
      try {
        final d = DateTime.parse(e.eventDate);
        return !d.isBefore(DateTime(now.year, now.month, now.day));
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        final ka = '${a.eventDate} ${a.eventTime ?? '99:99'}';
        final kb = '${b.eventDate} ${b.eventTime ?? '99:99'}';
        return ka.compareTo(kb);
      });
    if (upcoming.isEmpty) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [_emptyDay(c)]);
    }
    final byDate = <String, List<CalendarEvent>>{};
    for (final e in upcoming) {
      (byDate[e.eventDate] ??= []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        for (final entry in byDate.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 6),
            child: Text(midDate(DateTime.parse(entry.key)),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
          ),
          for (final e in entry.value) ...[
            _timedCard(context, vm, c, e),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _searchResults(BuildContext context, CalendarViewModel vm, AppColors c) {
    final q = _query.trim().toLowerCase();
    final res = vm.calendarEvents
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.description ?? '').toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (res.isEmpty) {
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [_emptyDay(c)]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        for (final e in res) ...[
          _timedCard(context, vm, c, e),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showUpcoming(BuildContext context, CalendarViewModel vm, AppColors c) {
    final now = DateTime.now();
    final upcoming = vm.calendarEvents.where((e) {
      try {
        final d = DateTime.parse(e.eventDate);
        return !d.isBefore(DateTime(now.year, now.month, now.day)) &&
            vm.metaForEvent(e.id).reminders.isNotEmpty;
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('calendar.upcomingReminders'.tr(),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                Text('calendar.noReminders'.tr(),
                    style: TextStyle(color: c.textSecondary))
              else
                ...upcoming.take(10).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Icon(Icons.notifications_active_rounded,
                            size: 18, color: eventColor(vm, e)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary)),
                        ),
                        Text('${DateTime.parse(e.eventDate).day} ${_monthName(DateTime.parse(e.eventDate).month)}',
                            style: TextStyle(
                                fontSize: 12.5, color: c.textMuted)),
                      ]),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ETKİNLİK FORM SHEET ====================

class _EventFormSheet extends StatelessWidget {
  final CalendarViewModel viewModel;
  final bool isDarkMode;
  final bool isEditing;
  const _EventFormSheet({
    required this.viewModel,
    required this.isDarkMode,
    this.isEditing = false,
  });

  static const _accent = Color(0xFFF6A821);
  static const _palette = [
    '#9F7AEA',
    '#4C9AFF',
    '#48BB78',
    '#F6A821',
    '#F6524B',
    '#ED64A6',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<CalendarViewModel>(
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
                        _titleCard(vm, c, context),
                        const SizedBox(height: 14),
                        _kindChips(vm, c),
                        const SizedBox(height: 16),
                        _timeCard(context, vm, c),
                        const SizedBox(height: 16),
                        _repeatReminderCard(context, vm, c),
                        const SizedBox(height: 16),
                        _locationCategoryCard(context, vm, c),
                        const SizedBox(height: 16),
                        _extraChips(context, vm, c),
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

  Widget _topBar(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          _sq(c, Icons.close_rounded, () => Navigator.pop(context)),
          Expanded(
            child: Text(
              isEditing ? 'calendar.editEvent'.tr() : 'calendar.newEvent'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _sq(AppColors c, IconData icon, VoidCallback onTap) => Material(
        color: c.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.border.withOpacity(0.6))),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, size: 18, color: c.textSecondary)),
        ),
      );

  Color _formColorValue(CalendarViewModel vm) {
    if (vm.formColor != null) {
      try {
        return Color(
            int.parse(vm.formColor!.replaceAll('#', 'FF'), radix: 16));
      } catch (_) {}
    }
    return evCatById(vm.formCategory).color;
  }

  Widget _titleCard(CalendarViewModel vm, AppColors c, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickColor(context, vm, c),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: _formColorValue(vm), shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: vm.eventTitleController,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'calendar.titleHint'.tr(),
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 17),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: c.border.withOpacity(0.5)),
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: c.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: vm.eventDescController,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(fontSize: 15, color: c.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'calendar.descHint'.tr(),
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kindChips(CalendarViewModel vm, AppColors c) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in kEvKinds) ...[
            GestureDetector(
              onTap: () => vm.setFormKind(k.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: vm.formKind == k.id
                      ? _accent.withOpacity(0.14)
                      : c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: vm.formKind == k.id
                          ? _accent
                          : c.border.withOpacity(0.7)),
                ),
                child: Row(children: [
                  Icon(k.icon,
                      size: 17,
                      color: vm.formKind == k.id ? _accent : c.textSecondary),
                  const SizedBox(width: 6),
                  Text(k.labelKey.tr(),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color:
                              vm.formKind == k.id ? _accent : c.textSecondary)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _timeCard(BuildContext context, CalendarViewModel vm, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          _dtRow(context, vm, c, 'calendar.start'.tr(), vm.formStartDate,
              vm.formAllDay ? null : vm.formStartTime,
              onDate: (d) => vm.setFormStartDate(d),
              onTime: (t) => vm.setFormStartTime(t)),
          _div(c),
          _dtRow(context, vm, c, 'calendar.end'.tr(), vm.formEndDate,
              vm.formAllDay ? null : vm.formEndTime,
              onDate: (d) => vm.setFormEndDate(d),
              onTime: (t) => vm.setFormEndTime(t)),
          _div(c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(children: [
              Expanded(
                child: Text('calendar.allDay'.tr(),
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
              ),
              Switch(
                value: vm.formAllDay,
                activeColor: _accent,
                onChanged: vm.setFormAllDay,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dtRow(BuildContext context, CalendarViewModel vm, AppColors c,
      String label, DateTime date, TimeOfDay? time,
      {required void Function(DateTime) onDate,
      required void Function(TimeOfDay) onTime}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 22, color: _accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 3));
              if (d != null) onDate(d);
            },
            child: Text(
                '${date.day} ${_monthName(date.month)} ${date.year}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary)),
          ),
          if (time != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: time);
                if (t != null) onTime(t);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: c.bg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _repeatReminderCard(
      BuildContext context, CalendarViewModel vm, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          _tapRow(c, Icons.repeat_rounded, 'calendar.recurrence'.tr(),
              'calendar.rec.${vm.formRecurrence}'.tr(),
              onTap: () => _pickRecurrence(context, vm, c)),
          _div(c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    size: 22, color: _accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('calendar.reminders'.tr(),
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in vm.formReminders)
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 6, top: 6, bottom: 6),
                              decoration: BoxDecoration(
                                  color: c.bg,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(_reminderLabel(m),
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => vm.removeFormReminder(m),
                                  child: Icon(Icons.close_rounded,
                                      size: 15, color: c.textMuted),
                                ),
                              ]),
                            ),
                          GestureDetector(
                            onTap: () => _pickReminder(context, vm, c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.add_rounded,
                                    size: 15, color: _accent),
                                const SizedBox(width: 3),
                                Text('calendar.addReminder'.tr(),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _accent)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCategoryCard(
      BuildContext context, CalendarViewModel vm, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          _tapRow(c, Icons.place_outlined, 'calendar.location'.tr(),
              vm.formLocation ?? 'calendar.locationAdd'.tr(),
              onTap: () => _textInput(context, vm, 'calendar.location'.tr(),
                  vm.formLocation ?? '', vm.setFormLocation)),
          _div(c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.folder_rounded, size: 22, color: _accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('calendar.calendarField'.tr(),
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                ),
                GestureDetector(
                  onTap: () => _pickCategory(context, vm, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: evCatById(vm.formCategory)
                            .color
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: evCatById(vm.formCategory).color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(evCatById(vm.formCategory).labelKey.tr(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: evCatById(vm.formCategory).color)),
                    ]),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: c.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraChips(BuildContext context, CalendarViewModel vm, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('calendar.extraOptions'.tr(),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _extraChip(c, Icons.local_offer_outlined,
                vm.formTag != null ? '#${vm.formTag}' : 'calendar.tag'.tr(),
                active: vm.formTag != null,
                onTap: () => _textInput(context, vm, 'calendar.tag'.tr(),
                    vm.formTag ?? '', vm.setFormTag)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _extraChip(c, Icons.palette_outlined, 'calendar.color'.tr(),
                active: vm.formColor != null,
                onTap: () => _pickColor(context, vm, c)),
          ),
        ]),
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
                  color: active ? _accent : c.border.withOpacity(0.7))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: active ? _accent : c.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? _accent : c.textSecondary)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, CalendarViewModel vm, AppColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(children: [
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
            onPressed: () => vm.saveEventFromForm(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                  isEditing
                      ? 'calendar.update'.tr()
                      : 'calendar.createEvent'.tr(),
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ---------- ortak satır / pickerlar ----------
  Widget _div(AppColors c) =>
      Divider(height: 1, thickness: 1, color: c.border.withOpacity(0.5), indent: 52);

  Widget _tapRow(AppColors c, IconData icon, String label, String value,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(children: [
            Icon(icon, size: 22, color: _accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
            ),
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
          ]),
        ),
      ),
    );
  }

  String _reminderLabel(int m) {
    if (m == 0) return 'calendar.rem.onTime'.tr();
    if (m % 1440 == 0) {
      return 'calendar.rem.day'.tr(namedArgs: {'n': '${m ~/ 1440}'});
    }
    if (m % 60 == 0) {
      return 'calendar.rem.hour'.tr(namedArgs: {'n': '${m ~/ 60}'});
    }
    return 'calendar.rem.min'.tr(namedArgs: {'n': '$m'});
  }

  void _pickReminder(BuildContext context, CalendarViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final m in [0, 5, 10, 15, 30, 60, 120, 1440])
            ListTile(
              title: Text(_reminderLabel(m),
                  style: TextStyle(color: c.textPrimary)),
              trailing: vm.formReminders.contains(m)
                  ? const Icon(Icons.check_rounded, color: _accent)
                  : null,
              onTap: () {
                vm.addFormReminder(m);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  void _pickRecurrence(
      BuildContext context, CalendarViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final r in ['none', 'daily', 'weekly', 'monthly', 'yearly'])
            ListTile(
              title: Text('calendar.rec.$r'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              trailing: vm.formRecurrence == r
                  ? const Icon(Icons.check_rounded, color: _accent)
                  : null,
              onTap: () {
                vm.setFormRecurrence(r);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  void _pickCategory(BuildContext context, CalendarViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          for (final cat in kEvCats)
            ListTile(
              leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: cat.color, shape: BoxShape.circle)),
              title: Text(cat.labelKey.tr(),
                  style: TextStyle(color: c.textPrimary)),
              trailing: vm.formCategory == cat.id
                  ? Icon(Icons.check_rounded, color: cat.color)
                  : null,
              onTap: () {
                vm.setFormCategory(cat.id);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _pickColor(BuildContext context, CalendarViewModel vm, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('calendar.color'.tr(),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final hex in _palette)
                  GestureDetector(
                    onTap: () {
                      vm.setFormColor(hex);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(
                            int.parse(hex.replaceAll('#', 'FF'), radix: 16)),
                        shape: BoxShape.circle,
                        border: vm.formColor == hex
                            ? Border.all(color: c.textPrimary, width: 3)
                            : null,
                      ),
                      child: vm.formColor == hex
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white)
                          : null,
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    vm.setFormColor(null);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border, width: 2),
                    ),
                    child: Icon(Icons.close_rounded, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  void _textInput(BuildContext context, CalendarViewModel vm, String title,
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
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () {
                onDone(ctrl.text);
                Navigator.pop(ctx);
              },
              child: Text('common.save'.tr(),
                  style: const TextStyle(color: _accent))),
        ],
      ),
    );
  }
}
