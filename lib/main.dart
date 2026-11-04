import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/constant/constants.dart';
import 'core/route/app_router.dart';
import 'presentation/common/app_update_gate.dart';
import 'core/utils/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_palette.dart';
import 'service/notification/notification_sound.dart';
import 'core/init/app_initializer.dart';
import 'core/init/app_providers.dart';
import 'core/utils/app_locale.dart';
import 'core/utils/animation_prefs.dart';
import 'service/share/share_intent_handler.dart';

void main() async {
  // Release derlemelerinde hiçbir debug log cihaz loglarına (logcat) yazılmasın;
  // PII (e-posta/kullanıcı adı) ve token'ların sızmasını önler.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await AppInitializer.init();

  // Animasyon tercihini (Ayarlar › Görünüm) belleğe yükle.
  await AnimationPrefs.load();

  // Seçili temayı (Ayarlar › Görünüm › Tema) ilk build'den önce yükle.
  await AppPalette.load();

  // Seçili bildirim sesini (Ayarlar › Bildirimler) belleğe yükle.
  await NotifSoundPrefs.load();

  // Başka uygulamadan "Paylaş" ile gelen metni not olarak içe aktar.
  ShareIntentHandler.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),  // İngilizce
        Locale('tr', 'TR'),  // Türkçe
        Locale('zh', 'CN'),  // Çince (Basitleştirilmiş)
        Locale('hi', 'IN'),  // Hintçe
        Locale('es', 'ES'),  // İspanyolca
        Locale('ar', 'SA'),  // Arapça
        Locale('fr', 'FR'),  // Fransızca
        Locale('ru', 'RU'),  // Rusça
        Locale('pt', 'PT'),  // Portekizce
        Locale('de', 'DE'),  // Almanca
        Locale('ja', 'JP'),  // Japonca
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: MultiProvider(
        providers: AppProviders.providers,
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  @override
  void initState() {
    super.initState();
    // Açılıştan kısa süre sonra sürüm kontrolü yap (gerekirse güncelleme uyarısı).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Splash → ana ekran geçişi oturduktan sonra kontrol et (diyalog
      // geçiş sırasında kaldırılmasın diye yeterli gecikme).
      Future.delayed(const Duration(milliseconds: 4500), () {
        final ctx = _appRouter.navigatorKey.currentContext;
        if (ctx != null) {
          AppUpdateGate.check(ctx);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // API isteklerinde backend'e gönderilecek dil kodunu güncel tut.
        AppLocale.code = context.locale.languageCode;
        return MaterialApp.router(
          title: Constants.appName,
          debugShowCheckedModeBanner:false,
          scaffoldMessengerKey: ShareIntentHandler.messengerKey,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localization
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,

          // Router configuration
          routerConfig: _appRouter.config(),
        );
      },
    );
  }
}
