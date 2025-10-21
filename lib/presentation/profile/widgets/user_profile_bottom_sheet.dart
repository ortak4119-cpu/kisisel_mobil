import 'package:flutter/material.dart';
import '../../../core/utils/color_constant.dart';
import '../../../models/social/social_model.dart';
import '../../../models/settings/settings_models.dart';

class UserProfileBottomSheet extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onSendFriendRequest;
  final VoidCallback? onUnfriend;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;
  final bool isFriend;
  final bool isFollowing;
  final bool isDarkMode;

  const UserProfileBottomSheet({
    super.key,
    required this.userProfile,
    this.onSendFriendRequest,
    this.onUnfriend,
    this.onFollow,
    this.onUnfollow,
    this.isFriend = false,
    this.isFollowing = false,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Handle
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

          // Profile Header
          _buildProfileHeader(),

          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(context),

          const SizedBox(height: 20),

          // Stats
          Expanded(
            child: _buildStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar with animation
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
                    backgroundColor: ColorConstant.accentBlue.withOpacity(0.2),
                    backgroundImage: userProfile.profilePictureUrl != null
                        ? NetworkImage(userProfile.profilePictureUrl!)
                        : null,
                    child: userProfile.profilePictureUrl == null
                        ? Text(
                      userProfile.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
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

          // Name with verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userProfile.displayName,
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
                      ColorConstant.accentBlue,
                      ColorConstant.primaryPurple,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  size: 16,
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
              color: ColorConstant.accentBlue.withOpacity(0.15),
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
                  '@${userProfile.username}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ColorConstant.accentBlue,
                  ),
                ),
              ],
            ),
          ),

          // Level (if visible)
          if (userProfile.showLevel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstant.accentYellow,
                    ColorConstant.accentOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstant.accentYellow.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Level ${userProfile.level}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ColorConstant.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstant.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${userProfile.totalXp} XP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bio
          if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  width: 1,
                ),
              ),
              child: Text(
                userProfile.bio!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDarkMode
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Friend/Unfriend Button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isFriend) {
                  onUnfriend?.call();
                } else {
                  onSendFriendRequest?.call();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: ColorConstant.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFriend
                        ? [
                      ColorConstant.errorRed,
                      ColorConstant.errorRed.withOpacity(0.8),
                    ]
                        : [
                      ColorConstant.accentBlue,
                      ColorConstant.primaryPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFriend ? Icons.person_remove : Icons.person_add,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFriend ? 'Arkadaşlıktan Çıkar' : 'Arkadaş Ekle',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Follow Button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isFollowing) {
                  onUnfollow?.call();
                } else {
                  onFollow?.call();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstant.accentOrange,
                side: BorderSide(
                  color: ColorConstant.accentOrange.withOpacity(0.5),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowing ? Icons.notifications_off : Icons.notifications,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFollowing ? 'Takipten Çık' : 'Takip Et',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (userProfile.stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'İstatistikler gizli',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? ColorConstant.textMutedDark
                    : ColorConstant.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    final stats = userProfile.stats!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstant.accentBlue,
                    ColorConstant.primaryPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('📊', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(
              'İstatistikler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Habits
        if (userProfile.showHabits)
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
          ),

        const SizedBox(height: 12),

        // Tasks
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
        ),

        const SizedBox(height: 12),

        // Social
        _buildStatCard(
          title: 'Sosyal',
          icon: Icons.people_rounded,
          emoji: '👥',
          color: const Color(0xFFB794F6),
          stats: [
            _StatItem('Arkadaş', '${stats.social.friends}', '🤝'),
            _StatItem('Takipçi', '${stats.social.followers}', '👀'),
            _StatItem('Takip', '${stats.social.following}', '⭐'),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String emoji,
    required Color color,
    required List<_StatItem> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats.map((stat) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.08),
                      color.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(stat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          stat.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
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