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
  bool _isInitialized = false;

  int get currentPage => _currentPage;
  bool get isInitialized => _isInitialized;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      image: 'assets/images/onboarding1.png',
      title: 'Alışkanlıklarını Yönet',
      description: 'Günlük alışkanlıklarını takip et, hedeflerine ulaş ve başarılarını kutla!',
    ),
    OnboardingPage(
      image: 'assets/images/onboarding2.png',
      title: 'Finanslarını Kontrol Et',
      description: 'Harcamalarını takip et, bütçeni yönet ve mali hedeflerine ulaş.',
    ),
    OnboardingPage(
      image: 'assets/images/onboarding3.png',
      title: 'Günlük Tut',
      description: 'Düşüncelerini kaydet, anılarını sakla ve gelişimini izle.',
    ),
    OnboardingPage(
      image: 'assets/images/onboarding4.png',
      title: 'Seviye Atla',
      description: 'Görevleri tamamla, rozet kazan ve arkadaşlarınla yarış!',
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