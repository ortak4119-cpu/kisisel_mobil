import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/color_constant.dart';

/// ============================================================================
/// UYGULAMA TASARIM SİSTEMİ
/// ----------------------------------------------------------------------------
/// Tüm ekranların paylaştığı ölçüler ve bileşenler. Amaç: aynı görevi yapan
/// parçaların (segment değiştirici, boş durum, bölüm başlığı, istatistik kutusu,
/// birincil buton) her ekranda birebir aynı görünmesi.
///
/// Renk, bilinçli olarak dışarıdan `accent` ile veriliyor: bölümler kendi
/// kimlik rengini korur (Notlar mor, Görevler turuncu, Finans mavi) ama
/// biçim/ölçü/davranış her yerde aynıdır.
/// ============================================================================

/// Boşluk ölçeği (4'ün katları).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Köşe yarıçapları. 2026 kalıbı: daha yuvarlak, daha yumuşak yüzeyler.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Animasyon süreleri.
abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
}

/// Tema duyarlı renk kısayolları.
class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  Color get bg =>
      isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight;
  Color get card => isDark ? ColorConstant.cardColorDark : ColorConstant.white;
  Color get textPrimary =>
      isDark ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
  Color get textSecondary => isDark
      ? ColorConstant.textSecondaryDark
      : ColorConstant.textSecondaryLight;
  Color get textMuted =>
      isDark ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
  Color get border =>
      isDark ? ColorConstant.borderColorDark : ColorConstant.borderColorLight;

  static AppColors of(BuildContext context) =>
      AppColors(Theme.of(context).brightness == Brightness.dark);
}

/// ============================================================================
/// EKRAN BAŞLIĞI — büyük başlık + sağda aksiyon ikonları
/// ============================================================================
class AppScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Başlık satırındaki yuvarlak ikon butonu.
class AppHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;
  final bool filled;
  final String? tooltip;

  const AppHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.accent,
    this.filled = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = accent ?? c.textSecondary;
    final button = Material(
      color: filled ? tint : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: filled ? ColorConstant.white : tint,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// ============================================================================
/// SEGMENT DEĞİŞTİRİCİ — iki/üç sekme arası geçiş (kayan seçim hapı)
/// Notlar/Günlüğüm, Alışkanlıklar/Görevler gibi yerlerde kullanılır.
/// ============================================================================
class AppSegmentedControl extends StatelessWidget {
  final List<AppSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segW = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              // Kayan seçim hapı
              AnimatedPositioned(
                duration: AppDuration.normal,
                curve: Curves.easeOutCubic,
                left: segW * selectedIndex,
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < segments.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                segments[i].icon,
                                size: 17,
                                color: i == selectedIndex
                                    ? ColorConstant.white
                                    : c.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  segments[i].label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: i == selectedIndex
                                        ? ColorConstant.white
                                        : c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AppSegment {
  final String label;
  final IconData icon;
  const AppSegment({required this.label, required this.icon});
}

/// ============================================================================
/// BOŞ DURUM — görsel + başlık + açıklama + AKSİYON BUTONU
/// Eski ekranlarda boş durumda tıklanacak hiçbir şey yoktu; bu bileşen
/// kullanıcıyı doğrudan ilk kaydı oluşturmaya yönlendirir.
/// ============================================================================
class AppEmptyState extends StatelessWidget {
  /// assets/images/ altındaki svg dosya adı (örn. 'empty_notes.svg').
  final String illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final Color accent;

  const AppEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    required this.accent,
    this.actionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Görsel — arkasında yumuşak vurgu halesi.
            // Ölçüler bilinçli olarak kompakt: dar alanlarda (ör. takvim gün
            // listesi) başlık/buton ekran dışına taşmasın.
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: c.isDark ? 0.20 : 0.14),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/$illustration',
                width: 94,
                height: 94,
                placeholderBuilder: (_) => Icon(
                  Icons.inbox_rounded,
                  size: 60,
                  color: accent.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(
                label: actionLabel!,
                icon: actionIcon,
                accent: accent,
                onPressed: onAction!,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// BİRİNCİL BUTON — dolu hap buton, opsiyonel ikon
/// ============================================================================
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.accent,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        disabledBackgroundColor: accent.withValues(alpha: 0.45),
        foregroundColor: ColorConstant.white,
        disabledForegroundColor: ColorConstant.white.withValues(alpha: 0.85),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );

    if (!expand) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

/// İkincil (çerçeveli) buton.
class AppGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool expand;

  const AppGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final child = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textSecondary,
        side: BorderSide(color: c.border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (!expand) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

/// ============================================================================
/// BÖLÜM BAŞLIĞI — ikon + başlık + sağda opsiyonel aksiyon
/// ============================================================================
class AppSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm - 3),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// ============================================================================
/// İSTATİSTİK KUTUSU — ikon + değer + etiket
/// ============================================================================
class AppStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const AppStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// SHEET BAŞLIĞI — "İptal · Başlık · Kaydet" üst aksiyon çubuğu
/// Alt sayfalardaki (bottom sheet) masaüstü tarzı alt buton çiftinin yerine
/// geçer; mobil modal standardı budur.
/// ============================================================================
class AppSheetHeader extends StatelessWidget {
  final String title;
  final String cancelLabel;
  final String confirmLabel;
  final Color accent;
  final VoidCallback onCancel;

  /// null ise onay butonu pasif (soluk) görünür.
  final VoidCallback? onConfirm;

  const AppSheetHeader({
    super.key,
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.accent,
    required this.onCancel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm + 2),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 14, 6),
          child: Row(
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: c.textMuted,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: AppDuration.fast,
                opacity: onConfirm != null ? 1.0 : 0.4,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent,
                    foregroundColor: ColorConstant.white,
                    disabledForegroundColor: ColorConstant.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 11,
                    ),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: c.border.withValues(alpha: 0.5)),
      ],
    );
  }
}

/// ============================================================================
/// ÇERÇEVESİZ METİN ALANI — dolgulu kutu yerine tipografi odaklı giriş
/// ============================================================================
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final double fontSize;
  final FontWeight fontWeight;
  final int? maxLines;
  final bool autofocus;
  final bool showDivider;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.accent,
    this.fontSize = 17,
    this.fontWeight = FontWeight.w500,
    this.maxLines = 1,
    this.autofocus = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          cursorColor: accent,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.4,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            hintText: hint,
            hintStyle: TextStyle(
              color: c.textMuted.withValues(alpha: 0.5),
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
        if (showDivider)
          Container(height: 1, color: c.border.withValues(alpha: 0.6)),
      ],
    );
  }
}

/// ============================================================================
/// KART — tutarlı yüzey
/// ============================================================================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: (accent ?? c.border)
                  .withValues(alpha: accent != null ? 0.35 : 0.7),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
