import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../models/social/social_model.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../widgets/user_profile_bottom_sheet.dart';

@RoutePage()
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (vm.isLoading && !vm.isUserLoaded) {
            return Scaffold(
              backgroundColor: isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
              body: const Center(child: CircularProgressIndicator(color: Color(0xFFF6A821))),
            );
          }

          final user = vm.currentUser;
          if (user == null) {
            return Scaffold(
              backgroundColor: isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🤔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'profile.userNotFound'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
            appBar: _buildAppBar(context, isDark),
            body: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                SliverToBoxAdapter(child: _buildProfileCard(context, vm, isDark)),
                SliverToBoxAdapter(child: _buildThreeStats(vm, isDark)),
                SliverToBoxAdapter(child: _buildLevelCard(vm, isDark)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabDelegate(tabBar: _buildTabBar(isDark), isDark: isDark),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _StatsContent(vm: vm, onViewAchievements: () => _tabController.animateTo(1)),
                  _AchievementsTab(viewModel: vm),
                  _FriendsTab(viewModel: vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Profil',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.qr_code_rounded,
              color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
          onPressed: () => CustomSnackBar.showInfo(context, 'QR kodu yakında gelecek'),
        ),
        IconButton(
          icon: Icon(Icons.settings_rounded,
              color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
          onPressed: () => context.router.push(const SettingsRoute()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  TabBar _buildTabBar(bool isDark) {
    return TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        color: const Color(0xFFF6A821),
        borderRadius: BorderRadius.circular(24),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor:
          isDark ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'İstatistikler'),
        Tab(text: 'Başarılar'),
        Tab(text: 'Arkadaşlar'),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, ProfileViewModel vm, bool isDark) {
    final user = vm.currentUser!;
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final joined = "${months[user.createdAt.month - 1]} ${user.createdAt.year}'dan beri üye";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF6A821).withValues(alpha: 0.15),
                backgroundImage: user.profilePictureUrl != null
                    ? NetworkImage(user.profilePictureUrl!)
                    : null,
                child: user.profilePictureUrl == null
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFF6A821)),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImageSourceDialog(context, vm, isCover: false),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6A821),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? ColorConstant.bgColorDark : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Color(0xFFF6A821), shape: BoxShape.circle),
                        child: const Icon(Icons.verified, size: 14, color: Colors.white),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight),
                ),
                const SizedBox(height: 2),
                Text(
                  joined,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.router.push(const SettingsRoute()),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Profili Düzenle',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(
                        color: isDark
                            ? ColorConstant.borderColorDark
                            : ColorConstant.borderColorLight),
                    foregroundColor:
                        isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeStats(ProfileViewModel vm, bool isDark) {
    final friendCount = vm.profileStats?.social.friends ?? vm.friends.length;
    final badgeCount = vm.profileStats?.gamification.achievementsUnlocked ??
        vm.achievements.where((a) => a.isCompleted).length;
    final daysActive = vm.levelInfo?.dailyStreak ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _statChip(Icons.people_rounded, '$friendCount', 'Arkadaş', isDark),
          _vDivider(isDark),
          _statChip(Icons.emoji_events_rounded, '$badgeCount', 'Başarı', isDark),
          _vDivider(isDark),
          _statChip(Icons.check_box_rounded, '$daysActive', 'Gün aktif', isDark),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF6A821), size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _vDivider(bool isDark) => Container(
        width: 1,
        height: 48,
        color: isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight,
      );

  Widget _buildLevelCard(ProfileViewModel vm, bool isDark) {
    final level = vm.levelInfo?.currentLevel ?? vm.profileStats?.gamification.level ?? 1;
    final totalXp = vm.levelInfo?.totalXp ?? vm.profileStats?.gamification.totalXp ?? 0;
    final progress =
        ((vm.levelInfo?.progressPercentage ?? 0) / 100.0).clamp(0.0, 1.0);
    final currentXp = vm.levelInfo?.currentXp ?? 0;
    final nextLevelXp = vm.levelInfo?.nextLevelXp ?? 1000;
    final remaining = (nextLevelXp - currentXp).clamp(0, 999999);
    final badgeCount = vm.profileStats?.gamification.achievementsUnlocked ??
        vm.achievements.where((a) => a.isCompleted).length;

    return GestureDetector(
      onTap: () => _tabController.animateTo(1),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6A821), Color(0xFFE8921A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFF6A821).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Seviye $level',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 13),
                    ],
                  ),
                  Text('${_fmtXp(totalXp)} XP',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$remaining XP kaldı',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500)),
                      Text('Seviye ${level + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text('$badgeCount rozet',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Detaylar >',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtXp(int n) {
    if (n >= 1000) {
      final high = n ~/ 1000;
      final low = (n % 1000).toString().padLeft(3, '0');
      return '$high.$low';
    }
    return '$n';
  }

  void _showImageSourceDialog(BuildContext context, ProfileViewModel viewModel,
      {required bool isCover}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isCover
                      ? 'profile.photoSelect.coverTitle'.tr()
                      : 'profile.photoSelect.profileTitle'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [ColorConstant.accentBlue, ColorConstant.primaryPurple]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: ColorConstant.white),
                ),
                title: Text(
                  'profile.photoSelect.fromGallery'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  'profile.photoSelect.fromGallerySubtitle'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isCover) {
                    viewModel.updateCoverImage(context, ImageSource.gallery);
                  } else {
                    viewModel.updateProfilePicture(context, ImageSource.gallery);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [ColorConstant.accentYellow, ColorConstant.accentOrange]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: ColorConstant.white),
                ),
                title: Text(
                  'profile.photoSelect.takePhoto'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  'profile.photoSelect.takePhotoSubtitle'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isCover) {
                    viewModel.updateCoverImage(context, ImageSource.camera);
                  } else {
                    viewModel.updateProfilePicture(context, ImageSource.camera);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== STICKY TAB DELEGATE ====================

class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ColorConstant.cardColorDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabDelegate old) => old.isDark != isDark;
}

// ==================== İSTATİSTİKLER CONTENT ====================

class _StatsContent extends StatelessWidget {
  final ProfileViewModel vm;
  final VoidCallback onViewAchievements;

  const _StatsContent({required this.vm, required this.onViewAchievements});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = vm.profileStats;

    if (stats == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF6A821)));
    }

    final habitRate = stats.habits.active > 0
        ? (stats.habits.completedToday / stats.habits.active * 100).round()
        : 0;
    final recentAchievements =
        vm.achievements.where((a) => a.isCompleted).take(3).toList();

    const taskGoal = 10;
    final taskProgress = (stats.tasks.completed / taskGoal).clamp(0.0, 1.0);
    final budgetProgress = stats.budget.monthlyBudget > 0
        ? (stats.budget.thisMonthExpenses / stats.budget.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final savingsRate = stats.budget.monthlyBudget > 0
        ? ((1 - budgetProgress) * 100).round()
        : 0;

    const orange = Color(0xFFF6A821);

    return RefreshIndicator(
      onRefresh: () => vm.refreshAll(),
      color: orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ─── Bu ayki ilerleme ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bu ayki ilerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? ColorConstant.cardColorDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? ColorConstant.borderColorDark
                          : ColorConstant.borderColorLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentMonth(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isDark
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 stat cards
          Row(
            children: [
              Expanded(
                child: _monthCard(
                  icon: Icons.check_box_rounded,
                  iconColor: orange,
                  iconBg: orange.withValues(alpha: 0.1),
                  label: 'Tamamlanan görev',
                  value: '${stats.tasks.completed}',
                  sub: '↑%12',
                  subColor: Colors.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _monthCard(
                  icon: Icons.track_changes_rounded,
                  iconColor: orange,
                  iconBg: orange.withValues(alpha: 0.1),
                  label: 'Alışkanlık oranı',
                  value: '$habitRate%',
                  sub: '${stats.habits.currentStreak} gün seri',
                  subColor: isDark
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _monthCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: ColorConstant.accentBlue,
                  iconBg: ColorConstant.accentBlue.withValues(alpha: 0.1),
                  label: 'Günlük not',
                  value: '${stats.diary.thisMonth}',
                  sub: 'bu ay',
                  subColor: isDark
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _monthCard(
                  icon: Icons.sticky_note_2_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  iconBg: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  label: 'Oluşturulan not',
                  value: '${stats.notes.total}',
                  sub: '${stats.notes.locked} sabitlenmiş',
                  subColor: isDark
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Son başarılar ───
          if (recentAchievements.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son başarılar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
                GestureDetector(
                  onTap: onViewAchievements,
                  child: const Text('Tümünü gör >',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF6A821))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(
                recentAchievements.length,
                (i) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i < recentAchievements.length - 1 ? 8 : 0),
                    child: _achievementBadge(recentAchievements[i], isDark),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ─── Kişisel hedefler ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kişisel hedefler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
              ),
              GestureDetector(
                onTap: () => context.router.push(const SettingsRoute()),
                child: const Text('Hedefleri düzenle >',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF6A821))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _goalRow(
            context,
            icon: Icons.track_changes_rounded,
            iconColor: orange,
            label: 'Günlük $taskGoal görev',
            progress: taskProgress,
            progressColor: orange,
            rightText: '${stats.tasks.completed.clamp(0, taskGoal)}/$taskGoal',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _goalRow(
            context,
            icon: Icons.savings_rounded,
            iconColor: ColorConstant.accentGreen,
            label: 'Aylık tasarruf',
            progress: (1 - budgetProgress).clamp(0.0, 1.0),
            progressColor: ColorConstant.accentGreen,
            rightText: '%$savingsRate/%30',
            rightColor: ColorConstant.accentGreen,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // ─── Ayarlar ───
          _settingsRow(context, Icons.person_outline_rounded, 'Hesap bilgileri',
              isDark: isDark),
          _settingsRow(context, Icons.notifications_outlined, 'Bildirimler',
              isDark: isDark,
              badge: vm.friendRequests.isNotEmpty ? '${vm.friendRequests.length}' : null),
          _settingsRow(context, Icons.palette_outlined, 'Görünüm ve tema',
              isDark: isDark, trailing: isDark ? 'Koyu' : 'Açık'),
          _settingsRow(context, Icons.shield_outlined, 'Gizlilik ve güvenlik',
              isDark: isDark),
          _settingsRow(context, Icons.cloud_outlined, 'Yedekleme ve senkronizasyon',
              isDark: isDark,
              trailing: 'Açık',
              trailingColor: ColorConstant.accentGreen),
          const SizedBox(height: 4),
          _settingsRow(context, Icons.help_outline_rounded, 'Yardım ve destek',
              isDark: isDark, muted: true),
          _settingsRow(context, Icons.info_outline_rounded, 'Uygulama hakkında',
              isDark: isDark, muted: true),
          _settingsRow(context, Icons.logout_rounded, 'Çıkış yap',
              isDark: isDark, isLogout: true),
        ],
      ),
    );
  }

  Widget _monthCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge(achievement, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFF6A821).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(achievement.icon ?? '🏆', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            achievement.titleKey ?? 'Başarı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.descriptionKey ?? '',
            style: TextStyle(
                fontSize: 10,
                color: isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _goalRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required double progress,
    required Color progressColor,
    required String rightText,
    Color? rightColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstant.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? ColorConstant.bgColorDark
                        : ColorConstant.borderColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            rightText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: rightColor ??
                  (isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
        ],
      ),
    );
  }

  Widget _settingsRow(
    BuildContext context,
    IconData icon,
    String label, {
    required bool isDark,
    String? badge,
    String? trailing,
    Color? trailingColor,
    bool muted = false,
    bool isLogout = false,
  }) {
    final labelColor = isLogout
        ? ColorConstant.errorRed
        : muted
            ? (isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight)
            : (isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight);
    final iconColor = isLogout
        ? ColorConstant.errorRed
        : muted
            ? (isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight)
            : (isDark ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight);

    return InkWell(
      onTap: () => context.router.push(const SettingsRoute()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15, color: labelColor, fontWeight: FontWeight.w500)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF6A821),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 13,
                  color: trailingColor ??
                      (isDark
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
          ],
        ),
      ),
    );
  }

  String _currentMonth() {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[DateTime.now().month - 1];
  }
}

// ==================== ARKADAŞLAR TAB ====================

class _FriendsTab extends StatelessWidget {
  final ProfileViewModel viewModel;

  const _FriendsTab({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => viewModel.loadFriends(),
      color: ColorConstant.accentBlue,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () => _showSearchDialog(context, viewModel, isDarkMode),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstant.accentBlue.withValues(alpha: 0.1),
                    ColorConstant.primaryPurple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: ColorConstant.accentBlue.withValues(alpha: 0.3), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [ColorConstant.accentBlue, ColorConstant.primaryPurple]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.search_rounded, color: ColorConstant.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.friends.searchTitle'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'profile.friends.searchSubtitle'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
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
          const SizedBox(height: 24),

          if (viewModel.friendRequests.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [ColorConstant.accentYellow, ColorConstant.accentOrange]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⏰', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text(
                  'profile.friends.requests'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstant.accentYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewModel.friendRequests.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ColorConstant.accentYellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...viewModel.friendRequests
                .map((r) => _buildFriendRequestCard(context, r, viewModel, isDarkMode)),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [ColorConstant.accentBlue, ColorConstant.primaryPurple]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('👥', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'profile.friends.myFriends'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstant.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${viewModel.friends.length}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ColorConstant.accentBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (viewModel.friends.isNotEmpty)
            ...viewModel.friends
                .map((f) => _buildFriendCard(context, f, viewModel, isDarkMode))
          else
            _buildEmptyState(
              illustration: 'empty_habits.svg',
              message: 'profile.friends.emptyState'.tr(),
              subtitle: 'profile.friends.emptyStateSubtitle'.tr(),
              accent: ColorConstant.accentBlue,
            ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(
      BuildContext context, request, ProfileViewModel viewModel, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          ColorConstant.accentYellow.withValues(alpha: 0.1),
          ColorConstant.accentOrange.withValues(alpha: 0.05)
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: ColorConstant.accentYellow.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ColorConstant.accentBlue.withValues(alpha: 0.2),
                backgroundImage: request.sender?.profilePictureUrl != null
                    ? NetworkImage(request.sender!.profilePictureUrl!)
                    : null,
                child: request.sender?.profilePictureUrl == null
                    ? Text(request.sender!.displayName[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ColorConstant.accentBlue))
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: ColorConstant.accentYellow, shape: BoxShape.circle),
                  child: const Text('👋', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.sender!.displayName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight)),
                Text('@${request.sender!.username}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => viewModel.acceptFriendRequest(request.id, context),
                style: IconButton.styleFrom(
                    backgroundColor: ColorConstant.accentGreen.withValues(alpha: 0.15)),
                icon: Icon(Icons.check_rounded, color: ColorConstant.accentGreen),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => viewModel.rejectFriendRequest(request.id, context),
                style: IconButton.styleFrom(
                    backgroundColor: ColorConstant.errorRed.withValues(alpha: 0.15)),
                icon: Icon(Icons.close_rounded, color: ColorConstant.errorRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
      BuildContext context, friend, ProfileViewModel viewModel, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showUserProfileDialog(context, friend.id, viewModel, isDarkMode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight,
              width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: ColorConstant.accentBlue.withValues(alpha: 0.2),
              backgroundImage: friend.profilePictureUrl != null
                  ? NetworkImage(friend.profilePictureUrl!)
                  : null,
              child: friend.profilePictureUrl == null
                  ? Text(friend.displayName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ColorConstant.accentBlue))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.displayName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('@${friend.username}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            ColorConstant.accentYellow.withValues(alpha: 0.2),
                            ColorConstant.accentOrange.withValues(alpha: 0.2)
                          ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text('Lv.${friend.level}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: ColorConstant.accentYellow)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
          ],
        ),
      ),
    );
  }

  void _showUserProfileDialog(
      BuildContext context, int userId, ProfileViewModel viewModel, bool isDarkMode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.accentBlue),
              const SizedBox(height: 16),
              Text('profile.loading'.tr(),
                  style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight)),
            ],
          ),
        ),
      ),
    );

    final userProfile = await viewModel.loadUserProfile(userId);
    if (!context.mounted) return;
    Navigator.pop(context);

    if (userProfile == null) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'profile.errors.profileLoadFailed'.tr());
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileBottomSheet(
        userProfile: userProfile,
        isFriend: viewModel.isFriend(userId),
        isFollowing: false,
        isDarkMode: isDarkMode,
        onSendFriendRequest: () async {
          await viewModel.sendFriendRequest(userId, context);
        },
        onUnfriend: () => viewModel.unfriend(userId, context),
        onFollow: () {},
        onUnfollow: () {},
      ),
    );
  }

  void _showSearchDialog(
      BuildContext context, ProfileViewModel viewModel, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _FriendSearchBottomSheet(viewModel: viewModel, isDarkMode: isDarkMode),
    );
  }
}

// ==================== BAŞARILAR TAB ====================

class _AchievementsTab extends StatelessWidget {
  final ProfileViewModel viewModel;

  const _AchievementsTab({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => viewModel.loadAchievements(),
      color: ColorConstant.accentYellow,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorConstant.accentYellow, ColorConstant.accentOrange],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: ColorConstant.accentYellow.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '${viewModel.achievements.where((a) => a.isCompleted).length} / ${viewModel.achievements.length}',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: ColorConstant.white,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text('profile.achievements.unlocked'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstant.white.withValues(alpha: 0.95))),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: viewModel.achievements.isEmpty
                        ? 0
                        : viewModel.achievements.where((a) => a.isCompleted).length /
                            viewModel.achievements.length,
                    backgroundColor: ColorConstant.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.white),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${viewModel.achievements.isEmpty ? 0 : ((viewModel.achievements.where((a) => a.isCompleted).length / viewModel.achievements.length) * 100).toStringAsFixed(0)}${'profile.achievements.completed'.tr()}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ColorConstant.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  emoji: '✅',
                  label: 'profile.achievements.stats.unlocked'.tr(),
                  value: '${viewModel.achievements.where((a) => a.isCompleted).length}',
                  color: ColorConstant.accentGreen,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '⏳',
                  label: 'profile.achievements.stats.inProgress'.tr(),
                  value:
                      '${viewModel.achievements.where((a) => !a.isCompleted && a.currentProgress > 0).length}',
                  color: ColorConstant.accentBlue,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '🔒',
                  label: 'profile.achievements.stats.locked'.tr(),
                  value:
                      '${viewModel.achievements.where((a) => !a.isCompleted && a.currentProgress == 0).length}',
                  color: ColorConstant.textMutedDark,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (viewModel.achievements.isNotEmpty)
            ...viewModel.achievements.map((a) => _buildAchievementCard(a, isDarkMode))
          else
            _buildEmptyState(
              illustration: 'empty_tasks.svg',
              message: 'profile.achievements.emptyState'.tr(),
              subtitle: 'profile.achievements.emptyStateSubtitle'.tr(),
              accent: ColorConstant.accentOrange,
            ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      {required String emoji,
      required String label,
      required String value,
      required Color color,
      required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(achievement, bool isDarkMode) {
    final isCompleted = achievement.isCompleted;
    final hasProgress = achievement.currentProgress > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(colors: [
                ColorConstant.accentYellow.withValues(alpha: 0.15),
                ColorConstant.accentOrange.withValues(alpha: 0.05)
              ])
            : null,
        color: isCompleted
            ? null
            : (isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? ColorConstant.accentYellow.withValues(alpha: 0.5)
              : (isDarkMode ? ColorConstant.borderColorDark : ColorConstant.borderColorLight),
          width: isCompleted ? 2 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(colors: [
                          ColorConstant.accentYellow.withValues(alpha: 0.3),
                          ColorConstant.accentOrange.withValues(alpha: 0.2)
                        ])
                      : null,
                  color: isCompleted
                      ? null
                      : (isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Opacity(
                    opacity: isCompleted ? 1.0 : 0.4,
                    child: Text(achievement.icon ?? '🏆',
                        style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.titleKey ?? 'profile.achievements.defaultTitle'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? (isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight)
                            : (isDarkMode
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.descriptionKey ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? ColorConstant.accentYellow.withValues(alpha: 0.2)
                      : (isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? ColorConstant.accentYellow
                        : (isDarkMode
                            ? ColorConstant.textMutedDark
                            : ColorConstant.textMutedLight),
                  ),
                ),
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'profile.achievements.progress'.tr(namedArgs: {
                        'current': '${achievement.currentProgress}',
                        'total': '${achievement.requirementValue}'
                      }),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight),
                    ),
                    Text(
                      '${achievement.progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ColorConstant.accentBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: achievement.progressPercentage / 100,
                    backgroundColor:
                        isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        hasProgress ? ColorConstant.accentBlue : ColorConstant.textMutedDark),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
          if (isCompleted && achievement.unlockedAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: ColorConstant.accentGreen),
                const SizedBox(width: 6),
                Text(
                  '${'profile.achievements.unlockedOn'.tr()} ${_formatDate(achievement.unlockedAt!)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorConstant.accentGreen),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'common.today'.tr();
    if (diff.inDays == 1) return 'common.yesterday'.tr();
    if (diff.inDays < 7) {
      return 'common.daysAgo'.tr(namedArgs: {'count': '${diff.inDays}'});
    }
    if (diff.inDays < 30) {
      return 'common.weeksAgo'.tr(namedArgs: {'count': '${(diff.inDays / 7).floor()}'});
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== ARKADAŞ ARAMA BOTTOM SHEET ====================

class _FriendSearchBottomSheet extends StatefulWidget {
  final ProfileViewModel viewModel;
  final bool isDarkMode;

  const _FriendSearchBottomSheet(
      {required this.viewModel, required this.isDarkMode});

  @override
  State<_FriendSearchBottomSheet> createState() =>
      _FriendSearchBottomSheetState();
}

class _FriendSearchBottomSheetState extends State<_FriendSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (value.length >= 2) {
                    widget.viewModel.searchUsers(value);
                  } else if (value.isEmpty) {
                    widget.viewModel.searchUsers('');
                  }
                },
                style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'profile.friends.searchHint'.tr(),
                  hintStyle: TextStyle(
                      color: widget.isDarkMode
                          ? ColorConstant.textMutedDark
                          : ColorConstant.textMutedLight),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: widget.isDarkMode
                          ? ColorConstant.textMutedDark
                          : ColorConstant.textMutedLight),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? ColorConstant.bgColorDark
                      : ColorConstant.bgColorLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: widget.viewModel,
                builder: (context, child) {
                  if (widget.viewModel.searchResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 64,
                            color: widget.isDarkMode
                                ? ColorConstant.textMutedDark.withValues(alpha: 0.5)
                                : ColorConstant.textMutedLight.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'profile.friends.searchEmpty'.tr()
                                : 'profile.friends.notFound'.tr(),
                            style: TextStyle(
                                fontSize: 16,
                                color: widget.isDarkMode
                                    ? ColorConstant.textMutedDark
                                    : ColorConstant.textMutedLight),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.viewModel.searchResults.length,
                    itemBuilder: (context, index) {
                      final user = widget.viewModel.searchResults[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showUserProfileDialogFromSearch(
                              context, user.id, widget.viewModel, widget.isDarkMode);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    ColorConstant.accentBlue.withValues(alpha: 0.2),
                                backgroundImage: user.profilePictureUrl != null
                                    ? NetworkImage(user.profilePictureUrl!)
                                    : null,
                                child: user.profilePictureUrl == null
                                    ? Text(user.displayName[0].toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: ColorConstant.accentBlue))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isDarkMode
                                            ? ColorConstant.textPrimaryDark
                                            : ColorConstant.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDarkMode
                                              ? ColorConstant.textSecondaryDark
                                              : ColorConstant.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  widget.viewModel.sendFriendRequest(user.id, context);
                                },
                                icon: Icon(Icons.person_add_rounded,
                                    color: ColorConstant.accentBlue),
                                tooltip: 'profile.friends.addFriend'.tr(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfileDialogFromSearch(BuildContext context, int userId,
      ProfileViewModel viewModel, bool isDarkMode) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => FutureBuilder<UserProfile?>(
        future: viewModel.loadUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: ColorConstant.accentBlue),
                    const SizedBox(height: 16),
                    Text('profile.loading'.tr(),
                        style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 16)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pop(sheetContext);
                CustomSnackBar.showError(
                    context, 'profile.errors.profileLoadFailed'.tr());
              }
            });
            return const SizedBox.shrink();
          }

          return UserProfileBottomSheet(
            userProfile: snapshot.data!,
            isFriend: viewModel.isFriend(userId),
            isFollowing: false,
            isDarkMode: isDarkMode,
            onSendFriendRequest: () async {
              await viewModel.sendFriendRequest(userId, context);
            },
            onUnfriend: () => viewModel.unfriend(userId, context),
            onFollow: () {},
            onUnfollow: () {},
          );
        },
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

Widget _buildEmptyState({
  required String illustration,
  required String message,
  required String subtitle,
  required Color accent,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: AppEmptyState(
      illustration: illustration,
      title: message,
      message: subtitle,
      accent: accent,
    ),
  );
}
