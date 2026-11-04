import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:audioplayers/audioplayers.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../../service/notification/notification_sound.dart';
import '../../../service/notification/notification_service.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/premium_helper.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/animation_prefs.dart';

@RoutePage()
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  /// Profilden "doğru bölüme git" için hedef bölüm + bölüm anahtarları.
  static String? focusSection;
  static final Map<String, GlobalKey> sectionKeys = {
    'notifications': GlobalKey(),
    'appearance': GlobalKey(),
    'privacy': GlobalKey(),
    'support': GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    // Hedef bölüm belirtilmişse ilk kareden sonra ona kaydır.
    final target = focusSection;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = sectionKeys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOut,
              alignment: 0.08);
        }
        focusSection = null;
      });
    }
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: ResponsiveCenter(
              child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDarkMode
                      ? ColorConstant.bgColorDark
                      : ColorConstant.bgColorLight,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
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
                                    ? ColorConstant.accentOrange
                                    : ColorConstant.accentOrange)
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

                        // Premium Bölümü - sadece premium OLMAYAN kullanıcıya göster.
                        // Premium kullanıcıda en üstte "Premium" başlığı görünmez.
                        if (viewModel.isUserLoaded &&
                            !PremiumHelper.isPremiumUser(
                                viewModel.currentUser)) ...[
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
                          const SizedBox(height: 20),
                        ],

                        // Bildirimler Bölümü — açılır/kapanır (varsayılan KAPALI).
                        _CollapsibleSettingsSection(
                          key: sectionKeys['notifications'],
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
                              iconColor: ColorConstant.accentOrange,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                            ),
                            _buildDivider(isDarkMode),
                            // Bildirim sesi — önizlemeli seçici (tek genel ses).
                            ValueListenableBuilder<String>(
                              valueListenable: NotifSoundPrefs.idListenable,
                              builder: (_, sid, __) => _buildListTile(
                                title: 'settings.notif_sound_title'.tr(),
                                subtitle:
                                    'settings.${NotifSound.byId(sid).nameKey}'
                                        .tr(),
                                icon: Icons.music_note_rounded,
                                isDarkMode: isDarkMode,
                                onTap: () =>
                                    _showSoundPicker(context, isDarkMode),
                                iconColor: ColorConstant.accentOrange,
                                iconBgColor: isDarkMode
                                    ? ColorConstant.cardPurpleDark
                                    : ColorConstant.cardPurpleLight,
                              ),
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
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.subscription'.tr(),
                              icon: Icons.subscriptions_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel
                                      .settings?.subscriptionNotifications ??
                                  true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  subscriptionNotifications: value,
                                );
                              },
                              iconColor: ColorConstant.accentOrange,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.note'.tr(),
                              icon: Icons.sticky_note_2_rounded,
                              isDarkMode: isDarkMode,
                              value:
                                  viewModel.settings?.noteNotifications ?? true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  noteNotifications: value,
                                );
                              },
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.social'.tr(),
                              icon: Icons.people_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.socialNotifications ??
                                  true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  socialNotifications: value,
                                );
                              },
                              iconColor: ColorConstant.accentGreen,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardGreenLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.notifications.engagement'.tr(),
                              icon: Icons.auto_awesome_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.settings?.engagementEnabled ??
                                  true,
                              onChanged: (value) {
                                viewModel.updateNotificationSettings(
                                  engagementEnabled: value,
                                );
                              },
                              iconColor: ColorConstant.accentOrange,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Görünüm Bölümü
                        _buildSection(
                          title: 'settings.sections.appearance'.tr(),
                          sectionKey: sectionKeys['appearance'],
                          isDarkMode: isDarkMode,
                          children: [
                            // Tema (5 tam palet, açık/koyu) — uygulama geneli.
                            _buildListTile(
                              title: 'settings.theme_title'.tr(),
                              subtitle:
                                  'settings.theme_${AppPalette.currentId}'.tr(),
                              icon: Icons.palette_rounded,
                              isDarkMode: isDarkMode,
                              onTap: () => _showThemePicker(context, isDarkMode),
                              iconColor: AppPalette.accent,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardColorLight,
                            ),
                            _buildLanguageTile(
                              context: context,
                              viewModel: viewModel,
                              title: 'settings.appearance.language'.tr(),
                              subtitle:
                                  'settings.appearance.languageSubtitle'.tr(),
                              icon: Icons.language_rounded,
                              isDarkMode: isDarkMode,
                            ),
                            // Animasyonları kapat (switch açık = animasyonlar KAPALI)
                            ValueListenableBuilder<bool>(
                              valueListenable: AnimationPrefs.enabled,
                              builder: (_, animEnabled, __) => _buildSwitchTile(
                                title:
                                    'settings.appearance.disableAnimations'.tr(),
                                subtitle:
                                    'settings.appearance.disableAnimationsSubtitle'
                                        .tr(),
                                icon: Icons.motion_photos_off_rounded,
                                isDarkMode: isDarkMode,
                                value: !animEnabled,
                                onChanged: (v) =>
                                    AnimationPrefs.setEnabled(!v),
                                iconColor: ColorConstant.accentOrange,
                                iconBgColor: isDarkMode
                                    ? ColorConstant.cardColorDark
                                    : ColorConstant.cardColorLight,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Gizlilik Bölümü
                        _buildSection(
                          title: 'settings.sections.privacy'.tr(),
                          isDarkMode: isDarkMode,
                          children: [
                            _buildListTile(
                              title: 'settings.privacy.visibility'.tr(),
                              subtitle: _visibilityLabel(
                                  viewModel.currentUser?.profileVisibility ??
                                      'public'),
                              icon: Icons.visibility_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentOrange,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardPurpleDark
                                  : ColorConstant.cardPurpleLight,
                              onTap: () =>
                                  _showVisibilityDialog(context, viewModel, isDarkMode),
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.privacy.showLevel'.tr(),
                              icon: Icons.military_tech_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.currentUser?.showLevel ?? true,
                              onChanged: (value) {
                                viewModel.updatePrivacy(showLevel: value);
                              },
                              iconColor: ColorConstant.accentYellow,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardYellowDark
                                  : ColorConstant.cardYellowLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.privacy.showAchievements'.tr(),
                              icon: Icons.emoji_events_rounded,
                              isDarkMode: isDarkMode,
                              value:
                                  viewModel.currentUser?.showAchievements ?? true,
                              onChanged: (value) {
                                viewModel.updatePrivacy(showAchievements: value);
                              },
                              iconColor: ColorConstant.accentGreen,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardGreenLight,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSwitchTile(
                              title: 'settings.privacy.showHabits'.tr(),
                              icon: Icons.track_changes_rounded,
                              isDarkMode: isDarkMode,
                              value: viewModel.currentUser?.showHabits ?? true,
                              onChanged: (value) {
                                viewModel.updatePrivacy(showHabits: value);
                              },
                              iconColor: ColorConstant.accentBlue,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardBlueDark
                                  : ColorConstant.cardBlueLight,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

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
                              title: 'settings.account.exportData'.tr(),
                              subtitle:
                                  'settings.account.exportDataSubtitle'.tr(),
                              icon: Icons.download_rounded,
                              isDarkMode: isDarkMode,
                              iconColor: ColorConstant.accentGreen,
                              iconBgColor: isDarkMode
                                  ? ColorConstant.cardColorDark
                                  : ColorConstant.cardGreenLight,
                              onTap: () => viewModel.exportData(context),
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
                              iconColor: ColorConstant.accentOrange,
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
                          sectionKey: sectionKeys['support'],
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
                                      ColorConstant.accentOrange,
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
    Key? sectionKey,
  }) {
    return Column(
      key: sectionKey,
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
                    : ColorConstant.accentOrange.withValues(alpha: 0.08),
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

    // Premium kullanıcıya ayarlarda "üyesiniz" uyarısı gösterilmez
    // (üyelik bilgisi artık Profil > Üyelik bölümünde).
    if (isPremium) {
      return const SizedBox.shrink();
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

  // Tema seçici (5 tam palet, önizlemeli) — seçince anında uygulanır.
  void _showThemePicker(BuildContext context, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final card = isDarkMode
              ? ColorConstant.cardColorDark
              : ColorConstant.cardColorLight;
          final bg = isDarkMode
              ? ColorConstant.bgColorDark
              : ColorConstant.bgColorLight;
          final txtP = isDarkMode
              ? ColorConstant.textPrimaryDark
              : ColorConstant.textPrimaryLight;
          final txtM = isDarkMode
              ? ColorConstant.textMutedDark
              : ColorConstant.textMutedLight;
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                            color: txtM.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text('settings.theme_title'.tr(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: txtP)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: Icon(Icons.close_rounded, color: txtM),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final o in AppPalette.all)
                      _themeRow(o, isDarkMode, card, txtP, () {
                        themeProvider.setPalette(o.id);
                        setSheet(() {});
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Bildirim sesi seçici — her satırda önizleme (çal) + seçim.
  void _showSoundPicker(BuildContext context, bool isDarkMode) {
    final player = AudioPlayer();
    Future<void> preview(NotifSound s) async {
      if (s.asset == null) return;
      try {
        await player.stop();
        await player.play(AssetSource(s.asset!));
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final card = isDarkMode
              ? ColorConstant.cardColorDark
              : ColorConstant.cardColorLight;
          final bg = isDarkMode
              ? ColorConstant.bgColorDark
              : ColorConstant.bgColorLight;
          final txtP = isDarkMode
              ? ColorConstant.textPrimaryDark
              : ColorConstant.textPrimaryLight;
          final txtM = isDarkMode
              ? ColorConstant.textMutedDark
              : ColorConstant.textMutedLight;
          final border = isDarkMode
              ? ColorConstant.borderColorDark
              : ColorConstant.borderColorLight;
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                            color: txtM.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text('settings.notif_sound_title'.tr(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: txtP)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: Icon(Icons.close_rounded, color: txtM),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final s in NotifSound.all)
                      _soundRow(s, card, txtP, border, () {
                        NotifSoundPrefs.set(s.id);
                        // Backend'e kaydet (arka plan push'ları için).
                        NotificationService().updateNotificationSound(s.id);
                        preview(s);
                        setSheet(() {});
                      }, () => preview(s)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => player.dispose());
  }

  Widget _soundRow(NotifSound s, Color card, Color txtP, Color border,
      VoidCallback onSelect, VoidCallback onPreview) {
    final selected = NotifSoundPrefs.currentId == s.id;
    final accent = ColorConstant.accentOrange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? accent : border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('settings.${s.nameKey}'.tr(),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: txtP)),
              ),
              if (s.asset != null)
                IconButton(
                  onPressed: onPreview,
                  icon: Icon(Icons.play_circle_outline_rounded, color: accent),
                  tooltip: 'settings.snd_preview'.tr(),
                ),
              const SizedBox(width: 2),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: border, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeRow(AppThemeOption o, bool isDarkMode, Color card, Color txtP,
      VoidCallback onTap) {
    final surf = isDarkMode ? o.dark : o.light;
    final selected = AppPalette.currentId == o.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? o.accent : surf.border,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              // Mini önizleme: zemin + kart + aksan.
              Container(
                width: 58,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: surf.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: surf.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: surf.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: o.accent, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('settings.theme_${o.nameKey}'.tr(),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: txtP)),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: o.accent)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: surf.border, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
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

  String _visibilityLabel(String v) {
    switch (v) {
      case 'friends':
        return 'settings.privacy.friends'.tr();
      case 'private':
        return 'settings.privacy.private'.tr();
      case 'public':
      default:
        return 'settings.privacy.public'.tr();
    }
  }

  void _showVisibilityDialog(
      BuildContext context, SettingsViewModel viewModel, bool isDarkMode) {
    final current = viewModel.currentUser?.profileVisibility ?? 'public';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        title: Text('settings.privacy.visibility'.tr(),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['public', 'friends', 'private'].map((v) {
            final selected = v == current;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? ColorConstant.accentOrange
                    : (isDarkMode
                        ? ColorConstant.textMutedDark
                        : ColorConstant.textMutedLight),
              ),
              title: Text(_visibilityLabel(v),
                  style: TextStyle(
                      color: isDarkMode
                          ? ColorConstant.textPrimaryDark
                          : ColorConstant.textPrimaryLight)),
              onTap: () {
                Navigator.pop(ctx);
                if (v != current) {
                  viewModel.updatePrivacy(profileVisibility: v);
                }
              },
            );
          }).toList(),
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
            // Seçili temanın aksanı (mor sabit yerine).
            activeThumbColor: ColorConstant.accentOrange,
            activeTrackColor: ColorConstant.accentOrange.withValues(alpha: 0.4),
          ),
        ],
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
                      : ColorConstant.cardColorLight,
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

/// Açılır/kapanır ayar bölümü (başlığa dokununca aç/kapa). Varsayılan kapalı.
class _CollapsibleSettingsSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool isDarkMode;
  final bool initiallyExpanded;
  const _CollapsibleSettingsSection({
    super.key,
    required this.title,
    required this.children,
    required this.isDarkMode,
    this.initiallyExpanded = false,
  });
  @override
  State<_CollapsibleSettingsSection> createState() =>
      _CollapsibleSettingsSectionState();
}

class _CollapsibleSettingsSectionState
    extends State<_CollapsibleSettingsSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final muted =
        isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: muted,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorConstant.cardColorDark
                          : ColorConstant.cardColorLight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? ColorConstant.black.withValues(alpha: 0.2)
                              : ColorConstant.accentOrange
                                  .withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(children: widget.children),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}
