import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/init/locator.dart';
import '../../../service/auth/auth_service.dart';
import '../../../service/settings/settings_service.dart';
import '../../../service/budget/budget_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../models/settings/settings_models.dart';
import '../../../models/budget/buget_models.dart';
import '../../../models/auth/auth_models.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/helper_methods.dart';

class SettingsViewModel extends ChangeNotifier {
  final IAuthService _authService = locator.get<IAuthService>();
  final ISettingsService _settingsService = locator.get<ISettingsService>();
  final IBudgetService _budgetService = locator.get<IBudgetService>();
  final IProfileService _profileService = locator.get<IProfileService>();
  final InAppReview _inAppReview = InAppReview.instance;

  String _appVersion = '1.0.0';
  bool _isLoading = false;
  bool _isUserLoaded = false;
  Settings? _settings;
  User? _currentUser;

  String get appVersion => _appVersion;
  bool get isLoading => _isLoading;
  bool get isUserLoaded => _isUserLoaded;
  Settings? get settings => _settings;
  User? get currentUser => _currentUser;

  SettingsViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAppVersion();
    await loadSettings();
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    } finally {
      _isUserLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _settingsService.getSettings();

      if (response.isSuccess && response.data != null) {
        _settings = response.data;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? taskNotifications,
    bool? habitNotifications,
    bool? subscriptionNotifications,
    bool? noteNotifications,
    bool? diaryReminders,
    bool? socialNotifications,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final request = SettingsUpdateRequest(
        notificationsEnabled: notificationsEnabled,
        taskNotifications: taskNotifications,
        habitNotifications: habitNotifications,
        subscriptionNotifications: subscriptionNotifications,
        noteNotifications: noteNotifications,
        diaryReminders: diaryReminders,
        socialNotifications: socialNotifications,
      );

      final response = await _settingsService.updateSettings(request);

      if (response.isSuccess && response.data != null) {
        _settings = response.data;
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSecuritySettings({
    bool? requireBiometric,
    int? autoLockTimeout,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final request = SettingsUpdateRequest(
        requireBiometric: requireBiometric,
        autoLockTimeout: autoLockTimeout,
      );

      final response = await _settingsService.updateSettings(request);

      if (response.isSuccess && response.data != null) {
        _settings = response.data;
      }
    } catch (e) {
      debugPrint('Error updating security settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences({
    String? firstDayOfWeek,
    String? dateFormat,
    String? timeFormat,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final request = SettingsUpdateRequest(
        firstDayOfWeek: firstDayOfWeek,
        dateFormat: dateFormat,
        timeFormat: timeFormat,
      );

      final response = await _settingsService.updateSettings(request);

      if (response.isSuccess && response.data != null) {
        _settings = response.data;
      }
    } catch (e) {
      debugPrint('Error updating preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchasePremium(BuildContext context) async {
    // Paywall ekranına git
    context.router.push(const PaywallRoute());
  }

  Future<void> restorePurchases(BuildContext context) async {
    // Paywall ekranına git (restore için)
    context.router.push(const PaywallRoute());
  }

  Future<void> logout(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.logout();

      if (response.isSuccess) {
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'settings.account.logoutSuccess'.tr(),
          );
          context.router.replaceAll([const SplashRoute()]);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Faz 3: kullanıcının kendi verisini (profil + ayarlar) JSON olarak dışa
  /// aktarır ve paylaşım sayfasıyla sunar (GDPR/CCPA taşınabilirlik).
  Future<void> exportData(BuildContext context) async {
    try {
      final profileResp = await _profileService.getProfile();
      final user = profileResp.data ?? _currentUser;
      final data = {
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'LifeSync',
        'profile': user?.toJson(),
        'settings': _settings?.toJson(),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/lifesync_data_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'LifeSync data export',
      );
    } catch (e) {
      debugPrint('Data export error: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _profileService.deleteAccount();

      if (response.isSuccess) {
        // Hesap silme başlatıldı; yerel oturumu da temizle (hata olsa da devam et)
        try {
          await _authService.logout();
        } catch (_) {}
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'settings.account.deleteAccountSuccess'.tr(),
          );
          context.router.replaceAll([const SplashRoute()]);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logoutAllDevices(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.logoutAllDevices();

      if (response.isSuccess) {
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'settings.account.logoutAllSuccess'.tr(),
          );
          context.router.replaceAll([const SplashRoute()]);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'settings.account.logoutAllError'.tr(),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openPrivacyPolicy() async {
    final url = Uri.parse('https://goodlifesync.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTermsOfService() async {
    final url = Uri.parse('https://goodlifesync.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> contactUs() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'doseraliemre@gmail.com',
      query: 'subject=Destek Talebi',
    );

    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    }
  }

  Future<void> rateApp() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        final appId = Platform.isIOS ? '6754823140' : 'com.aedev.kisisel';
        final url = Platform.isIOS
            ? 'https://apps.apple.com/app/id$appId?action=write-review'
            : 'https://play.google.com/store/apps/details?id=$appId';

        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error rating app: $e');
    }
  }

  void showLogoutDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            'settings.account.logout'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'settings.account.logoutConfirm'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                logout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.errorRed,
              ),
              child: Text(
                'settings.account.logout'.tr(),
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

  void showLogoutAllDevicesDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            'settings.account.logoutAll'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'settings.account.logoutAllConfirm'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                logoutAllDevices(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.errorRed,
              ),
              child: Text(
                'settings.account.logoutAll'.tr(),
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

  void showDeleteAccountDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            'settings.account.deleteAccountConfirm'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'settings.account.deleteAccountWarning'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteAccount(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.errorRed,
              ),
              child: Text(
                'common.delete'.tr(),
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

  Future<void> updateCurrencyForLocale(Locale locale) async {
    try {
      // Get currency code for the selected locale
      final currencyCode = getCurrencyFromLocale(locale);

      // Get current budget to preserve monthlyBudget value
      final budgetResponse = await _budgetService.getBudget();

      if (budgetResponse.isSuccess && budgetResponse.data != null) {
        final currentBudget = budgetResponse.data!;

        // Update budget with new currency
        final request = BudgetRequest(
          monthlyBudget: currentBudget.monthlyBudget,
          currency: currencyCode,
        );

        await _budgetService.updateBudget(request);
      }

      // Faz 2: dil tercihini kullanıcı kaydına da senkronla (eskiden yalnızca
      // cihazda setLocale yapılıyordu; backend preferred_language güncellenmiyordu).
      await _profileService.updateProfile(
        ProfileUpdateRequest(preferredLanguage: locale.languageCode),
      );
    } catch (e) {
      debugPrint('Error updating currency: $e');
    }
  }

  /// Faz 2: temayı backend'e senkronla (yerel ThemeProvider birincil kalır;
  /// bu yalnızca cihazlar arası tutarlılık için). Sistem modunda yazma.
  Future<void> updateThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) return;
    try {
      await _settingsService.updateSettings(
        SettingsUpdateRequest(darkMode: mode == ThemeMode.dark),
      );
      if (_settings != null) {
        _settings = Settings(
          id: _settings!.id,
          userId: _settings!.userId,
          notificationsEnabled: _settings!.notificationsEnabled,
          taskNotifications: _settings!.taskNotifications,
          habitNotifications: _settings!.habitNotifications,
          subscriptionNotifications: _settings!.subscriptionNotifications,
          noteNotifications: _settings!.noteNotifications,
          diaryReminders: _settings!.diaryReminders,
          socialNotifications: _settings!.socialNotifications,
          darkMode: mode == ThemeMode.dark,
          themeColor: _settings!.themeColor,
          requireBiometric: _settings!.requireBiometric,
          autoLockTimeout: _settings!.autoLockTimeout,
          firstDayOfWeek: _settings!.firstDayOfWeek,
          dateFormat: _settings!.dateFormat,
          timeFormat: _settings!.timeFormat,
        );
      }
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  /// Faz 2: profil gizlilik tercihleri (görünürlük + neyi göster) → PUT /profile.
  Future<void> updatePrivacy({
    String? profileVisibility,
    bool? showLevel,
    bool? showAchievements,
    bool? showHabits,
  }) async {
    try {
      final response = await _profileService.updateProfile(
        ProfileUpdateRequest(
          profileVisibility: profileVisibility,
          showLevel: showLevel,
          showAchievements: showAchievements,
          showHabits: showHabits,
        ),
      );
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating privacy: $e');
    }
  }
}
