import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/color_constant.dart';

/// Kaydet / Oluştur butonu için animasyonlu durum geçişi:
/// "Kaydet" → (dokununca) "Kaydediliyor…" (spinner) → kayıt bitince başa döner.
///
/// Not: Form kaydı başarılıysa genelde sayfayı kendisi kapatır (widget unmount)
/// ve viewmodel "Kaydedildi" başarı mesajını gösterir. Doğrulama hatasında
/// sayfa açık kalır; buton "Kaydediliyor…"dan tekrar "Kaydet"e döner. Böylece
/// başarısız kayıtta YANLIŞLIKLA "Kaydedildi" gösterilmez.
class AnimatedSaveButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String? label; // boşsa 'common.save'
  final String? workingLabel; // boşsa 'common.saving'
  final IconData icon;
  final Color? color;
  final Color foreground;
  final double height;
  final double radius;
  final bool enabled;

  const AnimatedSaveButton({
    super.key,
    required this.onPressed,
    this.label,
    this.workingLabel,
    this.icon = Icons.check_rounded,
    this.color,
    this.foreground = Colors.white,
    this.height = 52,
    this.radius = 16,
    this.enabled = true,
  });

  @override
  State<AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<AnimatedSaveButton> {
  bool _working = false;

  Future<void> _run() async {
    if (_working || !widget.enabled) return;
    setState(() => _working = true);
    try {
      await widget.onPressed();
    } catch (_) {}
    // Başarı → sayfa kapanır (unmount). Açık kaldıysa (hata) butonu sıfırla.
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? ColorConstant.accentOrange;
    final child = _working
        ? Row(
            key: const ValueKey('working'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    valueColor: AlwaysStoppedAnimation(widget.foreground)),
              ),
              const SizedBox(width: 10),
              Text(widget.workingLabel ?? 'common.saving'.tr(),
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: widget.foreground)),
            ],
          )
        : Row(
            key: const ValueKey('idle'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: widget.foreground),
              const SizedBox(width: 8),
              Text(widget.label ?? 'common.save'.tr(),
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: widget.foreground)),
            ],
          );

    return GestureDetector(
      onTap: widget.enabled ? _run : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.enabled ? base : base.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: child,
        ),
      ),
    );
  }
}
