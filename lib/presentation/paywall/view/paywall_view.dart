import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/route/auth_gate.dart';
import '../viewmodel/paywall_viewmodel.dart';

/// Paywall renk paleti (uygulamanin not/kraft temasiyla uyumlu sicak tonlar).
class _P {
  static const bg1 = Color(0xFFEFE8D6);
  static const bg2 = Color(0xFFE8DEC7);
  static const bg3 = Color(0xFFE2D7BD);
  static const ink = Color(0xFF3B3426);
  static const muted = Color(0xFF7A6F57);
  static const muted2 = Color(0xFF9B9079);
  static const legal = Color(0xFFA89E86);
  static const paper = Color(0xFFF6F1E6);
  static const border = Color(0xFFE4D9C2);
  static const amber = Color(0xFFC0792A);
  static const amberText = Color(0xFFB9731E);
  static const amberBtn1 = Color(0xFFE3952F);
  static const amberBtn2 = Color(0xFFC06B22);
  static const selBg = Color(0xFFF6E9CE);
  static const radioOff = Color(0xFFCDBF9C);
  static const green = Color(0xFF2E9E6B);
  static const greenText = Color(0xFF2E7D52);
  static const greenBg = Color(0xFFD7EFE1);
  static const kraft = Color(0xFF8A6A33);
  static const line = Color(0xFFDDD1B5);
}

@RoutePage()
class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  bool _couponOpen = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaywallViewModel()..initialize(),
      child: Consumer<PaywallViewModel>(
        builder: (context, vm, _) {
          // Kok rota olarak acildiysa (geri yigini bos) kapi modu.
          final isGate = !context.router.canPop();
          return PopScope(
            canPop: !isGate,
            child: Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_P.bg1, _P.bg2, _P.bg3],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: vm.isLoading
                      ? _loading()
                      : _content(context, vm, isGate),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _P.amber),
          const SizedBox(height: 16),
          Text('paywall.loading'.tr(),
              style: const TextStyle(color: _P.muted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, PaywallViewModel vm, bool isGate) {
    final selected = vm.selectedPackage;
    final hasTrial = vm.hasTrialPeriod(selected);

    return Column(
      children: [
        _topBar(context, isGate),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hasTrial
                      ? 'paywall.trial_headline'.tr()
                      : 'paywall.title'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.4,
                    color: _P.ink,
                  ),
                ),
                const SizedBox(height: 18),
                if (hasTrial) _timeline(vm, selected) else _features(),
                const SizedBox(height: 16),
                _plans(vm),
                const SizedBox(height: 12),
                _coupon(context, vm, isGate),
                const SizedBox(height: 14),
                _subscribeButton(context, vm, isGate, hasTrial),
                const SizedBox(height: 12),
                _disclosure(vm, selected, hasTrial),
                const SizedBox(height: 14),
                _restore(context, vm, isGate),
                const SizedBox(height: 12),
                _legal(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, bool isGate) {
    if (isGate) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => AuthGate.signOutToLogin(context),
              icon: const Icon(Icons.logout_rounded,
                  size: 18, color: _P.muted),
              label: Text('settings.account.logout'.tr(),
                  style: const TextStyle(
                      color: _P.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => context.router.pop(),
            icon: const Icon(Icons.close_rounded, color: _P.ink),
            style: IconButton.styleFrom(backgroundColor: _P.paper),
          ),
        ],
      ),
    );
  }

  // ---------- Deneme zaman cizelgesi ----------
  Widget _timeline(PaywallViewModel vm, Package? pkg) {
    final price = pkg?.storeProduct.priceString ?? '';
    return Container(
      decoration: BoxDecoration(
        color: _P.paper,
        border: Border.all(color: _P.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A3C3014), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _tlStep(
            _P.green,
            Icons.lock_open_rounded,
            'paywall.tl_today'.tr(),
            'paywall.tl_today_desc'.tr(),
            true,
          ),
          _tlStep(
            _P.kraft,
            Icons.notifications_none_rounded,
            'paywall.tl_mid'.tr(),
            'paywall.tl_mid_desc'.tr(),
            true,
          ),
          _tlStep(
            _P.amber,
            Icons.event_rounded,
            'paywall.tl_end'.tr(),
            'paywall.tl_end_desc'.tr(namedArgs: {'price': price}),
            false,
          ),
        ],
      ),
    );
  }

  Widget _tlStep(
      Color circle, IconData ic, String title, String desc, bool line) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
                child: Icon(ic, color: Colors.white, size: 17),
              ),
              if (line)
                Expanded(
                  child: Container(width: 2, color: _P.line, margin: const EdgeInsets.only(top: 4)),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _P.ink)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12.5, color: _P.muted, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Ozellik listesi (deneme yoksa) ----------
  Widget _features() {
    final items = [
      'paywall.feature1_title',
      'paywall.feature2_title',
      'paywall.feature3_title',
      'paywall.feature4_title',
      'paywall.feature5_title',
    ];
    return Container(
      decoration: BoxDecoration(
        color: _P.paper,
        border: Border.all(color: _P.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A3C3014), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('paywall.feature_header'.tr(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Color(0xFF8A7F66))),
          const SizedBox(height: 12),
          ...items.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: _P.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(k.tr(),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _P.ink)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------- Plan kartlari ----------
  Widget _plans(PaywallViewModel vm) {
    final cards = <Widget>[];
    if (vm.monthlyPackage != null) {
      cards.add(_planCard(
        vm: vm,
        index: 0,
        title: 'paywall.monthly'.tr(),
        sub: 'paywall.renews_monthly'.tr(),
        price: vm.monthlyPackage!.storeProduct.priceString,
      ));
    }
    if (vm.annualPackage != null) {
      cards.add(_planCard(
        vm: vm,
        index: 1,
        title: 'paywall.annual'.tr(),
        sub: '${vm.getMonthlyPriceForAnnual()}${'paywall.per_month'.tr()}',
        price: vm.annualPackage!.storeProduct.priceString,
        savings: '%${vm.getSavingsPercentage()} ${'paywall.savings'.tr()}',
      ));
    }
    if (vm.lifetimePackage != null) {
      cards.add(_planCard(
        vm: vm,
        index: 2,
        title: 'paywall.lifetime'.tr(),
        sub: 'paywall.unlimited_access'.tr(),
        price: vm.lifetimePackage!.storeProduct.priceString,
      ));
    }
    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          cards[i],
        ],
      ],
    );
  }

  Widget _planCard({
    required PaywallViewModel vm,
    required int index,
    required String title,
    required String sub,
    required String price,
    String? savings,
  }) {
    final selected = vm.selectedPackageIndex == index;
    return GestureDetector(
      onTap: () => vm.selectPackage(index),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? _P.selBg : _P.paper,
          border: Border.all(
            color: selected ? _P.amber : _P.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? _P.amber : _P.radioOff, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _P.amber),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    selected ? FontWeight.w800 : FontWeight.w700,
                                color: _P.ink)),
                      ),
                      if (savings != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: _P.greenBg,
                              borderRadius: BorderRadius.circular(7)),
                          child: Text(savings,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _P.greenText)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? _P.amberText : _P.muted2)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(price,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _P.ink)),
          ],
        ),
      ),
    );
  }

  // ---------- Indirim kodu (acilir / kapanir, varsayilan kapali) ----------
  Widget _coupon(BuildContext context, PaywallViewModel vm, bool isGate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _couponOpen = !_couponOpen);
            if (!_couponOpen) vm.clearCoupon();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text('%',
                    style: TextStyle(
                        color: _P.amber, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Text('paywall.coupon_prompt'.tr(),
                    style: const TextStyle(
                        color: _P.kraft,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Icon(
                    _couponOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: _P.kraft),
              ],
            ),
          ),
        ),
        if (_couponOpen) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFFBF8EF),
                    hintText: 'paywall.coupon_hint'.tr(),
                    hintStyle: const TextStyle(
                        color: Color(0xFFB3A98F), fontWeight: FontWeight.w500),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _P.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _P.amber, width: 1.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _P.border),
                    ),
                  ),
                  onChanged: (_) {
                    if (vm.couponMessage != null) vm.clearCoupon();
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.isApplyingCoupon
                      ? null
                      : () async {
                          final ok =
                              await vm.applyCoupon(_couponController.text);
                          if (ok && mounted) {
                            if (isGate) {
                              // Kuponla premium: karşılama akışına yönlendir.
                              context.router
                                  .replaceAll([const PremiumWelcomeRoute()]);
                            } else {
                              context.router.pop(true);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.amberBtn2,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: vm.isApplyingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('paywall.coupon_apply'.tr(),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (vm.couponMessage != null) ...[
            const SizedBox(height: 8),
            Text(vm.couponMessage!,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: vm.couponApplied ? _P.green : _P.amberText)),
          ],
        ],
      ],
    );
  }

  // ---------- Satin alma butonu ----------
  Widget _subscribeButton(
      BuildContext context, PaywallViewModel vm, bool isGate, bool hasTrial) {
    final label =
        hasTrial ? 'paywall.start_free_trial'.tr() : 'paywall.continue'.tr();
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: vm.isPurchasing
            ? null
            : () async {
                final ok = await vm.purchaseSelectedPackage();
                if (ok && mounted) {
                  if (isGate) {
                    // Yeni premium üye: tebrikler + tema + ses karşılama akışı.
                    context.router.replaceAll([const PremiumWelcomeRoute()]);
                  } else {
                    context.router.pop(true);
                  }
                } else if (!ok && vm.errorMessage != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage!)),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_P.amberBtn1, _P.amberBtn2],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: vm.isPurchasing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _disclosure(PaywallViewModel vm, Package? pkg, bool hasTrial) {
    final text = hasTrial
        ? vm.getTrialDisclosure(pkg)
        : '${pkg?.storeProduct.priceString ?? ''} · ${'paywall.renews_monthly'.tr()}';
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: _P.muted2, height: 1.5),
    );
  }

  Widget _restore(BuildContext context, PaywallViewModel vm, bool isGate) {
    return Center(
      child: TextButton(
        onPressed: vm.isRestoring
            ? null
            : () async {
                final ok = await vm.restorePurchases();
                if (ok && mounted) {
                  if (isGate) {
                    context.router.replaceAll([const HomeRoute()]);
                  } else {
                    context.router.pop(true);
                  }
                } else if (!ok && vm.errorMessage != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage!)),
                  );
                }
              },
        child: vm.isRestoring
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _P.muted))
            : Text('paywall.restore'.tr(),
                style: const TextStyle(
                    color: _P.kraft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _legal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse('https://goodlifesync.com/terms'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text('paywall.terms'.tr(),
              style: const TextStyle(color: _P.legal, fontSize: 12)),
        ),
        const Text('·', style: TextStyle(color: _P.legal)),
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse('https://goodlifesync.com/privacy'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text('paywall.privacy'.tr(),
              style: const TextStyle(color: _P.legal, fontSize: 12)),
        ),
      ],
    );
  }
}
