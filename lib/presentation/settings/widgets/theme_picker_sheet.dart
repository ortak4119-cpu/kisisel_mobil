import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/init/locator.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../models/settings/settings_models.dart';

/// Görünüm seçici — açık/koyu/sistem modu + 5 tam palet (Ayarlar › Görünüm).
/// Yerel ThemeProvider birincil; mod ayrıca backend'e senkronlanır
/// (sistem modu hariç).
void showThemePickerSheet(BuildContext context) {
  final themeProvider = context.read<ThemeProvider>();

  Future<void> applyMode(ThemeMode mode) async {
    await themeProvider.setThemeMode(mode);
    if (mode != ThemeMode.system) {
      try {
        await settingsService.updateSettings(
          SettingsUpdateRequest(darkMode: mode == ThemeMode.dark),
        );
      } catch (_) {/* yerel tercih birincil; sessizce geç */}
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final card =
            isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight;
        final bg = isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
        final border = isDark
            ? ColorConstant.borderColorDark
            : ColorConstant.borderColorLight;
        final txtP =
            isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
        final txtM =
            isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;

        Widget modeChip(String label, IconData icon, ThemeMode mode) {
          final sel = themeProvider.themeMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                await applyMode(mode);
                setSheet(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppPalette.accent.withValues(alpha: 0.14) : card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppPalette.accent : border),
                ),
                child: Column(children: [
                  Icon(icon, size: 22, color: sel ? AppPalette.accent : txtM),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: sel ? AppPalette.accent : txtP)),
                ]),
              ),
            ),
          );
        }

        Widget paletteCard(AppThemeOption o) {
          final sel = AppPalette.currentId == o.id;
          return GestureDetector(
            onTap: () {
              themeProvider.setPalette(o.id);
              setSheet(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? o.accent : border, width: sel ? 2 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [o.accent, o.accentSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('settings.theme_${o.nameKey}'.tr(),
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: txtP)),
                ),
                if (sel)
                  Icon(Icons.check_circle_rounded, size: 20, color: o.accent),
              ]),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                              color: txtM.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text('settings.appearance.theme'.tr(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: txtP)),
                    const SizedBox(height: 16),
                    Text('settings.appearance.themeSelect'.tr().toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: txtM)),
                    const SizedBox(height: 10),
                    Row(children: [
                      modeChip('settings.appearance.themeSystem'.tr(),
                          Icons.brightness_auto_rounded, ThemeMode.system),
                      modeChip('settings.appearance.themeLight'.tr(),
                          Icons.light_mode_rounded, ThemeMode.light),
                      modeChip('settings.appearance.themeDark'.tr(),
                          Icons.dark_mode_rounded, ThemeMode.dark),
                    ]),
                    const SizedBox(height: 22),
                    Text('settings.theme_title'.tr().toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: txtM)),
                    const SizedBox(height: 10),
                    for (final o in AppPalette.all) paletteCard(o),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Tema modunun satırda gösterilecek etiketi (Sistem/Açık/Koyu).
String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'settings.appearance.themeLight'.tr();
    case ThemeMode.dark:
      return 'settings.appearance.themeDark'.tr();
    case ThemeMode.system:
      return 'settings.appearance.themeSystem'.tr();
  }
}
