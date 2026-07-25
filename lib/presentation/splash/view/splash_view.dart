import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/utils/color_constant.dart';
import '../../../service/base/base_api_service.dart';
import '../../../service/auth/auth_service.dart';

@RoutePage()
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNextScreen();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    // Token kontrolü (SharedPreferences'tan)
    final token = await BaseApiService.getAuthToken();

    // Firebase Auth kontrolü
    final user = FirebaseAuth.instance.currentUser;

    // Kullanıcı bilgilerini logla (token varsa)
    if (token != null && token.isNotEmpty) {
      await _logUserPremiumStatus();
    }

    if (mounted) {
      if (isFirstTime) {
        // İlk açılışta onboarding'e git
        context.router.replace(const OnboardingRoute());
      } else if (token != null && token.isNotEmpty) {
        // Token varsa ana sayfaya git
        context.router.replace(const HomeRoute());
      } else if (user != null) {
        // Firebase kullanıcısı varsa ama token yoksa ana sayfaya git
        context.router.replace(const HomeRoute());
      } else {
        // Token ve kullanıcı yoksa login'e git
        context.router.replace(const LoginRoute());
      }
    }
  }

  Future<void> _logUserPremiumStatus() async {
    try {
      final authService = AuthService();
      final response = await authService.getCurrentUser();

      if (response.isSuccess && response.data != null) {
        final user = response.data!;
        debugPrint('═══════════════════════════════════════════');
        debugPrint('🚀 APP STARTED - USER INFO');
        debugPrint('═══════════════════════════════════════════');
        debugPrint('👤 User ID: ${user.id}');
        debugPrint('📧 Email: ${user.email}');
        debugPrint('👤 Username: ${user.username}');
        debugPrint('📱 Is Guest: ${user.isGuest}');
        debugPrint('───────────────────────────────────────────');
        debugPrint('💎 Subscription Type: ${user.subscriptionType ?? "null"}');
        debugPrint('📊 Subscription Status: ${user.subscriptionStatus ?? "null"}');

        // Premium durumu hesapla
        final isPremium = (user.subscriptionStatus == 'active' || user.subscriptionStatus == 'trialing') &&
            user.subscriptionType != null && user.subscriptionType != 'free';
        debugPrint('⭐ IS PREMIUM: $isPremium');
        debugPrint('═══════════════════════════════════════════');
      } else {
        debugPrint('⚠️ Could not fetch user info: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Error logging user status: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              ColorConstant.bgColorDark,
              ColorConstant.cardColorDark.withValues(alpha: 0.5),
            ]
                : [
              ColorConstant.bgColorLight,
              ColorConstant.primaryPurple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animations
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDarkMode
                                    ? ColorConstant.primaryDarkModePurple
                                    : ColorConstant.primaryPurple)
                                    .withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: Image.asset(
                              'assets/logos/1024.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // App Name with slide animation
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'app.name'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'app.tagline'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading Indicator
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDarkMode
                                    ? ColorConstant.primaryDarkModePurple
                                    : ColorConstant.primaryPurple,
                              ),
                              backgroundColor: (isDarkMode
                                  ? ColorConstant.primaryDarkModePurple
                                  : ColorConstant.primaryPurple)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'app.loading'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}