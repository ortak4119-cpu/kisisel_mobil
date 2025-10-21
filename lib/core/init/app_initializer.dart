import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

import '../../firebase_options.dart';
import '../constant/constants.dart';
import 'locator.dart';

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
  }

  static Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> _initRevenueCat() async {
    if (Platform.isIOS) {
      await Purchases.setup(Constants.revenueCatApiKeyIOS);
    } else if (Platform.isAndroid) {
      await Purchases.setup(Constants.revenueCatApiKeyAndroid);
    }

    await Purchases.setDebugLogsEnabled(true);
  }
}