import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/route/app_router.gr.dart';

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}

class OnboardingViewModel extends ChangeNotifier {
  int _currentPage = 0;
  final bool _isInitialized = false;

  int get currentPage => _currentPage;
  bool get isInitialized => _isInitialized;

  List<OnboardingPage> get pages => [
        OnboardingPage(
          image: 'assets/images/onboarding1.png',
          title: 'onboarding.title1'.tr(),
          description: 'onboarding.description1'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding2.png',
          title: 'onboarding.title2'.tr(),
          description: 'onboarding.description2'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding3.png',
          title: 'onboarding.title3'.tr(),
          description: 'onboarding.description3'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding4.png',
          title: 'onboarding.title4'.tr(),
          description: 'onboarding.description4'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding5.png',
          title: 'onboarding.title5'.tr(),
          description: 'onboarding.description5'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding6.png',
          title: 'onboarding.title6'.tr(),
          description: 'onboarding.description6'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding7.png',
          title: 'onboarding.title7'.tr(),
          description: 'onboarding.description7'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding8.png',
          title: 'onboarding.title8'.tr(),
          description: 'onboarding.description8'.tr(),
        ),
        OnboardingPage(
          image: 'assets/images/onboarding9.png',
          title: 'onboarding.title9'.tr(),
          description: 'onboarding.description9'.tr(),
        ),
      ];

  void nextPage(PageController pageController) {
    if (_currentPage < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<void> completeOnboarding(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);

      if (context.mounted) {
        context.router.replace(const RegisterRoute());
      }
    } catch (e) {
      debugPrint('Error during completing onboarding: $e');
    }
  }
}
