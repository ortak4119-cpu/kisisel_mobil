import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/utils/color_constant.dart';
import '../viewmodel/onboarding_viewmodel.dart';

@RoutePage()
class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _mainAnimationController;
  late AnimationController _secondaryAnimationController;

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _secondaryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mainAnimationController.dispose();
    _secondaryAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomCardHeight = screenHeight * 0.42;

    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              bottom: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                            ? [
                          ColorConstant.bgColorDark,
                          ColorConstant.cardColorDark,
                        ]
                            : [
                          ColorConstant.bgColorLight,
                          ColorConstant.white,
                        ],
                      ),
                    ),
                  ),

                  // Animation Area
                  Positioned.fill(
                    bottom: bottomCardHeight - 50,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: viewModel.pages.length,
                      onPageChanged: (index) => viewModel.onPageChanged(index),
                      itemBuilder: (context, index) {
                        return _buildAnimationPart(context, index);
                      },
                    ),
                  ),

                  // Skip Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildSkipButton(context, viewModel),
                  ),

                  // Bottom Card
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: bottomCardHeight,
                    child: _buildBottomCard(context, viewModel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, OnboardingViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorConstant.cardColorDark.withOpacity(0.9)
            : ColorConstant.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? ColorConstant.black.withOpacity(0.2)
                : ColorConstant.primaryPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => viewModel.completeOnboarding(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Atla',
                  style: TextStyle(
                    color: isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDarkMode
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationPart(BuildContext context, int index) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: _buildAnimationForPage(index),
      ),
    );
  }

  Widget _buildAnimationForPage(int index) {
    switch (index) {
      case 0:
        return _HabitAnimation(
          mainController: _mainAnimationController,
          secondaryController: _secondaryAnimationController,
        );
      case 1:
        return _FinanceAnimation(
          mainController: _mainAnimationController,
          secondaryController: _secondaryAnimationController,
        );
      case 2:
        return _DiaryAnimation(
          mainController: _mainAnimationController,
          secondaryController: _secondaryAnimationController,
        );
      case 3:
        return _GamificationAnimation(
          mainController: _mainAnimationController,
          secondaryController: _secondaryAnimationController,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomCard(BuildContext context, OnboardingViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorConstant.cardColorDark
            : ColorConstant.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? ColorConstant.black.withOpacity(0.3)
                : ColorConstant.primaryPurple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Drag Handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.borderColorDark
                  : ColorConstant.borderColorLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Title
                  Consumer<OnboardingViewModel>(
                    builder: (context, model, _) {
                      final page = model.pages[model.currentPage];

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          page.title,
                          key: ValueKey<String>(page.title),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      );
                    },
                  ),

                  // Description
                  Consumer<OnboardingViewModel>(
                    builder: (context, model, _) {
                      final page = model.pages[model.currentPage];

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          page.description,
                          key: ValueKey<String>(page.description),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                            fontSize: screenWidth * 0.042,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Navigation Controls
                  _buildNavigationControls(context, viewModel),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(BuildContext context, OnboardingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicators
          Row(
            children: List.generate(
              viewModel.pages.length,
                  (index) => _buildPageIndicator(index, viewModel.currentPage),
            ),
          ),

          // Next Button
          _buildNextButton(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, int currentPage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isActive = index == currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 10),
      width: isActive ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? (isDarkMode
            ? ColorConstant.primaryDarkModePurple
            : ColorConstant.primaryPurple)
            : (isDarkMode
            ? ColorConstant.borderColorDark
            : ColorConstant.borderColorLight),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: isDarkMode
                ? ColorConstant.primaryDarkModePurple.withOpacity(0.4)
                : ColorConstant.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, OnboardingViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = viewModel.currentPage == viewModel.pages.length - 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.16;
    final progressSize = buttonSize + 12;
    final iconSize = buttonSize * 0.5;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: viewModel.currentPage / viewModel.pages.length,
        end: (viewModel.currentPage + 1) / viewModel.pages.length,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      builder: (context, animatedProgress, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Progress Ring
            SizedBox(
              width: progressSize,
              height: progressSize,
              child: CircularProgressIndicator(
                value: animatedProgress,
                backgroundColor: isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? ColorConstant.successGreen
                      : ColorConstant.accentGreen,
                ),
                strokeWidth: 4.0,
                strokeCap: StrokeCap.round,
              ),
            ),

            // Button Container
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                    ColorConstant.primaryDarkModePurple,
                    ColorConstant.primaryDarkModeBlue,
                  ]
                      : [
                    ColorConstant.primaryPurple,
                    ColorConstant.accentBlue,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? ColorConstant.primaryDarkModePurple.withOpacity(0.4)
                        : ColorConstant.primaryPurple.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isLastPage) {
                      viewModel.completeOnboarding(context);
                    } else {
                      viewModel.nextPage(_pageController);
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        key: ValueKey<bool>(isLastPage),
                        color: ColorConstant.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== HABIT ANIMATION ====================
class _HabitAnimation extends StatelessWidget {
  final AnimationController mainController;
  final AnimationController secondaryController;

  const _HabitAnimation({
    required this.mainController,
    required this.secondaryController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          AnimatedBuilder(
            animation: mainController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (math.sin(mainController.value * 2 * math.pi) * 0.05),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ColorConstant.primaryPurple.withOpacity(0.15),
                        ColorConstant.accentBlue.withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating Cards
          ..._buildFloatingCards(isDarkMode),

          // Center Check
          AnimatedBuilder(
            animation: secondaryController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (secondaryController.value * 0.1),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorConstant.accentYellow, ColorConstant.accentOrange],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: ColorConstant.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCards(bool isDarkMode) {
    final items = [
      {'emoji': '💪', 'angle': 0.0},
      {'emoji': '📚', 'angle': math.pi / 2},
      {'emoji': '🏃', 'angle': math.pi},
      {'emoji': '🧘', 'angle': 3 * math.pi / 2},
    ];

    return items.map((item) {
      return AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final angle = (item['angle'] as double) + (mainController.value * 2 * math.pi);
          final radius = 80.0;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;

          return Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ==================== FINANCE ANIMATION ====================
class _FinanceAnimation extends StatelessWidget {
  final AnimationController mainController;
  final AnimationController secondaryController;

  const _FinanceAnimation({
    required this.mainController,
    required this.secondaryController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rising Coins
          ..._buildCoins(),

          // Wallet
          AnimatedBuilder(
            animation: secondaryController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (secondaryController.value * 0.08),
                child: Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorConstant.accentBlue, const Color(0xFF667EEA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: ColorConstant.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCoins() {
    return [0.0, 0.3, 0.6].map((delay) {
      return AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final progress = ((mainController.value - delay) % 1.0).clamp(0.0, 1.0);
          final y = -80 + (progress * 160) - (progress * progress * 160);

          return Transform.translate(
            offset: Offset((delay - 0.3) * 80, y),
            child: Opacity(
              opacity: 1.0 - progress,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorConstant.accentYellow, ColorConstant.accentOrange],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '₺',
                    style: TextStyle(
                      color: ColorConstant.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ==================== DIARY ANIMATION ====================
class _DiaryAnimation extends StatelessWidget {
  final AnimationController mainController;
  final AnimationController secondaryController;

  const _DiaryAnimation({
    required this.mainController,
    required this.secondaryController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final openAngle = (math.sin(mainController.value * 2 * math.pi) + 1) / 4;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Left Page
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(-openAngle),
                alignment: Alignment.centerRight,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorConstant.accentOrange, const Color(0xFFFF8A5C)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: ColorConstant.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Right Page
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(openAngle),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                            (index) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          height: 3,
                          decoration: BoxDecoration(
                            color: ColorConstant.textMutedLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== GAMIFICATION ANIMATION ====================
class _GamificationAnimation extends StatelessWidget {
  final AnimationController mainController;
  final AnimationController secondaryController;

  const _GamificationAnimation({
    required this.mainController,
    required this.secondaryController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stars
          ..._buildStars(),

          // Rocket
          AnimatedBuilder(
            animation: secondaryController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -secondaryController.value * 15),
                child: Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ColorConstant.primaryPurple, ColorConstant.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Center(
                    child: Text(
                      '🚀',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              );
            },
          ),

          // Badges
          ..._buildBadges(),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      {'x': -80.0, 'y': -80.0, 'delay': 0.0},
      {'x': 80.0, 'y': -60.0, 'delay': 0.25},
      {'x': -60.0, 'y': 80.0, 'delay': 0.5},
      {'x': 90.0, 'y': 70.0, 'delay': 0.75},
    ];

    return positions.map((pos) {
      return AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final progress = ((mainController.value - (pos['delay'] as double)) % 1.0).clamp(0.0, 1.0);
          final scale = math.sin(progress * math.pi);

          return Transform.translate(
            offset: Offset(pos['x'] as double, pos['y'] as double),
            child: Transform.scale(
              scale: scale * 0.8,
              child: Text(
                '⭐',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildBadges() {
    return [
      {'emoji': '🏆', 'x': -90.0},
      {'emoji': '🎯', 'x': 90.0},
    ].map((badge) {
      return AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final rotation = mainController.value * 2 * math.pi;

          return Transform.translate(
            offset: Offset(badge['x'] as double, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: ColorConstant.accentGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstant.accentGreen,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge['emoji'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}