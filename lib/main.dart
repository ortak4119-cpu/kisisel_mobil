import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/constant/constants.dart';
import 'core/route/app_router.dart';
import 'core/utils/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/init/app_initializer.dart';
import 'core/init/app_providers.dart';

void main() async {
  await AppInitializer.init();

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

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: Constants.appName,
          debugShowCheckedModeBanner:false,

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
