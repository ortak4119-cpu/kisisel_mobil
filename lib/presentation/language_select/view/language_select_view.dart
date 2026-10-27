import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/utils/color_constant.dart';

/// İlk açılışta gösterilen dil seçim ekranı.
/// Varsayılan olarak İngilizce seçili gelir; ekran yazıları (başlık / buton)
/// kasıtlı olarak İngilizcedir. Dil seçilip "Continue" ile devam edilince
/// uygulama dili ayarlanır ve onboarding seçilen dilde açılır.
@RoutePage()
class LanguageSelectView extends StatefulWidget {
  const LanguageSelectView({super.key});

  @override
  State<LanguageSelectView> createState() => _LanguageSelectViewState();
}

class _LanguageSelectViewState extends State<LanguageSelectView> {
  // code (rozet) · yerel ad · locale
  static const List<List<Object>> _languages = [
    ['EN', 'English', Locale('en', 'US')],
    ['TR', 'Türkçe', Locale('tr', 'TR')],
    ['中', '中文 (简体)', Locale('zh', 'CN')],
    ['हि', 'हिन्दी', Locale('hi', 'IN')],
    ['ES', 'Español', Locale('es', 'ES')],
    ['ع', 'العربية', Locale('ar', 'SA')],
    ['FR', 'Français', Locale('fr', 'FR')],
    ['DE', 'Deutsch', Locale('de', 'DE')],
    ['RU', 'Русский', Locale('ru', 'RU')],
    ['PT', 'Português', Locale('pt', 'PT')],
    ['日', '日本語', Locale('ja', 'JP')],
  ];

  // Varsayılan: İngilizce.
  Locale _selected = const Locale('en', 'US');

  static const _accent = Color(0xFF2FA39A); // seçili radio/rozet (teal)
  static const _accentBg = Color(0xFFDFF0EE); // seçili satır arka planı

  Future<void> _continue() async {
    await context.setLocale(_selected);
    if (!mounted) return;
    context.router.replace(const OnboardingRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.bgColorLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Başlık (İngilizce — bilinçli olarak sabit)
              Text(
                'Select language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColorConstant.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred language',
                style: TextStyle(
                  fontSize: 15,
                  color: ColorConstant.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final code = _languages[i][0] as String;
                    final name = _languages[i][1] as String;
                    final locale = _languages[i][2] as Locale;
                    final selected = locale.languageCode ==
                            _selected.languageCode &&
                        locale.countryCode == _selected.countryCode;
                    return _languageRow(code, name, locale, selected);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageRow(String code, String name, Locale locale, bool selected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = locale),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _accentBg : ColorConstant.cardColorLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _accent : ColorConstant.borderColorLight,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              // Kod rozeti
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _accent.withValues(alpha: 0.16)
                      : ColorConstant.bgColorLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? _accent
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ColorConstant.textPrimaryLight,
                  ),
                ),
              ),
              // Radio
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? _accent : ColorConstant.textMutedLight,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
