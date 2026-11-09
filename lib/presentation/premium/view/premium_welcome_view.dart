import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/utils/animation_prefs.dart';
import '../../../service/notification/notification_sound.dart';
import '../../../service/notification/notification_service.dart';

/// Premium satın alma sonrası karşılama akışı:
/// 0) Tebrikler (Işık hüzmesi animasyonu) → "Hadi başlayalım"
/// 1) Tema seçimi
/// 2) Bildirim sesi seçimi → Uygulamaya geç
///
/// Ekran kendi sabit premium (koyu + altın) renklerini kullanır; seçilen tema
/// uygulamaya uygulanır ama bu karşılama ekranının görünümünü değiştirmez.
@RoutePage()
class PremiumWelcomeView extends StatefulWidget {
  const PremiumWelcomeView({super.key});

  @override
  State<PremiumWelcomeView> createState() => _PremiumWelcomeViewState();
}

class _PremiumWelcomeViewState extends State<PremiumWelcomeView>
    with TickerProviderStateMixin {
  // ── Premium palet (temadan bağımsız sabit) ──
  static const _bg = Color(0xFF241B12);
  static const _card = Color(0xFF30271B);
  static const _gold = Color(0xFFE7B13C);
  static const _goldL = Color(0xFFF7D889);
  static const _tx = Color(0xFFF3E7CF);
  static const _txM = Color(0xFFB8A888);
  static const _ink = Color(0xFF2A1E0C);

  int _step = 0;
  late final AnimationController _rays;
  late final AnimationController _twinkle;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _rays = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _twinkle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rays.dispose();
    _twinkle.dispose();
    _player.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      context.router.replaceAll([const HomeRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AnimationPrefs.isOn
              ? const Duration(milliseconds: 420)
              : Duration.zero,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: _stepBody(),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 1:
        return _themeStep();
      case 2:
        return _soundStep();
      default:
        return _congratsStep();
    }
  }

  // ════════════════ 0) TEBRİKLER (Işık hüzmesi) ════════════════
  Widget _congratsStep() {
    return Padding(
      key: const ValueKey('congrats'),
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _rayStar(),
          const SizedBox(height: 28),
          Text('premium.congrats'.tr(),
              style: const TextStyle(
                  color: _tx,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('premium.unlocked'.tr(),
              style: const TextStyle(
                  color: _goldL,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 26),
          _feat('premium.feat_unlimited'.tr()),
          _feat('premium.feat_noads'.tr()),
          _feat('premium.feat_themes'.tr()),
          const Spacer(flex: 3),
          _goldButton('premium.start'.tr(), _next),
        ],
      ),
    );
  }

  Widget _rayStar() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dönen altın ışınlar
          RotationTransition(
            turns: _rays,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: [
                  for (int i = 0; i < 8; i++)
                    Transform.rotate(
                      angle: i * math.pi / 4,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 3,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_goldL, _goldL.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Yumuşak hale
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _gold.withValues(alpha: 0.25),
                _gold.withValues(alpha: 0),
              ]),
            ),
          ),
          // Giriş animasyonlu yıldız
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.2, end: 1),
            duration: AnimationPrefs.isOn
                ? const Duration(milliseconds: 650)
                : Duration.zero,
            curve: Curves.easeOutBack,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: const Icon(Icons.star_rounded, size: 58, color: _gold),
          ),
          // Parıltılar
          AnimatedBuilder(
            animation: _twinkle,
            builder: (_, __) {
              final o = 0.2 + 0.8 * _twinkle.value;
              return Stack(
                children: [
                  Positioned(
                      top: 16,
                      left: 24,
                      child: Opacity(
                          opacity: o,
                          child: const Icon(Icons.auto_awesome,
                              size: 16, color: _goldL))),
                  Positioned(
                      bottom: 22,
                      right: 20,
                      child: Opacity(
                          opacity: 1.2 - o,
                          child: const Icon(Icons.auto_awesome,
                              size: 18, color: _goldL))),
                  Positioned(
                      top: 54,
                      right: 14,
                      child: Opacity(
                          opacity: o,
                          child: const Icon(Icons.auto_awesome,
                              size: 12, color: _goldL))),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _feat(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 19, color: _gold),
            const SizedBox(width: 10),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      color: _tx, fontSize: 13.5, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  // ════════════════ 1) TEMA SEÇİMİ ════════════════
  Widget _themeStep() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Padding(
      key: const ValueKey('theme'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dots(1),
          const SizedBox(height: 18),
          _stepHeader(Icons.palette_rounded, 'premium.choose_theme'.tr(),
              'premium.choose_theme_sub'.tr()),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (final o in AppPalette.all)
                  _themeChip(o, () {
                    themeProvider.setPalette(o.id);
                    setState(() {});
                  }),
              ],
            ),
          ),
          _goldButton('premium.continue'.tr(), _next),
        ],
      ),
    );
  }

  Widget _themeChip(AppThemeOption o, VoidCallback onTap) {
    final s = o.light;
    final selected = AppPalette.currentId == o.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? _gold : Colors.white.withValues(alpha: 0.07),
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: s.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: o.accent, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('settings.theme_${o.nameKey}'.tr(),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _tx)),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _gold)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _txM.withValues(alpha: 0.5), width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════ 2) BİLDİRİM SESİ ════════════════
  Widget _soundStep() {
    return Padding(
      key: const ValueKey('sound'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dots(2),
          const SizedBox(height: 18),
          _stepHeader(Icons.music_note_rounded, 'premium.choose_sound'.tr(),
              'premium.choose_sound_sub'.tr()),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (final snd in NotifSound.all) _soundChip(snd),
              ],
            ),
          ),
          _goldButton('premium.finish'.tr(), _next),
        ],
      ),
    );
  }

  Future<void> _preview(NotifSound s) async {
    if (s.asset == null) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(s.asset!));
    } catch (_) {}
  }

  Widget _soundChip(NotifSound s) {
    final selected = NotifSoundPrefs.currentId == s.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          NotifSoundPrefs.set(s.id);
          NotificationService().updateNotificationSound(s.id);
          _preview(s);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? _gold : Colors.white.withValues(alpha: 0.07),
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('settings.${s.nameKey}'.tr(),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _tx)),
              ),
              if (s.asset != null)
                IconButton(
                  onPressed: () => _preview(s),
                  icon: const Icon(Icons.play_circle_outline_rounded,
                      color: _gold),
                ),
              const SizedBox(width: 2),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _gold)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _txM.withValues(alpha: 0.5), width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ortak parçalar ──
  Widget _stepHeader(IconData icon, String title, String sub) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _tx,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(color: _txM, fontSize: 13)),
              ],
            ),
          ),
        ],
      );

  Widget _dots(int active) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 1; i <= 2; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == active ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == active ? _gold : _txM.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );

  Widget _goldButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      );
}
