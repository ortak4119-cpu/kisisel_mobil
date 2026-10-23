import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/color_constant.dart';

/// App Store'daki en guncel surumu kontrol eder ve yeni surum varsa
/// yumusak (opsiyonel) bir "Yeni surum mevcut" diyalogu gosterir.
///
/// - Backend/Remote Config gerektirmez: App Store'un iTunes lookup API'sini kullanir.
/// - Yalnizca iOS'ta calisir (Android icin ileride Remote Config eklenebilir).
/// - Oturumda yalnizca bir kez gosterir, hata durumunda sessizce gecer.
class UpdateService {
  static const String _appStoreId = '6754823140';
  static const String _bundleId = 'com.aedev.kisisel';

  static bool _checkedThisSession = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    // Simdilik yalnizca iOS. Android icin Play Store resmi API vermez;
    // ileride Firebase Remote Config ile eklenebilir.
    if (!Platform.isIOS) return;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // orn. 2.0.0

      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$_bundleId&country=tr',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return;

      final data = json.decode(res.body) as Map<String, dynamic>;
      if ((data['resultCount'] ?? 0) == 0) return;

      final storeVersion = data['results'][0]['version'] as String?;
      if (storeVersion == null) return;

      if (_isNewer(storeVersion, currentVersion) && context.mounted) {
        _showUpdateDialog(context);
      }
    } catch (_) {
      // Guncelleme kontrolu hicbir sekilde uygulamayi etkilememeli.
    }
  }

  /// store surumu current'tan yuksekse true (ornek: 2.1.0 > 2.0.0)
  static bool _isNewer(String store, String current) {
    final s = store.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final c =
        current.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final len = s.length > c.length ? s.length : c.length;
    for (var i = 0; i < len; i++) {
      final sv = i < s.length ? s[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (sv > cv) return true;
      if (sv < cv) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'update.title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
            ),
          ),
          content: Text(
            'update.message'.tr(),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'update.later'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ColorConstant.textSecondaryDark
                      : ColorConstant.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openStore();
              },
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? ColorConstant.primaryDarkModePurple
                    : ColorConstant.primaryPurple,
              ),
              child: Text(
                'update.update'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openStore() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/id$_appStoreId'
        : 'https://play.google.com/store/apps/details?id=$_bundleId';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
