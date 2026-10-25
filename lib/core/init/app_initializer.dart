import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:async';
import 'dart:io';

import '../../firebase_options.dart';
import '../constant/constants.dart';
import 'package:home_widget/home_widget.dart';
import 'locator.dart';
import '../utils/currency.dart';
import '../../service/firebase/fcm_service.dart';
import '../../service/widget/note_widget_service.dart';
import '../../service/widget/calendar_widget_service.dart';

class AppInitializer {
  static Future<void> init() async {
    // Flutter engine'i başlatmadan önce binding'i başlat
    WidgetsFlutterBinding.ensureInitialized();

    // Dikey yönelim için zorla
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Firebase'i başlat
    await _initFirebase();

    // Easy Localization'ı başlat
    await EasyLocalization.ensureInitialized();

    // GetIt (Dependency Injection) setup
    setupLocator();

    // Para birimi: kayıtlı tercih yoksa cihaz ülkesine göre varsayılan
    await AppCurrency.init();

    // Ana ekran widget'ı (iOS için app group; Android'de zararsız)
    try {
      await HomeWidget.setAppGroupId('group.com.aedev.kisisel');
    } catch (_) {}

    // RevenueCat ve FCM ağ gerektirir ve UI'nin ilk karesi için gerekli degil.
    // Bunlari await ETMEDEN arka planda baslat; boylece uygulama aninda acilir.
    // (Her iki metot kendi icinde try/catch ile korunuyor.)
    unawaited(_initRevenueCat());
    unawaited(_initFCM());

    // Ana ekran not + takvim widget'larını açılışta güncelle (oturum yoksa
    // sessizce geçer).
    unawaited(NoteWidgetService.update());
    unawaited(CalendarWidgetService.update());
  }

  static Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> _initRevenueCat() async {
    try {
      final apiKey = Platform.isIOS
          ? Constants.revenueCatApiKeyIOS
          : Constants.revenueCatApiKeyAndroid;

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  static Future<void> _initFCM() async {
    try {
      final fcmService = locator<FCMService>();
      await fcmService.initialize();
    } catch (e) {
      // FCM hatası uygulamayı crash etmemeli
      debugPrint('FCM initialization error: $e');
    }
  }
}
