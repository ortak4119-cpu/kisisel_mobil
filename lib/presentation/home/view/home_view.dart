import 'dart:ui' show ImageFilter;
import 'package:auto_route/auto_route.dart';
import 'package:base/presentation/calender/view/calender_view.dart';
import 'package:base/presentation/finance/view/finance_view.dart';
import 'package:base/presentation/notes_diary/view/notes_diary_view.dart';
import 'package:base/presentation/profile/view/profile_view.dart';
import 'package:base/presentation/tasks_habits/view/tasks_habits_view.dart';
import 'package:base/presentation/today/view/today_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';
import '../../../core/utils/responsive.dart';
import '../../../service/update/update_service.dart';

@RoutePage()
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  // Alt menü pasif renkleri. Seçili vurgu artık ColorConstant.accentOrange
  // (seçili temanın aksanı) ile verilir.
  static const _navIdleIconLight = Color(0xFF6F6456); // sıcak kahve ikon (pasif)
  static const _navIdleLabelLight = Color(0xFF8A7F6C); // soluk etiket

  @override
  void initState() {
    super.initState();
    // Ana ekran acilinca App Store'da yeni surum var mi kontrol et.
    // Ilk kare cizildikten sonra, kisa bir gecikmeyle (acilisi yavaslatmaz).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        UpdateService.checkForUpdate(context);
      }
    });
  }

  // Sayfalar — Bugün ilk sekme; Görevler ve Alışkanlıklar ayrı sekmeler.
  Widget _pageAt(int i) {
    switch (i) {
      case 0: // Bugün
        return TodayView(
            onNavigate: (x) => setState(() => _selectedIndex = x));
      case 1: // Notlar
        return const NotesDiaryView();
      case 2: // Görevler
        return const TasksHabitsView(key: ValueKey('tasks'), mode: 'tasks');
      case 3: // Alışkanlıklar
        return const TasksHabitsView(key: ValueKey('habits'), mode: 'habits');
      case 4: // Takvim
        return const CalendarView();
      case 5: // Finans
        return const FinanceView();
      default: // Profil
        return const ProfileView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstant.bgColorDark
          : ColorConstant.bgColorLight,
      // Cam alt menünün arkasındaki içeriği bulanıklaştırabilmesi için gövde
      // alt menünün altına kadar uzanır.
      extendBody: true,
      // Geniş ekranda (iPad/tablet) içerik ortalanır ve makul genişliğe
      // sınırlanır; telefonda tam genişlik korunur. Her sekme için tek yerden.
      body: ResponsiveCenter(child: _pageAt(_selectedIndex)),
      bottomNavigationBar: _buildGlassNav(isDarkMode),
    );
  }

  /// Buzlu cam (glassmorphism) alt menü — arkadaki içeriği bulanıklaştırır.
  Widget _buildGlassNav(bool isDarkMode) {
    final glassColor = isDarkMode
        ? ColorConstant.cardColorDark.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.60);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.60);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: LayoutBuilder(
                builder: (context, cons) {
                  const count = 7;
                  final itemW = cons.maxWidth / count;
                  return Stack(
                    children: [
                      // Spotlight: her sekmenin kendi ışık hüzmesi var; seçili
                      // olanınki yanar, eskisi söner (çapraz geçiş animasyonu).
                      IgnorePointer(
                        child: SizedBox(
                          width: cons.maxWidth,
                          height: 68,
                          child: Row(
                            children: List.generate(count, (i) {
                              return SizedBox(
                                width: itemW,
                                height: 68,
                                child: AnimatedOpacity(
                                  opacity: _selectedIndex == i ? 1 : 0,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOut,
                                  child: CustomPaint(
                                    painter: _SpotlightPainter(ColorConstant.accentOrange),
                                    size: Size.infinite,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNavItem(
                              icon: Icons.wb_sunny_rounded,
                              label: 'today.title'.tr(),
                              index: 0,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.sticky_note_2_rounded,
                              label: 'navigation.home'.tr(),
                              index: 1,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.checklist_rounded,
                              label: 'navigation.tasks'.tr(),
                              index: 2,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.emoji_events_rounded,
                              label: 'navigation.habits'.tr(),
                              index: 3,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.calendar_month_rounded,
                              label: 'navigation.calendar'.tr(),
                              index: 4,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.attach_money,
                              label: 'navigation.finance'.tr(),
                              index: 5,
                              isDarkMode: isDarkMode),
                          _buildNavItem(
                              icon: Icons.person_rounded,
                              label: 'navigation.profile'.tr(),
                              index: 6,
                              isDarkMode: isDarkMode),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDarkMode,
  }) {
    final idleIcon =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleIconLight;
    final idleLabel =
        isDarkMode ? ColorConstant.textMutedDark : _navIdleLabelLight;
    // Dock büyüteç: aktife uzaklığa göre ikon ölçeği (hafif).
    final dist = (index - _selectedIndex).abs();
    final scale = dist == 0 ? 1.12 : (dist == 1 ? 1.04 : 1.0);

    return _NavItem(
      icon: icon,
      label: label,
      selected: _selectedIndex == index,
      iconScale: scale,
      // Seçili vurgu artık seçili temanın aksanı (FAB/Kaydet ile uyumlu).
      accent: ColorConstant.accentOrange,
      idleIcon: idleIcon,
      idleLabel: idleLabel,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

/// Alt menü öğesi. Seçilince/tıklanınca ikon yaylanarak zıplar (pop),
/// pembe hap genişler ve hafifçe yukarı kalkar — modern, canlı his.
/// Cam Büyüteç (dock) alt menü öğesi. İkon, aktife uzaklığa göre yaylanarak
/// büyür (AnimatedScale + easeOutBack); seçili olan turuncuya döner.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final double iconScale;
  final VoidCallback onTap;
  final Color accent;
  final Color idleIcon;
  final Color idleLabel;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.iconScale,
    required this.onTap,
    required this.accent,
    required this.idleIcon,
    required this.idleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Padding(
          // İkonları biraz aşağı indir: üstteki ışık hüzmesi/çubuğu ile
          // çakışmasınlar.
          padding: const EdgeInsets.only(top: 12),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: iconScale,
              child: Icon(
                icon,
                size: 19,
                color: selected ? accent : idleIcon,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : idleLabel,
                ),
                child: Text(label, maxLines: 1, softWrap: false),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Spotlight ışık hüzmesi — üstte parlak bir kaynak çubuğu ve aşağı doğru
/// genişleyen yumuşak bir ışık konisi çizer (seçili sekmenin arkasında).
class _SpotlightPainter extends CustomPainter {
  final Color color;
  _SpotlightPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const topY = 1.5;
    const topHalf = 3.5; // üstten çok dar başlasın (ince ışık kaynağı)
    final botHalf = w * 0.40;

    // Aşağı genişleyen koni (yukarıdan aşağıya soluklaşan degrade; daha parlak).
    final cone = Path()
      ..moveTo(cx - topHalf, topY)
      ..lineTo(cx + topHalf, topY)
      ..lineTo(cx + botHalf, h)
      ..lineTo(cx - botHalf, h)
      ..close();
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.38),
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.0),
      ],
      // Alt bölgede (ikon/etiketin olduğu yer) tamamen sönsün ki çakışmasın.
      stops: const [0.0, 0.42, 0.72],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(cone, Paint()..shader = shader);

    // Üstteki parlak ışık kaynağı + yumuşak parıltı (ince + parlak).
    final barRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, topY + 1.5), width: 11, height: 3.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      barRect,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(barRect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.color != color;
}

