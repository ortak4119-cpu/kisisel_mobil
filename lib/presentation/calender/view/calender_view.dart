import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../models/calender/calendar_models.dart';
import '../../../models/note/note_models.dart';
import '../../../models/diary/diary_models.dart';
import '../../../models/task/task_models.dart';
import '../../../models/subscription/subscription_models.dart';
import '../../../models/budget/buget_models.dart';
import '../viewmodel/calender_viewmodel.dart';

@RoutePage()
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel()..refreshData(),
      child: Consumer<CalendarViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, viewModel, isDarkMode),

                  // Calendar
                  _buildCalendar(viewModel, isDarkMode),

                  // Events List
                  Expanded(
                    child: viewModel.isLoading
                        ? _buildLoadingState(isDarkMode)
                        : _buildEventsList(context, viewModel, isDarkMode),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddEventDialog(context, viewModel, isDarkMode),
              backgroundColor: const Color(0xFFB794F6),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Takvim',
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
              // View Toggle Button
              IconButton(
                onPressed: () => viewModel.toggleCalendarViewType(),
                icon: Icon(
                  viewModel.calendarViewType == CalendarViewType.month
                      ? Icons.view_week_rounded
                      : Icons.calendar_month_rounded,
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                ),
                tooltip: viewModel.calendarViewType == CalendarViewType.month
                    ? 'Haftalık Görünüm'
                    : 'Aylık Görünüm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(CalendarViewModel viewModel, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: viewModel.focusedMonth,
        selectedDayPredicate: (day) => viewModel.isSelectedDate(day),
        calendarFormat: viewModel.calendarViewType == CalendarViewType.month
            ? CalendarFormat.month
            : CalendarFormat.week,
        onDaySelected: (selectedDay, focusedDay) {
          viewModel.setSelectedDate(selectedDay);
        },
        onPageChanged: (focusedDay) {
          viewModel.setFocusedMonth(focusedDay);
        },
        calendarStyle: CalendarStyle(
          // Today
          todayDecoration: BoxDecoration(
            color: const Color(0xFFB794F6).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFB794F6),
              width: 2,
            ),
          ),
          todayTextStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
          // Selected Day
          selectedDecoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
            ),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          // Default Day
          defaultTextStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
          // Outside Days
          outsideTextStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textMutedDark
                : ColorConstant.textMutedLight,
            fontWeight: FontWeight.w500,
          ),
          // Weekend
          weekendTextStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
          // Markers
          markerDecoration: const BoxDecoration(
            color: Color(0xFFB794F6),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 4,
          cellMargin: const EdgeInsets.all(4),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: false,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            return _buildDayMarkers(date, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildDayMarkers(DateTime date, CalendarViewModel viewModel) {
    final events = viewModel.getEventsForMonth();
    final dateKey = DateTime(date.year, date.month, date.day);
    final dayEvents = events[dateKey] ?? [];

    if (dayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kilitsiz not
          if (dayEvents.contains('note'))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: const BoxDecoration(
                color: Color(0xFFB794F6),
                shape: BoxShape.circle,
              ),
            ),
          // Kilitli not
          if (dayEvents.contains('locked_note'))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFB794F6),
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
            ),
          // Günlük
          if (dayEvents.contains('diary'))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA07A),
                shape: BoxShape.circle,
              ),
            ),
          // Görev
          if (dayEvents.contains('task'))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
                shape: BoxShape.circle,
              ),
            ),
          // Calendar Events
          if (dayEvents.any((e) => e.startsWith('calendar_')))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: const BoxDecoration(
                color: Color(0xFF64B5F6),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFB794F6),
          ),
          const SizedBox(height: 16),
          Text(
            'Yükleniyor...',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final totalEvents = viewModel.getTotalEventsForSelectedDate();

    if (totalEvents == 0) {
      return _buildEmptyState(isDarkMode);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Calendar Events Section
        if (viewModel.calendarEventsForSelectedDate.isNotEmpty)
          _buildCalendarEventsSection(context, viewModel, isDarkMode),

        // Diary Section
        if (viewModel.diaryForSelectedDate != null)
          _buildDiarySection(context, viewModel, isDarkMode),

        // Unlocked Notes Section
        if (viewModel.unlockedNotesForSelectedDate.isNotEmpty)
          _buildUnlockedNotesSection(context, viewModel, isDarkMode),

        // Locked Notes Section
        if (viewModel.lockedNotesForSelectedDate.isNotEmpty)
          _buildLockedNotesSection(context, viewModel, isDarkMode),

        // Tasks Section
        if (viewModel.tasksForSelectedDate.isNotEmpty)
          _buildTasksSection(context, viewModel, isDarkMode),

        // Expenses Section
        if (viewModel.expensesForSelectedDate.isNotEmpty)
          _buildExpensesSection(context, viewModel, isDarkMode),

        // Subscriptions Section
        if (viewModel.subscriptionsForSelectedDate.isNotEmpty)
          _buildSubscriptionsSection(context, viewModel, isDarkMode),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFB794F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: const Color(0xFFB794F6).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bu gün için etkinlik yok',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir etkinlik eklemek için + butonuna tıklayın',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ CALENDAR EVENTS SECTION ============
  Widget _buildCalendarEventsSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final events = viewModel.calendarEventsForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Etkinlikler',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Events List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildCalendarEventCard(context, event, viewModel, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarEventCard(
      BuildContext context,
      CalendarEvent event,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final eventTypeColors = {
      'habit': const Color(0xFF66BB6A),
      'task': const Color(0xFFEF5350),
      'subscription': const Color(0xFFAB47BC),
      'diary': const Color(0xFFFFCA28),
      'reminder': const Color(0xFF42A5F5),
      'custom': const Color(0xFF78909C),
    };

    final eventTypeIcons = {
      'habit': Icons.fitness_center_rounded,
      'task': Icons.check_circle_outline_rounded,
      'subscription': Icons.payment_rounded,
      'diary': Icons.menu_book_rounded,
      'reminder': Icons.notifications_rounded,
      'custom': Icons.event_note_rounded,
    };

    final color = eventTypeColors[event.eventType] ?? const Color(0xFF78909C);
    final icon = eventTypeIcons[event.eventType] ?? Icons.event_note_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCalendarEventDetail(context, event, viewModel, isDarkMode),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Time & Description
                      if (event.eventTime != null || event.description != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (event.eventTime != null) ...[
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.eventTime!,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (event.eventTime != null && event.description != null) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? ColorConstant.textMutedDark
                                      : ColorConstant.textMutedLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            if (event.description != null)
                              Expanded(
                                child: Text(
                                  event.description!,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'habit':
        return 'Alışkanlık';
      case 'task':
        return 'Görev';
      case 'subscription':
        return 'Abonelik';
      case 'diary':
        return 'Günlük';
      case 'reminder':
        return 'Hatırlatma';
      case 'custom':
        return 'Özel';
      default:
        return 'Etkinlik';
    }
  }

  void _showCalendarEventDetail(
      BuildContext context,
      CalendarEvent event,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Etkinlik Detayı',
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info Cards
                      _buildInfoRow(
                        isDarkMode,
                        Icons.calendar_today_rounded,
                        'Tarih',
                        _formatEventDate(event.eventDate),
                      ),
                      if (event.eventTime != null)
                        _buildInfoRow(
                          isDarkMode,
                          Icons.access_time_rounded,
                          'Saat',
                          event.eventTime!,
                        ),


                      // Description
                      if (event.description != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Açıklama',
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditEventDialog(context, event, viewModel, isDarkMode);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(
                                  color: Color(0xFFB794F6),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Düzenle',
                                style: TextStyle(
                                  color: Color(0xFFB794F6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final confirm = await _showDeleteConfirmation(
                                    context,
                                    isDarkMode,
                                  );
                                  if (confirm == true) {
                                    final success = await viewModel.deleteCalendarEvent(event.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      if (success) {
                                        CustomSnackBar.showSuccess(context, 'Etkinlik silindi');
                                      } else {
                                        CustomSnackBar.showError(context, 'Etkinlik silinemedi');
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Sil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      bool isDarkMode,
      IconData icon,
      String label,
      String value,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, bool isDarkMode) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Etkinliği Sil',
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Bu etkinliği silmek istediğinizden emin misiniz?',
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
              'İptal',
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFE53935)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ADD EVENT DIALOG
  void _showAddEventDialog(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'custom';
    DateTime selectedDate = viewModel.selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Yeni Etkinlik',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                TextField(
                  controller: titleController,
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Etkinlik başlığı',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextField(
                  controller: descriptionController,
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Etkinlik açıklaması (opsiyonel)',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),



                // Tarih Seçimi
                ListTile(
                  title: Text(
                    'Tarih',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Color(0xFFB794F6)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),

                // Saat Seçimi
                ListTile(
                  title: Text(
                    'Saat (Opsiyonel)',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  subtitle: Text(
                    selectedTime != null
                        ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Seçilmedi',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.access_time, color: Color(0xFFB794F6)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    CustomSnackBar.showError(context, 'Başlık boş olamaz');
                    return;
                  }

                  final request = CalendarEventRequest(
                    title: titleController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    eventType: selectedType,
                    eventDate:
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    eventTime: selectedTime != null
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                  );

                  final success = await viewModel.createCalendarEvent(request);

                  if (context.mounted) {
                    Navigator.pop(context);

                    if (success) {
                      CustomSnackBar.showSuccess(context, 'Etkinlik oluşturuldu');
                    } else {
                      CustomSnackBar.showError(context, 'Etkinlik oluşturulamadı');
                    }
                  }
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ DİĞER SECTION'LAR (Diary, Notes, Tasks, vb.) ============
  // Mevcut kodunuzdan diary, notes, tasks, expenses, subscriptions section'larını buraya ekleyin
  // Örnek olarak sadece birkaç tanesini ekliyorum:

  Widget _buildDiarySection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final diary = viewModel.diaryForSelectedDate!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA07A), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Günlük',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Diary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFA07A).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood
                Row(
                  children: [
                    Text(
                      _getMoodEmoji(diary.mood ?? 'neutral'),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getMoodLabel(diary.mood ?? 'neutral'),
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (diary.content != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    diary.content!,
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedNotesSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final notes = viewModel.unlockedNotesForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.note_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notlar',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB794F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: const TextStyle(
                      color: Color(0xFFB794F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB794F6).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title != null) ...[
                      Text(
                        note.title!,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (note.content != null)
                      Text(
                        note.content!,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLockedNotesSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final notes = viewModel.lockedNotesForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B6FE8), Color(0xFF7C4DFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kilitli Notlar',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B6FE8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: const TextStyle(
                      color: Color(0xFF9B6FE8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Locked Notes List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return GestureDetector(
                onTap: () => _showUnlockDialog(
                  context,
                  note,
                  viewModel,
                  isDarkMode,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFB794F6).withOpacity(0.15),
                        const Color(0xFF9B6FE8).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB794F6).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Lock Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB794F6).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title ?? 'Başlıksız Not',
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Görüntülemek için dokunun',
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textMutedDark
                                    : ColorConstant.textMutedLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow Icon
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: const Color(0xFFB794F6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Unlock Dialog
  void _showUnlockDialog(
      BuildContext context,
      Note note,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFB794F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFFB794F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kilitli Not',
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu notu görüntülemek için PIN kodunu girin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 16,
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
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? ColorConstant.borderColorDark
                        : ColorConstant.borderColorLight,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFB794F6),
                    width: 2,
                  ),
                ),
                hintText: '••••',
                hintStyle: TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  color: isDarkMode
                      ? ColorConstant.textMutedDark
                      : ColorConstant.textMutedLight,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                if (pinController.text.length == 4) {
                  Navigator.pop(context);

                  // Unlock note
                  final success = await viewModel.unlockNote(
                    note.id,
                    pinController.text,
                  );

                  if (context.mounted) {
                    if (success) {
                      // Başarılı - kilidi açılan notu göster
                      final unlockedNote = viewModel.getNoteById(note.id);
                      if (unlockedNote != null) {
                        _showUnlockedNoteDetail(
                          context,
                          unlockedNote,
                          isDarkMode,
                        );
                      }
                    } else {
                      // Hatalı PIN
                      CustomSnackBar.showError(context, 'Hatalı PIN kodu');
                    }
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Aç',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Unlocked Note Detail Bottom Sheet
  void _showUnlockedNoteDetail(
      BuildContext context,
      Note note,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatNoteDate(note.createdAt),
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (note.title != null && note.title!.isNotEmpty) ...[
                        Text(
                          note.title!,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Content
                      if (note.content != null && note.content!.isNotEmpty)
                        Text(
                          note.content!,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNoteDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildTasksSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final tasks = viewModel.tasksForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Görevler',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Color(0xFF66BB6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF81C784).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: task.isCompleted
                          ? const Color(0xFF66BB6A)
                          : isDarkMode
                          ? ColorConstant.textMutedDark
                          : ColorConstant.textMutedLight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final expenses = viewModel.expensesForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Harcamalar',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${expenses.length}',
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expenses List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getExpenseCategoryIcon(expense.category),
                        color: const Color(0xFFEF5350),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Label (Türkçe)
                          Text(
                            _getExpenseCategoryLabel(expense.category),
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Description (if exists)
                          if (expense.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              expense.description ?? "",
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Amount
                    Text(
                      '₺${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getExpenseCategoryLabel(String category) {
    switch (category) {
      case 'food':
        return 'Yemek';
      case 'transportation':
        return 'Ulaşım';
      case 'entertainment':
        return 'Eğlence';
      case 'shopping':
        return 'Alışveriş';
      case 'bills':
        return 'Faturalar';
      case 'health':
        return 'Sağlık';
      case 'education':
        return 'Eğitim';
      case 'other':
        return 'Diğer';
      default:
        return category;
    }
  }

  IconData _getExpenseCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Widget _buildSubscriptionsSection(
      BuildContext context,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final subscriptions = viewModel.subscriptionsForSelectedDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.subscriptions_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Abonelikler',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${subscriptions.length}',
                    style: const TextStyle(
                      color: Color(0xFFAB47BC),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subscriptions List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFAB47BC).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.name,
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : ColorConstant.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ödeme Günü',
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${subscription.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFAB47BC),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'very_happy':
        return '😄';
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😢';
      case 'very_sad':
        return '😭';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'very_happy':
        return 'Çok Mutlu';
      case 'happy':
        return 'Mutlu';
      case 'neutral':
        return 'Normal';
      case 'sad':
        return 'Üzgün';
      case 'very_sad':
        return 'Çok Üzgün';
      default:
        return 'Bilinmiyor';
    }
  }


  // EDIT EVENT DIALOG
  void _showEditEventDialog(
      BuildContext context,
      CalendarEvent event,
      CalendarViewModel viewModel,
      bool isDarkMode,
      ) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    DateTime selectedDate = DateTime.parse(event.eventDate);
    TimeOfDay? selectedTime;

    if (event.eventTime != null) {
      final timeParts = event.eventTime!.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Etkinliği Düzenle',
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                TextField(
                  controller: titleController,
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Etkinlik başlığı',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextField(
                  controller: descriptionController,
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Etkinlik açıklaması (opsiyonel)',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Tarih Seçimi
                ListTile(
                  title: Text(
                    'Tarih',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Color(0xFFB794F6)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),

                // Saat Seçimi
                ListTile(
                  title: Text(
                    'Saat (Opsiyonel)',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                  subtitle: Text(
                    selectedTime != null
                        ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Seçilmedi',
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() => selectedTime = null);
                          },
                        ),
                      const Icon(Icons.access_time, color: Color(0xFFB794F6)),
                    ],
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB794F6), Color(0xFF9B6FE8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    CustomSnackBar.showError(context, 'Başlık boş olamaz');
                    return;
                  }

                  final request = CalendarEventUpdateRequest(
                    title: titleController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    eventDate:
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    eventTime: selectedTime != null
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                  );

                  final success = await viewModel.updateCalendarEvent(event.id, request);

                  if (context.mounted) {
                    Navigator.pop(context);

                    if (success) {
                      CustomSnackBar.showSuccess(context, 'Etkinlik güncellendi');
                    } else {
                      CustomSnackBar.showError(context, 'Etkinlik güncellenemedi');
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Güncelle',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}