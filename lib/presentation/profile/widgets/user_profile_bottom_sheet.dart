import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
import '../../../models/social/social_model.dart';

class UserProfileBottomSheet extends StatefulWidget {
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
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? ColorConstant.cardColorDark
            : ColorConstant.white,
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
              color: widget.isDarkMode
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
                        color: ColorConstant.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor:
                        ColorConstant.accentBlue.withValues(alpha: 0.2),
                    backgroundImage: widget.userProfile.profilePictureUrl !=
                            null
                        ? NetworkImage(widget.userProfile.profilePictureUrl!)
                        : null,
                    child: widget.userProfile.profilePictureUrl == null
                        ? Text(
                            widget.userProfile.displayName[0].toUpperCase(),
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
                widget.userProfile.displayName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: widget.isDarkMode
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
              color: ColorConstant.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorConstant.accentBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👤', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '@${widget.userProfile.username}',
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
          if (widget.userProfile.showLevel) ...[
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
                    color: ColorConstant.accentYellow.withValues(alpha: 0.3),
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
                    'Level ${widget.userProfile.level}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ColorConstant.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstant.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.userProfile.totalXp} XP',
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
          if (widget.userProfile.bio != null &&
              widget.userProfile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  width: 1,
                ),
              ),
              child: Text(
                widget.userProfile.bio!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: widget.isDarkMode
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);

                  Navigator.pop(context);

                  if (widget.isFriend) {
                    widget.onUnfriend?.call();
                  } else {
                    widget.onSendFriendRequest?.call();
                  }

                  // Kısa bir delay ekle (isteğe bağlı)
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (mounted) {
                    setState(() => _isProcessing = false);
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
                colors: _isProcessing
                    ? [
                        ColorConstant.textMutedDark,
                        ColorConstant.textMutedDark.withValues(alpha: 0.8),
                      ]
                    : widget.isFriend
                        ? [
                            ColorConstant.errorRed,
                            ColorConstant.errorRed.withValues(alpha: 0.8),
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
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(ColorConstant.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isFriend
                              ? Icons.person_remove
                              : Icons.person_add,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isFriend
                              ? 'profile.friends.unfriend'.tr()
                              : 'profile.friends.addFriend'.tr(),
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
    );
  }

  Widget _buildStats() {
    if (widget.userProfile.stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'profile.stats.statsPrivate'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode
                    ? ColorConstant.textMutedDark
                    : ColorConstant.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    final stats = widget.userProfile.stats!;

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
              'profile.tabs.statistics'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: widget.isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Habits
        if (widget.userProfile.showHabits)
          _buildStatCard(
            title: 'profile.stats.habits'.tr(),
            icon: Icons.emoji_events_rounded,
            emoji: '🏆',
            color: ColorConstant.accentYellow,
            stats: [
              _StatItem(
                  'profile.stats.total'.tr(), '${stats.habits.total}', '📊'),
              _StatItem(
                  'profile.stats.active'.tr(), '${stats.habits.active}', '✅'),
              _StatItem('profile.stats.today'.tr(),
                  '${stats.habits.completedToday}', '🎯'),
              _StatItem('profile.stats.streak'.tr(),
                  '${stats.habits.currentStreak}', '🔥'),
            ],
          ),

        const SizedBox(height: 12),

        // Tasks
        _buildStatCard(
          title: 'profile.stats.tasks'.tr(),
          icon: Icons.task_rounded,
          emoji: '📝',
          color: ColorConstant.accentBlue,
          stats: [
            _StatItem('profile.stats.total'.tr(), '${stats.tasks.total}', '📊'),
            _StatItem('profile.stats.completed'.tr(),
                '${stats.tasks.completed}', '✅'),
            _StatItem(
                'profile.stats.pending'.tr(), '${stats.tasks.pending}', '⏳'),
            _StatItem(
                'profile.stats.overdue'.tr(), '${stats.tasks.overdue}', '⚠️'),
          ],
        ),

        const SizedBox(height: 12),

        // Social
        _buildStatCard(
          title: 'profile.stats.social'.tr(),
          icon: Icons.people_rounded,
          emoji: '👥',
          color: const Color(0xFFB794F6),
          stats: [
            _StatItem(
                'profile.stats.friends'.tr(), '${stats.social.friends}', '🤝'),
            _StatItem('profile.stats.followers'.tr(),
                '${stats.social.followers}', '👀'),
            _StatItem('profile.stats.following'.tr(),
                '${stats.social.following}', '⭐'),
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
        color: widget.isDarkMode
            ? ColorConstant.cardColorDark
            : ColorConstant.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
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
                  color: widget.isDarkMode
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
                      color.withValues(alpha: 0.08),
                      color.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
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
                            color: widget.isDarkMode
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
