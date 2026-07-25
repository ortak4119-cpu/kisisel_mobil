import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
import '../viewmodel/paywall_viewmodel.dart';

@RoutePage()
class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaywallViewModel()..initialize(),
      child: Consumer<PaywallViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: Stack(
              children: [
                // Gradient Background
                _buildGradientBackground(isDarkMode),

                // Content
                SafeArea(
                  child: viewModel.isLoading
                      ? _buildLoadingState()
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Close Button
                          _buildCloseButton(context, isDarkMode),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),

                                  // Crown Icon & Title
                                  _buildHeader(isDarkMode),

                                  const SizedBox(height: 32),

                                  // Features List
                                  _buildFeaturesList(isDarkMode),

                                  const SizedBox(height: 40),

                                  // Package Options
                                  _buildPackageOptions(
                                      context, viewModel, isDarkMode),

                                  const SizedBox(height: 32),

                                  // Trial Disclosure (Apple gereksinimi)
                                  if (viewModel.selectedPackage != null &&
                                      viewModel.hasTrialPeriod(
                                          viewModel.selectedPackage))
                                    _buildTrialDisclosure(
                                        context, viewModel, isDarkMode),

                                  // Subscribe Button
                                  _buildSubscribeButton(
                                      context, viewModel, isDarkMode),

                                  const SizedBox(height: 16),

                                  // Restore Purchases
                                  _buildRestoreButton(
                                      context, viewModel, isDarkMode),

                                  const SizedBox(height: 12),

                                  // Terms & Privacy
                                  _buildLegalLinks(isDarkMode),

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientBackground(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            ColorConstant.primaryDarkModePurple.withValues(alpha: 0.3),
            ColorConstant.primaryDarkModeBlue.withValues(alpha: 0.2),
            ColorConstant.bgColorDark,
          ]
              : [
            ColorConstant.primaryPurple.withValues(alpha: 0.1),
            ColorConstant.accentBlue.withValues(alpha: 0.05),
            ColorConstant.bgColorLight,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorConstant.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'paywall.loading'.tr(),
            style: TextStyle(
              color: ColorConstant.textSecondaryDark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => context.router.pop(),
            icon: Icon(
              Icons.close_rounded,
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      children: [
        // Crown Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstant.accentYellow,
                ColorConstant.accentOrange,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorConstant.accentYellow.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 40,
            color: ColorConstant.white,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'paywall.title'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'paywall.subtitle'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList(bool isDarkMode) {
    final features = [
      {
        'icon': Icons.task_alt_rounded,
        'title': 'paywall.feature1_title'.tr(),
        'subtitle': 'paywall.feature1_subtitle'.tr(),
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'paywall.feature2_title'.tr(),
        'subtitle': 'paywall.feature2_subtitle'.tr(),
      },
      {
        'icon': Icons.sync_rounded,
        'title': 'paywall.feature3_title'.tr(),
        'subtitle': 'paywall.feature3_subtitle'.tr(),
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'paywall.feature4_title'.tr(),
        'subtitle': 'paywall.feature4_subtitle'.tr(),
      },
      {
        'icon': Icons.notification_important_rounded,
        'title': 'paywall.feature5_title'.tr(),
        'subtitle': 'paywall.feature5_subtitle'.tr(),
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstant.primaryPurple,
                      ColorConstant.accentBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: ColorConstant.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textPrimaryDark
                            : ColorConstant.textPrimaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['subtitle'] as String,
                      style: TextStyle(
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPackageOptions(
      BuildContext context,
      PaywallViewModel viewModel,
      bool isDarkMode,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'paywall.choose_plan'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Package
        if (viewModel.monthlyPackage != null)
          _buildPackageCard(
            context: context,
            viewModel: viewModel,
            index: 0,
            package: viewModel.monthlyPackage!,
            title: 'paywall.monthly'.tr(),
            badge: null, // Ücretsiz deneme badge'i artık inline gösteriliyor
            isDarkMode: isDarkMode,
          ),

        const SizedBox(height: 12),

        // Annual Package (Most Popular)
        if (viewModel.annualPackage != null)
          _buildPackageCard(
            context: context,
            viewModel: viewModel,
            index: 1,
            package: viewModel.annualPackage!,
            title: 'paywall.annual'.tr(),
            badge: 'paywall.most_popular'.tr(),
            isPopular: true,
            isDarkMode: isDarkMode,
          ),

        const SizedBox(height: 12),

        // Lifetime Package
        if (viewModel.lifetimePackage != null)
          _buildPackageCard(
            context: context,
            viewModel: viewModel,
            index: 2,
            package: viewModel.lifetimePackage!,
            title: 'paywall.lifetime'.tr(),
            badge: 'paywall.one_time_payment'.tr(),
            isLifetime: true,
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required PaywallViewModel viewModel,
    required int index,
    required package,
    required String title,
    String? badge,
    bool isPopular = false,
    bool isLifetime = false,
    required bool isDarkMode,
  }) {
    final isSelected = viewModel.selectedPackageIndex == index;
    final price = package.storeProduct.priceString;
    final hasTrial = viewModel.hasTrialPeriod(package);

    return GestureDetector(
      onTap: () => viewModel.selectPackage(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode
                  ? ColorConstant.primaryDarkModePurple.withValues(alpha: 0.15)
                  : ColorConstant.primaryPurple.withValues(alpha: 0.08))
                  : (isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (isDarkMode
                    ? ColorConstant.primaryDarkModePurple
                    : ColorConstant.primaryPurple)
                    : (isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: (isDarkMode
                      ? ColorConstant.primaryDarkModePurple
                      : ColorConstant.primaryPurple)
                      .withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Radio Button
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDarkMode
                              ? ColorConstant.primaryDarkModePurple
                              : ColorConstant.primaryPurple)
                              : (isDarkMode
                              ? ColorConstant.borderColorDark
                              : ColorConstant.borderColorLight),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? ColorConstant.primaryDarkModePurple
                                : ColorConstant.primaryPurple,
                          ),
                        ),
                      )
                          : null,
                    ),

                    const SizedBox(width: 16),

                    // Package Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? ColorConstant.textPrimaryDark
                                      : ColorConstant.textPrimaryLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              // Ücretsiz deneme badge'i yanında göster
                              if (hasTrial) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ColorConstant.accentBlue,
                                        ColorConstant.primaryPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${viewModel.getTrialDurationText(package)} ${'paywall.free_badge'.tr()}',
                                    style: TextStyle(
                                      color: ColorConstant.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Annual plan details
                          if (isPopular) ...[
                            Row(
                              children: [
                                Text(
                                  '${viewModel.getMonthlyPriceForAnnual()}${'paywall.per_month'.tr()}',
                                  style: TextStyle(
                                    color: ColorConstant.primaryPurple,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstant.accentBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '%${viewModel.getSavingsPercentage()} ${'paywall.savings'.tr()}',
                                    style: TextStyle(
                                      color: ColorConstant.accentBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (index == 0)
                            Text(
                              'paywall.renews_monthly'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                                fontSize: 13,
                              ),
                            )
                          else if (isLifetime)
                              Text(
                                'paywall.unlimited_access'.tr(),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                  fontSize: 13,
                                ),
                              ),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            color: isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isPopular)
                          Text(
                            'paywall.per_year'.tr(),
                            style: TextStyle(
                              color: isDarkMode
                                  ? ColorConstant.textSecondaryDark
                                  : ColorConstant.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Corner Badge - Sadece badge varsa ve ücretsiz deneme badge'i değilse göster
          if (badge != null && !hasTrial)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPopular
                      ? ColorConstant.primaryPurple
                      : isLifetime
                      ? ColorConstant.accentBlue
                      : ColorConstant.primaryPurple,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: ColorConstant.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrialDisclosure(
      BuildContext context,
      PaywallViewModel viewModel,
      bool isDarkMode,
      ) {
    final disclosure = viewModel.getTrialDisclosure(viewModel.selectedPackage);

    if (disclosure.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorConstant.cardColorDark.withValues(alpha: 0.5)
            : ColorConstant.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? ColorConstant.borderColorDark
              : ColorConstant.borderColorLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDarkMode
                ? ColorConstant.primaryDarkModePurple
                : ColorConstant.primaryPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              disclosure,
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(
      BuildContext context,
      PaywallViewModel viewModel,
      bool isDarkMode,
      ) {
    // Yıllık plan ve ücretsiz deneme varsa buton metnini değiştir
    String buttonText = 'paywall.continue'.tr();
    if (viewModel.selectedPackageIndex == 1 &&
        viewModel.annualPackage != null &&
        viewModel.hasTrialPeriod(viewModel.annualPackage)) {
      buttonText = 'paywall.start_free_trial'.tr();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: viewModel.isPurchasing
            ? null
            : () async {
          final success = await viewModel.purchaseSelectedPackage();
          if (success && mounted) {
            context.router.pop(true); // Premium oldu
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstant.primaryPurple,
                ColorConstant.accentBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: viewModel.isPurchasing
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstant.white,
                ),
              ),
            )
                : Text(
              buttonText,
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(
      BuildContext context,
      PaywallViewModel viewModel,
      bool isDarkMode,
      ) {
    return TextButton(
      onPressed: viewModel.isRestoring
          ? null
          : () async {
        final success = await viewModel.restorePurchases();
        if (success && mounted) {
          context.router.pop(true); // Premium restore edildi
        } else if (!success && viewModel.errorMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage!),
              backgroundColor: ColorConstant.errorRed,
            ),
          );
        }
      },
      child: viewModel.isRestoring
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
      )
          : Text(
        'paywall.restore'.tr(),
        style: TextStyle(
          color: isDarkMode
              ? ColorConstant.textSecondaryDark
              : ColorConstant.textSecondaryLight,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLegalLinks(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            // Terms açılacak
          },
          child: Text(
            'paywall.terms'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '•',
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textMutedDark
                : ColorConstant.textMutedLight,
          ),
        ),
        TextButton(
          onPressed: () {
            // Privacy açılacak
          },
          child: Text(
            'paywall.privacy'.tr(),
            style: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
