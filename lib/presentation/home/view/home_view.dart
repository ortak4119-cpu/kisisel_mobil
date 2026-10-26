import 'package:auto_route/auto_route.dart';
import 'package:base/presentation/calender/view/calender_view.dart';
import 'package:base/presentation/finance/view/finance_view.dart';
import 'package:base/presentation/notes_diary/view/notes_diary_view.dart';
import 'package:base/presentation/profile/view/profile_view.dart';
import 'package:base/presentation/tasks_habits/view/tasks_habits_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../service/update/update_service.dart';

@RoutePage()
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ana ekran acilinca App Store'da yeni surum var mi kontrol et.
    // Ilk kare cizildikten sonra, kisa bir gecikmeyle (acilisi yavaslatmaz).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        UpdateService.checkForUpdate(context);
      }
    });
  }

  // Sayfalar — Görevler ve Alışkanlıklar artık ayrı sekmeler.
  final List<Widget> _pages = [
    const NotesDiaryView(), // 0 Notlar
    const TasksHabitsView(key: ValueKey('tasks'), mode: 'tasks'), // 1 Görevler
    const TasksHabitsView(
        key: ValueKey('habits'), mode: 'habits'), // 2 Alışkanlıklar
    const CalendarView(), // 3 Takvim (ortadaki FAB)
    const FinanceView(), // 4 Finans
    const ProfileView(), // 5 Profil
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          setState(() {
            _selectedIndex = 3; // Takvim sayfasına git
          });
        },
        backgroundColor: _selectedIndex == 3
            ? (isDarkMode
            ? ColorConstant.primaryDarkModePurple
            : ColorConstant.primaryPurple)
            : (isDarkMode
            ? ColorConstant.primaryDarkModePurple.withValues(alpha: 0.8)
            : ColorConstant.primaryPurple.withValues(alpha: 0.8)),
        elevation: 6,
        child: Icon(
          Icons.calendar_month_rounded,
          color: Colors.white,
          size: _selectedIndex == 3 ? 30 : 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode
            ? ColorConstant.cardColorDark
            : ColorConstant.white,
        elevation: 8,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Stack(
            children: [
          // Sol (3 öğe) ve sağ (2 öğe) gruplar eşit flex ile dengelenir;
          // ortadaki boşluk tam merkeze oturur, böylece FAB ve "Takvim"
          // etiketi çakışmadan hizalanır.
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'navigation.home'.tr(),
                      index: 0,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: Icons.checklist_rounded,
                      label: 'navigation.tasks'.tr(),
                      index: 1,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'navigation.habits'.tr(),
                      index: 2,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              // Ortadaki takvim FAB'ı (notch) için merkez boşluk.
              const SizedBox(width: 56),
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: Icons.attach_money,
                      label: 'navigation.finance'.tr(),
                      index: 4,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: Icons.person_rounded,
                      label: 'navigation.profile'.tr(),
                      index: 5,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Ortadaki FAB'ın tam altındaki "Takvim" etiketi (gerçek merkez).
          Positioned(
            left: 0,
            right: 0,
            bottom: 7,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'navigation.calendar'.tr(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _selectedIndex == 3 ? 12 : 11,
                    fontWeight:
                        _selectedIndex == 3 ? FontWeight.w600 : FontWeight.w500,
                    color: _selectedIndex == 3
                        ? (isDarkMode
                            ? ColorConstant.primaryDarkModePurple
                            : ColorConstant.primaryPurple)
                        : (isDarkMode
                            ? ColorConstant.textMutedDark
                            : ColorConstant.textMutedLight),
                  ),
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDarkMode
                    ? ColorConstant.primaryDarkModePurple
                    : ColorConstant.primaryPurple)
                    : (isDarkMode
                    ? ColorConstant.textMutedDark
                    : ColorConstant.textMutedLight),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDarkMode
                      ? ColorConstant.primaryDarkModePurple
                      : ColorConstant.primaryPurple)
                      : (isDarkMode
                      ? ColorConstant.textMutedDark
                      : ColorConstant.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

// Home Page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'home.title'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.primaryPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_rounded,
                size: 60,
                color: ColorConstant.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'home.title'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.welcome'.tr(),
              style: TextStyle(
                fontSize: 16,
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
}

// Tasks Page
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'tasks.title'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.accentBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_rounded,
                size: 60,
                color: ColorConstant.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'tasks.title'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.emptyTasks'.tr(),
              style: TextStyle(
                fontSize: 16,
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
}

// Habits Page
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'habits.title'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.accentYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 60,
                color: ColorConstant.accentYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'habits.title'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.emptyHabits'.tr(),
              style: TextStyle(
                fontSize: 16,
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
}

// Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'profile.title'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
            ),
            onPressed: () {
              context.router.push(const SettingsRoute());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstant.accentOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 60,
                color: ColorConstant.accentOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'profile.title'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.emptyProfile'.tr(),
              style: TextStyle(
                fontSize: 16,
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
}