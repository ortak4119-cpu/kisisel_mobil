import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';
import '../../../service/base/base_api_service.dart';
import '../../../service/auth/auth_service.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/design/app_design.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../models/social/social_model.dart';
import '../../settings/view/settings_view.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../widgets/user_profile_bottom_sheet.dart';

@RoutePage()
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Mockup paleti — satır ikonları için yumuşak aksan renkleri.
  static const _cOrange = Color(0xFFF6A821);
  static const _cGold = Color(0xFFF2B32C);
  static const _cBlue = Color(0xFF4C9AFF);
  static const _cRed = Color(0xFFF2685B);
  static const _cGreen = Color(0xFF46A46B);
  static const _cPurple = Color(0xFF9C7BD9);
  static const _cGray = Color(0xFF8A94A6);
  static const _cTeal = Color(0xFF2BB3A3);

  Color _textPrimary(bool d) =>
      d ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
  Color _textSecondary(bool d) =>
      d ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight;
  Color _textMuted(bool d) =>
      d ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
  Color _cardColor(bool d) => d ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
  Color _borderColor(bool d) =>
      d ? ColorConstant.borderColorDark : ColorConstant.borderColorLight;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg =
              isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;

          if (vm.isLoading && !vm.isUserLoaded) {
            return Scaffold(
              backgroundColor: bg,
              body: const Center(
                  child: CircularProgressIndicator(color: _cOrange)),
            );
          }

          final user = vm.currentUser;
          if (user == null) {
            return Scaffold(
              backgroundColor: bg,
              appBar: _buildAppBar(context, isDark),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🤔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text('profile.userNotFound'.tr(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary(isDark))),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: bg,
            appBar: _buildAppBar(context, isDark),
            body: RefreshIndicator(
              onRefresh: () => vm.refreshAll(),
              color: _cOrange,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                children: _buildSections(context, vm, user, isDark),
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
      backgroundColor:
          isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Text('profile.title'.tr(),
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textPrimary(isDark))),
    );
  }

  List<Widget> _buildSections(
      BuildContext context, ProfileViewModel vm, dynamic user, bool isDark) {
    final stats = vm.profileStats;
    final level = vm.levelInfo;

    // ---- Seviye / sosyal ----
    final lvl = level?.currentLevel ?? stats?.gamification.level ?? 1;
    final totalXp = level?.totalXp ?? stats?.gamification.totalXp ?? 0;
    final progress = ((level?.progressPercentage ?? 0) / 100.0).clamp(0.0, 1.0);
    final remaining =
        ((level?.nextLevelXp ?? 0) - (level?.currentXp ?? 0)).clamp(0, 999999);
    final achievements = stats?.gamification.achievementsUnlocked ??
        vm.achievements.where((a) => a.isCompleted).length;
    final friends = stats?.social.friends ?? vm.friends.length;
    final activeDays = level?.dailyStreak ?? 0;

    // ---- Bu ayki ilerleme ----
    final habitRate = (stats != null && stats.habits.active > 0)
        ? (stats.habits.completedToday / stats.habits.active * 100).round()
        : 0;
    final habitStreak = stats?.habits.currentStreak ?? 0;
    final completedTasks = stats?.tasks.completed ?? 0;
    final dailyNote = stats?.diary.thisMonth ?? 0;
    final notesTotal = stats?.notes.total ?? 0;
    final notesLocked = stats?.notes.locked ?? 0;

    // ---- Kişisel hedefler ----
    const taskGoal = 10;
    final taskProgress = (completedTasks / taskGoal).clamp(0.0, 1.0);
    final budgetProgress = (stats != null && stats.budget.monthlyBudget > 0)
        ? (stats.budget.thisMonthExpenses / stats.budget.monthlyBudget)
            .clamp(0.0, 1.0)
        : 0.0;
    final savingsRate = (stats != null && stats.budget.monthlyBudget > 0)
        ? ((1 - budgetProgress) * 100).round()
        : 0;

    return [
      _header(context, vm, user, isDark),
      const SizedBox(height: 22),

      // ─── SEVİYE ───
      _sectionHeader('profile.secLevel'.tr(), isDark),
      _card(isDark, [
        _levelRow(isDark,
            title:
                '${'profile.levelLabel'.tr(namedArgs: {'count': '$lvl'})} · ${_fmtXp(totalXp)} XP',
            progress: progress.toDouble(),
            right: 'profile.xpLeft'.tr(namedArgs: {'count': '$remaining'})),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cGold,
            icon: Icons.emoji_events_rounded,
            title: 'profile.achievementsBadges'.tr(),
            value: '$achievements',
            onTap: () => _openAchievements(context, vm, isDark)),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cBlue,
            icon: Icons.group_rounded,
            title: 'profile.friendsRow'.tr(),
            value: '$friends',
            onTap: () => _openFriends(context, vm, isDark)),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cRed,
            icon: Icons.local_fire_department_rounded,
            title: 'profile.activeDays'.tr(),
            value: '$activeDays',
            showChevron: false),
      ]),
      const SizedBox(height: 18),

      // ─── BU AYKİ İLERLEME ───
      _sectionHeader('profile.secMonth'.tr(), isDark),
      _card(isDark, [
        _navRow(context, isDark,
            color: _cOrange,
            icon: Icons.check_box_rounded,
            title: 'profile.completedTasks'.tr(),
            value: '$completedTasks',
            showChevron: false),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cGreen,
            icon: Icons.track_changes_rounded,
            title: 'profile.habitRate'.tr(),
            value:
                '%$habitRate · ${'profile.dayStreak'.tr(namedArgs: {'count': '$habitStreak'})}',
            valueColor: _cGreen,
            showChevron: false),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cBlue,
            icon: Icons.event_note_rounded,
            title: 'profile.dailyNote'.tr(),
            value: '$dailyNote',
            showChevron: false),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cPurple,
            icon: Icons.sticky_note_2_rounded,
            title: 'profile.createdNotes'.tr(),
            value: '$notesTotal · $notesLocked ${'profile.pinnedWord'.tr()}',
            showChevron: false),
      ]),
      const SizedBox(height: 18),

      // ─── KİŞİSEL HEDEFLER ───
      _sectionHeader('profile.secGoals'.tr(), isDark),
      _card(isDark, [
        _goalRow(isDark,
            color: _cOrange,
            icon: Icons.track_changes_rounded,
            title: 'profile.dailyTasksGoal'.tr(namedArgs: {'count': '$taskGoal'}),
            progress: taskProgress.toDouble(),
            right: '${completedTasks.clamp(0, taskGoal)}/$taskGoal'),
        _divider(isDark),
        _goalRow(isDark,
            color: _cGreen,
            icon: Icons.savings_rounded,
            title: 'profile.monthlySavings'.tr(),
            progress: (savingsRate / 30).clamp(0.0, 1.0).toDouble(),
            right: '%$savingsRate / %30',
            rightColor: _cGreen),
      ]),
      const SizedBox(height: 18),

      // ─── HESAP ───
      _sectionHeader('profile.secAccount'.tr(), isDark),
      _card(isDark, [
        _navRow(context, isDark,
            color: _cGray,
            icon: Icons.badge_rounded,
            title: 'profile.accountInfo'.tr(),
            value: (vm.currentUser?.email?.isNotEmpty ?? false)
                ? vm.currentUser!.email
                : null,
            onTap: () => showAccountInfoSheet(context, vm)),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cRed,
            icon: Icons.notifications_rounded,
            title: 'profile.notifications'.tr(),
            badge: vm.friendRequests.isNotEmpty
                ? '${vm.friendRequests.length}'
                : null,
            onTap: () => _openSettings(context, 'notifications')),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cPurple,
            icon: Icons.palette_rounded,
            title: 'profile.appearanceTheme'.tr(),
            value: isDark
                ? 'settings.appearance.themeDark'.tr()
                : 'settings.appearance.themeLight'.tr(),
            onTap: () => _openSettings(context, 'appearance')),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cGreen,
            icon: Icons.shield_rounded,
            title: 'profile.privacySecurity'.tr(),
            onTap: () => _openSettings(context, 'privacy')),
      ]),
      const SizedBox(height: 18),

      // ─── DESTEK ───
      _sectionHeader('profile.secSupport'.tr(), isDark),
      _card(isDark, [
        _navRow(context, isDark,
            color: _cBlue,
            icon: Icons.feedback_rounded,
            title: 'profile.feedback'.tr(),
            onTap: () => _openFeedback(context, vm, isDark)),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cTeal,
            icon: Icons.help_rounded,
            title: 'profile.helpSupport'.tr(),
            onTap: () => _openSettings(context, 'support')),
        _divider(isDark),
        _navRow(context, isDark,
            color: _cGray,
            icon: Icons.info_rounded,
            title: 'profile.aboutApp'.tr(),
            onTap: () => _showAbout(context)),
      ]),
      const SizedBox(height: 18),

      _logoutCard(context, vm, isDark),
    ];
  }

  // ---------- Profil başlık kartı ----------
  Widget _header(
      BuildContext context, ProfileViewModel vm, dynamic user, bool isDark) {
    final joined = 'profile.memberSince'.tr(namedArgs: {
      'date': DateFormat('MMMM yyyy', context.locale.toLanguageTag())
          .format(user.createdAt)
    });
    return GestureDetector(
      onTap: () => showEditProfileSheet(context, vm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor(isDark)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  _showImageSourceDialog(context, vm, isCover: false),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _cOrange.withValues(alpha: 0.15),
                backgroundImage: user.profilePictureUrl != null
                    ? NetworkImage(user.profilePictureUrl!)
                    : null,
                child: user.profilePictureUrl == null
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _cOrange))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary(isDark))),
                  const SizedBox(height: 2),
                  Text('@${user.username} · $joined',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: _textMuted(isDark))),
                  const SizedBox(height: 3),
                  Text('profile.editProfile'.tr(),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ColorConstant.primaryPurple)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: _textMuted(isDark)),
          ],
        ),
      ),
    );
  }

  // ---------- Bölüm başlığı ----------
  Widget _sectionHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _textMuted(isDark),
        ),
      ),
    );
  }

  // ---------- Kart (satırları saran beyaz kutu) ----------
  Widget _card(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(bool isDark) => Divider(
      height: 1,
      thickness: 0.6,
      indent: 66,
      color: _borderColor(isDark).withValues(alpha: 0.8));

  Widget _iconSquare(Color color, IconData icon) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 20),
      );

  // ---------- Navigasyon/değer satırı ----------
  Widget _navRow(
    BuildContext context,
    bool isDark, {
    required Color color,
    required IconData icon,
    required String title,
    String? value,
    Color? valueColor,
    String? badge,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _iconSquare(color, icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary(isDark))),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _cRed, borderRadius: BorderRadius.circular(10)),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            if (value != null)
              Text(value,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? _textSecondary(isDark))),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _textMuted(isDark)),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Seviye satırı (başlık + ilerleme + kalan XP) ----------
  Widget _levelRow(bool isDark,
      {required String title, required double progress, required String right}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _iconSquare(_cOrange, Icons.star_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary(isDark))),
                    ),
                    const SizedBox(width: 8),
                    Text(right,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textMuted(isDark))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _cOrange.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_cOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Hedef satırı (başlık + ilerleme + oran) ----------
  Widget _goalRow(bool isDark,
      {required Color color,
      required IconData icon,
      required String title,
      required double progress,
      required String right,
      Color? rightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _iconSquare(color, icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary(isDark))),
                    ),
                    const SizedBox(width: 8),
                    Text(right,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: rightColor ?? _textSecondary(isDark))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Çıkış kartı ----------
  Widget _logoutCard(BuildContext context, ProfileViewModel vm, bool isDark) {
    return InkWell(
      onTap: () => _confirmLogout(context, vm),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _cardColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor(isDark)),
        ),
        child: Text('settings.account.logout'.tr(),
            style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: ColorConstant.errorRed)),
      ),
    );
  }

  // ---------- Başarılar / Arkadaşlar sayfaları ----------
  void _openAchievements(
      BuildContext context, ProfileViewModel vm, bool isDark) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Scaffold(
          backgroundColor:
              isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
          appBar: AppBar(
            backgroundColor:
                isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            foregroundColor: _textPrimary(isDark),
            title: Text('profile.achievementsBadges'.tr(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark))),
          ),
          body: _AchievementsTab(viewModel: vm),
        ),
      ),
    ));
  }

  void _openFriends(BuildContext context, ProfileViewModel vm, bool isDark) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Scaffold(
          backgroundColor:
              isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
          appBar: AppBar(
            backgroundColor:
                isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            foregroundColor: _textPrimary(isDark),
            title: Text('profile.friendsRow'.tr(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark))),
          ),
          body: _FriendsTab(viewModel: vm),
        ),
      ),
    ));
  }

  // Ayarlar sayfasını doğru bölüme kaydırarak açar.
  void _openSettings(BuildContext context, String section) {
    SettingsView.focusSection = section;
    context.router.push(const SettingsRoute());
  }

  // Uygulama hakkında (ad + sürüm) bilgisini gösterir.
  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'LifeSync',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF6A821)),
      ),
      children: [
        Text('profile.aboutText'.tr()),
      ],
    );
  }

  // Görüş / şikayet formunu açar.
  void _openFeedback(BuildContext context, ProfileViewModel vm, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSheet(isDark: isDark),
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
          color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
          color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
              color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
        isFollowing: viewModel.isFollowingUser(userId),
        isDarkMode: isDarkMode,
        onSendFriendRequest: () async {
          await viewModel.sendFriendRequest(userId, context);
        },
        onUnfriend: () => viewModel.unfriend(userId, context),
        onFollow: () => viewModel.follow(userId, context),
        onUnfollow: () => viewModel.unfollow(userId, context),
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
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
            : (isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight),
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
        color: widget.isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
                color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
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
            isFollowing: viewModel.isFollowingUser(userId),
            isDarkMode: isDarkMode,
            onSendFriendRequest: () async {
              await viewModel.sendFriendRequest(userId, context);
            },
            onUnfriend: () => viewModel.unfriend(userId, context),
            onFollow: () => viewModel.follow(userId, context),
            onUnfollow: () => viewModel.unfollow(userId, context),
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

// ==================== PROFİL DÜZENLEME + ÇIKIŞ ====================

/// Çıkış onay diyaloğu → onaylanırsa oturumu kapatır (settings ile aynı akış).
void _confirmLogout(BuildContext context, ProfileViewModel vm) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
      title: Text('settings.account.logout'.tr(),
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight)),
      content: Text('settings.account.logoutConfirm'.tr(),
          style: TextStyle(
              color: isDark
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            vm.logout(context);
          },
          child: Text('settings.account.logout'.tr(),
              style: const TextStyle(
                  color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

/// Ad / kullanıcı adı / bio düzenleme alt sayfası.
/// Backend PUT /profile (updateProfile) hazırdı ama hiçbir UI çağırmıyordu.
// ==================== GÖRÜŞ / ŞİKAYET FORMU ====================
class _FeedbackSheet extends StatefulWidget {
  final bool isDark;
  const _FeedbackSheet({required this.isDark});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _ctrl = TextEditingController();
  String _category = 'suggestion';
  bool _sending = false;

  static const _cats = [
    ['suggestion', 'profile.fbSuggestion'],
    ['complaint', 'profile.fbComplaint'],
    ['bug', 'profile.fbBug'],
    ['other', 'profile.fbOther'],
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.length < 10) {
      CustomSnackBar.showError(context, 'profile.feedbackEmpty'.tr());
      return;
    }
    setState(() => _sending = true);
    // Konu: mesajın tek satırlık kısa özeti (backend zorunlu tutuyor).
    var subject = msg.replaceAll('\n', ' ').trim();
    if (subject.length > 80) subject = '${subject.substring(0, 80)}…';
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    final res = await BaseApiService.post('/feedback', body: {
      'feedback_type': _category,
      'subject': subject,
      'message': msg,
      if (appVersion != null) 'app_version': appVersion,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.isSuccess) {
      Navigator.pop(context);
      CustomSnackBar.showSuccess(context, 'profile.feedbackSent'.tr());
    } else {
      CustomSnackBar.showError(
          context, res.errorMessage ?? 'errors.general'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final card = isDark ? ColorConstant.cardColorDark : ColorConstant.white;
    final fill =
        isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
    final txtP =
        isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
    final txtS = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    const accent = Color(0xFF4C9AFF);
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: fill, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('profile.feedbackTitle'.tr(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: txtP)),
              const SizedBox(height: 4),
              Text('profile.feedbackSubtitle'.tr(),
                  style: TextStyle(fontSize: 13, color: txtS)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in _cats)
                    GestureDetector(
                      onTap: () => setState(() => _category = cat[0]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _category == cat[0]
                              ? accent.withValues(alpha: 0.15)
                              : fill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _category == cat[0]
                                  ? accent
                                  : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Text(cat[1].tr(),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _category == cat[0] ? accent : txtS)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLength: 2000,
                  minLines: 4,
                  maxLines: 8,
                  autofocus: true,
                  style: TextStyle(fontSize: 15, color: txtP),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'profile.feedbackHint'.tr(),
                    hintStyle: TextStyle(color: txtS),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('profile.feedbackSend'.tr(),
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showEditProfileSheet(BuildContext context, ProfileViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditProfileSheet(vm: vm),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final ProfileViewModel vm;
  const _EditProfileSheet({required this.vm});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.vm.currentUser;
    _nameCtrl = TextEditingController(text: u?.displayName ?? '');
    _userCtrl = TextEditingController(text: u?.username ?? '');
    _bioCtrl = TextEditingController(text: u?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await widget.vm.updateProfile(
      displayName: _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      context: context,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      CustomSnackBar.showSuccess(context, 'profile.editSheet.saved'.tr());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = widget.vm.currentUser;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ColorConstant.bgColorDark : const Color(0xFFF6F4EF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: (isDark
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight)
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('profile.editSheet.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight)),
                const SizedBox(height: 18),
                _label('profile.editSheet.displayName'.tr(), isDark),
                _field(_nameCtrl, isDark),
                const SizedBox(height: 14),
                _label('profile.editSheet.username'.tr(), isDark),
                _field(_userCtrl, isDark, prefix: '@'),
                const SizedBox(height: 14),
                _label('profile.editSheet.bio'.tr(), isDark),
                _field(_bioCtrl, isDark,
                    hint: 'profile.editSheet.bioHint'.tr(), maxLines: 3),
                if (u?.email != null && u!.email!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _label('profile.editSheet.email'.tr(), isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            size: 18,
                            color: isDark
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(u.email!,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6A821),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('common.save'.tr(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight)),
      );

  Widget _field(TextEditingController ctrl, bool isDark,
      {String? hint, String? prefix, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: 15,
          color: isDark
              ? ColorConstant.textPrimaryDark
              : ColorConstant.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF6A821), width: 1.5)),
      ),
    );
  }
}

// ==================== HESAP BİLGİLERİ ====================

/// Salt okunur hesap/kimlik bilgileri + şifre değiştirme.
void showAccountInfoSheet(BuildContext context, ProfileViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AccountInfoSheet(vm: vm),
  );
}

class _AccountInfoSheet extends StatelessWidget {
  final ProfileViewModel vm;
  const _AccountInfoSheet({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = vm.currentUser;
    final textPrimary = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    final textSecondary = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    final textMuted =
        isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
    final cardColor =
        isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
    final borderColor = isDark
        ? ColorConstant.borderColorDark
        : ColorConstant.borderColorLight;

    final isGuest = u?.isGuest ?? false;
    final hasEmail = (u?.email?.isNotEmpty ?? false);
    final isPremium = (u?.subscriptionType != null &&
        u!.subscriptionType!.isNotEmpty &&
        u.subscriptionType!.toLowerCase() != 'free');

    final memberSince = u != null
        ? DateFormat('d MMMM yyyy', context.locale.toLanguageTag())
            .format(u.createdAt)
        : '—';

    Widget infoRow(IconData icon, Color color, String label, String value,
        {Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textMuted)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );
    }

    Widget verifiedBadge() {
      final ok = u?.isVerified ?? false;
      final c = ok ? const Color(0xFF46A46B) : const Color(0xFFF2685B);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded,
              size: 14, color: c),
          const SizedBox(width: 5),
          Text(
              ok
                  ? 'profile.account.verified'.tr()
                  : 'profile.account.notVerified'.tr(),
              style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ColorConstant.bgColorDark : const Color(0xFFF6F4EF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('profile.account.title'.tr(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 2),
                Text('profile.account.subtitle'.tr(),
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 16),

                // Bilgi kartı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      infoRow(
                          Icons.mail_rounded,
                          const Color(0xFF4C9AFF),
                          'profile.account.email'.tr(),
                          hasEmail
                              ? u!.email!
                              : 'profile.account.noEmail'.tr(),
                          trailing: hasEmail ? verifiedBadge() : null),
                      Divider(height: 1, color: borderColor),
                      infoRow(
                          Icons.calendar_today_rounded,
                          const Color(0xFF9C7BD9),
                          'profile.account.memberSince'.tr(),
                          memberSince),
                      Divider(height: 1, color: borderColor),
                      infoRow(
                          isGuest
                              ? Icons.person_outline_rounded
                              : Icons.account_circle_rounded,
                          const Color(0xFF2BB3A3),
                          'profile.account.type'.tr(),
                          isGuest
                              ? 'profile.account.typeGuest'.tr()
                              : 'profile.account.typeEmail'.tr()),
                      Divider(height: 1, color: borderColor),
                      infoRow(
                          isPremium
                              ? Icons.workspace_premium_rounded
                              : Icons.card_giftcard_rounded,
                          const Color(0xFFF6A821),
                          'profile.account.subscription'.tr(),
                          isPremium
                              ? 'profile.account.subPremium'.tr()
                              : 'profile.account.subFree'.tr()),
                    ],
                  ),
                ),

                if (isGuest) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6A821).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 20, color: Color(0xFFF6A821)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('profile.account.guestNote'.tr(),
                            style:
                                TextStyle(fontSize: 13, color: textSecondary)),
                      ),
                    ]),
                  ),
                ],

                // Şifre değiştir (sadece e-postalı hesaplar)
                if (!isGuest && hasEmail) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            _ChangePasswordDialog(email: u!.email!, isDark: isDark),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2685B).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              size: 20, color: Color(0xFFF2685B)),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('profile.account.changePassword'.tr(),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary)),
                              const SizedBox(height: 2),
                              Text('profile.account.changePasswordSub'.tr(),
                                  style: TextStyle(
                                      fontSize: 12.5, color: textMuted)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 15, color: textMuted),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Giriş yapmış kullanıcı için şifre değiştirme: önce e-postaya kod gönderilir,
/// sonra kod + yeni şifre ile güncellenir (forgot/reset akışı yeniden kullanılır).
class _ChangePasswordDialog extends StatefulWidget {
  final String email;
  final bool isDark;
  const _ChangePasswordDialog({required this.email, required this.isDark});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _codeSent = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    final auth = GetIt.I<IAuthService>();
    final res = await auth.forgotPassword(widget.email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      setState(() => _codeSent = true);
      CustomSnackBar.showSuccess(context, 'auth.codeSent'.tr());
    } else {
      CustomSnackBar.showError(
          context, res.message ?? 'errors.general'.tr());
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = GetIt.I<IAuthService>();
    final res = await auth.resetPassword(
      widget.email,
      _codeCtrl.text.trim(),
      _passCtrl.text,
      _passConfirmCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      Navigator.pop(context);
      CustomSnackBar.showSuccess(context, 'auth.passwordChanged'.tr());
    } else {
      CustomSnackBar.showError(
          context, res.message ?? 'errors.general'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final textPrimary =
        d ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
    final textSecondary = d
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    return AlertDialog(
      backgroundColor:
          d ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('profile.account.cpTitle'.tr(),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_codeSent) ...[
                Text(
                    'profile.account.cpSendDesc'
                        .tr(namedArgs: {'email': widget.email}),
                    style: TextStyle(color: textSecondary)),
              ] else ...[
                Text('profile.account.cpResetDesc'.tr(),
                    style: TextStyle(color: textSecondary)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'auth.resetCode'.tr(),
                    hintText: 'auth.resetCodeHint'.tr(),
                    counterText: '',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'auth.codeRequired'.tr();
                    if (v.length != 6) return 'auth.codeInvalid'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'auth.newPassword'.tr(),
                    hintText: 'auth.passwordHint'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (v.length < 6) return 'auth.passwordMinLength'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passConfirmCtrl,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'auth.confirmPassword'.tr(),
                    hintText: 'auth.passwordHint'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (v != _passCtrl.text) {
                      return 'auth.passwordsDoNotMatch'.tr();
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('common.cancel'.tr(),
              style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : (_codeSent ? _reset : _sendCode),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstant.primaryPurple,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  _codeSent
                      ? 'profile.account.cpUpdate'.tr()
                      : 'auth.sendCode'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
