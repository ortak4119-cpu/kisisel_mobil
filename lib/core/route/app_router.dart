import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'View,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: SplashRoute.page,
      initial: true,
    ),
    AutoRoute(
      page: OnboardingRoute.page,
    ),
    AutoRoute(
      page: RegisterRoute.page,
    ),
    AutoRoute(
      page: HomeRoute.page,
    ),
    AutoRoute(
      page: SettingsRoute.page,
    ),
    AutoRoute(
      page: LoginRoute.page,
    ),
    AutoRoute(
      page: PaywallRoute.page,
    ),
  ];
}