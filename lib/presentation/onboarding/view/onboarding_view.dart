import 'dart:async';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/route/app_router.gr.dart';
import '../viewmodel/onboarding_viewmodel.dart';

/// Onboarding demo tutarları için dile uygun para birimi sembolü/kodu.
/// (Örnek değerler — gerçek kur dönüşümü değil.)
String _curSymbol(String lc) {
  switch (lc) {
    case 'tr':
      return '₺';
    case 'en':
      return '\$';
    case 'ru':
      return '₽';
    case 'ja':
    case 'zh':
      return '¥';
    case 'ar':
      return 'ر.س';
    case 'hi':
      return '₹';
    default:
      return '€';
  }
}

String _curCode(String lc) {
  switch (lc) {
    case 'tr':
      return 'TRY';
    case 'en':
      return 'USD';
    case 'ru':
      return 'RUB';
    case 'ja':
      return 'JPY';
    case 'zh':
      return 'CNY';
    case 'ar':
      return 'SAR';
    case 'hi':
      return 'INR';
    default:
      return 'EUR';
  }
}

String _money(String lc, num v, {int dec = 0}) {
  try {
    return NumberFormat.currency(
      locale: lc,
      symbol: _curSymbol(lc),
      decimalDigits: dec,
    ).format(v);
  } catch (_) {
    return '${_curSymbol(lc)}$v';
  }
}

/// Onboarding renk paleti (uygulamanın not/kraft ekranına uygun sıcak tonlar).
class _C {
  static const bg1 = Color(0xFFEFE8D6);
  static const bg2 = Color(0xFFE8DEC7);
  static const bg3 = Color(0xFFE2D7BD);
  static const sheet = Color(0xFFFBF7EE);
  static const ink = Color(0xFF3B3426);
  static const muted = Color(0xFF7A6F57);
  static const muted2 = Color(0xFF9B9079);
  static const paper = Color(0xFFF7F2E6);
  static const border = Color(0xFFE4D9C2);
  static const border2 = Color(0xFFE7DCC3);
  static const tanDot = Color(0xFFDCD0B6);
  static const ringTrack = Color(0xFFE6DBC1);
  static const amber = Color(0xFFC0792A);
  static const amberText = Color(0xFFB9731E);
  static const amberBtn1 = Color(0xFFE3952F);
  static const amberBtn2 = Color(0xFFC06B22);
  static const green = Color(0xFF2E9E6B);
  static const red = Color(0xFFD94B3A);
  static const purple = Color(0xFF7C5CD0);
  static const teal = Color(0xFF1F6F5C);
  static const chipBg = Color(0xFFF7F2E6);
  static const chipBorder = Color(0xFFE3D8BF);
  // modül ikon tonları
  static const nAmberBg = Color(0xFFFEF3C7);
  static const nAmberIc = Color(0xFFB45309);
  static const nGreenBg = Color(0xFFDCFCE7);
  static const nGreenIc = Color(0xFF15803D);
  static const nBlueBg = Color(0xFFDBEAFE);
  static const nBlueIc = Color(0xFF1D4ED8);
  static const nTealBg = Color(0xFFCCFBF1);
  static const nTealIc = Color(0xFF0F766E);
  static const nRedBg = Color(0xFFFEE2E2);
  static const nRedIc = Color(0xFFDC2626);
}

double _iv(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

@RoutePage()
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entry;
  late final AnimationController _loop;
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _entry.forward();
    _startReplayTimer();
  }

  // Sayfa değişmedikçe her 5 saniyede giriş animasyonu yeniden başlar.
  void _startReplayTimer() {
    _replayTimer?.cancel();
    _replayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _entry.forward(from: 0);
    });
  }

  void _onPageChanged(int i, OnboardingViewModel vm) {
    vm.onPageChanged(i);
    _entry.forward(from: 0);
    _startReplayTimer();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    _pageController.dispose();
    _entry.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardHeight = (size.height * 0.40).clamp(300.0, 380.0);

    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => OnboardingViewModel(),
        child: Consumer<OnboardingViewModel>(
          builder: (context, vm, _) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_C.bg1, _C.bg2, _C.bg3],
                  stops: [0.0, 0.58, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Animasyon alanı
                    Positioned.fill(
                      bottom: cardHeight - 36,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: vm.pages.length,
                        onPageChanged: (i) => _onPageChanged(i, vm),
                        itemBuilder: (context, index) {
                          return _OnboardAnimation(
                            index: index,
                            entry: _entry,
                            loop: _loop,
                          );
                        },
                      ),
                    ),
                    // Alt kart
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardHeight,
                      child: _buildBottomCard(context, vm),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context, OnboardingViewModel vm) {
    final page = vm.pages[vm.currentPage];
    return Container(
      decoration: const BoxDecoration(
        color: _C.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F3C3014),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: _C.chipBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      page.title,
                      key: ValueKey(page.title),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _C.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        page.description,
                        key: ValueKey(page.description),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _C.muted,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildControls(context, vm),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.router.push(const LoginRoute()),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: _C.muted2,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: '${'onboarding.haveAccount'.tr()} '),
                          TextSpan(
                            text: 'onboarding.login'.tr(),
                            style: const TextStyle(
                              color: _C.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, OnboardingViewModel vm) {
    final total = vm.pages.length;
    final current = vm.currentPage;
    final isLast = current == total - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(total, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              width: active ? 28 : 9,
              height: 9,
              decoration: BoxDecoration(
                color: active ? _C.amber : _C.tanDot,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (current + 1) / total),
                  duration: const Duration(milliseconds: 450),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _C.ringTrack,
                    valueColor: const AlwaysStoppedAnimation(_C.amber),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (isLast) {
                    vm.completeOnboarding(context);
                  } else {
                    vm.nextPage(_pageController);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.amberBtn1, _C.amberBtn2],
                    ),
                  ),
                  child: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sayfaya göre animasyonu seçen widget.
class _OnboardAnimation extends StatelessWidget {
  final int index;
  final AnimationController entry;
  final AnimationController loop;
  const _OnboardAnimation({
    required this.index,
    required this.entry,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    return AnimatedBuilder(
      animation: Listenable.merge([entry, loop]),
      builder: (context, _) {
        final t = entry.value;
        final l = loop.value;
        Widget child;
        switch (index) {
          case 0:
            child = _hub(t, l);
            break;
          case 1:
            child = _notes(t, l);
            break;
          case 2:
            child = _tasks(t);
            break;
          case 3:
            child = _habits(t);
            break;
          case 4:
            child = _calendar(t);
            break;
          case 5:
            child = _finance(t, lc);
            break;
          default:
            child = _notifications(t);
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: child,
          ),
        );
      },
    );
  }

  Widget _reveal(double t, double a, double b, Widget child,
      {double dy = 12, double dx = 0}) {
    final p = Curves.easeOut.transform(_iv(t, a, b));
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(dx * (1 - p), dy * (1 - p)),
        child: child,
      ),
    );
  }

  Widget _pop(double t, double a, double b, Widget child) {
    final p = Curves.elasticOut.transform(_iv(t, a, b)).clamp(0.0, 1.2);
    return Opacity(
      opacity: _iv(t, a, a + (b - a) * 0.4),
      child: Transform.scale(scale: p, child: child),
    );
  }

  // ---------- 1) HUB + ELEKTRİK KABLOLAR ----------
  Widget _hub(double t, double l) {
    const stage = 300.0;
    const center = Offset(150, 150);
    final nodes = <_NodeData>[
      _NodeData(const Offset(150, 48), 'onboarding.anim.notes'.tr(), _C.nAmberBg,
          _C.nAmberIc, Icons.sticky_note_2_outlined, 0.08),
      _NodeData(const Offset(245, 116), 'onboarding.anim.tasks'.tr(),
          _C.nGreenBg, _C.nGreenIc, Icons.check_box_outlined, 0.14),
      _NodeData(const Offset(210, 232), 'onboarding.anim.calendar'.tr(),
          _C.nBlueBg, _C.nBlueIc, Icons.calendar_today_outlined, 0.20),
      _NodeData(const Offset(90, 232), 'onboarding.anim.finance'.tr(),
          _C.nTealBg, _C.nTealIc, Icons.account_balance_wallet_outlined, 0.26),
      _NodeData(const Offset(55, 116), 'onboarding.anim.habit'.tr(), _C.nRedBg,
          _C.nRedIc, Icons.local_fire_department_outlined, 0.32),
    ];

    final halo1 = (l) % 1.0;
    final halo2 = (l + 0.5) % 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stage,
          height: stage,
          child: Stack(
            children: [
              // kablolar
              Positioned.fill(
                child: CustomPaint(
                  painter: _CablesPainter(
                    center: center,
                    nodes: nodes.map((n) => n.pos).toList(),
                    flow: l,
                    reveal: _iv(t, 0.0, 0.5),
                  ),
                ),
              ),
              // halolar (kare sinyaller, logonun merkezinde)
              _haloRing(center, halo1),
              _haloRing(center, halo2),
              // düğümler
              for (final n in nodes) _nodeWidget(n, t),
              // merkez logo
              Positioned(
                left: center.dx - 33,
                top: center.dy - 33,
                child: _pop(
                  t,
                  0.1,
                  0.6,
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x473C3014),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset('assets/logos/1024.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: center.dy + 36,
                child: _reveal(
                  t,
                  0.4,
                  0.8,
                  const Center(
                    child: Text('LifeSync',
                        style: TextStyle(
                            color: _C.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reveal(t, 0.7, 1.0,
            _chip(Icons.cloud_queue_rounded, 'onboarding.anim.hubChip'.tr(), _C.green)),
      ],
    );
  }

  Widget _haloRing(Offset center, double p) {
    final scale = 0.85 + p * 1.25;
    final opacity = (0.55 * (1 - p)).clamp(0.0, 1.0);
    return Positioned(
      left: center.dx - 33,
      top: center.dy - 33,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nodeWidget(_NodeData n, double t) {
    return Positioned(
      left: n.pos.dx - 37,
      top: n.pos.dy - 33,
      width: 74,
      child: _pop(
        t,
        n.delay,
        n.delay + 0.35,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: n.bg,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x243C3014),
                      blurRadius: 14,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Icon(n.icon, color: n.ic, size: 24),
            ),
            const SizedBox(height: 6),
            Text(n.label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B4E33))),
          ],
        ),
      ),
    );
  }

  // ---------- 2) NOTLAR PANOSU (asılı notlar) ----------
  Widget _notes(double t, double l) {
    Widget note({
      required double angleBase,
      required double delay,
      required double swaySpeed,
      required Widget card,
    }) {
      final drop = Curves.easeOut.transform(_iv(t, delay, delay + 0.4));
      final sway = math.sin((l * 2 * math.pi) / swaySpeed) * 0.04;
      return Opacity(
        opacity: drop,
        child: Transform.translate(
          offset: Offset(0, -18 * (1 - drop)),
          child: Transform.rotate(
            alignment: Alignment.topCenter,
            angle: angleBase + sway,
            child: card,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _reveal(t, 0.0, 0.3,
                Text('onboarding.anim.myNotes'.tr(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _C.ink))),
            _reveal(t, 0.0, 0.3,
                Text('onboarding.anim.swipe'.tr(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: _C.amberText))),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              PositionedDirectional(
                start: 0,
                top: 20,
                child: note(
                  angleBase: -0.10,
                  delay: 0.25,
                  swaySpeed: 1.6,
                  card: _polaroidSimple('onboarding.anim.ideas'.tr(), star: true),
                ),
              ),
              PositionedDirectional(
                end: 0,
                top: 24,
                child: note(
                  angleBase: -0.08,
                  delay: 0.55,
                  swaySpeed: 1.3,
                  card: _polaroidLocked('onboarding.anim.bank'.tr()),
                ),
              ),
              Positioned(
                top: 0,
                child: note(
                  angleBase: 0.04,
                  delay: 0.4,
                  swaySpeed: 2.0,
                  card: _polaroidFolder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _reveal(t, 0.9, 1.0,
            _chip(Icons.lock_outline_rounded, 'onboarding.anim.notesChip'.tr(),
                const Color(0xFF8A6A33))),
      ],
    );
  }

  Widget _polaroidWrap(Widget child, {double width = 110}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: _C.paper,
        border: Border.all(color: _C.border2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Color(0x243C3014), blurRadius: 16, offset: Offset(0, 9)),
        ],
      ),
      padding: const EdgeInsets.all(11),
      child: child,
    );
  }

  Widget _clip() => Container(
        width: 13,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCBA85A), Color(0xFFA8813A)],
          ),
        ),
      );

  Widget _polaroidSimple(String title, {bool star = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _clip(),
        const SizedBox(height: 4),
        _polaroidWrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _C.ink))),
                  if (star)
                    const Text('★',
                        style: TextStyle(color: Color(0xFFD79A2E), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 7),
              _line(1),
              const SizedBox(height: 5),
              _line(0.7),
              const SizedBox(height: 9),
              Text('onboarding.anim.dateShort'.tr(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFABA088))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _polaroidLocked(String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _clip(),
        const SizedBox(height: 4),
        _polaroidWrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _C.ink))),
                  const Icon(Icons.lock_outline,
                      size: 12, color: Color(0xFF6B5B35)),
                ],
              ),
              const SizedBox(height: 7),
              const Text('✱✱✱✱✱',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Color(0xFFB3A98F))),
              const SizedBox(height: 9),
              Text('onboarding.anim.dateShort'.tr(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFABA088))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _polaroidFolder() {
    Widget miniNote(Color bar) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8EF),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: bar),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('onboarding.anim.note'.tr(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _C.ink)),
                      const SizedBox(height: 2),
                      const Text('✱✱✱✱',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Color(0xFFB3A98F))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _clip(),
        const SizedBox(height: 4),
        Container(
          width: 128,
          decoration: BoxDecoration(
            color: _C.paper,
            border: Border.all(color: _C.border2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x333C3014),
                  blurRadius: 22,
                  offset: Offset(0, 12)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF8A6A33),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 11, color: Color(0xFFF4EAD2)),
                    const SizedBox(width: 4),
                    Text('onboarding.anim.secret'.tr(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF4EAD2))),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              miniNote(const Color(0xFFE0912F)),
              const SizedBox(height: 7),
              miniNote(const Color(0xFF3B7DBF)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(double w) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: w,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFE3D8BF),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  // ---------- 3) GÖREV OLUŞTURMA ----------
  Widget _tasks(double t) {
    Widget row(IconData ic, Color icC, String label, Widget trailing) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(ic, color: icC, size: 17),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.ink))),
              trailing,
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 14, color: Color(0xFFC5B88F)),
            ],
          ),
        );

    final toggleOn = _iv(t, 0.8, 0.95);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEE0),
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E3C3014), blurRadius: 40, offset: Offset(0, 18)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reveal(t, 0.1, 0.3,
              Text('onboarding.anim.newTask'.tr(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: _C.ink))),
          const SizedBox(height: 12),
          _reveal(
            t,
            0.25,
            0.45,
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8DFC9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC5B88F), width: 2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text('onboarding.anim.prepPresentation'.tr(),
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _C.ink)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          _reveal(
            t,
            0.45,
            0.6,
            Row(
              children: [
                _taskChip(Icons.calendar_today_outlined,
                    'onboarding.anim.today'.tr(), true),
                const SizedBox(width: 7),
                _taskChip(Icons.notifications_none_rounded,
                    'onboarding.anim.remind'.tr(), false),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _reveal(
              t,
              0.6,
              0.72,
              row(Icons.calendar_today_outlined, _C.amberBtn1,
                  'onboarding.anim.dateTime'.tr(),
                  Text('onboarding.anim.taskDate'.tr(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.muted2)))),
          _reveal(
              t,
              0.72,
              0.84,
              row(Icons.flag_outlined, _C.red, 'onboarding.anim.priority'.tr(),
                  _pill('onboarding.anim.medium'.tr(), _C.amberText,
                      const Color(0xFFFBEFD6)))),
          _reveal(
              t,
              0.84,
              0.96,
              row(Icons.folder_outlined, _C.purple,
                  'onboarding.anim.category'.tr(),
                  Text('onboarding.anim.work'.tr(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B5B35))))),
          const SizedBox(height: 10),
          _reveal(
            t,
            0.9,
            1.0,
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8DFC9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      size: 18,
                      color: toggleOn > 0.5
                          ? const Color(0xFFB86A2A)
                          : _C.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      toggleOn > 0.5
                          ? 'onboarding.anim.reminderOn'.tr()
                          : 'onboarding.anim.reminderOff'.tr(),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              toggleOn > 0.5 ? FontWeight.w700 : FontWeight.w600,
                          color: toggleOn > 0.5
                              ? const Color(0xFFB86A2A)
                              : _C.ink),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color.lerp(const Color(0xFFCFC4A9),
                          const Color(0xFFE0912F), toggleOn),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Align(
                      alignment: Alignment(-0.75 + 1.5 * toggleOn, 0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskChip(IconData ic, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFBEFD6) : const Color(0xFFECE3CE),
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: const Color(0xFFE8C78A))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic,
              size: 12,
              color: active ? _C.amberText : const Color(0xFF6B5B35)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? _C.amberText : const Color(0xFF6B5B35))),
        ],
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

  // ---------- 4) ALIŞKANLIKLAR ----------
  Widget _habits(double t) {
    final seg = [
      _iv(t, 0.4, 0.7),
      _iv(t, 0.5, 0.8),
      _iv(t, 0.6, 0.9),
      _iv(t, 0.7, 1.0),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(
          t,
          0.1,
          0.3,
          Row(
            children: [
              Expanded(
                  child: Text('onboarding.anim.habits'.tr(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _C.ink))),
              _chip(Icons.group_outlined, 'onboarding.anim.shared'.tr(),
                  _C.amberText),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _reveal(
          t,
          0.3,
          0.5,
          _cardBox(
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutPainter(seg),
                    child: Center(
                      child: _pop(
                        t,
                        0.8,
                        1.0,
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('2/2',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _C.ink,
                                    height: 1)),
                            Text('onboarding.anim.todayLower'.tr(),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _C.muted2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(const Color(0xFFB9A0E8),
                          'onboarding.anim.relationships'.tr()),
                      const SizedBox(height: 8),
                      _Legend(const Color(0xFF85B4E6),
                          'onboarding.anim.learning'.tr()),
                      const SizedBox(height: 8),
                      _Legend(
                          const Color(0xFF7FD2A0), 'onboarding.anim.health'.tr()),
                      const SizedBox(height: 8),
                      _Legend(
                          const Color(0xFFE8C585), 'onboarding.anim.mind'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        _reveal(t, 0.82, 1.0, _habitHeatmap(t)),
      ],
    );
  }

  Widget _habitHeatmap(double t) {
    final colors = [
      const Color(0xFF2E9E6B),
      const Color(0xFFE4D9C1),
      const Color(0xFF2E9E6B),
      const Color(0xFFE0912F),
      const Color(0xFF2E9E6B),
      const Color(0xFF2E9E6B),
      const Color(0xFFE4D9C1),
      const Color(0xFF2E9E6B),
    ];
    Widget rowCells(int rowIndex) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(8, (c) {
            final isToday = rowIndex == 2 && c == 7;
            final col = isToday
                ? const Color(0xFF2E9E6B)
                : colors[(rowIndex * 3 + c) % colors.length];
            final appear =
                _iv(t, 1.0 + 0, 1.0); // heatmap page: show immediately
            return Opacity(
              opacity: appear == 0 ? 1 : 1,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: col,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: const Color(0xFFBBE8CC), width: 2)
                      : null,
                ),
              ),
            );
          }),
        );

    return _cardBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: const Color(0xFFEE7A34),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.star, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('onboarding.anim.water'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _C.ink))),
              Text('onboarding.anim.historyHeatmap'.tr(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A7F66))),
            ],
          ),
          const SizedBox(height: 11),
          rowCells(0),
          const SizedBox(height: 4),
          rowCells(1),
          const SizedBox(height: 4),
          rowCells(2),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeatLegend(
                  const Color(0xFF2E9E6B), 'onboarding.anim.done'.tr()),
              const SizedBox(width: 14),
              _HeatLegend(
                  const Color(0xFFE0912F), 'onboarding.anim.skipped'.tr()),
              const SizedBox(width: 14),
              _HeatLegend(
                  const Color(0xFFE4D9C1), 'onboarding.anim.missed'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- 5) TAKVİM ----------
  Widget _calendar(double t) {
    const days = [
      [0, 0, 1, 2, 3, 4, 5],
      [6, 7, 8, 9, 10, 11, 12],
      [13, 14, 15, 16, 17, 18, 19],
      [20, 21, 22, 23, 24, 25, 26],
      [27, 28, 29, 30, 31, 0, 0],
    ];
    final dots = {2: _C.amberBtn1, 8: _C.green, 17: _C.nBlueIc, 22: _C.amberBtn1};
    return _reveal(
      t,
      0.1,
      0.4,
      _cardBox(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('onboarding.anim.calMonth'.tr(),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.ink))),
                const Icon(Icons.chevron_left,
                    size: 16, color: Color(0xFFC5B88F)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFFC5B88F)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: 'onboarding.anim.weekdays'.tr().split(',')
                  .map((d) => SizedBox(
                        width: 26,
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB4A684))),
                      ))
                  .toList(),
            ),
            for (final week in days)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: week.map((d) {
                    final selected = d == 15;
                    return SizedBox(
                      width: 26,
                      height: 30,
                      child: d == 0
                          ? const SizedBox()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                selected
                                    ? _pop(
                                        t,
                                        0.45,
                                        0.75,
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                              color: _C.amberBtn1,
                                              shape: BoxShape.circle),
                                          alignment: Alignment.center,
                                          child: Text('$d',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                        ),
                                      )
                                    : Text('$d',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B5E42))),
                                if (dots.containsKey(d) && !selected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: dots[d],
                                        shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFE7DCC4)),
            const SizedBox(height: 10),
            Text('onboarding.anim.calToday'.tr(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A7F66))),
            const SizedBox(height: 9),
            _agendaRow('09:00', _C.green, 'onboarding.anim.dentist'.tr(),
                const Icon(Icons.notifications_none_rounded,
                    size: 14, color: _C.amber)),
            const SizedBox(height: 9),
            _agendaRow('11:30', _C.amberBtn1, 'onboarding.anim.teamMeeting'.tr(),
                const Icon(Icons.autorenew_rounded,
                    size: 14, color: _C.amberText)),
            const SizedBox(height: 9),
            _reveal(
              t,
              0.6,
              0.85,
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E9CE),
                  border: Border.all(color: const Color(0xFFE8C78A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 34,
                        child: Text('14:00',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _C.amberText))),
                    Container(
                        width: 3,
                        height: 26,
                        color: _C.amberBtn1,
                        margin: const EdgeInsets.symmetric(horizontal: 9)),
                    Text('${'onboarding.anim.presentation'.tr()} ',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _C.ink)),
                    _pill('onboarding.anim.taskTag'.tr(), _C.amberText,
                        const Color(0xFFFBEFD6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agendaRow(String time, Color bar, String title, Widget trailing) {
    return Row(
      children: [
        SizedBox(
            width: 34,
            child: Text(time,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _C.muted2))),
        Container(
            width: 3,
            height: 26,
            color: bar,
            margin: const EdgeInsets.symmetric(horizontal: 9)),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.ink))),
        trailing,
      ],
    );
  }

  // ---------- 6) FİNANS ----------
  Widget _finance(double t, String lc) {
    Widget qa(double delay, IconData ic, Color icC, String label) => _pop(
          t,
          delay,
          delay + 0.3,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEE0),
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.border),
                ),
                child: Icon(ic, color: icC, size: 22),
              ),
              const SizedBox(height: 5),
              // Uzun çeviriler (ör. Almanca "Abonnement") taşmasın diye sığdır.
              SizedBox(
                width: 70,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B4E33))),
                ),
              ),
            ],
          ),
        );
    Widget summary(double delay, Color c, String label, String amt, String sub) =>
        _reveal(
          t,
          delay,
          delay + 0.12,
          Container(
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                // Para birimi metni uzadığında (ör. Arapça "ر.س") kartı taşırmasın
                // diye tek satırda küçülterek sığdır.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(amt,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        );
    final fill = _iv(t, 0.78, 0.98);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(
          t,
          0.1,
          0.3,
          Row(
            children: [
              Text('onboarding.anim.finance'.tr(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _C.ink)),
              const SizedBox(width: 8),
              Text('· ${'onboarding.anim.financeMonth'.tr()}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.muted2)),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _reveal(
          t,
          0.25,
          0.45,
          Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF235C4C), Color(0xFF2E7A61)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('onboarding.anim.mainAccount'.tr(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBDE3D5)))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(7)),
                      child: Text(_curCode(lc),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_money(lc, 1240, dec: lc == 'ja' ? 0 : 2),
                    style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(
                    '${'onboarding.anim.spendableToday'.tr()} · ${_money(lc, 320)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8FD6BD))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              qa(0.42, Icons.add, _C.green, 'onboarding.anim.income'.tr()),
              qa(0.49, Icons.remove, _C.red, 'onboarding.anim.expense'.tr()),
              qa(0.56, Icons.autorenew_rounded, _C.purple,
                  'onboarding.anim.subscription'.tr()),
              qa(0.63, Icons.lock_outline, const Color(0xFF8A6A33),
                  'onboarding.anim.lock'.tr()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reveal(
          t,
          0.58,
          0.76,
          _cardBox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('onboarding.anim.thisMonth'.tr(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A7F66)))),
                    _pill('onboarding.anim.savingsLabel'.tr(), _C.green,
                        const Color(0xFFE1F2E8)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 9,
                    color: const Color(0xFFE6DBC2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.62 * fill,
                      child: Container(color: _C.amberBtn1),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HeatLegend(const Color(0xFFD94B3A),
                        '${'onboarding.anim.expense'.tr()} ${_money(lc, 2450)}',
                        dot: true),
                    const SizedBox(width: 14),
                    _HeatLegend(const Color(0xFF2E9E6B),
                        '${'onboarding.anim.income'.tr()} ${_money(lc, 3100)}',
                        dot: true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: Row(
            children: [
              Expanded(
                  child: summary(0.76, _C.purple,
                      'onboarding.anim.subscriptions'.tr(), _money(lc, 220),
                      'onboarding.anim.subsCount'.tr())),
              const SizedBox(width: 10),
              Expanded(
                  child: summary(0.83, _C.teal,
                      'onboarding.anim.installments'.tr(), _money(lc, 850),
                      'onboarding.anim.monthly'.tr())),
              const SizedBox(width: 10),
              Expanded(
                  child: summary(0.9, const Color(0xFFB23B32),
                      'onboarding.anim.debt'.tr(), _money(lc, 1200),
                      'onboarding.anim.total'.tr())),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- 7) BİLDİRİM YAĞMURU ----------
  Widget _notifications(double t) {
    final items = [
      [
        'onboarding.anim.notes'.tr(),
        'onboarding.anim.shoppingList'.tr(),
        'onboarding.anim.pinnedNote'.tr(),
        0.1
      ],
      [
        'onboarding.anim.tasks'.tr(),
        'onboarding.anim.presentationAt'.tr(),
        'onboarding.anim.tasksDueToday'.tr(),
        0.25
      ],
      [
        'onboarding.anim.calendar'.tr(),
        'onboarding.anim.dentistTomorrow'.tr(),
        'onboarding.anim.healthReminder'.tr(),
        0.4
      ],
      [
        'onboarding.anim.habit'.tr(),
        'onboarding.anim.drinkWater'.tr(),
        'onboarding.anim.streak'.tr(),
        0.55
      ],
      [
        'onboarding.anim.finance'.tr(),
        'onboarding.anim.billLastDay'.tr(),
        'onboarding.anim.budgetUsed'.tr(),
        0.7
      ],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pop(
          t,
          0.05,
          0.35,
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x383C3014),
                    blurRadius: 26,
                    offset: Offset(0, 12)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.asset('assets/logos/1024.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: items.map((it) {
            final delay = it[3] as double;
            final p = Curves.easeOut.transform(_iv(t, delay, delay + 0.25));
            return Opacity(
              opacity: p,
              child: Transform.translate(
                offset: Offset(0, -14 * (1 - p)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _notifCard(
                      it[0] as String, it[1] as String, it[2] as String),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _notifCard(String module, String title, String sub) {
    return Container(
      width: 310,
      decoration: BoxDecoration(
        color: _C.paper,
        border: Border.all(color: _C.border2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A3C3014), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logos/1024.png',
                width: 28, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('LifeSync · $module',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _C.muted2))),
                    Text('onboarding.anim.now'.tr(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _C.muted2)),
                  ],
                ),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.ink)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A7F66))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ortak ----------
  Widget _cardBox(Widget child, {double width = 300}) => Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEE0),
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F3C3014),
                blurRadius: 22,
                offset: Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      );

  Widget _chip(IconData ic, String text, Color icColor) => Container(
        decoration: BoxDecoration(
          color: _C.chipBg,
          border: Border.all(color: _C.chipBorder),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A3C3014),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 16, color: icColor),
            const SizedBox(width: 7),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B4E33))),
            ),
          ],
        ),
      );
}

class _NodeData {
  final Offset pos;
  final String label;
  final Color bg;
  final Color ic;
  final IconData icon;
  final double delay;
  _NodeData(this.pos, this.label, this.bg, this.ic, this.icon, this.delay);
}

class _CablesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodes;
  final double flow;
  final double reveal;
  _CablesPainter({
    required this.center,
    required this.nodes,
    required this.flow,
    required this.reveal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final base = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final spark = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final n in nodes) {
      final end = Offset.lerp(center, n, reveal)!;
      canvas.drawLine(center, end, glow);
      canvas.drawLine(center, end, base);
      // elektrik paketi (merkeze doğru akan nokta)
      final d = (1 - (flow % 1.0));
      final p = Offset.lerp(n, center, d)!;
      canvas.drawCircle(p, 2.2, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _CablesPainter old) => true;
}

class _DonutPainter extends CustomPainter {
  final List<double> seg;
  _DonutPainter(this.seg);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final colors = [
      const Color(0xFFC3B1EE),
      const Color(0xFF9DC2EC),
      const Color(0xFFA9DCBC),
      const Color(0xFFECD3A0),
    ];
    const gap = 0.14; // radian gap
    final sweep = (2 * math.pi / 4) - gap;
    for (int i = 0; i < 4; i++) {
      final start = -math.pi / 2 + i * (2 * math.pi / 4) + gap / 2;
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * seg[i].clamp(0.0, 1.0),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.seg != seg;
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _C.ink)),
      ],
    );
  }
}

class _HeatLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dot;
  const _HeatLegend(this.color, this.label, {this.dot = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(dot ? 5 : 3))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B5E42))),
      ],
    );
  }
}
