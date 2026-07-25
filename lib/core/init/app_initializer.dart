import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

import '../../firebase_options.dart';
import '../constant/constants.dart';
import 'locator.dart';
import '../../service/firebase/fcm_service.dart';

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

    // RevenueCat'i başlat
    await _initRevenueCat();

    // FCM'i başlat
    await _initFCM();
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
