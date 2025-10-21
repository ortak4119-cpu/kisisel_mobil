import 'package:auto_route/auto_route.dart';
import 'package:base/presentation/finance/view/finance_view.dart';
import 'package:base/presentation/notes_diary/view/notes_diary_view.dart';
import 'package:base/presentation/profile/view/profile_view.dart';
import 'package:base/presentation/tasks_habits/view/tasks_habits_view.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/route/app_router.gr.dart';

@RoutePage()
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  // Sayfalar
  final List<Widget> _pages = [
    const NotesDiaryView(),
    const TasksHabitsView(),
    const FinanceView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? ColorConstant.cardColorDark
              : ColorConstant.white,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? ColorConstant.black.withOpacity(0.3)
                  : ColorConstant.primaryPurple.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GNav(
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              gap: 8,
              activeColor: isDarkMode
                  ? ColorConstant.white
                  : ColorConstant.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isDarkMode
                  ? ColorConstant.primaryDarkModePurple
                  : ColorConstant.primaryPurple,
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Ana Sayfa',
                ),
                GButton(
                  icon: Icons.task_rounded,
                  text: 'Görevler',
                ),
                GButton(
                  icon: Icons.attach_money,
                  text: 'Finans',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }

  void _showAddBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? ColorConstant.borderColorDark
                        : ColorConstant.borderColorLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Yeni Ekle',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                _buildAddOption(
                  context,
                  icon: Icons.task_rounded,
                  title: 'Görev Ekle',
                  subtitle: 'Yeni bir görev oluştur',
                  color: ColorConstant.accentBlue,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Görev ekleme sayfasına git
                  },
                ),
                const SizedBox(height: 12),
                _buildAddOption(
                  context,
                  icon: Icons.emoji_events_rounded,
                  title: 'Alışkanlık Ekle',
                  subtitle: 'Yeni bir alışkanlık oluştur',
                  color: ColorConstant.accentYellow,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Alışkanlık ekleme sayfasına git
                  },
                ),
                const SizedBox(height: 12),
                _buildAddOption(
                  context,
                  icon: Icons.note_add_rounded,
                  title: 'Not Ekle',
                  subtitle: 'Yeni bir not oluştur',
                  color: ColorConstant.accentGreen,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Not ekleme sayfasına git
                  },
                ),
                const SizedBox(height: 12),
                _buildAddOption(
                  context,
                  icon: Icons.book_rounded,
                  title: 'Günlük Girişi',
                  subtitle: 'Günlüğüne yeni bir giriş ekle',
                  color: ColorConstant.accentOrange,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Günlük ekleme sayfasına git
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required bool isDarkMode,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? ColorConstant.cardColorDark.withOpacity(0.5)
                : ColorConstant.bgColorLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isDarkMode
                    ? ColorConstant.textMutedDark
                    : ColorConstant.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SAYFA WIDGET'LARI ====================

// Dashboard Page
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
          'Ana Sayfa',
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
              Icons.notifications_rounded,
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
            ),
            onPressed: () {},
          ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorConstant.primaryPurple.withOpacity(0.2),
                    ColorConstant.accentBlue.withOpacity(0.2),
                  ],
                ),
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
              'Ana Sayfa',
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
              'Hoş geldiniz!',
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
          'Görevler',
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
                color: ColorConstant.accentBlue.withOpacity(0.15),
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
              'Görevler',
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
              'Henüz görev eklenmemiş',
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
          'Alışkanlıklar',
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
                color: ColorConstant.accentYellow.withOpacity(0.15),
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
              'Alışkanlıklar',
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
              'Henüz alışkanlık eklenmemiş',
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
          'Profil',
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
                color: ColorConstant.accentOrange.withOpacity(0.15),
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
              'Profil',
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
              'Profilinizi görüntüleyin',
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