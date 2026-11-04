import 'package:flutter/material.dart';
import '../utils/color_constant.dart';
import '../utils/animation_prefs.dart';

/// Menü geçişlerinde (sayfa yüklenirken) kullanılan ortak yükleme göstergesi.
///
/// Tasarım: "Yörünge noktaları" — merkez etrafında dönen 3 nokta. Renk seçili
/// temadan gelir ([ColorConstant.accentOrange] = AppPalette.accent), böylece
/// her temada ayrı renklenir. Animasyon kapalıysa (Ayarlar › Görünüm) statik
/// olarak gösterilir.
class AppLoader extends StatefulWidget {
  /// Göstergenin kenar uzunluğu (noktaların döndüğü kare alan).
  final double size;

  /// Varsayılan tema aksanı yerine özel renk (ör. koyu zemin üstünde beyaz).
  final Color? color;

  const AppLoader({super.key, this.size = 46, this.color});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? ColorConstant.accentOrange;
    final s = widget.size;
    final dot = s * 0.24;

    Widget dotAt(Alignment a, double diameter, double opacity) => Align(
          alignment: a,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: opacity),
            ),
          ),
        );

    final orbit = SizedBox(
      width: s,
      height: s,
      child: Stack(
        children: [
          dotAt(Alignment.topCenter, dot, 1.0),
          dotAt(Alignment.bottomCenter, dot, 0.8),
          dotAt(Alignment.centerLeft, dot * 0.72, 0.55),
        ],
      ),
    );

    // Animasyonlar kapalıysa dönmeden sabit göster (erişilebilirlik/tercih).
    if (!AnimationPrefs.isOn) return Center(child: orbit);
    return Center(child: RotationTransition(turns: _ctrl, child: orbit));
  }
}
