import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/utils/premium_helper.dart';

@RoutePage()
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final themeProvider = Provider.of<ThemeProvider>(context);

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight,
                    ),
                    onPressed: () => context.router.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'settings.title'.tr(),
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (isDarkMode
                                    ? ColorConstant.primaryDarkModePurple
                                    : ColorConstant.primaryPurple)
                                .withValues(alpha: 0.1),
                            (isDarkMode
                                    ? ColorConstant.accentBlue
                                    : ColorConstant.accentBlue)
                                .withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Premium Bölümü - sadece kullanıcı yüklendikten sonra göster
                        if (viewModel.isUserLoaded)
                          _buildSection(
                            title: 'settings.sections.premium'.tr(),
                            isDarkMode: isDarkMode,
                            children: [
                              _buildPremiumCard(
                                context: context,
                                viewModel: viewModel,
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),

                        if (viewModel.isUserLoaded) const SizedBox(height: 20),

                        // Bildirimler Bölümü
                        _buildSection(
                          title: 'settings.sections.notifications'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildSwitchTile(
                              title: 'settings.notifications.all'.tr(),
                              subtitle:
                                  'settings.notifications.allSubtitle'.tr(),
                              icon: Icons.notifications_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.notificationsEnabled ??
                                  true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  notificationsEnabled: value,
                                );
                              },
                              iconColor: ColorConstant.primaryPurple,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.tasks'.tr(),
                              subtitle:
                                  'settings.notifications.tasksSubtitle'.tr(),
                              icon: Icons.task_rounded,
                              isDarkMode: isDarkMode,
                              value:
                                  viewModel.settings?.taskNotifications ?? true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  taskNotifications: value,
                                );
                              },
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.habits'.tr(),
                              subtitle:
                                  'settings.notifications.habitsSubtitle'.tr(),
                              icon: Icons.emoji_events_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.habitNotifications ??
                                  true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  habitNotifications: value,
                                );
                              },
                              iconColor: ColorConstant.accentGreen,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardGreenLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.diary'.tr(),
                              subtitle:
                                  'settings.notifications.diarySubtitle'.tr(),
                              icon: Icons.book_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.diaryReminders ?? true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  diaryReminders: value,
                                );
                              },
                              iconColor: ColorConstant.accentYellow,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardYellowDark
                                  : ColorConstant.cardYellowLight,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Görünüm Bölümü
                        _buildSection(
                          title: 'settings.sections.appearance'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildThemeTile(
                              context: context,
                              title: 'settings.appearance.theme'.tr(),
                              subtitle:
                                  'settings.appearance.themeSubtitle'.tr(),
                              icon: Icons.palette_rounded,
                              isDarkMode: isDarkMode,
                              themeProvider: themeProvider,
                            ),
                            _buildDivider(isDarkMode),
                            _buildLanguageTile(
                              context: context,
                              viewModel: viewModel,
                              title: 'settings.appearance.language'.tr(),
                              subtitle:
                                  'settings.appearance.languageSubtitle'.tr(),
                              icon: Icons.language_rounded,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        /*

                        // Güvenlik Bölümü
                        _buildSection(
                          title: 'settings.sections.security'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildSwitchTile(
                              title: 'settings.security.biometric'.tr(),
                              subtitle: 'settings.security.biometricSubtitle'.tr(),
                              icon: Icons.fingerprint_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.requireBiometric ?? false,
                              onChanged: (value) {
                                viewModel.updateSecuritySettings(
                                  requireBiometric: value,
                                );
                              },
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                         */

                        // Hesap İşlemleri Bölümü
                        _buildSection(
                          title: 'settings.sections.account'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildListTile(
                              title: 'settings.account.logout'.tr(),
                              subtitle: 'settings.account.logoutSubtitle'.tr(),
                              icon: Icons.logout_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                              onTap: () => viewModel.showLogoutDialog(context),
                            ),
                            _buildDivider(isDarkMode),
                            _buildListTile(
                              title: 'settings.account.logoutAll'.tr(),
                              subtitle:
                                  'settings.account.logoutAllSubtitle'.tr(),
                              icon: Icons.devices_other_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentOrange,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardYellowDark
                                  : ColorConstant.cardYellowLight,
                              onTap: () =>
                                  viewModel.showLogoutAllDevicesDialog(context),
                            ),
                            _buildDivider(isDarkMode),
                            _buildListTile(
                              title: 'settings.account.deleteAccount'.tr(),
                              subtitle:
                                  'settings.account.deleteAccountSubtitle'.tr(),
                              icon: Icons.delete_forever_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.errorRed,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.errorRed
                                      .withValues(alpha: 0.15)
                                  : ColorConstant.errorRed
                                      .withValues(alpha: 0.1),
                              onTap: () =>
                                  viewModel.showDeleteAccountDialog(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Yasal Bölüm
                        _buildSection(
                          title: 'settings.sections.legal'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildListTile(
                              title: 'settings.legal.privacy'.tr(),
                              subtitle: 'settings.legal.privacySubtitle'.tr(),
                              icon: Icons.privacy_tip_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentGreen,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardGreenLight,
                              onTap: () => viewModel.openPrivacyPolicy(),
                            ),
                            _buildDivider(isDarkMode),
                            _buildListTile(
                              title: 'settings.legal.terms'.tr(),
                              subtitle: 'settings.legal.termsSubtitle'.tr(),
                              icon: Icons.description_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.primaryPurple,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                              onTap: () => viewModel.openTermsOfService(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Destek Bölümü
                        _buildSection(
                          title: 'settings.sections.support'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildListTile(
                              title: 'settings.support.contact'.tr(),
                              subtitle: 'settings.support.contactSubtitle'.tr(),
                              icon: Icons.mail_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                              onTap: () => viewModel.contactUs(),
                            ),
                            _buildDivider(isDarkMode),
                            _buildListTile(
                              title: 'settings.support.rate'.tr(),
                              subtitle: 'settings.support.rateSubtitle'.tr(),
                              icon: Icons.star_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentYellow,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardYellowDark
                                  : ColorConstant.cardYellowLight,
                              onTap: () => viewModel.rateApp(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Versiyon Bilgisi
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? ColorConstant.cardColorDark
                                    .withValues(alpha: 0.5)
                                : ColorConstant.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorConstant.primaryPurple,
                                      ColorConstant.accentBlue,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.sync_rounded,
                                  size: 16,
                                  color: ColorConstant.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LifeSync',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? ColorConstant.textPrimaryDark
                                          : ColorConstant.textPrimaryLight,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Versiyon ${viewModel.appVersion}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? ColorConstant.textSecondaryDark
                                          : ColorConstant.textSecondaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? ColorConstant.cardColorDark
                : ColorConstant.cardColorLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? ColorConstant.black.withValues(alpha: 0.2)
                    : ColorConstant.primaryPurple.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required BuildContext context,
    required SettingsViewModel viewModel,
    required bool isDarkMode,
  }) {
    final isPremium = PremiumHelper.isPremiumUser(viewModel.currentUser);

    // Premium kullanıcı için farklı kart
    if (isPremium) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorConstant.accentGreen,
              ColorConstant.accentBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorConstant.accentGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                color: ColorConstant.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.premium.active'.tr(),
                    style: TextStyle(
                      color: ColorConstant.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'settings.premium.enjoyFeatures'.tr(),
                    style: TextStyle(
                      color: ColorConstant.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Premium olmayan kullanıcı için mevcut kart
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstant.accentYellow,
            ColorConstant.accentOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstant.accentYellow.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstant.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: ColorConstant.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'paywall.title'.tr(),
                      style: TextStyle(
                        color: ColorConstant.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'paywall.unlockFeatures'.tr(),
                      style: TextStyle(
                        color: ColorConstant.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.check_circle_rounded,
            text: 'paywall.unlimitedHabits'.tr(),
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(
            icon: Icons.check_circle_rounded,
            text: 'paywall.advancedAnalytics'.tr(),
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(
            icon: Icons.check_circle_rounded,
            text: 'paywall.adFree'.tr(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => viewModel.purchasePremium(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.white,
                    foregroundColor: ColorConstant.accentOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'paywall.buyNow'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => viewModel.restorePurchases(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstant.white,
                  side: BorderSide(color: ColorConstant.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(
                  Icons.restore_rounded,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: ColorConstant.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ColorConstant.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor ??
                      (isDarkMode
                          ? ColorConstant.cardColorDark
                          : ColorConstant.cardColorLight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor ??
                      (isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight),
                  size: 24,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDarkMode,
    required bool value,
    required Function(bool) onChanged,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor ??
                  (isDarkMode
                      ? ColorConstant.cardColorDark
                      : ColorConstant.cardColorLight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor ??
                  (isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight),
              size: 24,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDarkMode
                ? ColorConstant.primaryDarkModePurple
                : ColorConstant.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
  }) {
    String themeModeText;
    IconData themeModeIcon;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        themeModeText = 'settings.appearance.themeLight'.tr();
        themeModeIcon = Icons.light_mode_rounded;
        break;
      case ThemeMode.dark:
        themeModeText = 'settings.appearance.themeDark'.tr();
        themeModeIcon = Icons.dark_mode_rounded;
        break;
      default:
        themeModeText = 'settings.appearance.themeSystem'.tr();
        themeModeIcon = Icons.brightness_auto_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showThemeDialog(
          context: context,
          themeProvider: themeProvider,
          isDarkMode: isDarkMode,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.cardPurpleDark
                      : ColorConstant.cardPurpleLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: ColorConstant.primaryPurple,
                  size: 24,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      themeModeIcon,
                      size: 16,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      themeModeText,
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
              const SizedBox(width: 8),
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

  Widget _buildLanguageTile({
    required BuildContext context,
    required SettingsViewModel viewModel,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final currentLocale = context.locale;
    String languageText;

    if (currentLocale.languageCode == 'tr') {
      languageText = 'settings.appearance.turkish'.tr();
    } else {
      languageText = 'settings.appearance.english'.tr();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageDialog(
          context: context,
          viewModel: viewModel,
          isDarkMode: isDarkMode,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.cardBlueDark
                      : ColorConstant.cardBlueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: ColorConstant.accentBlue,
                  size: 24,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      languageText,
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
              const SizedBox(width: 8),
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

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDarkMode
            ? ColorConstant.borderColorDark
            : ColorConstant.borderColorLight,
      ),
    );
  }

  void _showThemeDialog({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required bool isDarkMode,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? ColorConstant.cardColorDark
              : ColorConstant.cardColorLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'settings.appearance.themeSelect'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context: dialogContext,
                title: 'settings.appearance.themeSystem'.tr(),
                subtitle: 'settings.appearance.themeSystemSubtitle'.tr(),
                icon: Icons.brightness_auto_rounded,
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                isDarkMode: isDarkMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: dialogContext,
                title: 'settings.appearance.themeLight'.tr(),
                subtitle: 'settings.appearance.themeLightSubtitle'.tr(),
                icon: Icons.light_mode_rounded,
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                isDarkMode: isDarkMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: dialogContext,
                title: 'settings.appearance.themeDark'.tr(),
                subtitle: 'settings.appearance.themeDarkSubtitle'.tr(),
                icon: Icons.dark_mode_rounded,
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                isDarkMode: isDarkMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.primaryPurple,
              ),
              child: const Text(
                'Kapat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog({
    required BuildContext context,
    required SettingsViewModel viewModel,
    required bool isDarkMode,
  }) {
    final currentLocale = context.locale;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? ColorConstant.cardColorDark
              : ColorConstant.cardColorLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'settings.appearance.languageSelect'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'English',
                  icon: Icons.flag_rounded,
                  locale: const Locale('en', 'US'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Türkçe',
                  icon: Icons.flag_rounded,
                  locale: const Locale('tr', 'TR'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: '中文 (简体)',
                  icon: Icons.flag_rounded,
                  locale: const Locale('zh', 'CN'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'हिन्दी',
                  icon: Icons.flag_rounded,
                  locale: const Locale('hi', 'IN'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Español',
                  icon: Icons.flag_rounded,
                  locale: const Locale('es', 'ES'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'العربية',
                  icon: Icons.flag_rounded,
                  locale: const Locale('ar', 'SA'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Français',
                  icon: Icons.flag_rounded,
                  locale: const Locale('fr', 'FR'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Русский',
                  icon: Icons.flag_rounded,
                  locale: const Locale('ru', 'RU'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Português',
                  icon: Icons.flag_rounded,
                  locale: const Locale('pt', 'PT'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: 'Deutsch',
                  icon: Icons.flag_rounded,
                  locale: const Locale('de', 'DE'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  context: dialogContext,
                  title: '日本語',
                  icon: Icons.flag_rounded,
                  locale: const Locale('ja', 'JP'),
                  currentLocale: currentLocale,
                  isDarkMode: isDarkMode,
                  onChanged: (locale) async {
                    context.setLocale(locale);
                    await viewModel.updateCurrencyForLocale(locale);
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.accentBlue,
              ),
              child: Text(
                'common.close'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required bool isDarkMode,
    required Function(ThemeMode?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? ColorConstant.primaryDarkModePurple.withValues(alpha: 0.2)
                    : ColorConstant.primaryPurple.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDarkMode
                      ? ColorConstant.primaryDarkModePurple
                      : ColorConstant.primaryPurple)
                  : (isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.cardColorDark
                      : ColorConstant.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? (isDarkMode
                          ? ColorConstant.primaryDarkModePurple
                          : ColorConstant.primaryPurple)
                      : (isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight),
                  size: 24,
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
                        fontWeight: FontWeight.w600,
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
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: isDarkMode
                      ? ColorConstant.primaryDarkModePurple
                      : ColorConstant.primaryPurple,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Locale locale,
    required Locale currentLocale,
    required bool isDarkMode,
    required Function(Locale) onChanged,
  }) {
    final isSelected = locale.languageCode == currentLocale.languageCode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(locale),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? ColorConstant.accentBlue.withValues(alpha: 0.2)
                    : ColorConstant.accentBlue.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ColorConstant.accentBlue
                  : (isDarkMode
                      ? ColorConstant.borderColorDark
                      : ColorConstant.borderColorLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ColorConstant.cardColorDark
                      : ColorConstant.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? ColorConstant.accentBlue
                      : (isDarkMode
                          ? ColorConstant.textSecondaryDark
                          : ColorConstant.textSecondaryLight),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: ColorConstant.accentBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
