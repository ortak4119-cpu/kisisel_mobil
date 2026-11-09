import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../service/stt/stt_service.dart';
import '../../../core/design/app_design.dart';
import '../../../core/design/app_loader.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/animation_prefs.dart';
import '../../../core/widgets/speed_dial_fab.dart';
import '../../../models/diary/diary_models.dart';
import '../../../models/note/note_models.dart';
import '../../../models/share/shared_item_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../share/share_with_friends_sheet.dart';
import '../../share/shared_hub_sheet.dart';
import '../../share/shared_item_editor_sheet.dart';
import '../viewmodel/notes_diary_viewmodel.dart';
import 'markdown_note_parser.dart';

/// Mantar panosu "ip"i — hafif sarkan yatay çizgi.
class _StringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB09A78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 2)
      ..quadraticBezierTo(size.width / 2, 10, size.width, 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ======================================================================
// ESİNTİ (rüzgâr) altyapısı
// Askıdaki kartlar mandal/raptiye noktasından sürekli hafifçe sallanır.
// Hem DİKEY (sayfa) hem de YATAY (ip) kaydırma salınım gücünü artırır.
// ======================================================================
class _BreezeScope extends StatefulWidget {
  final Widget child;
  const _BreezeScope({required this.child});

  static _BreezeScopeState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BreezeScopeState>();

  @override
  State<_BreezeScope> createState() => _BreezeScopeState();
}

class _BreezeScopeState extends State<_BreezeScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock;
  double energy = 0; // 0..1 — kaydırmayla artan esinti gücü

  @override
  void initState() {
    super.initState();
    clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (AnimationPrefs.isOn) clock.repeat();
    clock.addListener(_decay);
    AnimationPrefs.enabled.addListener(_onAnimFlag);
  }

  // Animasyon tercihi değişince saati durdur/başlat.
  void _onAnimFlag() {
    if (!mounted) return;
    if (AnimationPrefs.isOn) {
      if (!clock.isAnimating) clock.repeat();
    } else {
      clock.stop();
    }
  }

  // Her karede esinti gücü biraz söner (kaydırma durunca sakinleşir).
  void _decay() {
    if (energy > 0) energy = math.max(0.0, energy - 0.016);
  }

  // Dikey sayfa ve yatay ip kaydırmalarının ikisi de buraya düşer.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final d = (n.scrollDelta ?? 0).abs();
      energy = (energy + d * 0.010).clamp(0.0, 1.0);
    } else if (n is OverscrollNotification) {
      energy = (energy + n.overscroll.abs() * 0.010).clamp(0.0, 1.0);
    }
    return false;
  }

  @override
  void dispose() {
    AnimationPrefs.enabled.removeListener(_onAnimFlag);
    clock.removeListener(_decay);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}

/// Tek bir askıdaki kartı mandal/raptiye noktasından (üst-orta) sallar.
class _Sway extends StatelessWidget {
  final int index;
  final Widget child;
  const _Sway({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Animasyonlar kapalıysa (Ayarlar › Görünüm) kart sabit durur.
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationPrefs.enabled,
      builder: (context, animOn, _) {
        if (!animOn) return child;
        final breeze = _BreezeScope.of(context);
        if (breeze == null) return child;
        return AnimatedBuilder(
          animation: breeze.clock,
          child: child,
          builder: (context, inner) {
            final phase = breeze.clock.value * 2 * math.pi + index * 1.15;
            final amp = 0.028 + breeze.energy * 0.11; // kaydırınca güçlenir
            return Transform.rotate(
              angle: math.sin(phase) * amp,
              alignment: Alignment.topCenter,
              child: inner,
            );
          },
        );
      },
    );
  }
}

// ======================================================================
// Kök katman (Overlay) animasyonları: kaydetme kutlaması + kilit/aç
// ======================================================================
void _showRootOverlay(
    OverlayState overlay, Widget Function(VoidCallback remove) builder) {
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => builder(() {
        if (entry.mounted) entry.remove();
      }));
  overlay.insert(entry);
}

/// Yeni not kaydedilince: yeşil daire + çizilen onay işareti belirir,
/// ardından küçülüp bir not kartına dönüşerek panoya doğru uçup kaybolur.
class _SaveCelebrationOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _SaveCelebrationOverlay({required this.onDone});
  @override
  State<_SaveCelebrationOverlay> createState() =>
      _SaveCelebrationOverlayState();
}

class _SaveCelebrationOverlayState extends State<_SaveCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1750))
      ..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final appear = Curves.easeOutBack.transform((t / 0.26).clamp(0.0, 1.0));
          final check = ((t - 0.22) / 0.26).clamp(0.0, 1.0);
          final fly =
              Curves.easeInCubic.transform(((t - 0.62) / 0.38).clamp(0.0, 1.0));
          final scale = appear * (1 - 0.5 * fly);
          final opacity = t < 0.62 ? 1.0 : (1 - fly);
          return Center(
            child: Transform.translate(
              offset: Offset(fly * 120, -fly * 300),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.25),
                  child: _badge(check, fly),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _badge(double check, double fly) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // yeşil onay dairesi (uçmaya başlayınca solar)
          Opacity(
            opacity: (1 - fly).clamp(0.0, 1.0),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34C759),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.45),
                      blurRadius: 26,
                      spreadRadius: 2),
                ],
              ),
              child: CustomPaint(painter: _CheckPainter(check)),
            ),
          ),
          // uçarken beliren mini not kartı
          Opacity(
            opacity: fly.clamp(0.0, 1.0),
            child: Container(
              width: 74,
              height: 90,
              decoration: BoxDecoration(
                color: ColorConstant.cardColorLight,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double p; // 0..1 çizim ilerlemesi
  _CheckPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    final p1 = Offset(w * 0.30, h * 0.52);
    final p2 = Offset(w * 0.44, h * 0.66);
    final p3 = Offset(w * 0.72, h * 0.36);
    final seg1 = (p * 2).clamp(0.0, 1.0);
    final seg2 = ((p * 2) - 1).clamp(0.0, 1.0);
    final path = Path()..moveTo(p1.dx, p1.dy);
    final a = Offset.lerp(p1, p2, seg1)!;
    path.lineTo(a.dx, a.dy);
    if (seg2 > 0) {
      final b = Offset.lerp(p2, p3, seg2)!;
      path.lineTo(b.dx, b.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.p != p;
}

/// Kilitleme / kilit açma için AYRI animasyonlar.
/// Kilitleme: asma kilit yukarıdan düşer, halka kapanır (kehribar).
/// Açma: halka yukarı açılır, kilit hafif yükselir (yeşil).
class _LockCelebrationOverlay extends StatefulWidget {
  final bool locking;
  final VoidCallback onDone;
  const _LockCelebrationOverlay(
      {required this.locking, required this.onDone});
  @override
  State<_LockCelebrationOverlay> createState() =>
      _LockCelebrationOverlayState();
}

class _LockCelebrationOverlayState extends State<_LockCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1250))
      ..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.locking
        ? const Color(0xFFF6A821) // kehribar
        : const Color(0xFF34C759); // yeşil
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final appear =
              Curves.easeOutBack.transform((t / 0.34).clamp(0.0, 1.0));
          final out = ((t - 0.78) / 0.22).clamp(0.0, 1.0);
          // İkon durumu: kilitlemede ortadan sonra kapanır, açmada açılır.
          final closed = widget.locking ? (t > 0.45) : (t < 0.45);
          // Hareket: kilit düşerek gelir / açılırken yükselir.
          final dy = widget.locking
              ? -26 * (1 - appear)
              : -14 * appear;
          // Küçük sarsıntı/eğim.
          final tilt = widget.locking
              ? (t > 0.4 && t < 0.62 ? math.sin(t * 60) * 0.05 : 0.0)
              : -0.14 * appear;
          return Center(
            child: Opacity(
              opacity: (1 - out).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: appear.clamp(0.0, 1.2),
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.45),
                              blurRadius: 26,
                              spreadRadius: 2),
                        ],
                      ),
                      child: Icon(
                        closed
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// İçindeki öğeleri sırayla (kayarak + belirerek) içeri getirir.
class _StaggerIn extends StatefulWidget {
  final List<Widget> children;
  final double gap;
  const _StaggerIn({required this.children}) : gap = 12;
  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 260 + widget.children.length * 110))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    // Animasyonlar kapalıysa öğeler doğrudan görünür.
    if (!AnimationPrefs.isOn) {
      final rows = <Widget>[];
      for (var i = 0; i < n; i++) {
        if (i > 0) rows.add(SizedBox(height: widget.gap));
        rows.add(widget.children[i]);
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final rows = <Widget>[];
        for (var i = 0; i < n; i++) {
          final start = n == 1 ? 0.0 : (i / n) * 0.6;
          final v = Curves.easeOutCubic
              .transform(((_c.value - start) / 0.4).clamp(0.0, 1.0));
          if (i > 0) rows.add(SizedBox(height: widget.gap));
          rows.add(Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 22),
              child: widget.children[i],
            ),
          ));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

@RoutePage()
class NotesDiaryView extends StatefulWidget {
  const NotesDiaryView({super.key});

  @override
  State<NotesDiaryView> createState() => _NotesDiaryViewState();
}

class _NotesDiaryViewState extends State<NotesDiaryView> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesDiaryViewModel()..refreshAll(),
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, viewModel, _) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            // Not sekmesi için sıcak krem zemin (Stitch "Sunny Script" dili).
            // Sadece bu sekmeyi etkiler; diğer sekmeler kendi Scaffold'unu kullanır.
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              child: Column(
                children: [
                  // Başlık — el yazısı "Notlarım" + arama + ekle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 18, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'notes.title'.tr(),
                            style: TextStyle(fontFamily: 'JosefinSans',
                              color: isDarkMode
                                  ? ColorConstant.textPrimaryDark
                                  : const Color(0xFF3A3326),
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                        // Paylaşım Merkezi — davetler + benimle paylaşılan notlar.
                        // Bekleyen davet varsa buton üzerinde kırmızı rozet.
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _headerCircleBtn(
                              icon: Icons.diversity_3_rounded,
                              bg: ColorConstant.cardColorLight,
                              fg: const Color(0xFF3A3326),
                              onTap: () async {
                                await showSharedHubSheet(context, kind: 'note');
                                // Hub'dan dönünce rozeti/paylaşım bilgisini tazele.
                                viewModel.loadSharedNotesInfo();
                              },
                            ),
                            if (viewModel.noteInviteCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  constraints:
                                      const BoxConstraints(minWidth: 19),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE24B4A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: ColorConstant.bgColorLight,
                                        width: 1.5),
                                  ),
                                  child: Text(
                                    '${viewModel.noteInviteCount}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Not ekleme tek yerden (FAB). Başlıkta arama + paylaşım.
                        _headerCircleBtn(
                          icon: Icons.search_rounded,
                          bg: ColorConstant.cardColorLight,
                          fg: const Color(0xFF3A3326),
                          onTap: () =>
                              _openNoteSearch(context, viewModel, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _BreezeScope(
                      child: _NotesContent(viewModel: viewModel),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Padding(
              // Tüm menülerde + aynı konumda (Bugün ile aynı).
              padding: const EdgeInsets.only(bottom: 92),
              child: SpeedDialFab(actions: [
                DialAction(
                  icon: Icons.note_add_rounded,
                  label: 'notes.add.noteTitle'.tr(),
                  color: AppColors(isDarkMode).accent,
                  onTap: () => showAddNoteSheet(context, viewModel, isDarkMode),
                ),
                DialAction(
                  icon: Icons.create_new_folder_rounded,
                  label: 'notes.add.folderTitle'.tr(),
                  color: AppColors(isDarkMode).accentCool,
                  onTap: () =>
                      _showAddFolderDialog(context, viewModel, isDarkMode),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _headerCircleBtn(
      {required IconData icon,
      required Color bg,
      required Color fg,
      required VoidCallback onTap}) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }

  /// Başlıktaki arama: metin girilince klasik liste arama sonuçlarını gösterir.
  void _openNoteSearch(BuildContext context, NotesDiaryViewModel viewModel,
      bool isDarkMode) {
    final c = AppColors(isDarkMode);
    final ctrl = TextEditingController(text: viewModel.noteSearchQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('notes.searchTitle'.tr(),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(hintText: 'notes.searchHint'.tr()),
          onSubmitted: (v) {
            viewModel.setNoteSearchQuery(v.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
              onPressed: () {
                viewModel.setNoteSearchQuery(ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: Text('notes.searchBtn'.tr())),
        ],
      ),
    );
  }

  /// Klasör (kategori) oluşturma diyaloğu.
  void _showAddFolderDialog(BuildContext context,
          NotesDiaryViewModel viewModel, bool isDarkMode,
          {NoteCategory? editing}) =>
      showFolderDialog(context, viewModel, isDarkMode, editing: editing);

}

/// Not ekleme sayfasını açar.
/// Üst seviyede tutuluyor ki hem FAB hem de boş durum butonu aynı yeri açsın.
void showAddNoteSheet(
    BuildContext context, NotesDiaryViewModel viewModel, bool isDarkMode) {
  // Yeni not her zaman temiz/boş açılsın (önceki düzenlemeden kalan içerik olmasın).
  viewModel.resetNoteForm();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddNoteBottomSheet(
      viewModel: viewModel,
      isDarkMode: isDarkMode,
    ),
  );
}

/// Klasör ekleme/düzenleme sayfası (üst seviye — hem FAB hem klasör kartı kullanır).
void showFolderDialog(BuildContext context,
    NotesDiaryViewModel viewModel, bool isDarkMode,
    {NoteCategory? editing}) {
  final c = AppColors(isDarkMode);
  final nameController = TextEditingController(text: editing?.name ?? '');
  const icons = ['📁', '🔒', '🎂', '💼', '💡', '❤️', '✈️', '🛒', '📚', '🏠'];
  String selectedIcon = (editing?.icon != null && icons.contains(editing!.icon))
      ? editing.icon!
      : icons.first;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(editing != null
                    ? 'notes.folders.editTitle'.tr()
                    : 'notes.add.folderTitle'.tr(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
            const SizedBox(height: 4),
            Text('notes.folders.hint'.tr(),
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final ic in icons)
                    GestureDetector(
                      onTap: () => setState(() => selectedIcon = ic),
                      child: Container(
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedIcon == ic
                              ? c.accent.withOpacity(0.2)
                              : c.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selectedIcon == ic
                                  ? c.accent
                                  : c.border),
                        ),
                        child: Text(ic,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'notes.folders.nameHint'.tr(),
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: editing != null
                  ? 'common.save'.tr()
                  : 'common.create'.tr(),
              icon: editing != null ? Icons.check_rounded : Icons.add_rounded,
              accent: c.accent,
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                if (editing != null) {
                  viewModel.updateCategory(context, editing.id,
                      nameController.text.trim(), selectedIcon, '#9F7AEA');
                } else {
                  viewModel.createCategory(context,
                      nameController.text.trim(), selectedIcon, '#9F7AEA');
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ==================== NOTLAR FİLTRE SHEET ====================

// ==================== KATEGORİ YÖNETİMİ SHEET ====================

// ==================== GÜNLÜK TAKVİM SHEET ====================

class _DiaryCalendarSheet extends StatefulWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;

  const _DiaryCalendarSheet({
    required this.viewModel,
    required this.isDarkMode,
  });

  @override
  State<_DiaryCalendarSheet> createState() => _DiaryCalendarSheetState();
}

class _DiaryCalendarSheetState extends State<_DiaryCalendarSheet> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.cardColorLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Month Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                });
                                vm.loadDiaryEntriesByMonth(
                                  _selectedMonth.month,
                                  _selectedMonth.year,
                                );
                              },
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: widget.isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: widget.isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                });
                                vm.loadDiaryEntriesByMonth(
                                  _selectedMonth.month,
                                  _selectedMonth.year,
                                );
                              },
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: widget.isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calendar Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _getDaysInMonth(_selectedMonth),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month,
                          day,
                        );
                        final hasEntry = vm.diaryEntries.any(
                              (d) =>
                          d.diaryDate.year == date.year &&
                              d.diaryDate.month == date.month &&
                              d.diaryDate.day == date.day,
                        );
                        final isToday = DateTime.now().year == date.year &&
                            DateTime.now().month == date.month &&
                            DateTime.now().day == date.day;

                        return GestureDetector(
                          onTap: hasEntry
                              ? () {
                            final entry = vm.diaryEntries.firstWhere(
                                  (d) =>
                              d.diaryDate.year == date.year &&
                                  d.diaryDate.month == date.month &&
                                  d.diaryDate.day == date.day,
                            );
                            Navigator.pop(context);
                            _showDiaryDetail(
                                context, vm, entry, widget.isDarkMode);
                          }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: hasEntry
                                  ? const Color(0xFFFFA07A).withOpacity(0.2)
                                  : (isToday
                                  ? const Color(0xFFB794F6).withOpacity(0.1)
                                  : null),
                              border: Border.all(
                                color: isToday
                                    ? const Color(0xFFB794F6)
                                    : (hasEntry
                                    ? const Color(0xFFFFA07A)
                                    : (widget.isDarkMode
                                    ? ColorConstant.borderColorDark
                                    : ColorConstant.borderColorLight)),
                                width: isToday || hasEntry ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  hasEntry ? FontWeight.w700 : FontWeight.w500,
                                  color: hasEntry
                                      ? const Color(0xFFFFA07A)
                                      : (isToday
                                      ? const Color(0xFFB794F6)
                                      : (widget.isDarkMode
                                      ? ColorConstant.textPrimaryDark
                                      : ColorConstant.textPrimaryLight)),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Legend
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          context,
                          const Color(0xFFFFA07A),
                          'diary.hasEntry'.tr(),
                        ),
                        const SizedBox(width: 24),
                        _buildLegendItem(
                          context,
                          const Color(0xFFB794F6),
                          'common.today'.tr(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'common.months.january'.tr();
      case 2:
        return 'common.months.february'.tr();
      case 3:
        return 'common.months.march'.tr();
      case 4:
        return 'common.months.april'.tr();
      case 5:
        return 'common.months.may'.tr();
      case 6:
        return 'common.months.june'.tr();
      case 7:
        return 'common.months.july'.tr();
      case 8:
        return 'common.months.august'.tr();
      case 9:
        return 'common.months.september'.tr();
      case 10:
        return 'common.months.october'.tr();
      case 11:
        return 'common.months.november'.tr();
      case 12:
        return 'common.months.december'.tr();
      default:
        return '';
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  void _showDiaryDetail(
      BuildContext context,
      NotesDiaryViewModel vm,
      Diary entry,
      bool isDarkMode,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiaryDetailSheet(
        viewModel: vm,
        diary: entry,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

// ==================== GÜNLÜK DETAY SHEET ====================

class _DiaryDetailSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final Diary diary;
  final bool isDarkMode;

  const _DiaryDetailSheet({
    required this.viewModel,
    required this.diary,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? ColorConstant.borderColorDark
                          : ColorConstant.borderColorLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date & Mood
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA07A),
                              const Color(0xFFFF8A5C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatFullDate(diary.diaryDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ColorConstant.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (diary.moodIcon != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA07A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            diary.moodIcon!,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      const SizedBox(width: 12),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [

                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () {
                                  Navigator.pop(context);
                                  _showEditDiaryDialog(
                                      context, viewModel, isDarkMode, diary);
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                ),
                                const SizedBox(width: 12),
                                Text('common.edit'.tr()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                    () {
                                  Navigator.pop(context);
                                  _showDeleteDiaryDialog(
                                    context,
                                    diary.diaryDate
                                        .toIso8601String()
                                        .split('T')[0],
                                    viewModel,
                                  );
                                },
                              );
                            },
                            child: Row(
                              children:  [
                                Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'common.delete'.tr(),
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    if (diary.title != null && diary.title!.isNotEmpty) ...[
                      Text(
                        diary.title!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content
                    Text(
                      diary.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDarkMode
                            ? ColorConstant.textSecondaryDark
                            : ColorConstant.textSecondaryLight,
                      ),
                    ),

                    // Weather
                    if (diary.weather != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? ColorConstant.bgColorDark
                              : ColorConstant.bgColorLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getWeatherIcon(diary.weather!),
                              color: const Color(0xFFFFA07A),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hava: ${_getWeatherLabel(diary.weather!)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'common.monthsShort.january'.tr();
      case 2:
        return 'common.monthsShort.february'.tr();
      case 3:
        return 'common.monthsShort.march'.tr();
      case 4:
        return 'common.monthsShort.april'.tr();
      case 5:
        return 'common.monthsShort.may'.tr();
      case 6:
        return 'common.monthsShort.june'.tr();
      case 7:
        return 'common.monthsShort.july'.tr();
      case 8:
        return 'common.monthsShort.august'.tr();
      case 9:
        return 'common.monthsShort.september'.tr();
      case 10:
        return 'common.monthsShort.october'.tr();
      case 11:
        return 'common.monthsShort.november'.tr();
      case 12:
        return 'common.monthsShort.december'.tr();
      default:
        return '';
    }
  }

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'rainy':
        return Icons.water_drop_rounded;
      case 'snowy':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  String _getWeatherLabel(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return 'common.weather.sunny'.tr();
      case 'cloudy':
        return 'common.weather.cloudy'.tr();
      case 'rainy':
        return 'common.weather.rainy'.tr();
      case 'snowy':
        return 'common.weather.snowy'.tr();
      default:
        return weather;
    }
  }

  void _showEditDiaryDialog(
      BuildContext context,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      Diary diary,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDiaryBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
        diary: diary,
      ),
    );
  }

  void _showDeleteDiaryDialog(
      BuildContext context,
      String date,
      NotesDiaryViewModel viewModel,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'diary.deleteDiary'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'diary.deleteConfirm'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteDiary(date, context);
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DEVAM EDİYOR - Şimdi NotesContent ve DiaryContent classlarını güncelleyeceğim...
// Dosya çok uzun olduğu için ikinci artifact'ta devam edeceğim.
// ==================== NOTLAR İÇERİĞİ ====================

// ==================== NOTLAR İÇERİĞİ ====================
// ==================== NOTLAR İÇERİĞİ ====================
// ==================== TAM _NotesContent CLASS'I ====================
// Bu kodu mevcut _NotesContent class'ınızın yerine koyun

class _NotesContent extends StatefulWidget {
  final NotesDiaryViewModel viewModel;

  const _NotesContent({required this.viewModel});

  @override
  State<_NotesContent> createState() => _NotesContentState();
}

class _NotesContentState extends State<_NotesContent> {
  // Sürükle-bırak reorder animasyonu: her notun başlangıç ötelemesi (kart
  // genişliği birimiyle). Bırakınca kartlar eski yerlerinde belirip yeni
  // yerlerine kayar; bir kare sonra sıfırlanıp AnimatedSlide ile yumuşar.
  final Map<int, Offset> _recentSlide = {};
  NotesDiaryViewModel get viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.isLoading) {
      return const Center(child: AppLoader());
    }
    // Varsayılan görünüm = mantar panosu. Arşiv kendi mantar panosunu kullanır.
    // Diğer filtreler (sabitlenen/klasör) veya arama klasik ızgaraya düşer.
    final searchActive = viewModel.noteSearchQuery.trim().isNotEmpty;
    if (!searchActive && viewModel.notesFilter == 'archive') {
      return _archiveBoard(context, isDarkMode);
    }
    // Açık klasör (bir kategori seçiliyken) kendi dosya görünümünü kullanır.
    if (!searchActive &&
        viewModel.notesFilter == 'folders' &&
        viewModel.selectedCategoryId != null) {
      return _folderBoard(context, isDarkMode);
    }
    if (viewModel.notesFilter != 'all' || searchActive) {
      return _classicBody(context, isDarkMode);
    }
    return _corkBoard(context, isDarkMode);
  }

  // ==================== KLASÖR (DOSYA) GÖRÜNÜMÜ ====================
  // Açık klasör, sayfayı kaplayan bir dosya klasörü gibi gösterilir; notlar
  // klasör içinde kâğıt yaprakları olarak listelenir. Renk paleti notlarla
  // aynı: klasör zemini = notlar arka planı, kâğıtlar = not kartı rengi.
  static const List<Color> _folderAccents = [
    Color(0xFFF6A821), // turuncu
    Color(0xFF15788C), // teal
    Color(0xFF9F7AEA), // mor
    Color(0xFFE24B4A), // kırmızı
    Color(0xFF34C759), // yeşil
  ];

  Widget _folderBoard(BuildContext context, bool isDark) {
    final catId = viewModel.selectedCategoryId;
    final cat = viewModel.categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => viewModel.categories.isNotEmpty
          ? viewModel.categories.first
          : NoteCategory(
              id: catId ?? 0,
              name: 'notes.stats.folders'.tr(),
              notesCount: 0,
              orderIndex: 0),
    );
    final notes = viewModel.applyTagFilter(viewModel.applyNoteSearch(viewModel
        .notes
        .where((n) => !n.isArchived && n.categoryId == cat.id)
        .toList()));
    return Column(
      children: [
        const SizedBox(height: 6),
        _folderTopBar(context, cat, notes.length),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _folderFrame(
              cat: cat,
              child: RefreshIndicator(
                onRefresh: () => viewModel.loadNotes(),
                color: ColorConstant.accentOrange,
                child: LayoutBuilder(
                  builder: (context, cons) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: cons.maxHeight),
                      child: notes.isEmpty
                          ? Center(child: _emptyFolderContent(context))
                          : Column(
                              children: [
                                for (var i = 0; i < notes.length; i++)
                                  _folderNoteSheet(context, notes[i], i, isDark),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _folderTopBar(BuildContext context, NoteCategory cat, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => viewModel.setNotesFilter('all'),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEAE0CD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: _boardBrown),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.folder_rounded, size: 18, color: _boardBrown),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
                '${cat.name.toUpperCase()} · $count ${'notes.noteUnit'.tr().toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: _boardBrown)),
          ),
        ],
      ),
    );
  }

  // Dosya klasörü: üstte sekme (ikon + ad), gövde notlar arka planı rengiyle.
  Widget _folderFrame({required NoteCategory cat, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            decoration: const BoxDecoration(
              color: _boardBrown,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat.icon ?? '📁', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 7),
                Text(cat.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEAE0CD))),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstant.bgColorLight,
              border: Border.all(color: const Color(0xFF9B7B4F), width: 2),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF3C2A14).withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            child: child,
          ),
        ),
      ],
    );
  }

  // Klasör içindeki bir not — kâğıt yaprağı (sol renkli kenar + ⋯ menü).
  Widget _folderNoteSheet(
      BuildContext context, Note note, int i, bool isDark) {
    final accent = _folderAccents[i % _folderAccents.length];
    final angle = ((i % 3) - 1) * 0.006;
    final preview = _plainPreview(note);
    final d = note.createdAt;
    String two(int v) => v.toString().padLeft(2, '0');
    final dateLabel =
        '${two(d.day)}.${two(d.month)} · ${two(d.hour)}:${two(d.minute)}';
    final title = (note.title ?? '').trim().isNotEmpty
        ? note.title!.trim()
        : 'notes.untitledNote'.tr();
    return Transform.rotate(
      angle: angle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF3C2A14).withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(1, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: GestureDetector(
            onTap: () => _openNote(context, note, isDark),
            child: ColoredBox(
              color: ColorConstant.cardColorLight,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (viewModel.isNoteLockedForMe(note))
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6, top: 1),
                                    child: Icon(Icons.lock_rounded,
                                        size: 15, color: Color(0xFF8A7A5E)),
                                  ),
                                Expanded(
                                  child: Text(title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontFamily: 'JosefinSans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3A3326))),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: _cardMenu(context, note, viewModel,
                                      isDark, AppColors(isDark)),
                                ),
                              ],
                            ),
                            if (!viewModel.isNoteLockedForMe(note) && preview.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.35,
                                      color: Color(0xFF6B5E4A))),
                            ],
                            if (viewModel.isNoteLockedForMe(note)) ...[
                              const SizedBox(height: 4),
                              const Text('••••••••••',
                                  style: TextStyle(
                                      fontSize: 13.5, color: Color(0xFF9B8A6E))),
                            ],
                            const SizedBox(height: 7),
                            Text(dateLabel,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFFA8966F))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Not içeriğinden düz önizleme metni (işaretçiler temizlenir).
  String _plainPreview(Note note) {
    final raw = (note.content ?? '').trim();
    if (raw.isEmpty) return '';
    final lines = raw.split('\n');
    final out = <String>[];
    for (final l in lines) {
      var t = l.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('☐ ') || t.startsWith('☑ ')) t = t.substring(2);
      if (t.startsWith('• ')) t = t.substring(2);
      t = t.replaceAll('**', '').replaceAll('__', '');
      out.add(t);
      if (out.length >= 2) break;
    }
    return out.join('  ');
  }

  Widget _emptyFolderContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded,
              size: 42, color: const Color(0xFF9B8A6E).withOpacity(0.7)),
          const SizedBox(height: 12),
          Text('notes.folders.emptyDesc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A7A5E))),
        ],
      ),
    );
  }

  // Arşiv görünümü — artık ipe asılı kartlar (mantar pano değil).
  Widget _archiveBoard(BuildContext context, bool isDark) {
    final archived = viewModel.applyTagFilter(viewModel
        .applyNoteSearch(viewModel.notes.where((n) => n.isArchived).toList()));
    return RefreshIndicator(
      onRefresh: () => viewModel.loadNotes(),
      color: ColorConstant.accentOrange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 120),
        children: [
          _archiveTopBar(context, archived.length),
          const SizedBox(height: 12),
          archived.isEmpty
              ? _boardEmptyLine('notes.board.archiveEmpty'.tr())
              : _clothesline(context, archived, isDark),
        ],
      ),
    );
  }

  Widget _archiveTopBar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => viewModel.setNotesFilter('all'),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEAE0CD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: _boardBrown),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.inventory_2_rounded, size: 18, color: _boardBrown),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
                '${'notes.stats.archive'.tr().toUpperCase()} · $count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: _boardBrown)),
          ),
        ],
      ),
    );
  }

  Widget _classicBody(BuildContext context, bool isDarkMode) {
    final all = viewModel.applyTagFilter(viewModel
        .applyNoteSearch(viewModel.notes.where((n) => !n.isArchived).toList()));
    final pinned = all.where((n) => n.isPinned).toList();
    // Son notlar: sabitlenmiş notlar burada TEKRAR gösterilmez.
    final recent = all.where((n) => !n.isPinned).toList();
    final archived = viewModel.applyTagFilter(viewModel
        .applyNoteSearch(viewModel.notes.where((n) => n.isArchived).toList()));
    final tab = viewModel.notesFilter; // all | pinned | folders | archive
    const orange = Color(0xFFF6A821);
    const purple = Color(0xFF9F7AEA);
    const green = Color(0xFF48BB78);

    return RefreshIndicator(
      onRefresh: () => viewModel.loadNotes(),
      color: const Color(0xFFB794F6),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          _searchBar(context, isDarkMode),
          const SizedBox(height: 16),
          // İstatistik kartları = tıklanabilir filtreler
          Row(
            children: [
              _statCard(Icons.notes_rounded, 'notes.stats.all'.tr(),
                  '${all.length}', orange, isDarkMode,
                  filled: tab == 'all',
                  onTap: () => viewModel.setNotesFilter('all')),
              const SizedBox(width: 10),
              _statCard(Icons.push_pin_rounded, 'notes.stats.pinned'.tr(),
                  '${pinned.length}', orange, isDarkMode,
                  filled: tab == 'pinned',
                  onTap: () => viewModel.setNotesFilter('pinned')),
              const SizedBox(width: 10),
              _statCard(Icons.folder_rounded, 'notes.stats.folders'.tr(),
                  '${viewModel.categories.length}', purple, isDarkMode,
                  filled: tab == 'folders',
                  onTap: () => viewModel.setNotesFilter('folders')),
              const SizedBox(width: 10),
              _statCard(Icons.archive_rounded, 'notes.stats.archive'.tr(),
                  '${archived.length}', green, isDarkMode,
                  filled: tab == 'archive',
                  onTap: () => viewModel.setNotesFilter('archive')),
            ],
          ),
          // Etiket filtresi (notlarda etiket varsa)
          if (viewModel.allTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in viewModel.allTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => viewModel.setSelectedTag(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: viewModel.selectedTag == t
                                ? purple
                                : purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$t',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: viewModel.selectedTag == t
                                  ? Colors.white
                                  : purple,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ..._notesBody(context, isDarkMode, tab, all, pinned, recent, archived),
        ],
      ),
    );
  }

  // ==================== MANTAR PANOSU ====================
  static const _boardBrown = Color(0xFF6E5C42);
  static const _pinLight = Color(0xFFDFB176);
  static const _pinDark = Color(0xFFBE8A4E);

  Widget _corkBoard(BuildContext context, bool isDark) {
    final live = viewModel.applyTagFilter(viewModel
        .applyNoteSearch(viewModel.notes.where((n) => !n.isArchived).toList()));
    final pinned = live.where((n) => n.isPinned).toList();
    // BUGÜN listesi yalnızca kategorisiz (klasöre atanmamış) ve sabitlenmemiş
    // notları gösterir; klasöre/arşive/sabitlenenlere giden not burada tekrar
    // görünmez.
    final recent = live
        .where((n) => !n.isPinned && n.categoryId == null)
        .toList();
    final archived = viewModel.applyTagFilter(viewModel
        .applyNoteSearch(viewModel.notes.where((n) => n.isArchived).toList()));

    return RefreshIndicator(
      onRefresh: () => viewModel.loadNotes(),
      color: const Color(0xFFB794F6),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 120),
        children: [
          // 1) Notlar (klasöre atanmamış, sabitlenmemiş son notlar)
          _boardHeader('notes.recentSection'.tr().toUpperCase(),
              '${recent.length} ${'notes.noteUnit'.tr()}',
              trailing: recent.length > 2 ? 'notes.scroll'.tr() : null),
          const SizedBox(height: 2),
          recent.isEmpty
              ? _recentDropZone(context, _boardEmptyLine('notes.board.noNotes'.tr()))
              : _clothesline(context, recent, isDark, zone: 'recent'),
          const SizedBox(height: 24),
          // 2) Sabitlenen
          _boardHeader('notes.pinnedSection'.tr().toUpperCase(),
              '${pinned.length}'),
          const SizedBox(height: 2),
          pinned.isEmpty
              ? _pinnedDropZone(context, _emptyPins())
              : _clothesline(context, pinned, isDark, zone: 'pinned'),
          const SizedBox(height: 24),
          // 3) Klasörler
          _foldersHeader(context),
          const SizedBox(height: 2),
          viewModel.categories.isEmpty
              ? _emptyFoldersRope(context)
              : _foldersClothesline(context, isDark),
          const SizedBox(height: 24),
          // 4) Arşiv — artık ipe asılı (pano değil)
          _boardHeader('notes.stats.archive'.tr().toUpperCase(),
              '${archived.length}'),
          const SizedBox(height: 2),
          archived.isEmpty
              ? _boardEmptyLine('notes.board.archiveEmpty'.tr())
              : _clothesline(context, archived, isDark),
        ],
      ),
    );
  }

  Widget _boardHeader(String label, String? count, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(
        children: [
          Flexible(
            child: Text(count != null ? '$label · $count' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: _boardBrown)),
          ),
          const Spacer(),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9B7B4F))),
        ],
      ),
    );
  }

  Widget _boardEmptyLine(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9B8A6E))),
      );

  Widget _clothesline(BuildContext context, List<Note> notes, bool isDark,
      {String? zone}) {
    // İçindeki en uzun (boyutlandırılmış) karta göre ipin yüksekliği.
    double maxH = 162; // otomatik kartlar için taban
    for (final n in notes) {
      final s = viewModel.noteSize(n.id);
      if (s != null && s.length >= 2 && s[1] > maxH) maxH = s[1];
    }
    final lineH = maxH + 58; // mandal + boşluk payı
    // Bir not boyutlandırılırken ipi kaydırma (tutamak sürüklemesi rahat olsun).
    final resizing = viewModel.resizingNoteId != null;
    final line = SizedBox(
      height: lineH,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 14,
            child: CustomPaint(
                size: const Size(double.infinity, 12),
                painter: _StringPainter()),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: resizing ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) =>
                _hungCard(context, notes[i], i, isDark, zone: zone, zoneList: notes),
          ),
        ],
      ),
    );
    // Bölüm geneli bırakma hedefi: boş alana bırakınca pin/unpin.
    if (zone == 'recent' || zone == 'pinned') {
      return DragTarget<Note>(
        onWillAcceptWithDetails: (d) =>
            d.data.isPinned != (zone == 'pinned'),
        onAcceptWithDetails: (d) => _handleNoteDrop(context, d.data, zone!),
        builder: (ctx, cand, rej) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cand.isNotEmpty
                ? const Color(0xFFB794F6).withOpacity(0.10)
                : Colors.transparent,
            border: cand.isNotEmpty
                ? Border.all(
                    color: const Color(0xFFB794F6).withOpacity(0.6), width: 1.5)
                : null,
          ),
          child: line,
        ),
      );
    }
    return line;
  }

  Widget _hungCard(BuildContext context, Note note, int i, bool isDark,
      {String? zone, List<Note>? zoneList}) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _clothespin(),
        Transform.translate(
          offset: const Offset(0, -3),
          child: _paperCard(context, note, isDark),
        ),
      ],
    );
    // Boyutlandırılan kart sallanmasın (sürükleme hedefi sabit kalsın).
    if (viewModel.resizingNoteId == note.id) return column;
    final swayed = _Sway(index: i, child: column);

    // Boyutlandırma modunda veya sürüklenmeyen bölümlerde: düz salınan kart.
    if (viewModel.resizingNoteId != null ||
        (zone != 'recent' && zone != 'pinned')) {
      return swayed;
    }

    // Sürükle-bırak: uzun bas → sürükle. Karta bırakınca aynı bölümde sırala,
    // farklı bölüme bırakınca pin/unpin.
    final dragTarget = DragTarget<Note>(
      onWillAcceptWithDetails: (d) => d.data.id != note.id,
      onAcceptWithDetails: (d) =>
          _handleNoteDrop(context, d.data, zone!, targetIndex: i, zoneList: zoneList),
      builder: (ctx, cand, rej) => Container(
        decoration: cand.isNotEmpty
            ? const BoxDecoration(
                border: Border(
                    left: BorderSide(color: Color(0xFFB794F6), width: 3)))
            : null,
        child: LongPressDraggable<Note>(
          data: note,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _dragFeedback(context, note, isDark),
          childWhenDragging: Opacity(opacity: 0.3, child: swayed),
          child: swayed,
        ),
      ),
    );
    // Reorder olunca kart yeni yerine yumuşak kayar; komşular da kayar.
    // (Bırakınca _handleNoteDrop her kart için başlangıç ötelemesini verir,
    //  sonraki karede sıfıra animasyonlanır.)
    return AnimatedSlide(
      offset: _recentSlide[note.id] ?? Offset.zero,
      duration: AnimationPrefs.isOn
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      child: dragTarget,
    );
  }

  // Sürükleme sırasında parmağın altında yüzen küçük not kağıdı.
  Widget _dragFeedback(BuildContext context, Note note, bool isDark) {
    return Transform.rotate(
      angle: -0.04,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A251D) : const Color(0xFFFBF7EF),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(2, 6)),
            ],
          ),
          child: Text(
            (note.title ?? '').trim().isEmpty ? '•••' : note.title!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF3A3326)),
          ),
        ),
      ),
    );
  }

  // Sürüklenen notun bırakıldığı yere göre pin/unpin veya sıralama.
  void _handleNoteDrop(BuildContext context, Note dragged, String targetZone,
      {int? targetIndex, List<Note>? zoneList}) {
    final draggedPinned = dragged.isPinned;
    final sameZone =
        (targetZone == 'pinned') == draggedPinned; // aynı bölüm mü
    if (!sameZone) {
      // Farklı bölüme bırakıldı → pin (son→sabit) veya unpin (sabit→son).
      viewModel.togglePin(dragged.id, context);
      return;
    }
    // Aynı bölüm + bir kartın üzerine bırakıldı → sadece "son notlar"da sırala.
    if (targetZone == 'recent' && targetIndex != null && zoneList != null) {
      final from = zoneList.indexWhere((n) => n.id == dragged.id);
      if (from != -1 && from != targetIndex) {
        // Yeni sırayı simüle edip her kart için başlangıç ötelemesini hesapla
        // (eski index − yeni index = kaç slot kaydığı). Önce listeyi güncelle,
        // sonra kartları eski yerlerinde gösterip bir kare sonra sıfırla →
        // hepsi yeni yerlerine yumuşak kayar.
        final oldOrder = zoneList.map((n) => n.id).toList();
        final to = targetIndex.clamp(0, oldOrder.length - 1);
        final newOrder = List<int>.from(oldOrder);
        newOrder.insert(to, newOrder.removeAt(from));
        final slides = <int, Offset>{};
        for (var ni = 0; ni < newOrder.length; ni++) {
          final oi = oldOrder.indexOf(newOrder[ni]);
          if (oi != ni) slides[newOrder[ni]] = Offset((oi - ni).toDouble(), 0);
        }
        viewModel.reorderRecentNotes(from, targetIndex);
        setState(() {
          _recentSlide
            ..clear()
            ..addAll(slides);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _recentSlide.isNotEmpty) {
            setState(() => _recentSlide.clear());
          }
        });
      }
    }
  }

  // Boş "Son notlar" alanı: sabitli bir not sürüklenip bırakılınca sabitlemeyi
  // kaldırır (son notlara döner).
  Widget _recentDropZone(BuildContext context, Widget child) =>
      DragTarget<Note>(
        onWillAcceptWithDetails: (d) => d.data.isPinned,
        onAcceptWithDetails: (d) => _handleNoteDrop(context, d.data, 'recent'),
        builder: (ctx, cand, rej) => _dropWrap(cand.isNotEmpty, child),
      );

  // Boş "Sabitlenenler" alanı: sabitsiz bir not bırakılınca sabitler.
  Widget _pinnedDropZone(BuildContext context, Widget child) =>
      DragTarget<Note>(
        onWillAcceptWithDetails: (d) => !d.data.isPinned,
        onAcceptWithDetails: (d) => _handleNoteDrop(context, d.data, 'pinned'),
        builder: (ctx, cand, rej) => _dropWrap(cand.isNotEmpty, child),
      );

  Widget _dropWrap(bool hover, Widget child) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: hover
              ? const Color(0xFFB794F6).withOpacity(0.12)
              : Colors.transparent,
          border: hover
              ? Border.all(
                  color: const Color(0xFFB794F6).withOpacity(0.6), width: 1.5)
              : null,
        ),
        child: child,
      );

  Widget _clothespin() {
    return Container(
      width: 15,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_pinLight, _pinDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Container(
            width: 2,
            height: 18,
            color: const Color(0xFF8A6334).withOpacity(0.55)),
      ),
    );
  }

  /// Benimle paylaşılan not kartı (ana listedeki "Paylaşılanlar" şeridi).
  /// Dokununca ortak düzenleyiciyi (canlı önizleme + kilit) açar.
  Widget _sharedWithMeCard(BuildContext context, SharedNoteItem item,
      NotesDiaryViewModel viewModel, bool isDark) {
    final c = AppColors(isDark);
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: () async {
          await showSharedNoteEditor(context, item: item);
          viewModel.loadSharedNotesInfo();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: ColorConstant.accentOrange.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.group_rounded,
                      size: 14, color: ColorConstant.accentOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.canEdit
                          ? 'share.canEdit'.tr()
                          : 'share.viewOnly'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: ColorConstant.accentInk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (item.note?.title ?? '').isNotEmpty
                    ? item.note!.title!
                    : 'notes.untitledNote'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  (item.note?.content ?? '').replaceAll('\n', ' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ),
              Text('share.sharedBy'.tr(namedArgs: {'name': item.owner?.name ?? '—'}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: c.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // Sabit yükseklikli (boyutlandırılmış) kartta içeriği taşmadan kırpar;
  // otomatik yükseklikte (null) içeriği olduğu gibi bırakır.
  Widget _cardScrollWrap(double? fixedHeight, Widget child) {
    if (fixedHeight == null) return child;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: child,
    );
  }

  // Paylaşımlı not rozeti — belirgin turuncu (grup ikonu + kişi sayısı).
  Widget _sharedBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 3, top: 1),
      padding: EdgeInsets.symmetric(horizontal: count > 0 ? 5 : 4, vertical: 2),
      decoration: BoxDecoration(
        color: ColorConstant.accentOrange,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_rounded, size: 11, color: Colors.white),
          if (count > 0) ...[
            const SizedBox(width: 2),
            Text('$count',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Widget _paperCard(BuildContext context, Note note, bool isDark) {
    const w = 150.0;
    final lines = (note.content ?? '').split('\n');
    final checks = <List<dynamic>>[];
    final texts = <String>[];
    for (final l in lines) {
      if (l.startsWith('☐ ') || l.startsWith('☑ ')) {
        checks.add([l.startsWith('☑ '), l.substring(2)]);
      } else if (l.trim().isNotEmpty) {
        texts.add(l.startsWith('• ') ? l.substring(2) : l);
      }
    }
    final imgs = note.attachments.where((a) => a.isImage).toList();
    final title =
        (note.title ?? '').trim().isNotEmpty ? note.title!.trim() : 'notes.untitledNote'.tr();

    Widget preview;
    if (viewModel.isNoteLockedForMe(note)) {
      // Kilitli not: içerik/görsel gizli — yalnızca başlık + kilit göstergesi.
      preview = Row(
        children: [
          const Icon(Icons.lock_rounded,
              size: 15, color: Color(0xFF8A7A5E)),
          const SizedBox(width: 5),
          Text('notes.lockedNote'.tr(),
              style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B8A6E))),
        ],
      );
    } else if (imgs.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(imgs.first.thumbnailUrl ?? imgs.first.fileUrl,
            width: double.infinity,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                height: 78,
                color: const Color(0xFFE6ECF5),
                child: const Icon(Icons.image_rounded,
                    color: Color(0xFF9DB3D6)))),
      );
    } else if (checks.isNotEmpty) {
      preview = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in checks.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                      (e[0] as bool)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 15,
                      color: const Color(0xFF8A7A5E)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(e[1] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'JosefinSans',
                            fontSize: 15.5,
                            height: 1.1,
                            color: const Color(0xFF3A3326))),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      preview = MarkdownNoteText(
        text: texts.isEmpty ? ' ' : texts.take(4).join('\n'),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        baseStyle: const TextStyle(fontFamily: 'JosefinSans',
            fontSize: 15.5, height: 1.15, color: Color(0xFF473F2F)),
      );
    }

    // Boyutlandırma: kaydedilmiş boyut (yoksa varsayılan 150 genişlik, oto yükseklik).
    final sizes = viewModel.noteSize(note.id);
    final cardW = (sizes != null && sizes.isNotEmpty) ? sizes[0] : w;
    final double? cardH =
        (sizes != null && sizes.length >= 2) ? sizes[1] : null;
    final resizing = viewModel.resizingNoteId == note.id;
    final mq = MediaQuery.of(context).size;
    final minW = mq.width * 0.20, maxW = mq.width * 0.50;
    const minH = 60.0; // başlık + ~1 satır
    final maxH = mq.height * 0.25;

    final body = Container(
      width: cardW,
      height: cardH,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: ColorConstant.cardColorLight,
        borderRadius: BorderRadius.circular(3),
        border: resizing
            ? Border.all(color: ColorConstant.accentOrange, width: 1.6)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 9,
              offset: const Offset(2, 7)),
        ],
      ),
      child: _cardScrollWrap(
        cardH,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'JosefinSans',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: const Color(0xFF3A3326))),
                ),
                if (viewModel.isNoteShared(note.id))
                  _sharedBadge(viewModel.sharedParticipantCount(note.id)),
                if (viewModel.isNoteLockedForMe(note))
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 2),
                    child: Icon(Icons.lock_rounded,
                        size: 13, color: const Color(0xFF8A7A5E)),
                  ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: _cardMenu(
                      context, note, viewModel, isDark, AppColors(isDark)),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Sabit yükseklikte Flexible yerine doğal boyut (scroll-wrap kırpar).
            if (cardH == null) Flexible(child: preview) else preview,
            if (!viewModel.isNoteLockedForMe(note) && note.tags.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('#${note.tags.first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD1584F))),
            ],
          ],
        ),
      ),
    );

    // NOT: Basılı tutma artık sabitlemez; sürüklemeyi başlatır (LongPressDraggable
    // _hungCard'ta). Uzun basıp sabitlenenlere/son notlara sürükleyerek pin/unpin.
    final card = GestureDetector(
      onTap: resizing
          ? () => viewModel.stopResizingNote()
          : () => _openNote(context, note, isDark),
      child: body,
    );

    if (!resizing) return card;

    // Boyutlandırma modu: sağ-alt köşe tutamağı (Windows gibi) + "bitti" rozeti.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          right: 1,
          bottom: 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) {
              final cur =
                  viewModel.noteSize(note.id) ?? [cardW, cardH ?? 132.0];
              final nw = (cur[0] + d.delta.dx).clamp(minW, maxW).toDouble();
              final nh = (cur[1] + d.delta.dy).clamp(minH, maxH).toDouble();
              viewModel.updateNoteSize(note.id, nw, nh);
            },
            onPanEnd: (_) => viewModel.persistNoteSizes(),
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: ColorConstant.accentOrange,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFC96E00).withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.open_in_full_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          right: 1,
          top: 1,
          child: GestureDetector(
            onTap: () => viewModel.stopResizingNote(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF48BB78),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyPins() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Stack(
              children: [
                Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: CustomPaint(
                        size: const Size(double.infinity, 10),
                        painter: _StringPainter())),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (_) => _clothespin()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('notes.board.pinnedHint'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B8A6E))),
        ],
      ),
    );
  }

  // KLASÖRLER satırı başlığı. Büyük "Arşiv kutusu" kartı kaldırıldı; arşive
  // sağdaki küçük bağlantıdan ulaşılıyor.
  Widget _foldersHeader(BuildContext context) {
    return _boardHeader('notes.stats.folders'.tr().toUpperCase(),
        '${viewModel.categories.length}');
  }

  // Klasörler — sabitlenenler gibi ipe mandalla asılı kartlar.
  Widget _foldersClothesline(BuildContext context, bool isDark) {
    final cats = viewModel.categories;
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 14,
            child: CustomPaint(
                size: const Size(double.infinity, 12),
                painter: _StringPainter()),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final count = viewModel.notes
                  .where((n) => !n.isArchived && n.categoryId == cat.id)
                  .length;
              return _folderHungCard(context, cat, count, i, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _folderHungCard(BuildContext context, NoteCategory cat, int count,
      int i, bool isDark) {
    final locked = viewModel.isFolderLocked(cat.id);
    return _Sway(
      index: i,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _clothespin(),
          Transform.translate(
            offset: const Offset(0, -3),
            child: GestureDetector(
              onTap: () => _openFolder(context, cat, isDark),
              onLongPress: () => _showFolderActions(context, cat, isDark),
              child: Container(
                width: 132,
                height: 96,
                padding: const EdgeInsets.fromLTRB(12, 9, 6, 11),
                decoration: BoxDecoration(
                  color: ColorConstant.cardColorLight,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 9,
                        offset: const Offset(2, 7)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(cat.icon ?? '📁',
                            style: const TextStyle(fontSize: 20)),
                        if (locked)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.lock_rounded,
                                size: 14, color: Color(0xFF8A7A5E)),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6E5C42).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6E5C42))),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _showFolderActions(context, cat, isDark),
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(4, 2, 2, 2),
                            child: Icon(Icons.more_horiz_rounded,
                                size: 18, color: Color(0xFF8A7A5E)),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(cat.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: Color(0xFF3A3326))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Boş klasör durumu — boş mandallı ip + ipucu.
  Widget _emptyFoldersRope(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Stack(
              children: [
                Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: CustomPaint(
                        size: const Size(double.infinity, 10),
                        painter: _StringPainter())),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (_) => _clothespin()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('notes.folders.emptyDesc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B8A6E))),
        ],
      ),
    );
  }

  // Klasör ⋯ / uzun bas: düzenle / kilitle / sil.
  void _showFolderActions(BuildContext context, NoteCategory cat, bool isDark) {
    final c = AppColors(isDark);
    final locked = viewModel.isFolderLocked(cat.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading:
                  Text(cat.icon ?? '📁', style: const TextStyle(fontSize: 22)),
              title: Text(cat.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: c.textPrimary)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: c.textSecondary),
              title: Text('${'common.edit'.tr()} · ${cat.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showFolderDialog(context, viewModel, isDark, editing: cat);
              },
            ),
            ListTile(
              leading: Icon(
                  locked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: c.textSecondary),
              title: Text(
                  locked
                      ? 'notes.folders.unlock'.tr()
                      : 'notes.folders.lock'.tr(),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                if (locked) {
                  _confirmFolderRemoveLock(context, cat, isDark);
                } else {
                  _showFolderSetPin(context, cat, isDark);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE53E3E)),
              title: Text('common.delete'.tr(),
                  style: const TextStyle(color: Color(0xFFE53E3E))),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteFolder(context, cat, c);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openNote(BuildContext context, Note note, bool isDark) {
    if (viewModel.isNoteLockedForMe(note)) {
      // Dokunarak açmak geçicidir: çıkınca not kilitli kalır.
      _showUnlockDialog(context, note, viewModel, isDark, reLockAfter: true);
    } else {
      // Nota dokununca (checklist olsa da) doğrudan editör açılır.
      // Checklist hızlı işaretleme artık ⋯ → "Önizleme" ile açılır.
      _showEditNoteDialog(context, note, viewModel, isDark);
    }
  }

  /// Her zaman editörü açar (⋯ menüsündeki "Düzenle" için — popup'ı atlar).
  void _openNoteEditor(BuildContext context, Note note, bool isDark) {
    if (viewModel.isNoteLockedForMe(note)) {
      _showUnlockDialog(context, note, viewModel, isDark, reLockAfter: true);
    } else {
      _showEditNoteDialog(context, note, viewModel, isDark);
    }
  }

  void _showChecklistPopup(BuildContext context, Note note, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => ChangeNotifierProvider<NotesDiaryViewModel>.value(
        value: viewModel,
        child: _ChecklistPopup(
          noteId: note.id,
          isDark: isDark,
          onEdit: () {
            Navigator.pop(context);
            _openNoteEditor(context, note, isDark);
          },
        ),
      ),
    );
  }

  // Klasörü aç — kilitliyse önce PIN sorar.
  void _openFolder(BuildContext context, NoteCategory cat, bool isDark) {
    if (viewModel.isFolderLocked(cat.id)) {
      _showFolderUnlockToOpen(context, cat, isDark);
    } else {
      viewModel.setNotesFilter('folders');
      viewModel.setSelectedCategory(cat.id);
    }
  }

  // Ortak 4 haneli PIN dialogu.
  void _folderPinDialog(
    BuildContext context,
    bool isDark, {
    required String title,
    required String hint,
    required String confirmLabel,
    required void Function(String pin) onConfirm,
  }) {
    final pinController = TextEditingController();
    final bg = isDark
        ? ColorConstant.cardColorDark
        : ColorConstant.cardColorLight;
    final tp = isDark
        ? ColorConstant.textPrimaryDark
        : ColorConstant.textPrimaryLight;
    final ts = isDark
        ? ColorConstant.textSecondaryDark
        : ColorConstant.textSecondaryLight;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: TextStyle(color: tp, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint, style: TextStyle(color: ts)),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: tp),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: TextStyle(color: ts)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(ctx);
                onConfirm(pinController.text);
              }
            },
            child: Text(confirmLabel,
                style: const TextStyle(
                    color: Color(0xFFB794F6), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFolderSetPin(BuildContext context, NoteCategory cat, bool isDark) {
    _folderPinDialog(
      context,
      isDark,
      title: 'notes.folders.lock'.tr(),
      hint: 'notes.enterPinToLock'.tr(),
      confirmLabel: 'common.lock'.tr(),
      onConfirm: (pin) async {
        final overlay = Overlay.of(context, rootOverlay: true);
        await viewModel.setFolderLock(cat.id, pin);
        if (context.mounted) {
          if (AnimationPrefs.isOn) {
            _showRootOverlay(
              overlay,
              (remove) =>
                  _LockCelebrationOverlay(locking: true, onDone: remove),
            );
          }
          CustomSnackBar.showSuccess(context, 'notes.folders.locked'.tr());
        }
      },
    );
  }

  void _showFolderUnlockToOpen(
      BuildContext context, NoteCategory cat, bool isDark) {
    _folderPinDialog(
      context,
      isDark,
      title: 'notes.folders.unlockTitle'.tr(),
      hint: 'notes.folders.enterPinOpen'.tr(),
      confirmLabel: 'common.open'.tr(),
      onConfirm: (pin) {
        if (pin == viewModel.folderPin(cat.id)) {
          viewModel.setNotesFilter('folders');
          viewModel.setSelectedCategory(cat.id);
        } else if (context.mounted) {
          CustomSnackBar.showError(context, 'notes.folders.wrongPin'.tr());
        }
      },
    );
  }

  void _confirmFolderRemoveLock(
      BuildContext context, NoteCategory cat, bool isDark) {
    _folderPinDialog(
      context,
      isDark,
      title: 'notes.folders.unlock'.tr(),
      hint: 'notes.folders.enterPinRemove'.tr(),
      confirmLabel: 'notes.folders.unlock'.tr(),
      onConfirm: (pin) async {
        if (pin == viewModel.folderPin(cat.id)) {
          final overlay = Overlay.of(context, rootOverlay: true);
          await viewModel.removeFolderLock(cat.id);
          if (context.mounted) {
            if (AnimationPrefs.isOn) {
              _showRootOverlay(
                overlay,
                (remove) =>
                    _LockCelebrationOverlay(locking: false, onDone: remove),
              );
            }
            CustomSnackBar.showSuccess(context, 'notes.folders.unlocked'.tr());
          }
        } else if (context.mounted) {
          CustomSnackBar.showError(context, 'notes.folders.wrongPin'.tr());
        }
      },
    );
  }

  /// Seçili istatistik sekmesine göre gövde.
  List<Widget> _notesBody(
      BuildContext context,
      bool isDarkMode,
      String tab,
      List<Note> all,
      List<Note> pinned,
      List<Note> recent,
      List<Note> archived) {
    // Arama aktifse: sabitlenen/normal ayırmadan tüm eşleşen notları göster.
    if (viewModel.noteSearchQuery.trim().isNotEmpty) {
      // Aynı not iki kez görünmesin (id'ye göre tekilleştir).
      final seen = <int>{};
      final results = <Note>[
        for (final n in [...all, ...archived])
          if (seen.add(n.id)) n
      ];
      return [
        _sectionRow('${'notes.searchHint'.tr()} · ${results.length}',
            isDarkMode: isDarkMode),
        const SizedBox(height: 10),
        results.isEmpty
            ? _inlineEmpty(context, isDarkMode)
            : _notesGrid(context, results, isDarkMode),
      ];
    }
    switch (tab) {
      case 'pinned':
        return [
          _sectionRow('notes.pinnedSection'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          pinned.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : _notesGrid(context, pinned, isDarkMode),
        ];
      case 'archive':
        return [
          _sectionRow('notes.stats.archive'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          archived.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : _notesGrid(context, archived, isDarkMode),
        ];
      case 'folders':
        final catId = viewModel.selectedCategoryId;
        if (catId != null) {
          final inCat = all.where((n) => n.categoryId == catId).toList();
          return [
            _sectionRow('notes.stats.folders'.tr(), isDarkMode: isDarkMode),
            const SizedBox(height: 12),
            inCat.isEmpty
                ? _inlineEmpty(context, isDarkMode)
                : _notesGrid(context, inCat, isDarkMode),
          ];
        }
        return [
          _sectionRow('notes.stats.folders'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 12),
          if (viewModel.categories.isEmpty)
            _foldersEmpty(context, isDarkMode)
          else
            ...viewModel.categories.map((cat) {
              final count =
                  all.where((n) => n.categoryId == cat.id).length;
              return _folderCard(context, cat, count, isDarkMode);
            }),
        ];
      default: // all
        return [
          // Benimle paylaşılan notlar — ana listede (Paylaşım Merkezi dışında da).
          if (viewModel.sharedWithMeNotes.isNotEmpty) ...[
            _sectionRow('share.sharedWithMe'.tr(), isDarkMode: isDarkMode),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.sharedWithMeNotes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _sharedWithMeCard(
                    context, viewModel.sharedWithMeNotes[i], viewModel,
                    isDarkMode),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (pinned.isNotEmpty) ...[
            _sectionRow('notes.pinnedSection'.tr(),
                trailing: 'notes.seeAll'.tr(),
                onTrailing: () => viewModel.setNotesFilter('pinned'),
                isDarkMode: isDarkMode),
            const SizedBox(height: 10),
            // Sabitlenenler: yatay kaydırmalı, ekranda 3 kart yan yana sığar.
            Builder(builder: (context) {
              final w = MediaQuery.of(context).size.width;
              final cardW = ((w - 32 - 20) / 3).clamp(96.0, 150.0);
              return SizedBox(
                height: 146,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pinned.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _buildPinnedCard(
                      context, pinned[i], viewModel, isDarkMode,
                      width: cardW),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          _sectionRow('notes.recentSection'.tr(), isDarkMode: isDarkMode),
          const SizedBox(height: 10),
          recent.isEmpty
              ? _inlineEmpty(context, isDarkMode)
              : (viewModel.canReorderNotes
                  ? _reorderableNotesGrid(context, recent, isDarkMode)
                  : _notesGrid(context, recent, isDarkMode)),
        ];
    }
  }

  /// Klasör (kategori) kartı — dokununca o klasörün notlarını gösterir.
  Widget _folderCard(BuildContext context, NoteCategory cat, int count,
      bool isDark) {
    final c = AppColors(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openFolder(context, cat, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Text((cat.icon ?? '📁'),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                ),
                if (viewModel.isFolderLocked(cat.id))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock_rounded,
                        size: 15, color: c.textMuted),
                  ),
                Text('$count',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted)),
                // Pano ile aynı menü (düzenle/kilitle/sil) — tutarlılık için.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showFolderActions(context, cat, isDark),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.more_horiz_rounded,
                        size: 20, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteFolder(
      BuildContext context, NoteCategory cat, AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('notes.folders.deleteTitle'.tr()),
        content: Text('notes.folders.deleteConfirm'
            .tr(namedArgs: {'name': cat.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.deleteCategory(context, cat.id);
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFE53E3E))),
          ),
        ],
      ),
    );
  }

  Widget _foldersEmpty(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded,
              size: 40, color: const Color(0xFF9F7AEA).withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('notes.folders.emptyTitle'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('notes.folders.emptyDesc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }

  /// Not ızgarası boşken gösterilen kompakt satır içi boş durum.
  Widget _inlineEmpty(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.note_add_rounded,
              size: 36, color: const Color(0xFFB794F6).withOpacity(0.6)),
          const SizedBox(height: 10),
          Text('notes.emptyState'.tr(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 14),
          _emptyHint(c, Icons.note_add_rounded,
              const Color(0xFFB794F6), 'notes.add.noteDesc'.tr()),
          const SizedBox(height: 8),
          _emptyHint(c, Icons.create_new_folder_rounded,
              const Color(0xFF9F7AEA), 'notes.add.folderDesc'.tr()),
        ],
      ),
    );
  }

  Widget _emptyHint(AppColors c, IconData icon, Color accent, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
        ),
      ],
    );
  }

  /// Arama çubuğu (görsel amaçlı).
  Widget _searchBar(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: viewModel.setNoteSearchQuery,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'notes.searchHint'.tr(),
                hintStyle: TextStyle(fontSize: 15, color: c.textMuted),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showNotesFilterSheet(context, isDark),
            child: Icon(Icons.tune_rounded, size: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Filtre alt sayfası: sekmelere göre hızlı filtre.
  void _showNotesFilterSheet(BuildContext context, bool isDark) {
    final c = AppColors(isDark);
    final items = [
      ['all', Icons.notes_rounded, 'notes.stats.all'.tr()],
      ['pinned', Icons.push_pin_rounded, 'notes.stats.pinned'.tr()],
      ['folders', Icons.folder_rounded, 'notes.stats.folders'.tr()],
      ['archive', Icons.archive_rounded, 'notes.stats.archive'.tr()],
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            for (final it in items)
              ListTile(
                leading: Icon(it[1] as IconData, color: c.textSecondary),
                title: Text(it[2] as String),
                trailing: viewModel.notesFilter == it[0]
                    ? Icon(Icons.check_rounded, color: ColorConstant.accentOrange)
                    : null,
                onTap: () {
                  viewModel.setNotesFilter(it[0] as String);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String count, Color color,
      bool isDark,
      {bool filled = false, VoidCallback? onTap}) {
    final c = AppColors(isDark);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(isDark ? 0.16 : 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color:
                      filled ? Colors.white.withOpacity(0.9) : c.textSecondary,
                )),
            Text(count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: filled ? Colors.white : c.textPrimary,
                )),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionRow(String title,
      {String? trailing, VoidCallback? onTrailing, required bool isDarkMode}) {
    final c = AppColors(isDarkMode);
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: c.textPrimary,
            )),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Row(
              children: [
                Text(trailing,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ColorConstant.accentOrange,
                    )),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: ColorConstant.accentOrange),
              ],
            ),
          ),
      ],
    );
  }

  /// 3 sütunlu kompakt ızgara — sabit yükseklik, taşma yok.
  Widget _notesGrid(BuildContext context, List<Note> notes, bool isDarkMode) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 146,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) =>
          _buildPinnedCard(context, notes[i], viewModel, isDarkMode),
    );
  }

  /// "Son notlar" için sürükle-bırak sıralanabilir ızgara. Bir kartı basılı
  /// tutup sürükleyince sıra değişir ve sunucuya kaydedilir (order_index).
  Widget _reorderableNotesGrid(
      BuildContext context, List<Note> notes, bool isDarkMode) {
    return ReorderableGridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 146,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) => KeyedSubtree(
        key: ValueKey(notes[i].id),
        child: _buildPinnedCard(context, notes[i], viewModel, isDarkMode),
      ),
      onReorder: (oldIndex, newIndex) =>
          viewModel.reorderRecentNotes(oldIndex, newIndex),
    );
  }

  /// Sabitlenenler satırındaki kompakt kart — sabit yükseklik, taşma yok.
  /// Gövde Expanded + ClipRect ile kırpılır; içerik ne kadar uzun olursa olsun
  /// kart sabit yüksekliği aşmaz (hata göstergesi çıkmaz).
  Widget _buildPinnedCard(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode, {
      double? width,
      }) {
    final category = note.categoryId != null
        ? viewModel.categories.firstWhere(
            (c) => c.id == note.categoryId,
            orElse: () =>
                NoteCategory(id: 0, name: '', notesCount: 0, orderIndex: 0),
          )
        : null;
    final noteColor = _getNoteColor(note.color ?? '#B794F6');
    final c = AppColors(isDarkMode);
    final cardBg = isDarkMode
        ? Color.alphaBlend(
            noteColor.withOpacity(0.12), ColorConstant.cardColorDark)
        : Color.alphaBlend(noteColor.withOpacity(0.07), Colors.white);

    final rawLines = (note.content ?? '').split('\n');
    final checkItems = <List<dynamic>>[];
    final otherLines = <String>[];
    for (var i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      if (l.startsWith('☐ ') || l.startsWith('☑ ')) {
        checkItems.add([i, l.startsWith('☑ '), l.substring(2)]);
      } else if (l.trim().isNotEmpty) {
        otherLines.add(l.startsWith('• ') ? l.substring(2) : l);
      }
    }
    final total = checkItems.length;
    final done = checkItems.where((e) => e[1] as bool).length;
    final imgs = viewModel.imagesForNote(note.id);

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: noteColor.withOpacity(0.25)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openNote(context, note, isDarkMode),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            (note.title ?? '').isNotEmpty
                                ? note.title!
                                : (category?.name ?? ' '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.2,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (note.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 3),
                          child: Icon(Icons.push_pin_rounded,
                              size: 11, color: noteColor.withOpacity(0.9)),
                        ),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: _cardMenu(
                            context, note, viewModel, isDarkMode, c),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Küçük görsel önizleme — backend eki öncelikli, yoksa yerel.
                  // Kilitli notta görsel/ek de gizlenir (sadece başlık görünür).
                  if (!viewModel.isNoteLockedForMe(note) && note.attachments.any((a) => a.isImage)) ...[
                    Builder(builder: (_) {
                      final img =
                          note.attachments.firstWhere((a) => a.isImage);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          img.thumbnailUrl ?? img.fileUrl,
                          height: 32,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : const SizedBox(height: 32),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                  ] else if (!viewModel.isNoteLockedForMe(note) && imgs.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imgs.first),
                        height: 32,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Ek göstergeleri (ses / dosya).
                  if (!viewModel.isNoteLockedForMe(note) &&
                      note.attachments.any((a) => a.isAudio || a.isFile)) ...[
                    Row(
                      children: [
                        if (note.attachments.any((a) => a.isAudio)) ...[
                          Icon(Icons.mic_rounded,
                              size: 11, color: c.textMuted),
                          const SizedBox(width: 3),
                        ],
                        if (note.attachments.any((a) => a.isFile)) ...[
                          Icon(Icons.attach_file_rounded,
                              size: 11, color: c.textMuted),
                          const SizedBox(width: 3),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Gövde — kırpılır, asla taşmaz.
                  Expanded(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: viewModel.isNoteLockedForMe(note)
                            ? Row(children: [
                                Icon(Icons.lock_rounded,
                                    size: 12, color: c.textMuted),
                                const SizedBox(width: 4),
                                Text('notes.lockedNote'.tr(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: c.textMuted)),
                              ])
                            : total > 0
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int k = 0;
                                          k < checkItems.length && k < 3;
                                          k++)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 3),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => viewModel
                                                .toggleChecklistLine(note,
                                                    checkItems[k][0] as int),
                                            child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                  (checkItems[k][1] as bool)
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons
                                                          .radio_button_unchecked,
                                                  size: 12,
                                                  color: (checkItems[k][1]
                                                          as bool)
                                                      ? const Color(
                                                          0xFF48BB78)
                                                      : c.textMuted),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  checkItems[k][2] as String,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    height: 1.2,
                                                    color: (checkItems[k][1]
                                                            as bool)
                                                        ? c.textMuted
                                                        : c.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text('$done/$total',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: c.textSecondary)),
                                    ],
                                  )
                                : RichText(
                                    text: TextSpan(
                                      children: parseMarkdownSpans(
                                        otherLines.join('\n'),
                                        TextStyle(
                                          fontSize: 11.5,
                                          height: 1.3,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 11, color: c.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _formatDate(note.updatedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: c.textMuted),
                        ),
                      ),
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: noteColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.tags.length > 1
                                  ? '#${note.tags.first} +${note.tags.length - 1}'
                                  : '#${note.tags.first}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: c.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kart içindeki işaretlenebilir checklist satırı.

  /// Kart köşesindeki ⋯ menüsü (pin/kopya/kilit/arşiv/sil).
  Widget _cardMenu(BuildContext context, Note note,
      NotesDiaryViewModel viewModel, bool isDarkMode, AppColors c) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: c.textMuted),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        // Önizleme — en üstte; popup'ta içerik + checkbox işaretleme.
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => _showChecklistPopup(context, note, isDarkMode)),
          child: Row(children: [
            const Icon(Icons.visibility_rounded, size: 20),
            const SizedBox(width: 12),
            Text('notes.preview'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => _openNoteEditor(context, note, isDarkMode)),
          child: Row(children: [
            const Icon(Icons.edit_rounded, size: 20),
            const SizedBox(width: 12),
            Text('common.edit'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.togglePin(note.id, context)),
          child: Row(children: [
            Icon(note.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded, size: 20),
            const SizedBox(width: 12),
            Text(note.isPinned
                ? 'notes.unpinNote'.tr()
                : 'notes.pinNote'.tr()),
          ]),
        ),
        // Boyutlandır — kartı ipte sağ-alt köşeden sürükleyerek yeniden boyutla.
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.startResizingNote(note.id)),
          child: Row(children: [
            const Icon(Icons.open_in_full_rounded, size: 20),
            const SizedBox(width: 12),
            Text('notes.resizeNote'.tr()),
          ]),
        ),
        // Arkadaşla ortak paylaşım (davet gönderir).
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => showShareWithFriendsSheet(context,
                  kind: 'note', itemId: note.id)),
          child: Row(children: [
            const Icon(Icons.group_add_rounded, size: 20),
            const SizedBox(width: 12),
            Text('share.shareWithFriend'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100), () {
            if (viewModel.isNoteLockedForMe(note)) {
              _showUnlockDialog(context, note, viewModel, isDarkMode);
            } else {
              _showLockDialog(context, note, viewModel, isDarkMode);
            }
          }),
          child: Row(children: [
            Icon(viewModel.isNoteLockedForMe(note)
                ? Icons.lock_open_rounded
                : Icons.lock_rounded, size: 20),
            const SizedBox(width: 12),
            Text(viewModel.isNoteLockedForMe(note)
                ? 'notes.unlockNote'.tr()
                : 'notes.lockNote'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => viewModel.toggleArchive(note.id, context)),
          child: Row(children: [
            Icon(note.isArchived
                ? Icons.unarchive_rounded
                : Icons.archive_rounded, size: 20),
            const SizedBox(width: 12),
            Text(note.isArchived
                ? 'notes.unarchiveNote'.tr()
                : 'notes.archiveNote'.tr()),
          ]),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(const Duration(milliseconds: 100),
              () => _showDeleteNoteDialog(context, note.id, viewModel)),
          child: Row(children: [
            const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Text('common.delete'.tr(),
                style: const TextStyle(color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  void _showLockDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'notes.lockNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'notes.enterPinToLock'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                final overlay = Overlay.of(context, rootOverlay: true);
                Navigator.pop(context);
                viewModel.lockNote(note.id, pinController.text, context);
                if (AnimationPrefs.isOn) {
                  _showRootOverlay(
                    overlay,
                    (remove) =>
                        _LockCelebrationOverlay(locking: true, onDone: remove),
                  );
                }
              }
            },
            child:  Text(
              'common.lock'.tr(),
              style: TextStyle(
                color: Color(0xFFB794F6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [reLockAfter] true ise: PIN ile açılıp editör gösterilir, editör
  // kapandığında not aynı PIN ile sessizce yeniden kilitlenir (geçici
  // görüntüleme). false ise: kalıcı olarak kilidi açılır (editör açılmaz).
  void _showUnlockDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode, {
      bool reLockAfter = false,
      }) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          reLockAfter
              ? 'notes.lockedNoteDialog'.tr()
              : 'notes.unlockNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'notes.enterPin'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDarkMode
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                final pin = pinController.text;
                final overlay = Overlay.of(context, rootOverlay: true);
                Navigator.pop(dialogCtx);

                if (reLockAfter) {
                  // Geçici görüntüleme: aç → editörü göster → kapanınca
                  // aynı PIN ile sessizce yeniden kilitle.
                  viewModel.unlockNote(
                    note.id,
                    pin,
                    context,
                    () {
                      Future.delayed(const Duration(milliseconds: 300),
                          () async {
                        if (!context.mounted) return;
                        // Kilidi açılmış (içerikli) taze notu editöre ver.
                        final fresh = viewModel.notes.firstWhere(
                            (n) => n.id == note.id,
                            orElse: () => note);
                        await _showEditNoteDialog(
                            context, fresh, viewModel, isDarkMode);
                        if (context.mounted) {
                          await viewModel.lockNote(note.id, pin, context,
                              silent: true);
                        }
                      });
                    },
                    silent: true,
                  );
                } else {
                  // Kalıcı kilit açma: editör açılmaz, not açık kalır.
                  viewModel.unlockNote(note.id, pin, context, null);
                  if (AnimationPrefs.isOn) {
                    _showRootOverlay(
                      overlay,
                      (remove) => _LockCelebrationOverlay(
                          locking: false, onDone: remove),
                    );
                  }
                }
              }
            },
            child: Text(
              reLockAfter ? 'common.open'.tr() : 'notes.unlockNote'.tr(),
              style: const TextStyle(
                color: Color(0xFFB794F6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNoteDialog(
      BuildContext context,
      Note note,
      NotesDiaryViewModel viewModel,
      bool isDarkMode,
      ) {
    // Düzenleme de aynı zengin editörle yapılır.
    viewModel.setNoteForEdit(note);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddNoteBottomSheet(
        viewModel: viewModel,
        isDarkMode: isDarkMode,
        isEditing: true,
      ),
    );
  }

  void _showDeleteNoteDialog(
      BuildContext context,
      int noteId,
      NotesDiaryViewModel viewModel,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'notes.deleteNote'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'notes.deleteNoteConfirm'.tr(),
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textSecondaryDark
                : ColorConstant.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode
                    ? ColorConstant.textSecondaryDark
                    : ColorConstant.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteNote(noteId, context);
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (e) {
      return const Color(0xFFB794F6);
    }
  }

  // Sticky-note yardımcıları artık dosya sonunda top-level fonksiyon
  // (hem not hem günlük kartları paylaşıyor): _stickyFill/_stickyFold/_stickyInk

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'common.today'.tr();
    } else if (difference.inDays == 1) {
      return 'common.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'common.daysAgo'.tr(namedArgs: {'count': '${difference.inDays}'});
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

// ==================== GÜNLÜK İÇERİĞİ ====================

/// Çok satırlı not içeriğinde liste sürekliliği: bir madde (•), onay-kutusu
/// (☐/☑) veya numaralı satırdayken Enter'a basınca aynı işaret otomatik
/// devam eder; boş bir madde satırında Enter'a basınca işaret silinip
/// listeden çıkılır (maddelerdeki gibi).
class NoteListContinuationFormatter extends TextInputFormatter {
  static final RegExp _checkPrefix = RegExp(r'^(☐ |☑ )');
  static final RegExp _bulletPrefix = RegExp(r'^• ');
  static final RegExp _numberPrefix = RegExp(r'^(\d+)\. ');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Yalnızca tek bir '\n' eklendiğinde (Enter'a basıldığında) devreye gir.
    if (newValue.text.length != oldValue.text.length + 1) return newValue;
    final caret = newValue.selection.baseOffset;
    if (caret <= 0 || caret > newValue.text.length) return newValue;
    if (newValue.text[caret - 1] != '\n') return newValue;

    // Enter'ın basıldığı (yeni satırdan önceki) satırı bul.
    final before = newValue.text.substring(0, caret - 1);
    final lineStart = before.lastIndexOf('\n') + 1;
    final line = before.substring(lineStart);

    String? prefix;
    String contentAfterPrefix = line;
    final mNumber = _numberPrefix.firstMatch(line);
    if (_checkPrefix.hasMatch(line)) {
      prefix = '☐ '; // devam ederken daima işaretsiz kutu
      contentAfterPrefix = line.substring(2);
    } else if (_bulletPrefix.hasMatch(line)) {
      prefix = '• ';
      contentAfterPrefix = line.substring(2);
    } else if (mNumber != null) {
      final n = int.tryParse(mNumber.group(1)!) ?? 0;
      prefix = '${n + 1}. ';
      contentAfterPrefix = line.substring(mNumber.group(0)!.length);
    }
    if (prefix == null) return newValue;

    // Boş madde satırında Enter: işareti kaldır, listeden çık.
    if (contentAfterPrefix.trim().isEmpty) {
      final newText = newValue.text.replaceRange(lineStart, caret, '');
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }

    // İşareti yeni satıra ekle.
    final newText = newValue.text.replaceRange(caret, caret, prefix);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret + prefix.length),
    );
  }
}

/// Hex renk ('#RRGGBB') → Color. Hatalıysa varsayılan mor.
Color noteColorFromHex(String colorHex) {
  try {
    return Color(int.parse(colorHex.replaceAll('#', 'FF'), radix: 16));
  } catch (_) {
    return const Color(0xFFB794F6);
  }
}

/// Checklist'li notu dokununca açılan hızlı işaretleme popup'ı. Düzenleme
/// YOK — yalnızca kutular tıklanır (alışveriş listesi gibi pratik). İşaretli
/// olanlar solar ve en alta iner; işaretsizler üstte kalır.
class _ChecklistPopup extends StatelessWidget {
  final int noteId;
  final bool isDark;
  final VoidCallback onEdit;
  const _ChecklistPopup({
    required this.noteId,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(isDark);
    return Consumer<NotesDiaryViewModel>(
      builder: (context, vm, _) {
        final idx = vm.notes.indexWhere((n) => n.id == noteId);
        if (idx == -1) return const SizedBox.shrink();
        final note = vm.notes[idx];
        final accent = noteColorFromHex(note.color ?? '#B794F6');
        final lines = (note.content ?? '').split('\n');

        // [lineIndex, type('check'|'text'), checked, text] — TÜM satırlar.
        // N1: önizlemede tüm not gösterilir (checkbox + düz metin).
        final items = <List<dynamic>>[];
        for (var i = 0; i < lines.length; i++) {
          final l = lines[i];
          if (l.startsWith('☐ ')) {
            items.add([i, 'check', false, l.substring(2)]);
          } else if (l.startsWith('☑ ')) {
            items.add([i, 'check', true, l.substring(2)]);
          } else if (l.trim().isNotEmpty) {
            items.add(
                [i, 'text', false, l.startsWith('• ') ? l.substring(2) : l]);
          }
        }
        // N3: checkbox işaretlenince yeniden SIRALAMA YOK — not düzeni sabit.
        final ordered = items;
        final checkItems = items.where((e) => e[1] == 'check').toList();
        final total = checkItems.length;
        final done = checkItems.where((e) => e[2] as bool).length;

        return Dialog(
          backgroundColor:
              isDark ? ColorConstant.cardColorDark : const Color(0xFFF6F4EF),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst tutma çubuğu (daha düzgün görünüm)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 2),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Başlık + ilerleme
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 10, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (note.title ?? '').isNotEmpty
                              ? note.title!
                              : 'notes.editor.checklistTitle'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      // Metni kopyala (önizlemede de kopyalanabilir).
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: Icon(Icons.content_copy_rounded,
                              color: c.textSecondary),
                          onPressed: () {
                            final t =
                                cleanNoteMarkers(note.content ?? '').trim();
                            if (t.isEmpty) return;
                            Clipboard.setData(ClipboardData(text: t));
                            CustomSnackBar.showSuccess(
                                context, 'notes.copiedText'.tr());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 22,
                          icon: Icon(Icons.close_rounded,
                              color: c.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : done / total,
                              minHeight: 7,
                              backgroundColor: c.border.withOpacity(0.5),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$done/$total',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary)),
                      ],
                    ),
                  ),
                Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6)),
                // N1: tüm not (checkbox + düz metin), N3: yeniden sıralama yok.
                Flexible(
                  child: ordered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('notes.board.noNotes'.tr(),
                                style: TextStyle(
                                    fontSize: 14, color: c.textMuted)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: ordered.length,
                          itemBuilder: (ctx, k) {
                            final lineIndex = ordered[k][0] as int;
                            final type = ordered[k][1] as String;
                            final rawText = (ordered[k][3] as String).trim();
                            // Düz metin satırı — seçilebilir (kopyalanabilir).
                            if (type == 'text') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 7),
                                child: SelectableText(
                                  rawText,
                                  style: TextStyle(
                                      fontSize: 15.5,
                                      height: 1.4,
                                      color: c.textPrimary),
                                ),
                              );
                            }
                            final isChecked = ordered[k][2] as bool;
                            final isEmpty = rawText.isEmpty;
                            final Color textColor = isEmpty
                                ? c.textMuted
                                : (isChecked
                                    ? c.textSecondary
                                    : c.textPrimary);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    vm.toggleChecklistLine(note, lineIndex),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 11),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 180),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? accent
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isChecked
                                                ? accent
                                                : c.textSecondary.withValues(
                                                    alpha: 0.7),
                                            width: 2,
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(Icons.check_rounded,
                                                size: 19,
                                                color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          isEmpty ? '—' : rawText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            color: textColor,
                                            decoration: isChecked
                                                ? TextDecoration.lineThrough
                                                : null,
                                            decorationColor: c.textSecondary
                                                .withValues(alpha: 0.7),
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6)),
                // Düzenle butonu (tam editör)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text('common.edit'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withOpacity(0.6)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sesli dikte alt sayfası: cihaz-içi konuşma tanıma ile konuşulanı metne çevirir.
class _DictationSheet extends StatefulWidget {
  final String localeId;
  final void Function(String text) onInsert;
  const _DictationSheet({required this.localeId, required this.onInsert});

  @override
  State<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends State<_DictationSheet> {
  final SttService _stt = SttService();
  String _committed = '';
  String _partial = '';
  bool _listening = false;
  bool _initFailed = false;

  // Dikte sayfası aksanı — seçili temadan.
  Color get _accent => ColorConstant.accentOrange;

  String get _display => [
        if (_committed.isNotEmpty) _committed,
        if (_partial.isNotEmpty) _partial,
      ].join(' ').trim();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!_stt.isAvailable) {
      final ok = await _stt.init(
        onStatus: (s) {
          if (!mounted) return;
          final listening = s == 'listening';
          if (listening != _listening) setState(() => _listening = listening);
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!ok) {
        if (mounted) setState(() => _initFailed = true);
        return;
      }
    }
    await _stt.start(
      localeId: widget.localeId,
      onResult: (words, isFinal) {
        if (mounted) setState(() => _partial = words);
      },
    );
    if (mounted) setState(() => _listening = true);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _stt.stop();
      if (mounted) {
        setState(() {
          _committed = _display;
          _partial = '';
          _listening = false;
        });
      }
    } else {
      if (_partial.isNotEmpty) {
        _committed = _display;
        _partial = '';
      }
      await _start();
    }
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors(isDark);
    final text = _display;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: _accent, size: 22),
                const SizedBox(width: 8),
                Text('notes.dictation.title'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_initFailed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('notes.dictation.unavailable'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary)),
              )
            else ...[
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_listening ? _accent : c.textSecondary)
                        .withOpacity(_listening ? 0.18 : 0.10),
                  ),
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _listening ? _accent : c.textSecondary,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _listening
                    ? 'notes.dictation.listening'.tr()
                    : 'notes.dictation.paused'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(minHeight: 70, maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border.withOpacity(0.6)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    text.isEmpty ? 'notes.dictation.hint'.tr() : text,
                    style: TextStyle(
                      color: text.isEmpty ? c.textSecondary : c.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggle,
                      icon: Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 20),
                      label: Text(_listening
                          ? 'notes.dictation.stop'.tr()
                          : 'notes.dictation.start'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: BorderSide(color: _accent.withOpacity(0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: text.isEmpty
                          ? null
                          : () {
                              widget.onInsert(text);
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text('notes.dictation.add'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Editör alt çubuğundaki ekleme çipi (checklist / madde işareti).

// ==================== NOT EKLEME BOTTOM SHEET ====================
/// Tam ekran resim görüntüleyici — thumbnail'a dokununca açılır.
/// Yakınlaştırma (pinch) + alt çubukta Kaydet / Paylaş / Sil seçenekleri.
/// Hem backend (network) hem yerel (File) görseller için çalışır.
void _openImageViewer(
  BuildContext context, {
  String? networkUrl,
  File? file,
  VoidCallback? onDelete,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ImageViewerPage(
        networkUrl: networkUrl,
        file: file,
        onDelete: onDelete,
      ),
    ),
  );
}

class _ImageViewerPage extends StatefulWidget {
  final String? networkUrl;
  final File? file;
  final VoidCallback? onDelete;
  const _ImageViewerPage({this.networkUrl, this.file, this.onDelete});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  bool _busy = false;

  /// Paylaşım/kaydetme için yerel bir dosya döndürür.
  /// Network görselini geçici klasöre indirir.
  Future<File?> _resolveLocalFile() async {
    if (widget.file != null) return widget.file;
    final url = widget.networkUrl;
    if (url == null) return null;
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      var name = url.split('/').last.split('?').first;
      if (name.isEmpty || !name.contains('.')) {
        name = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(resp.bodyBytes);
      return f;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveOrShare() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final f = await _resolveLocalFile();
      if (f == null) {
        if (mounted) {
          CustomSnackBar.showError(context, 'errors.generic'.tr());
        }
        return;
      }
      // Sistem paylaşım sayfası: "Fotoğraflara Kaydet" / "Dosyalara Kaydet".
      await Share.shareXFiles([XFile(f.path)]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget img = widget.file != null
        ? Image.file(widget.file!, fit: BoxFit.contain)
        : Image.network(
            widget.networkUrl ?? '',
            fit: BoxFit.contain,
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 48),
            ),
          );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(child: img),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _viewerAction(
                    icon: Icons.download_rounded,
                    label: 'common.save'.tr(),
                    onTap: _busy ? null : _saveOrShare,
                  ),
                  _viewerAction(
                    icon: Icons.ios_share_rounded,
                    label: 'notes.editor.share'.tr(),
                    onTap: _busy ? null : _saveOrShare,
                  ),
                  if (widget.onDelete != null)
                    _viewerAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'common.delete'.tr(),
                      danger: true,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewerAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFFF6B6B) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Kaydet butonu — tıklanınca anında "Kaydediliyor…" durumuna geçer,
/// tekrar basılmayı engeller (çift kayıt fix) ve bitince yeni not için
/// yeşil onay + panoya uçuş animasyonunu (kök overlay) tetikler.
class _SaveNoteButton extends StatefulWidget {
  final NotesDiaryViewModel vm;
  final bool isEditing;
  final Color accent;
  final Color accentDark;
  const _SaveNoteButton({
    required this.vm,
    required this.isEditing,
    required this.accent,
    required this.accentDark,
  });

  @override
  State<_SaveNoteButton> createState() => _SaveNoteButtonState();
}

class _SaveNoteButtonState extends State<_SaveNoteButton> {
  bool _saving = false;

  Future<void> _onTap() async {
    // Çift tık / çoklu kayıt engeli: zaten kaydediliyorsa yok say.
    if (_saving || widget.vm.isSavingNote) return;
    setState(() => _saving = true);
    // createNote sayfayı kendisi kapattığı için overlay referansını önceden al.
    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      if (widget.isEditing) {
        await widget.vm.updateNote(context);
      } else {
        await widget.vm.createNote(context);
        if (widget.vm.consumeJustCreated() && AnimationPrefs.isOn) {
          _showRootOverlay(
            overlay,
            (remove) => _SaveCelebrationOverlay(onDone: remove),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [widget.accent, widget.accentDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _saving
              ? [
                  BoxShadow(
                    color: widget.accentDark.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: _saving
              ? Row(
                  key: const ValueKey('saving'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('notes.editor.saving'.tr(),
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('common.save'.tr(),
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AddNoteBottomSheet extends StatelessWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;
  final bool isEditing;

  const _AddNoteBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    this.isEditing = false,
  });

  // Not editörü aksanı — seçili temadan (sabit turuncu yerine).
  Color get _accent => ColorConstant.accentOrange;
  Color get _accentDark => Color.alphaBlend(
      Colors.black.withValues(alpha: 0.28), ColorConstant.accentOrange);
  static const Color _green = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          final c = AppColors(isDarkMode);
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? ColorConstant.bgColorDark
                  : const Color(0xFFF6F4EF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _topBar(context, vm, c),
                  _metaChips(context, vm, c),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: _editorCard(context, vm, c),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _EditorToolbar(
                      c: c,
                      accent: _accent,
                      accentDark: _accentDark,
                      controller: vm.noteContentController,
                      boldActive: vm.boldMode,
                      italicActive: vm.italicMode,
                      reminderLabel: vm.noteReminder != null
                          ? '${vm.noteReminder!.day}.${vm.noteReminder!.month} ${vm.noteReminder!.hour.toString().padLeft(2, '0')}:${vm.noteReminder!.minute.toString().padLeft(2, '0')}'
                          : null,
                      onBold: () => _toggleFormat(vm, '**', 'bold'),
                      onItalic: () => _toggleFormat(vm, '*', 'italic'),
                      onBullet: () => _toggleListPrefix(vm, 'bullet'),
                      onNumbered: () => _toggleListPrefix(vm, 'numbered'),
                      onCheckbox: () => _toggleListPrefix(vm, 'checkbox'),
                      onCopyText: () => _copySelectedText(context, vm),
                      onMic: () => _showDictationSheet(context, vm),
                      onCamera: () => vm.pickNoteImage(ImageSource.camera),
                      onPhoto: () => vm.pickNoteImage(ImageSource.gallery),
                      onFile: () => _pickFile(context, vm),
                      onDraw: () => _openDrawingPad(context, vm),
                      onScan: () => vm.pickNoteImage(ImageSource.camera),
                      onReminder: () => _pickReminder(context, vm),
                      onShare: () => _shareNote(context, vm),
                      onShareCollab: () => _shareNoteCollab(context, vm),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Üst çubuk ----------
  Widget _topBar(BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new_rounded, c, () {
            vm.resetNoteForm();
            Navigator.pop(context);
          }),
          Expanded(
            child: Text(
              isEditing ? 'notes.editor.editNote'.tr() : 'notes.newNote'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          // Sabitle — kaydedince notu sabitler
          _circleBtn(
            vm.notePinned ? Icons.push_pin : Icons.push_pin_outlined,
            c,
            () {
              vm.toggleNotePinned();
              _toast(context,
                  vm.notePinned ? 'notes.editor.willPin'.tr() : 'notes.editor.unpinned'.tr());
            },
            active: vm.notePinned,
          ),
          const SizedBox(width: 8),
          _SaveNoteButton(
            vm: vm,
            isEditing: isEditing,
            accent: _accent,
            accentDark: _accentDark,
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, AppColors c, VoidCallback onTap,
      {bool active = false}) {
    return Material(
      color: active ? _accent.withOpacity(0.15) : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: active ? _accent : c.border.withOpacity(0.7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 19, color: active ? _accentDark : c.textPrimary),
        ),
      ),
    );
  }

  // ---------- Klasör / kilit / durum çipleri ----------
  Widget _metaChips(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    // Seçili kategorinin adı (yoksa "Kişisel")
    String folderLabel = 'notes.editor.personal'.tr();
    if (vm.selectedCategoryForNote != null) {
      final cat = vm.categories.where(
          (e) => e.id == vm.selectedCategoryForNote);
      if (cat.isNotEmpty) folderLabel = cat.first.name;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metaChip(Icons.folder_rounded, folderLabel, c,
                      trailing: true, onTap: () => _pickCategory(context, vm)),
                  const SizedBox(width: 8),
                  _metaChip(
                    vm.noteLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    vm.noteLocked
                        ? 'notes.editor.locked'.tr()
                        : 'notes.editor.unlocked'.tr(),
                    c,
                    trailing: true,
                    active: vm.noteLocked,
                    onTap: () {
                      if (vm.noteLocked) {
                        vm.setNoteLockPin(null);
                        _toast(context, 'notes.editor.lockRemoved'.tr());
                      } else {
                        _showEditorLockDialog(context, vm, isDarkMode);
                      }
                    },
                  ),
                  // Paylaşımlı not ise: kaç kişiyle paylaşıldığı + son düzenleme.
                  // (Paylaşım başlatma artık + menüsündeki "Paylaşımlı not"tan.)
                  if (vm.editingNoteId != null &&
                      vm.isNoteShared(vm.editingNoteId!))
                    ...[
                    const SizedBox(width: 8),
                    _sharedInfoChip(context, vm, c),
                  ],
                ],
              ),
            ),
          ),
          // "Şimdi düzenleniyor" — YALNIZCA paylaşımlı notta göster.
          if (vm.editingNoteId != null &&
              vm.isNoteShared(vm.editingNoteId!)) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'notes.editor.editingNow'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Paylaşımlı not bilgi çipi: kaç kişiyle paylaşıldığı + son düzenleme zamanı.
  /// Dokununca paylaşım yönetimini (arkadaş listesi) açar.
  Widget _sharedInfoChip(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    final nid = vm.editingNoteId!;
    final count = vm.sharedParticipantCount(nid);
    final matches = vm.notes.where((n) => n.id == nid);
    final updated = matches.isNotEmpty ? matches.first.updatedAt : null;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _shareNoteCollab(context, vm),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_rounded, size: 15, color: _accentDark),
              const SizedBox(width: 5),
              Text(
                '$count ${'notes.editor.people'.tr()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accentDark,
                ),
              ),
              if (updated != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.schedule_rounded, size: 13, color: c.textMuted),
                const SizedBox(width: 4),
                Text(
                  fmt(updated),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, AppColors c,
      {bool trailing = false, bool active = false, VoidCallback? onTap}) {
    return Material(
      color: active ? _accent.withOpacity(0.14) : c.card,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: active ? _accent : c.border.withOpacity(0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15,
                  color: active ? _accentDark : c.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? _accentDark : c.textPrimary,
                ),
              ),
              if (trailing) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: c.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Kategori seçimi (klasör) — alt sayfa.
  void _pickCategory(BuildContext context, NotesDiaryViewModel vm) {
    final c = AppColors(isDarkMode);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.folder_open_rounded, color: c.textSecondary),
              title: Text('notes.editor.noCategory'.tr()),
              trailing: vm.selectedCategoryForNote == null
                  ? Icon(Icons.check_rounded, color: _accentDark)
                  : null,
              onTap: () {
                vm.setSelectedCategoryForNote(null);
                Navigator.pop(ctx);
              },
            ),
            for (final cat in vm.categories)
              ListTile(
                leading: Text(cat.icon ?? '📁',
                    style: const TextStyle(fontSize: 20)),
                title: Text(cat.name),
                trailing: vm.selectedCategoryForNote == cat.id
                    ? Icon(Icons.check_rounded, color: _accentDark)
                    : null,
                onTap: () {
                  vm.setSelectedCategoryForNote(cat.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Hatırlatıcı — tarih + saat seçimi.
  Future<void> _pickReminder(
      BuildContext context, NotesDiaryViewModel vm) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
    vm.setNoteReminder(dt);
    if (context.mounted) {
      _toast(context,
          'notes.editor.reminderSet'.tr(namedArgs: {
        'date':
            '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
      }));
    }
  }

  // ---------- Editör kartı ----------
  Widget _editorCard(
      BuildContext context, NotesDiaryViewModel vm, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.0 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık (işlevsel)
          TextField(
            controller: vm.noteTitleController,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: c.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'notes.noteTitle'.tr(),
              hintStyle: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: c.textMuted.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: c.border.withOpacity(0.6)),
          const SizedBox(height: 16),

          // Etiketler (serbest biçimli) — chip listesi + ekle
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final t in vm.editTags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB794F6).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('#$t',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => vm.removeTag(t),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () => _showAddTagDialog(context, vm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 15, color: c.textSecondary),
                      const SizedBox(width: 3),
                      Text('notes.tagsAdd'.tr(),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notun eski yerel görselleri — yalnız backend eki YOKSA gösterilir
          // (çift gösterimi önler; yeni notlar backend eklerini kullanır).
          if (vm.editingExistingImages.isNotEmpty &&
              vm.editingNoteAttachments.isEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < vm.editingExistingImages.length; i++)
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageViewer(
                          context,
                          file: File(vm.editingExistingImages[i]),
                          onDelete: () => vm.removeExistingImage(i),
                        ),
                        child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(vm.editingExistingImages[i]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: c.card,
                            child: Icon(Icons.broken_image_rounded,
                                color: c.textMuted),
                          ),
                        ),
                      )),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => vm.removeExistingImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Kayıtlı (backend) ekler — düzenlemede gösterilir; başka cihazdan
          // eklenmiş olanlar da buradan görünür/silinir.
          if (vm.editingNoteAttachments.isNotEmpty) ...[
            Builder(builder: (ctx) {
              final atts = vm.editingNoteAttachments;
              final imgs = atts.where((a) => a.isImage).toList();
              final auds = atts.where((a) => a.isAudio).toList();
              final files = atts.where((a) => a.isFile).toList();
              final noteId = vm.editingNoteId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imgs.isNotEmpty) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final a in imgs)
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _openImageViewer(
                                  ctx,
                                  networkUrl: a.fileUrl,
                                  onDelete: noteId != null
                                      ? () => vm.removeAttachment(
                                          noteId, a.id, ctx)
                                      : null,
                                ),
                                child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  a.thumbnailUrl ?? a.fileUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, prog) =>
                                      prog == null
                                          ? child
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              color: c.card,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                            ),
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    height: 100,
                                    color: c.card,
                                    child: Icon(Icons.broken_image_rounded,
                                        color: c.textMuted),
                                  ),
                                ),
                              )),
                              if (noteId != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        vm.removeAttachment(noteId, a.id, ctx),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final a in auds) ...[
                    _VoiceNoteChip(
                      path: a.fileUrl,
                      isNetwork: true,
                      durationSeconds: a.durationSeconds,
                      onRemove: noteId == null
                          ? () {}
                          : () => vm.removeAttachment(noteId, a.id, ctx),
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final a in files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border.withOpacity(0.8)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file_rounded,
                                size: 18, color: c.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary),
                              ),
                            ),
                            if (noteId != null)
                              GestureDetector(
                                onTap: () =>
                                    vm.removeAttachment(noteId, a.id, ctx),
                                child: Icon(Icons.close_rounded,
                                    size: 18, color: c.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],

          // Eklenen görseller (Fotoğraf/Kamera ile seçilenler)
          if (vm.pickedImages.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < vm.pickedImages.length; i++)
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openImageViewer(
                          context,
                          file: vm.pickedImages[i],
                          onDelete: () => vm.removePickedImage(i),
                        ),
                        child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          vm.pickedImages[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => vm.removePickedImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Ses kaydı durumu / kaydedilmiş ses notu
          if (vm.isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF5350)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('notes.editor.recording'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF5350))),
                  ),
                  GestureDetector(
                    onTap: () => vm.toggleRecording(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('notes.editor.stop'.tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (vm.voiceNotePath != null) ...[
            _VoiceNoteChip(
              path: vm.voiceNotePath!,
              onRemove: () => vm.removeVoiceNote(),
            ),
            const SizedBox(height: 16),
          ],

          // Eklenen dosyalar
          if (vm.pickedFiles.isNotEmpty) ...[
            for (int i = 0; i < vm.pickedFiles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border.withOpacity(0.8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_rounded,
                          size: 18, color: c.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vm.pickedFiles[i].path.split(Platform.pathSeparator).last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => vm.removePickedFile(i),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // Gerçek, işlevsel içerik alanı. Araç çubuğundaki liste/onay-kutusu
          // butonları buraya madde ekler; kaydedilince kartta işaretlenebilir.
          TextField(
            controller: vm.noteContentController,
            focusNode: vm.noteContentFocus,
            inputFormatters: [NoteListContinuationFormatter()],
            maxLines: null,
            minLines: 10,
            cursorColor: _accent,
            // İmleç araç çubuğunun üstünde rahat görünsün diye geniş pay.
            scrollPadding: const EdgeInsets.only(bottom: 160),
            style: TextStyle(fontSize: 16, height: 1.55, color: c.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText:
                  'notes.editor.startWriting'.tr(),
              hintStyle: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: c.textMuted.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili metni (yoksa tüm içeriği) panoya kopyalar — araç çubuğundaki
  /// "metni kopyala" ikonu için. Markdown işaretleri temizlenir.
  void _copySelectedText(BuildContext context, NotesDiaryViewModel vm) {
    final ctrl = vm.noteContentController;
    final sel = ctrl.selection;
    String text;
    if (sel.isValid && !sel.isCollapsed) {
      text = ctrl.text.substring(sel.start, sel.end);
    } else {
      text = ctrl.text; // seçim yoksa tümünü kopyala
    }
    text = cleanNoteMarkers(text).trim();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _toast(context, 'notes.copiedText'.tr());
  }

  /// Madde (•) / numara (1.) / onay-kutusu (☐) aç-kapa. İmlecin bulunduğu
  /// SATIRA uygulanır: satırda o işaret varsa kaldırır (kapat), yoksa ekler
  /// (farklı liste işareti varsa onunla değiştirir).
  void _toggleListPrefix(NotesDiaryViewModel vm, String kind) {
    vm.noteContentFocus.requestFocus();
    final ctrl = vm.noteContentController;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final caret =
        (sel.isValid && sel.baseOffset >= 0) ? sel.baseOffset : text.length;

    final lineStart = caret <= 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd < 0) lineEnd = text.length;
    final line = text.substring(lineStart, lineEnd);

    // Mevcut liste işareti.
    String? currentKind;
    int currentLen = 0;
    if (line.startsWith('☐ ') || line.startsWith('☑ ')) {
      currentKind = 'checkbox';
      currentLen = 2;
    } else if (line.startsWith('• ')) {
      currentKind = 'bullet';
      currentLen = 2;
    } else {
      final m = RegExp(r'^(\d+)\. ').firstMatch(line);
      if (m != null) {
        currentKind = 'numbered';
        currentLen = m.group(0)!.length;
      }
    }

    String newLine;
    int caretDelta;
    if (currentKind == kind) {
      // Kapat: işareti kaldır.
      newLine = line.substring(currentLen);
      caretDelta = -currentLen;
    } else {
      // Aç/değiştir: varsa eski işareti at, yeni işareti ekle.
      final bare = currentKind != null ? line.substring(currentLen) : line;
      String newPrefix;
      if (kind == 'checkbox') {
        newPrefix = '☐ ';
      } else if (kind == 'bullet') {
        newPrefix = '• ';
      } else {
        // Numara: önceki satırlardaki en büyük numaranın bir fazlası.
        var maxN = 0;
        for (final l in text.substring(0, lineStart).split('\n')) {
          final mm = RegExp(r'^(\d+)\.\s').firstMatch(l.trimLeft());
          if (mm != null) {
            final n = int.tryParse(mm.group(1)!) ?? 0;
            if (n > maxN) maxN = n;
          }
        }
        newPrefix = '${maxN + 1}. ';
      }
      newLine = '$newPrefix$bare';
      caretDelta = newPrefix.length - currentLen;
    }

    final newText = text.replaceRange(lineStart, lineEnd, newLine);
    final newCaret =
        (caret + caretDelta).clamp(lineStart, lineStart + newLine.length);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
  }

  /// Biçimlendirme aç/kapa (kalın=** , italik=*).
  /// - Seçim varsa: seçili metni tek seferlik sarar.
  /// - Seçim yoksa: "aktif" moda geçer; işaretçi çiftini ekleyip imleci
  ///   ortaya alır, böylece yazılan metin o biçimde olur. Tekrar basınca
  ///   mod kapanır (boş işaretçi çifti kaldırılır veya imleç dışarı alınır).
  void _toggleFormat(NotesDiaryViewModel vm, String marker, String kind) {
    vm.noteContentFocus.requestFocus();
    final ctrl = vm.noteContentController;
    final text = ctrl.text;
    final sel = ctrl.selection;

    // Seçim varsa: tek seferlik sar.
    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final newText =
          text.replaceRange(sel.start, sel.end, '$marker$selected$marker');
      ctrl.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: sel.end + marker.length * 2),
      );
      return;
    }

    final bool active = kind == 'bold' ? vm.boldMode : vm.italicMode;
    final int pos = sel.isValid ? sel.start : text.length;
    final int mlen = marker.length;

    if (!active) {
      // AÇ: işaretçi çiftini ekle, imleci ortaya al → yazılan metin biçimli olur.
      final newText = text.replaceRange(pos, pos, '$marker$marker');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + mlen),
      );
      vm.setFormatMode(
        bold: kind == 'bold' ? true : null,
        italic: kind == 'italic' ? true : null,
      );
    } else {
      // KAPAT → düz yazıya dön. İmleci, O AN AKTİF olan TÜM biçimlerin kapanış
      // işaretçilerinin dışına al; böylece yazılmış içerik biçimli KALIR, yeni
      // yazılacaklar düz olur. (Kalın+italik birlikteyken kapanış: *** gibi.)
      final String closeAll =
          (vm.boldMode ? '**' : '') + (vm.italicMode ? '*' : '');
      if (closeAll.isNotEmpty &&
          pos + closeAll.length <= text.length &&
          text.substring(pos, pos + closeAll.length) == closeAll) {
        final bool emptyPair = pos >= closeAll.length &&
            text.substring(pos - closeAll.length, pos) == closeAll;
        if (emptyPair) {
          // İçi boş çift (hiç yazılmadı) → tamamen kaldır.
          final newText = text.replaceRange(
              pos - closeAll.length, pos + closeAll.length, '');
          ctrl.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: pos - closeAll.length),
          );
        } else {
          // İmleci tüm kapanışın dışına al (içerik biçimli kalır).
          ctrl.selection =
              TextSelection.collapsed(offset: pos + closeAll.length);
        }
      }
      // Kapatınca düz yazıya dönülür (her iki mod da kapanır).
      vm.clearFormatModes();
    }
  }

  /// Ortak (arkadaşla) paylaşım: notun kaydedilmiş olması gerekir (id lazım).
  /// Yeni not ise önce kaydetmesi için uyarır; düzenlenen notta arkadaş
  /// listesini açar.
  void _shareNoteCollab(BuildContext context, NotesDiaryViewModel vm) {
    final id = vm.editingNoteId;
    if (id == null) {
      _toast(context, 'share.saveNoteFirst'.tr());
      return;
    }
    showShareWithFriendsSheet(context, kind: 'note', itemId: id);
  }

  /// Sesli dikte alt sayfasını açar; tanınan metni not içeriğine ekler.
  void _showDictationSheet(BuildContext context, NotesDiaryViewModel vm) {
    final localeId = SttService.localeIdFor(context.locale.languageCode);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DictationSheet(
        localeId: localeId,
        onInsert: (text) {
          if (text.trim().isEmpty) return;
          vm.noteContentFocus.requestFocus();
          _insertDictatedText(vm.noteContentController, text.trim());
        },
      ),
    );
  }

  /// Dikte edilen metni imleç konumuna ekler (gerekirse araya boşluk koyar).
  void _insertDictatedText(TextEditingController c, String text) {
    final cur = c.text;
    final sel = c.selection;
    final pos =
        (sel.isValid && sel.baseOffset >= 0) ? sel.baseOffset : cur.length;
    final needsSpace =
        pos > 0 && !RegExp(r'\s$').hasMatch(cur.substring(0, pos));
    final insert = '${needsSpace ? ' ' : ''}$text';
    final newText = cur.replaceRange(pos, pos, insert);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
  }

  /// İmleçteki seçili metni verilen işaretle sarar (**kalın**, *italik*).

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Etiket ekleme diyaloğu.
  void _showAddTagDialog(BuildContext context, NotesDiaryViewModel vm) {
    final ctrl = TextEditingController();
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('notes.tagsAdd'.tr(),
            style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            prefixText: '#',
            hintText: 'notes.tagsHint'.tr(),
            counterText: '',
          ),
          onSubmitted: (v) {
            vm.addTag(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              vm.addTag(ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('notes.tagsAdd'.tr()),
          ),
        ],
      ),
    );
  }

  /// Çizim tuvalini açar; kaydedilen çizim görsel olarak nota eklenir.
  Future<void> _openDrawingPad(
      BuildContext context, NotesDiaryViewModel vm) async {
    final File? file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const _DrawingPadPage()),
    );
    if (file != null) vm.addPickedImageFile(file);
  }

  /// Dosya seçici — seçilen dosyayı nota ekler.
  Future<void> _pickFile(BuildContext context, NotesDiaryViewModel vm) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (path != null) vm.addPickedFile(File(path));
    } catch (_) {
      if (context.mounted) _toast(context, 'notes.editor.fileError'.tr());
    }
  }

  // ---------- Etiket / Hatırlatıcı / Paylaş — işlevsel ----------
  // ---------- Paylaş ----------
  void _shareNote(BuildContext context, NotesDiaryViewModel vm) {
    final title = vm.noteTitleController.text.trim();
    final body = vm.noteContentController.text.trim();
    final text = [title, body].where((s) => s.isNotEmpty).join('\n\n');
    if (text.isEmpty) {
      _toast(context, 'notes.editor.shareEmpty'.tr());
    } else {
      Share.share(text);
    }
  }

  /// Editörde (henüz kaydedilmemiş/düzenlenen not) PIN belirleme. PIN kayıttan
  /// sonra uygulanmak üzere viewModel'de saklanır; chip "Kilitli" olur.
  void _showEditorLockDialog(
      BuildContext context, NotesDiaryViewModel vm, bool isDark) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor:
            isDark ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('notes.lockNote'.tr(),
            style: TextStyle(
                color: isDark
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
                fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('notes.enterPinToLock'.tr(),
                style: TextStyle(
                    color: isDark
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight)),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: isDark
                      ? ColorConstant.textPrimaryDark
                      : ColorConstant.textPrimaryLight),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark
                    ? ColorConstant.bgColorDark
                    : ColorConstant.bgColorLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text('common.cancel'.tr(),
                style: TextStyle(
                    color: isDark
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                vm.setNoteLockPin(pinController.text);
                Navigator.pop(dctx);
                _toast(context, 'notes.editor.willLock'.tr());
              }
            },
            child: Text('common.lock'.tr(),
                style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

}

// ==================== GÜNLÜK DÜZENLEME BOTTOM SHEET ====================

class _EditDiaryBottomSheet extends StatefulWidget {
  final NotesDiaryViewModel viewModel;
  final bool isDarkMode;
  final Diary diary;

  const _EditDiaryBottomSheet({
    required this.viewModel,
    required this.isDarkMode,
    required this.diary,
  });

  @override
  State<_EditDiaryBottomSheet> createState() => _EditDiaryBottomSheetState();
}

class _EditDiaryBottomSheetState extends State<_EditDiaryBottomSheet> {
  List<Map<String, String>> get _moods => [
    {'emoji': '😊', 'label': 'common.moods.happy'.tr()},
    {'emoji': '😔', 'label': 'common.moods.sad'.tr()},
    {'emoji': '😌', 'label': 'common.moods.calm'.tr()},
    {'emoji': '😍', 'label': 'common.moods.inLove'.tr()},
    {'emoji': '😡', 'label': 'common.moods.angry'.tr()},
    {'emoji': '😴', 'label': 'common.moods.tired'.tr()},
  ];

  @override
  void initState() {
    super.initState();
    widget.viewModel.setDiaryForEdit(widget.diary);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<NotesDiaryViewModel>(
        builder: (context, vm, _) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? ColorConstant.cardColorDark
                  : ColorConstant.cardColorLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'diary.editDiary'.tr(),
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mood Selection
                        Text(
                          'diary.moodQuestion'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode
                                ? ColorConstant.textSecondaryDark
                                : ColorConstant.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _moods.length,
                            itemBuilder: (context, index) {
                              final mood = _moods[index];
                              final isSelected =
                                  vm.selectedMood == mood['emoji'];
                              return GestureDetector(
                                onTap: () => vm.setSelectedMood(mood['emoji']!),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFA07A)
                                        .withOpacity(0.2)
                                        : (widget.isDarkMode
                                        ? ColorConstant.bgColorDark
                                        : ColorConstant.bgColorLight),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFA07A)
                                          : (widget.isDarkMode
                                          ? ColorConstant.borderColorDark
                                          : ColorConstant.borderColorLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mood['emoji']!,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mood['label']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFFFFA07A)
                                              : (widget.isDarkMode
                                              ? ColorConstant.textMutedDark
                                              : ColorConstant
                                              .textMutedLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Diary Title
                        TextField(
                          controller: vm.diaryTitleController,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.titleOptional'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Diary Content
                        TextField(
                          controller: vm.diaryContentController,
                          maxLines: 10,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? ColorConstant.textPrimaryDark
                                : ColorConstant.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'diary.hints.thatDayContent'.tr(),
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? ColorConstant.textMutedDark
                                  : ColorConstant.textMutedLight,
                            ),
                            filled: true,
                            fillColor: widget.isDarkMode
                                ? ColorConstant.bgColorDark
                                : ColorConstant.bgColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  vm.resetDiaryForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: widget.isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.cancel'.tr(),
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? ColorConstant.textSecondaryDark
                                        : ColorConstant.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => vm.updateDiary(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA07A),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'common.update'.tr(),
                                  style: TextStyle(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

// ==================== HELPER WIDGETS ====================

// ==================== ÇİZİM TUVALİ ====================
/// Saf Flutter çizim tuvali. Çizimi PNG'ye dönüştürüp File olarak döndürür.
class _DrawingPadPage extends StatefulWidget {
  const _DrawingPadPage();

  @override
  State<_DrawingPadPage> createState() => _DrawingPadPageState();
}

class _DrawingPadPageState extends State<_DrawingPadPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFF2A2620);
  double _width = 4;
  bool _saving = false;

  static const List<Color> _palette = [
    Color(0xFF2A2620),
    Color(0xFFF6A821),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
  ];

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        setState(() => _saving = false);
        return;
      }
      final dir = Directory.systemTemp;
      final file = File(
          '${dir.path}/cizim_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2A2620)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('notes.editor.draw'.tr(),
            style: const TextStyle(
                color: Color(0xFF2A2620), fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFF2A2620)),
            onPressed: () => setState(() => _strokes.clear()),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('common.save'.tr(),
                style: TextStyle(
                    color: ColorConstant.accentOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      onPanStart: (d) {
                        setState(() {
                          _strokes.add(_Stroke(
                              color: _color,
                              width: _width,
                              points: [d.localPosition]));
                        });
                      },
                      onPanUpdate: (d) {
                        setState(() {
                          _strokes.last.points.add(d.localPosition);
                        });
                      },
                      child: CustomPaint(
                        painter: _DrawPainter(_strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Renk + kalınlık çubuğu
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  for (final col in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = col),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == col
                                ? ColorConstant.accentOrange
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.brush_rounded, size: 18),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: _width,
                      min: 2,
                      max: 16,
                      activeColor: ColorConstant.accentOrange,
                      onChanged: (v) => setState(() => _width = v),
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
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke({required this.color, required this.width, required this.points});
}

class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], paint);
      }
      if (s.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawPainter old) => true;
}

// ==================== SES NOTU CALAR ====================
/// Kaydedilmiş ses notunu çalan/duraklatan kompakt bileşen.
class _VoiceNoteChip extends StatefulWidget {
  final String path;
  final VoidCallback onRemove;

  /// true ise [path] bir URL'dir (backend ses eki); false ise yerel dosya.
  final bool isNetwork;

  /// Varsa kayıt süresi (saniye) — mm:ss olarak gösterilir.
  final int? durationSeconds;

  const _VoiceNoteChip({
    required this.path,
    required this.onRemove,
    this.isNetwork = false,
    this.durationSeconds,
  });

  @override
  State<_VoiceNoteChip> createState() => _VoiceNoteChipState();
}

class _VoiceNoteChipState extends State<_VoiceNoteChip> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(widget.isNetwork
          ? UrlSource(widget.path)
          : DeviceFileSource(widget.path));
      setState(() => _playing = true);
    }
  }

  String _durationLabel() {
    final d = widget.durationSeconds;
    if (d == null || d <= 0) return 'notes.editor.voiceNote'.tr();
    final m = (d ~/ 60).toString().padLeft(2, '0');
    final s = (d % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = ColorConstant.accentOrange;
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: accent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(28, (i) {
                final h = 5.0 + ((i * 13) % 18);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.4),
                  child: Container(
                    width: 2.6,
                    height: h,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(_durationLabel(),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

// ==================== EDİTÖR ALT ARAÇ ÇUBUĞU ====================
/// Seçili araç düğmesinin etrafına çizilen kesikli çember (RotationTransition
/// ile döndürülür). Düğme çevresinde eşit aralıklı kısa yaylar çizer.
class _DashedRingPainter extends CustomPainter {
  final Color color;
  const _DashedRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 1.5;
    const dashCount = 11;
    final sweep = 2 * math.pi / dashCount;
    final dash = sweep * 0.55; // yay/boşluk oranı
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweep, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

/// Kompakt biçimlendirme çubuğu [+ B i • ≡ ☑ 🎤]; + ekleme menüsünü
/// (Kamera/Fotoğraf/Dosya/Çizim/Tarama/Hatırlatıcı/Paylaş) açıp kapatır.
class _EditorToolbar extends StatefulWidget {
  final AppColors c;
  final Color accent;
  final Color accentDark;
  final String? reminderLabel;
  final TextEditingController controller;
  final bool boldActive;
  final bool italicActive;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final VoidCallback onCheckbox;
  final VoidCallback onCopyText;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onPhoto;
  final VoidCallback onFile;
  final VoidCallback onDraw;
  final VoidCallback onScan;
  final VoidCallback onReminder;
  final VoidCallback onShare;
  final VoidCallback onShareCollab;

  const _EditorToolbar({
    required this.c,
    required this.accent,
    required this.accentDark,
    required this.reminderLabel,
    required this.controller,
    required this.boldActive,
    required this.italicActive,
    required this.onBold,
    required this.onItalic,
    required this.onBullet,
    required this.onNumbered,
    required this.onCheckbox,
    required this.onCopyText,
    required this.onMic,
    required this.onCamera,
    required this.onPhoto,
    required this.onFile,
    required this.onDraw,
    required this.onScan,
    required this.onReminder,
    required this.onShare,
    required this.onShareCollab,
  });

  @override
  State<_EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<_EditorToolbar>
    with SingleTickerProviderStateMixin {
  // Menü, layout akışına eklenmek yerine (sayfayı ittirip kaydırıyordu)
  // + butonuna sabitlenmiş bir Overlay olarak açılır. Böylece hizalı kalır,
  // içerik kaymaz ve metin alanının seçim tutamacının üstünde görünür.
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  // Seçili (aktif) düğmenin etrafında dönen kesikli çember için.
  late final AnimationController _ringController;

  bool get _open => _entry != null;

  @override
  void initState() {
    super.initState();
    // İmleç/metin değişince madde-işareti aktiflik göstergesi güncellensin.
    widget.controller.addListener(_onCtrlChanged);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

  /// İmlecin bulunduğu satırın başındaki liste işaretini döndürür
  /// ('check' / 'bullet' / 'number' / null).
  String? get _currentLinePrefix {
    final t = widget.controller.text;
    final sel = widget.controller.selection;
    final caret = (sel.isValid && sel.baseOffset >= 0) ? sel.baseOffset : t.length;
    final start = t.lastIndexOf('\n', caret > 0 ? caret - 1 : 0);
    final lineStart = start < 0 ? 0 : start + 1;
    final line = t.substring(lineStart.clamp(0, t.length));
    if (line.startsWith('☐ ') || line.startsWith('☑ ')) return 'check';
    if (line.startsWith('• ')) return 'bullet';
    if (RegExp(r'^\d+\. ').hasMatch(line)) return 'number';
    return null;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrlChanged);
    _ringController.dispose();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _toggle() {
    if (_entry != null) {
      _closeMenu();
    } else {
      _entry = OverlayEntry(builder: (_) => _overlay());
      Overlay.of(context).insert(_entry!);
      setState(() {}); // + ikonunu döndür
    }
  }

  void _closeMenu() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _run(VoidCallback cb) {
    _closeMenu();
    cb();
  }

  Widget _overlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeMenu,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -10),
          child: Material(
            color: Colors.transparent,
            child: _menu(widget.c),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: _bar(widget.c),
    );
  }

  Widget _bar(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          CompositedTransformTarget(
            link: _link,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [widget.accent, widget.accentDark]),
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _open ? 0.125 : 0.0,
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _fmt(Icons.format_bold_rounded, widget.onBold, c,
                      active: widget.boldActive),
                  _fmt(Icons.format_italic_rounded, widget.onItalic, c,
                      active: widget.italicActive),
                  _fmt(Icons.format_list_bulleted_rounded, widget.onBullet, c,
                      active: _currentLinePrefix == 'bullet'),
                  _fmt(Icons.format_list_numbered_rounded, widget.onNumbered, c,
                      active: _currentLinePrefix == 'number'),
                  _fmt(Icons.check_box_rounded, widget.onCheckbox, c,
                      active: _currentLinePrefix == 'check', big: true),
                  // Seçili metni kopyala.
                  _fmt(Icons.content_copy_rounded, widget.onCopyText, c),
                  _fmt(Icons.mic_none_rounded, widget.onMic, c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Biçimlendirme düğmesi. [active] olduğunda animasyonlu vurgu (dolgu + hafif
  /// büyüme) ile seçili olduğu belli olur. [big] onay-kutusu gibi sık dokunulan
  /// düğmeyi büyütüp dokunması kolaylaştırır.
  /// Biçimlendirme düğmesi. Normalde sade durur; SEÇİLİ (aktif) olduğunda
  /// etrafında dönen kesikli bir çember + hafif mor dolgu belirir.
  Widget _fmt(IconData icon, VoidCallback onTap, AppColors c,
      {bool active = false, bool big = false}) {
    final double box = big ? 42 : 40;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(box / 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: SizedBox(
          width: box,
          height: box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Seçili dolgu (yumuşak)
              if (active)
                Container(
                  width: box - 8,
                  height: box - 8,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                ),
              Icon(icon,
                  size: big ? 26 : 22,
                  color: active ? widget.accentDark : c.textSecondary),
              // Dönen kesikli çember
              if (active)
                RotationTransition(
                  turns: _ringController,
                  child: CustomPaint(
                    size: Size(box, box),
                    painter: _DashedRingPainter(widget.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(AppColors c) {
    final items = <List<dynamic>>[
      [Icons.camera_alt_outlined, 'notes.editor.camera'.tr(), widget.onCamera],
      [Icons.image_outlined, 'notes.editor.photo'.tr(), widget.onPhoto],
      [Icons.attach_file_rounded, 'notes.editor.file'.tr(), widget.onFile],
      [Icons.gesture_rounded, 'notes.editor.draw'.tr(), widget.onDraw],
      [
        Icons.document_scanner_outlined,
        'notes.editor.scan'.tr(),
        widget.onScan
      ],
      [
        widget.reminderLabel != null
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        widget.reminderLabel ?? 'notes.editor.reminder'.tr(),
        widget.onReminder
      ],
      // Sıradan paylaşım (metni dışa aktar) — kalsın.
      [Icons.ios_share_rounded, 'notes.editor.share'.tr(), widget.onShare],
      // Ortak (arkadaşla) paylaşımlı not — ayrı seçenek.
      [
        Icons.group_add_rounded,
        'notes.editor.shareCollab'.tr(),
        widget.onShareCollab
      ],
    ];
    return Container(
      width: 244,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((it) {
          return InkWell(
            onTap: () => _run(it[2] as VoidCallback),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(it[0] as IconData,
                        size: 19, color: widget.accentDark),
                  ),
                  const SizedBox(width: 13),
                  Text(it[1] as String,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
