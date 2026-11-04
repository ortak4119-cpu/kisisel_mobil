import 'package:flutter/material.dart';

/// Ekranın ortasında kısa süreli, animasyonlu bir onay rozeti gösterir
/// (ör. arkadaşlık isteği "Gönderildi"). Yaklaşık 1.4 sn sonra kendini kaldırır.
void showSentAnimation(BuildContext context, String label) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SentBadge(
      label: label,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _SentBadge extends StatefulWidget {
  final String label;
  final VoidCallback onDone;
  const _SentBadge({required this.label, required this.onDone});

  @override
  State<_SentBadge> createState() => _SentBadgeState();
}

class _SentBadgeState extends State<_SentBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // Giriş: 0→0.22 ölçek-yayla belir; çıkış: 0.8→1 solup yüksel.
            final appear = Curves.elasticOut.transform((t / 0.35).clamp(0, 1).toDouble());
            final out = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
            final opacity = (1 - out).clamp(0.0, 1.0);
            final checkT = ((t - 0.18) / 0.3).clamp(0.0, 1.0);
            return Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, -24 * out),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * appear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3AB7A8),
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: checkT,
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 34),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
