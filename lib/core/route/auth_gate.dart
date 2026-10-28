import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:base/service/auth/auth_service.dart';
import 'package:base/service/base/base_api_service.dart';
import 'package:base/service/revenue_cat/revenue_cat_service.dart';
import 'package:base/core/route/app_router.gr.dart';

/// Abonelik kapısı.
///
/// Uygulama "7 gün dene, sonra öde" modelinde çalışır: aktif abonelik veya
/// deneme olmadan kullanıcı ana ekranı göremez. Bu sınıf, giriş noktalarının
/// (splash, kayıt, giriş) ortak yönlendirme mantığını tutar.
class AuthGate {
  const AuthGate._();

  /// Kullanıcının aktif aboneliği/denemesi var mı?
  ///
  /// Önce cihazdaki RevenueCat entitlement'ına (anında, çevrimdışı çalışır),
  /// o olmazsa backend durumuna (webhook ile senkron, cihazlar arası doğru
  /// kaynak) bakar. Biri "premium" diyorsa true döner.
  static Future<bool> hasActiveSubscription() async {
    // 1) RevenueCat entitlement (cihaz)
    try {
      if (await RevenueCatService().isPremiumUser()) return true;
    } catch (_) {}

    // 2) Backend (webhook ile senkron)
    try {
      final response = await AuthService().getCurrentUser();
      final user = response.data;
      if (response.isSuccess && user != null) {
        final status = user.subscriptionStatus;
        final type = user.subscriptionType;
        if ((status == 'active' || status == 'trialing') &&
            type != null &&
            type != 'free') {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Kayıt/giriş sonrası yönlendirme: abonelik varsa Home, yoksa Paywall kapısı.
  ///
  /// Paywall `replaceAll` ile kök rota olarak açılır; böylece geri yığını boş
  /// kalır ve PaywallView bunu "kapı modu" (✕ yok, geri kilitli) olarak algılar.
  static Future<void> goAfterAuth(BuildContext context) async {
    final subscribed = await hasActiveSubscription();
    if (!context.mounted) return;
    if (subscribed) {
      context.router.replaceAll([const HomeRoute()]);
    } else {
      context.router.replaceAll([const PaywallRoute()]);
    }
  }

  /// Paywall kapısındaki tek çıkış: oturumu kapatıp Login'e döner.
  static Future<void> signOutToLogin(BuildContext context) async {
    try {
      await AuthService().logout();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await BaseApiService.clearAuthToken();
    } catch (_) {}
    try {
      await RevenueCatService().logOut();
    } catch (_) {}
    if (!context.mounted) return;
    context.router.replaceAll([const LoginRoute()]);
  }
}
