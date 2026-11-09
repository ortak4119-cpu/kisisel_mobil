import 'package:flutter/material.dart';
import '../utils/color_constant.dart';
import '../utils/animation_prefs.dart';

/// Speed-dial + FAB: dokununca yukarı doğru küçük kartlar açılır; + simgesi 45°
/// dönüp kırmızı × olur. Bir kart seçilince kapanır ve [DialAction.onTap] çalışır.
/// Bugün ve Notlar ekranlarında ortak kullanılır.
class DialAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  DialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class SpeedDialFab extends StatefulWidget {
  final List<DialAction> actions;
  const SpeedDialFab({super.key, required this.actions});
  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _a.forward();
    } else {
      _a.reverse();
    }
  }

  void _pick(DialAction a) {
    setState(() => _open = false);
    _a.reverse();
    a.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? ColorConstant.cardColorDark : Colors.white;
    final txt = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Açılır kartlar (yukarı doğru, sıralı belirir).
        for (int i = 0; i < widget.actions.length; i++)
          AnimatedBuilder(
            animation: _a,
            builder: (_, child) {
              final n = widget.actions.length;
              final order = (n - 1 - i);
              final start = (order / (n + 1));
              final t = Curves.easeOutBack
                  .transform(((_a.value - start) / (1 - start)).clamp(0.0, 1.0));
              if (_a.value == 0) return const SizedBox.shrink();
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _pick(widget.actions[i]),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.actions[i].label,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: txt)),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: widget.actions[i].color,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(widget.actions[i].icon,
                          color: Colors.white, size: 20),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        // Ana + / × butonu
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _a,
            builder: (_, __) {
              final open = _a.value;
              final base = Color.lerp(
                  ColorConstant.accentOrange, const Color(0xFFE2574C), open)!;
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(ColorConstant.accentYellow,
                          const Color(0xFFEE6C60), open)!,
                      base,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: base.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: (AnimationPrefs.isOn ? open : (open > 0.5 ? 1 : 0)) *
                      0.785398, // 45°
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 30),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
