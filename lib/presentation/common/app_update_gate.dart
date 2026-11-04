import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_version/app_version_models.dart';
import '../../service/app_version/app_version_service.dart';

/// Açılışta sürüm kontrolü yapıp gerekiyorsa güncelleme diyaloğunu gösterir.
/// Zorunlu güncellemede diyalog kapatılamaz (kapı); yumuşakta "Daha sonra" var.
class AppUpdateGate {
  static bool _shown = false;

  /// [context] Navigator altında bir context olmalı (router navigatorKey).
  static Future<void> check(BuildContext context) async {
    if (_shown) return;
    final result = await AppVersionService().check();
    debugPrint('🔄 UpdateGate: result=${result == null ? 'null' : 'avail=${result.updateAvailable} force=${result.forceUpdate} store=${result.storeUrl}'}');
    if (result == null) return;
    if (!result.updateAvailable && !result.forceUpdate) return;
    if (!context.mounted) return;
    _shown = true;
    await _showDialog(context, result);
  }

  static Future<void> _showDialog(
      BuildContext context, AppVersionCheck check) async {
    final force = check.forceUpdate;
    final body = (check.message != null && check.message!.trim().isNotEmpty)
        ? check.message!
        : (force ? 'update.forceBody'.tr() : 'update.softBody'.tr());

    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: Color(0xFFF6A821)),
              const SizedBox(width: 10),
              Expanded(child: Text('update.title'.tr())),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              const SizedBox(height: 8),
              // Yeni güncellemeyi incele — popup'ta sürüm notları görünür.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showReleaseNotes(ctx, check),
                  icon: const Icon(Icons.article_rounded, size: 18),
                  label: Text('update.review'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF6A821),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('update.later'.tr()),
              )
            else
              const SizedBox.shrink(),
            // Dikkat çeken, kendini tıklatmaya çalışan nabız/parıltı animasyonlu buton.
            _PulsingUpdateButton(
              label: 'update.update'.tr(),
              onTap: () => _openStore(check.storeUrl),
            ),
          ],
        ),
      ),
    );

    // Yumuşak güncelleme kapatıldıysa, sonraki açılışta tekrar sorulabilsin.
    if (!force) _shown = false;
  }

  /// "İncele" — güncellemede neler var popup'ı. Kapatılınca güncelleme
  /// diyaloğu (arkada hâlâ açık) tekrar görünür.
  static Future<void> _showReleaseNotes(
      BuildContext ctx, AppVersionCheck check) {
    final notes =
        (check.releaseNotes != null && check.releaseNotes!.trim().isNotEmpty)
            ? check.releaseNotes!.trim()
            : ((check.message != null && check.message!.trim().isNotEmpty)
                ? check.message!.trim()
                : 'update.noNotes'.tr());
    return showDialog<void>(
      context: ctx,
      builder: (c2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.new_releases_rounded, color: Color(0xFFF6A821)),
            const SizedBox(width: 10),
            Expanded(child: Text('update.whatsNew'.tr())),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(notes, style: const TextStyle(height: 1.45)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c2).pop(),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  static Future<void> _openStore(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Mağaza açılamazsa sessizce geç.
    }
  }
}

/// Dikkat çeken "Güncelle" butonu: sürekli nabız gibi büyüyüp küçülür ve
/// etrafında yumuşak bir parıltı dalgalanır — kullanıcıyı tıklamaya davet eder.
class _PulsingUpdateButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PulsingUpdateButton({required this.label, required this.onTap});

  @override
  State<_PulsingUpdateButton> createState() => _PulsingUpdateButtonState();
}

class _PulsingUpdateButtonState extends State<_PulsingUpdateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const Color _c1 = Color(0xFF9F7AEA); // mor
  static const Color _c2 = Color(0xFF7C5CD6);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 1.0 + 0.06 * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _c1.withOpacity(0.30 + 0.40 * t),
                  blurRadius: 10 + 16 * t,
                  spreadRadius: 0.5 + 1.5 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_c1, _c2]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
