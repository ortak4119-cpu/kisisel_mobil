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

  // Alt menü renkleri (referans tasarım: seçili öğede pembe hap).
  static const _navAccent = Color(0xFFD6336C); // gül-magenta vurgu
  static const _navPillLight = Color(0xFFFCE3EC); // açık pembe hap zemini
  static const _navIdleIconLight = Color(0xFF3C4250); // koyu ikon (seçili değil)
  static const _navIdleLabelLight = Color(0xFF8A8F9A); // gri etiket

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
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode
            ? ColorConstant.cardColorDark
            : ColorConstant.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          // Tüm sekmeler eşit ikon+yazı olarak hizalı dağıtılır.
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
              _buildNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'navigation.calendar'.tr(),
                index: 3,
                isDarkMode: isDarkMode,
              ),
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
    final idleIcon =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleIconLight;
    final idleLabel =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleLabelLight;
    final pill = isDarkMode
        ? _navAccent.withValues(alpha: 0.22)
        : _navPillLight;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon + seçili olunca animasyonla beliren pembe hap.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 18 : 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? pill : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? _navAccent : idleIcon,
              ),
            ),
            const SizedBox(height: 4),
            // Uzun etiketler (ör. "Alışkanlık") dar yuvada taşmasın diye
            // tek satıra sığacak şekilde ölçeklenir.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _navAccent : idleLabel,
                ),
                child: Text(label, maxLines: 1, softWrap: false),
              ),
            ),
          ],
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