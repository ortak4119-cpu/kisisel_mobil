import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../../core/init/locator.dart';
import '../../../service/auth/auth_service.dart';
import '../../../service/settings/settings_service.dart';
import '../../../service/budget/budget_service.dart';
import '../../../models/settings/settings_models.dart';
import '../../../models/budget/buget_models.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/helper_methods.dart';

class SettingsViewModel extends ChangeNotifier {
  final IAuthService _authService = locator.get<IAuthService>();
  final ISettingsService _settingsService = locator.get<ISettingsService>();
  final IBudgetService _budgetService = locator.get<IBudgetService>();
  final InAppReview _inAppReview = InAppReview.instance;

  String _appVersion = '1.0.0';
  bool _isLoading = false;
  Settings? _settings;

  String get appVersion => _appVersion;
  bool get isLoading => _isLoading;
  Settings? get settings => _settings;

  SettingsViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAppVersion();
    await loadSettings();
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
        final appId = Platform.isIOS
            ? '6754823140'
            : 'com.aedev.kisiseş';
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
              child:  Text(
                'common.cancel'.tr(),
                style: TextStyle(
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
              child:  Text(
                'settings.account.logout'.tr(),
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
              child:  Text(
                'common.cancel'.tr(),
                style: TextStyle(
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
              child:  Text(
                'settings.account.logoutAll'.tr(),
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
              child:  Text(
                'common.cancel'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // TODO: Hesap silme endpoint'i eklendiğinde burası güncellenecek
                // Şimdilik sadece çıkış yap
                logout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorConstant.errorRed,
              ),
              child:  Text(
                'common.delete'.tr(),
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
    } catch (e) {
      debugPrint('Error updating currency: $e');
    }
  }
}
