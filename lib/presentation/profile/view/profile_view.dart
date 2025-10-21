import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../widgets/user_profile_bottom_sheet.dart';

@RoutePage()
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
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
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          if (viewModel.isLoading) {
            return Scaffold(
              backgroundColor: isDarkMode
                  ? ColorConstant.bgColorDark
                  : ColorConstant.bgColorLight,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: ColorConstant.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '✨ Profil yükleniyor...',
                      style: TextStyle(
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

          final user = viewModel.currentUser;
          if (user == null) {
            return Scaffold(
              backgroundColor: isDarkMode
                  ? ColorConstant.bgColorDark
                  : ColorConstant.bgColorLight,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🤔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'Kullanıcı bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 320,
                    floating: false,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: isDarkMode
                        ? ColorConstant.cardColorDark
                        : ColorConstant.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeader(context, viewModel, isDarkMode),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () =>
                              context.router.push(const SettingsRoute()),
                          style: IconButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? ColorConstant.cardColorDark.withOpacity(0.8)
                                : ColorConstant.white.withOpacity(0.8),
                          ),
                          icon: Icon(
                            Icons.settings_rounded,
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ];
              },
              body: Column(
                children: [
                  // Modern Tab Bar
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? ColorConstant.cardColorDark
                          : ColorConstant.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? ColorConstant.borderColorDark
                            : ColorConstant.borderColorLight,
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstant.accentBlue,
                            ColorConstant.accentBlue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: ColorConstant.white,
                      unselectedLabelColor: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('📊'),
                              SizedBox(width: 4),
                              Flexible(child: Text('İstatistik', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('👥'),
                              SizedBox(width: 4),
                              Flexible(child: Text('Arkadaş', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('🏆'),
                              SizedBox(width: 4),
                              Flexible(child: Text('Başarı', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _StatsTab(viewModel: viewModel),
                        _FriendsTab(viewModel: viewModel),
                        _AchievementsTab(viewModel: viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ProfileViewModel viewModel, bool isDarkMode) {
    final user = viewModel.currentUser!;

    return Stack(
      children: [
        // Gradient Cover
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorConstant.accentBlue,
                const Color(0xFF667EEA),
                ColorConstant.primaryPurple,
              ],
            ),
          ),
          child: user.coverImageUrl != null
              ? Image.network(user.coverImageUrl!, fit: BoxFit.cover)
              : null,
        ),

        // Decorative circles
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstant.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstant.white.withOpacity(0.1),
            ),
          ),
        ),

        // Profile Content
        Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Avatar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode
                              ? ColorConstant.bgColorDark
                              : ColorConstant.bgColorLight,
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstant.accentBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: ColorConstant.white,
                        backgroundImage: user.profilePictureUrl != null
                            ? NetworkImage(user.profilePictureUrl!)
                            : null,
                        child: user.profilePictureUrl == null
                            ? Text(
                          user.displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: ColorConstant.accentBlue,
                          ),
                        )
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Display Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConstant.accentYellow,
                          ColorConstant.accentOrange,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Username badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.cardColorDark
                      : ColorConstant.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorConstant.accentBlue.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👤', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorConstant.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),

              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? ColorConstant.cardColorDark.withOpacity(0.5)
                        : ColorConstant.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== İSTATİSTİKLER TAB ====================

class _StatsTab extends StatelessWidget {
  final ProfileViewModel viewModel;

  const _StatsTab({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.profileStats == null) {
      return Center(
        child: CircularProgressIndicator(color: ColorConstant.accentBlue),
      );
    }

    final stats = viewModel.profileStats!;

    return RefreshIndicator(
      onRefresh: () => viewModel.loadProfileStats(),
      color: ColorConstant.accentBlue,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(opacity: value, child: _buildLevelCard(stats.gamification, isDarkMode)),
              );
            },
          ),
          const SizedBox(height: 20),

          _buildStatCard(
            title: 'Alışkanlıklar',
            icon: Icons.emoji_events_rounded,
            emoji: '🏆',
            color: ColorConstant.accentYellow,
            stats: [
              _StatItem('Toplam', '${stats.habits.total}', '📊'),
              _StatItem('Aktif', '${stats.habits.active}', '✅'),
              _StatItem('Bugün', '${stats.habits.completedToday}', '🎯'),
              _StatItem('Streak', '${stats.habits.currentStreak}', '🔥'),
            ],
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            title: 'Görevler',
            icon: Icons.task_rounded,
            emoji: '📝',
            color: ColorConstant.accentBlue,
            stats: [
              _StatItem('Toplam', '${stats.tasks.total}', '📊'),
              _StatItem('Tamamlanan', '${stats.tasks.completed}', '✅'),
              _StatItem('Bekleyen', '${stats.tasks.pending}', '⏳'),
              _StatItem('Geciken', '${stats.tasks.overdue}', '⚠️'),
            ],
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            title: 'Notlar & Günlük',
            icon: Icons.note_rounded,
            emoji: '📔',
            color: const Color(0xFFB794F6),
            stats: [
              _StatItem('Notlar', '${stats.notes.total}', '📝'),
              _StatItem('Kategori', '${stats.notes.categories}', '📁'),
              _StatItem('Günlük', '${stats.diary.totalEntries}', '📖'),
              _StatItem('Bu Ay', '${stats.diary.thisMonth}', '📅'),
            ],
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            title: 'Finans',
            icon: Icons.account_balance_wallet_rounded,
            emoji: '💰',
            color: ColorConstant.accentGreen,
            stats: [
              _StatItem('Bütçe', '₺${stats.budget.monthlyBudget.toStringAsFixed(0)}', '💵'),
              _StatItem('Harcama', '₺${stats.budget.thisMonthExpenses.toStringAsFixed(0)}', '💸'),
              _StatItem('Abonelik', '${stats.subscriptions.total}', '📱'),
              _StatItem('Aylık', '₺${stats.subscriptions.monthlyCost.toStringAsFixed(0)}', '💳'),
            ],
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(gamification, bool isDarkMode) {
    return Container(
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
            color: ColorConstant.accentYellow.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorConstant.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 16),
          Text(
            'Level ${gamification.level}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: ColorConstant.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLevelBadge('⚡', '${gamification.totalXp} XP'),
              const SizedBox(width: 12),
              _buildLevelBadge('🎖️', '${gamification.achievementsUnlocked}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstant.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstant.white.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ColorConstant.white)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String emoji,
    required Color color,
    required List<_StatItem> stats,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: stats.map((stat) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(stat.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        stat.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String emoji;
  _StatItem(this.label, this.value, this.emoji);
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
                    ColorConstant.accentBlue.withOpacity(0.1),
                    ColorConstant.primaryPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ColorConstant.accentBlue.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [ColorConstant.accentBlue, ColorConstant.primaryPurple]),
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
                          'Arkadaş Ara',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Yeni arkadaşlar bul! 🚀',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight,
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
                    gradient: LinearGradient(colors: [ColorConstant.accentYellow, ColorConstant.accentOrange]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⏰', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Arkadaşlık İstekleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstant.accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewModel.friendRequests.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ColorConstant.accentYellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...viewModel.friendRequests.map((r) => _buildFriendRequestCard(context, r, viewModel, isDarkMode)),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [ColorConstant.accentBlue, ColorConstant.primaryPurple]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('👥', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(
                'Arkadaşlarım',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstant.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${viewModel.friends.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ColorConstant.accentBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (viewModel.friends.isNotEmpty)
            ...viewModel.friends.map((f) => _buildFriendCard(context, f, viewModel, isDarkMode))
          else
            _buildEmptyState(emoji: '🤝', message: 'Henüz arkadaşın yok', subtitle: 'Hemen yeni arkadaşlar ekle!', isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(BuildContext context, request, ProfileViewModel viewModel, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ColorConstant.accentYellow.withOpacity(0.1), ColorConstant.accentOrange.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstant.accentYellow.withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ColorConstant.accentBlue.withOpacity(0.2),
                backgroundImage: request.sender?.profilePictureUrl != null ? NetworkImage(request.sender!.profilePictureUrl!) : null,
                child: request.sender?.profilePictureUrl == null
                    ? Text(request.sender!.displayName[0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ColorConstant.accentBlue))
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: ColorConstant.accentYellow, shape: BoxShape.circle),
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
                Text(
                  request.sender!.displayName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
                ),
                Text(
                  '@${request.sender!.username}',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => viewModel.acceptFriendRequest(request.id, context),
                style: IconButton.styleFrom(backgroundColor: ColorConstant.accentGreen.withOpacity(0.15)),
                icon: Icon(Icons.check_rounded, color: ColorConstant.accentGreen),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => viewModel.rejectFriendRequest(request.id, context),
                style: IconButton.styleFrom(backgroundColor: ColorConstant.errorRed.withOpacity(0.15)),
                icon: Icon(Icons.close_rounded, color: ColorConstant.errorRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, friend, ProfileViewModel viewModel, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showUserProfileDialog(context, friend.id, viewModel, isDarkMode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDarkMode ? ColorConstant.borderColorDark : ColorConstant.borderColorLight, width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: ColorConstant.accentBlue.withOpacity(0.2),
              backgroundImage: friend.profilePictureUrl != null ? NetworkImage(friend.profilePictureUrl!) : null,
              child: friend.profilePictureUrl == null
                  ? Text(friend.displayName[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ColorConstant.accentBlue))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '@${friend.username}',
                        style: TextStyle(fontSize: 12, color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [ColorConstant.accentYellow.withOpacity(0.2), ColorConstant.accentOrange.withOpacity(0.2)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text('Lv.${friend.level}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ColorConstant.accentYellow)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
          ],
        ),
      ),
    );
  }

  void _showUserProfileDialog(BuildContext context, int userId, ProfileViewModel viewModel, bool isDarkMode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.accentBlue),
              const SizedBox(height: 16),
              Text('✨ Profil yükleniyor...', style: TextStyle(color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight)),
            ],
          ),
        ),
      ),
    );

    final userProfile = await viewModel.loadUserProfile(userId);
    if (!context.mounted) return;
    Navigator.pop(context);

    if (userProfile == null) {
      if (context.mounted) CustomSnackBar.showError(context, 'Profil yüklenemedi');
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
        onSendFriendRequest: () => viewModel.sendFriendRequest(userId, context),
        onUnfriend: () => viewModel.unfriend(userId, context),
        onFollow: () {},
        onUnfollow: () {},
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ProfileViewModel viewModel, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FriendSearchBottomSheet(viewModel: viewModel, isDarkMode: isDarkMode),
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
              boxShadow: [BoxShadow(color: ColorConstant.accentYellow.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '${viewModel.achievements.where((a) => a.isCompleted).length} / ${viewModel.achievements.length}',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: ColorConstant.white, letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text('Başarı Açıldı! 🎉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColorConstant.white.withOpacity(0.95))),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: viewModel.achievements.isEmpty ? 0 : viewModel.achievements.where((a) => a.isCompleted).length / viewModel.achievements.length,
                    backgroundColor: ColorConstant.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.white),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${viewModel.achievements.isEmpty ? 0 : ((viewModel.achievements.where((a) => a.isCompleted).length / viewModel.achievements.length) * 100).toStringAsFixed(0)}% Tamamlandı',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ColorConstant.white.withOpacity(0.9)),
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
                  label: 'Açıldı',
                  value: '${viewModel.achievements.where((a) => a.isCompleted).length}',
                  color: ColorConstant.accentGreen,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '⏳',
                  label: 'Devam Ediyor',
                  value: '${viewModel.achievements.where((a) => !a.isCompleted && a.currentProgress > 0).length}',
                  color: ColorConstant.accentBlue,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  emoji: '🔒',
                  label: 'Kilitli',
                  value: '${viewModel.achievements.where((a) => !a.isCompleted && a.currentProgress == 0).length}',
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
            _buildEmptyState(emoji: '🎯', message: 'Henüz başarı yok', subtitle: 'Hemen görevlere başla!', isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatBox({required String emoji, required String label, required String value, required Color color, required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
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
            ? LinearGradient(colors: [ColorConstant.accentYellow.withOpacity(0.15), ColorConstant.accentOrange.withOpacity(0.05)])
            : null,
        color: isCompleted ? null : (isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? ColorConstant.accentYellow.withOpacity(0.5) : (isDarkMode ? ColorConstant.borderColorDark : ColorConstant.borderColorLight),
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
                  gradient: isCompleted ? LinearGradient(colors: [ColorConstant.accentYellow.withOpacity(0.3), ColorConstant.accentOrange.withOpacity(0.2)]) : null,
                  color: isCompleted ? null : (isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Opacity(
                    opacity: isCompleted ? 1.0 : 0.4,
                    child: Text(achievement.icon ?? '🏆', style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.titleKey ?? 'Başarı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCompleted ? (isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight) : (isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.descriptionKey ?? '',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? ColorConstant.accentYellow.withOpacity(0.2) : (isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? ColorConstant.accentYellow : (isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
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
                      'İlerleme: ${achievement.currentProgress}/${achievement.requirementValue}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
                    ),
                    Text(
                      '${achievement.progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ColorConstant.accentBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: achievement.progressPercentage / 100,
                    backgroundColor: isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(hasProgress ? ColorConstant.accentBlue : ColorConstant.textMutedDark),
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
                  'Açıldı: ${_formatDate(achievement.unlockedAt!)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorConstant.accentGreen),
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
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== ARKADAŞ ARAMA BOTTOM SHEET ====================

class _FriendSearchBottomSheet extends StatefulWidget {
  final ProfileViewModel viewModel;
  final bool isDarkMode;

  const _FriendSearchBottomSheet({required this.viewModel, required this.isDarkMode});

  @override
  State<_FriendSearchBottomSheet> createState() => _FriendSearchBottomSheetState();
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? ColorConstant.borderColorDark : ColorConstant.borderColorLight,
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
                style: TextStyle(color: widget.isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  hintStyle: TextStyle(color: widget.isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
                  prefixIcon: Icon(Icons.search_rounded, color: widget.isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
                  filled: true,
                  fillColor: widget.isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                            color: widget.isDarkMode ? ColorConstant.textMutedDark.withOpacity(0.5) : ColorConstant.textMutedLight.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty ? 'Kullanıcı ara...' : 'Kullanıcı bulunamadı',
                            style: TextStyle(fontSize: 16, color: widget.isDarkMode ? ColorConstant.textMutedDark : ColorConstant.textMutedLight),
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
                          _showUserProfileDialogFromSearch(context, user.id, widget.viewModel, widget.isDarkMode);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: ColorConstant.accentBlue.withOpacity(0.2),
                                backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
                                child: user.profilePictureUrl == null
                                    ? Text(user.displayName[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ColorConstant.accentBlue))
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
                                        color: widget.isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: TextStyle(fontSize: 12, color: widget.isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  widget.viewModel.sendFriendRequest(user.id, context);
                                },
                                icon: Icon(Icons.person_add_rounded, color: ColorConstant.accentBlue),
                                tooltip: 'Arkadaş Ekle',
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

  void _showUserProfileDialogFromSearch(BuildContext context, int userId, ProfileViewModel viewModel, bool isDarkMode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.accentBlue),
              const SizedBox(height: 16),
              Text('Profil yükleniyor...', style: TextStyle(color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight)),
            ],
          ),
        ),
      ),
    );

    final userProfile = await viewModel.loadUserProfile(userId);
    if (!context.mounted) return;
    Navigator.pop(context);

    if (userProfile == null) {
      if (context.mounted) CustomSnackBar.showError(context, 'Profil yüklenemedi');
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
        onSendFriendRequest: () => viewModel.sendFriendRequest(userId, context),
        onUnfriend: () => viewModel.unfriend(userId, context),
        onFollow: () {},
        onUnfollow: () {},
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

Widget _buildEmptyState({required String emoji, required String message, required String subtitle, required bool isDarkMode}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: Text(emoji, style: const TextStyle(fontSize: 80)));
            },
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight,
            ),
          ),
        ],
      ),
    ),
  );
}