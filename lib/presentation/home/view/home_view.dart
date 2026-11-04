import 'dart:ui' show ImageFilter;
import 'package:auto_route/auto_route.dart';
import 'package:base/presentation/calender/view/calender_view.dart';
import 'package:base/presentation/finance/view/finance_view.dart';
import 'package:base/presentation/notes_diary/view/notes_diary_view.dart';
import 'package:base/presentation/profile/view/profile_view.dart';
import 'package:base/presentation/tasks_habits/view/tasks_habits_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/responsive.dart';
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

  // Alt menü pasif renkleri. Seçili vurgu artık ColorConstant.accentOrange
  // (seçili temanın aksanı) ile verilir.
  static const _navIdleIconLight = Color(0xFF6F6456); // sıcak kahve ikon (pasif)
  static const _navIdleLabelLight = Color(0xFF8A7F6C); // soluk etiket

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
      // Cam alt menünün arkasındaki içeriği bulanıklaştırabilmesi için gövde
      // alt menünün altına kadar uzanır.
      extendBody: true,
      // Geniş ekranda (iPad/tablet) içerik ortalanır ve makul genişliğe
      // sınırlanır; telefonda tam genişlik korunur. Her sekme için tek yerden.
      body: ResponsiveCenter(child: _pages[_selectedIndex]),
      bottomNavigationBar: _buildGlassNav(isDarkMode),
    );
  }

  /// Buzlu cam (glassmorphism) alt menü — arkadaki içeriği bulanıklaştırır.
  Widget _buildGlassNav(bool isDarkMode) {
    final glassColor = isDarkMode
        ? ColorConstant.cardColorDark.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.60);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.60);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'navigation.home'.tr(),
                      index: 0,
                      isDarkMode: isDarkMode),
                  _buildNavItem(
                      icon: Icons.checklist_rounded,
                      label: 'navigation.tasks'.tr(),
                      index: 1,
                      isDarkMode: isDarkMode),
                  _buildNavItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'navigation.habits'.tr(),
                      index: 2,
                      isDarkMode: isDarkMode),
                  _buildNavItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'navigation.calendar'.tr(),
                      index: 3,
                      isDarkMode: isDarkMode),
                  _buildNavItem(
                      icon: Icons.attach_money,
                      label: 'navigation.finance'.tr(),
                      index: 4,
                      isDarkMode: isDarkMode),
                  _buildNavItem(
                      icon: Icons.person_rounded,
                      label: 'navigation.profile'.tr(),
                      index: 5,
                      isDarkMode: isDarkMode),
                ],
              ),
            ),
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
    final idleIcon =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleIconLight;
    final idleLabel =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleLabelLight;
    // Dock büyüteç: aktife uzaklığa göre ikon ölçeği.
    final dist = (index - _selectedIndex).abs();
    final scale = dist == 0 ? 1.4 : (dist == 1 ? 1.15 : 1.0);

    return _NavItem(
      icon: icon,
      label: label,
      selected: _selectedIndex == index,
      iconScale: scale,
      // Seçili vurgu artık seçili temanın aksanı (FAB/Kaydet ile uyumlu).
      accent: ColorConstant.accentOrange,
      idleIcon: idleIcon,
      idleLabel: idleLabel,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

/// Alt menü öğesi. Seçilince/tıklanınca ikon yaylanarak zıplar (pop),
/// pembe hap genişler ve hafifçe yukarı kalkar — modern, canlı his.
/// Cam Büyüteç (dock) alt menü öğesi. İkon, aktife uzaklığa göre yaylanarak
/// büyür (AnimatedScale + easeOutBack); seçili olan turuncuya döner.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final double iconScale;
  final VoidCallback onTap;
  final Color accent;
  final Color idleIcon;
  final Color idleLabel;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.iconScale,
    required this.onTap,
    required this.accent,
    required this.idleIcon,
    required this.idleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: iconScale,
              child: Icon(
                icon,
                size: 22,
                color: selected ? accent : idleIcon,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : idleLabel,
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