import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir tema modunun (açık/koyu) yüzey + metin renkleri.
class ThemeSurface {
  final Color bg;
  final Color card;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const ThemeSurface({
    required this.bg,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });
}

/// Seçilebilir bir tam palet (zemin + kart + metin + aksan), açık ve koyu varyantlı.
class AppThemeOption {
  final String id;
  final String nameKey; // i18n: settings.theme.<nameKey>
  final Color accent; // birincil vurgu (FAB, buton, seçili)
  final Color accentSoft; // aksanın açık tonu (gradyan ucu)
  final ThemeSurface light;
  final ThemeSurface dark;

  const AppThemeOption({
    required this.id,
    required this.nameKey,
    required this.accent,
    required this.accentSoft,
    required this.light,
    required this.dark,
  });
}

/// Uygulama geneli aktif palet. Statik + senkron erişilir (ColorConstant
/// getter'ları buradan okur). Değişim UI'a ThemeProvider.notify ile yansır.
class AppPalette {
  static const String _key = 'app_theme_id';

  static final List<AppThemeOption> all = [
    // 1) Sıcak Kraft (mevcut)
    AppThemeOption(
      id: 'kraft',
      nameKey: 'kraft',
      accent: Color(0xFFF6A821),
      accentSoft: Color(0xFFFFD36A),
      light: ThemeSurface(
        bg: Color(0xFFDED0B2),
        card: Color(0xFFEAE0CD),
        border: Color(0xFFDCD0BA),
        divider: Color(0xFFE5DBC7),
        textPrimary: Color(0xFF2B2620),
        textSecondary: Color(0xFF6F6456),
        textMuted: Color(0xFFA79A84),
      ),
      dark: ThemeSurface(
        bg: Color(0xFF16130E),
        card: Color(0xFF221E17),
        border: Color(0xFF3A3226),
        divider: Color(0xFF2C2619),
        textPrimary: Color(0xFFF2ECE0),
        textSecondary: Color(0xFFB7AC97),
        textMuted: Color(0xFF7C7260),
      ),
    ),
    // 2) Açık Mavi
    AppThemeOption(
      id: 'blue',
      nameKey: 'blue',
      accent: Color(0xFF3B9BD6),
      accentSoft: Color(0xFF7FC3EC),
      light: ThemeSurface(
        bg: Color(0xFFCFE0EC),
        card: Color(0xFFE6F0F7),
        border: Color(0xFFC2D6E4),
        divider: Color(0xFFD5E4EE),
        textPrimary: Color(0xFF1F2D38),
        textSecondary: Color(0xFF5A6B78),
        textMuted: Color(0xFF93A4B0),
      ),
      dark: ThemeSurface(
        bg: Color(0xFF0E1419),
        card: Color(0xFF18212A),
        border: Color(0xFF2A3742),
        divider: Color(0xFF1E2832),
        textPrimary: Color(0xFFE6EEF4),
        textSecondary: Color(0xFF9FB2C0),
        textMuted: Color(0xFF6B7C88),
      ),
    ),
    // 3) Açık Pembe
    AppThemeOption(
      id: 'pink',
      nameKey: 'pink',
      accent: Color(0xFFE0689A),
      accentSoft: Color(0xFFF0A2C0),
      light: ThemeSurface(
        bg: Color(0xFFEFD9E0),
        card: Color(0xFFF8E9EF),
        border: Color(0xFFE3C7D2),
        divider: Color(0xFFEED7DF),
        textPrimary: Color(0xFF3A2A31),
        textSecondary: Color(0xFF7C6169),
        textMuted: Color(0xFFB295A0),
      ),
      dark: ThemeSurface(
        bg: Color(0xFF190F13),
        card: Color(0xFF241820),
        border: Color(0xFF3C2A33),
        divider: Color(0xFF2C1E26),
        textPrimary: Color(0xFFF4E6EC),
        textSecondary: Color(0xFFC09FAC),
        textMuted: Color(0xFF86606E),
      ),
    ),
    // 4) Açık Yeşil
    AppThemeOption(
      id: 'green',
      nameKey: 'green',
      accent: Color(0xFF5BA468),
      accentSoft: Color(0xFF93C99E),
      light: ThemeSurface(
        bg: Color(0xFFD6E4C9),
        card: Color(0xFFEAF2E0),
        border: Color(0xFFC6D9B7),
        divider: Color(0xFFD9E6CC),
        textPrimary: Color(0xFF26331E),
        textSecondary: Color(0xFF5F6E53),
        textMuted: Color(0xFF97A587),
      ),
      dark: ThemeSurface(
        bg: Color(0xFF0F150C),
        card: Color(0xFF1A2416),
        border: Color(0xFF2C3A26),
        divider: Color(0xFF1F2A1A),
        textPrimary: Color(0xFFE8F0E0),
        textSecondary: Color(0xFFA6B89C),
        textMuted: Color(0xFF6E7E64),
      ),
    ),
    // 5) Açık Turuncu
    AppThemeOption(
      id: 'orange',
      nameKey: 'orange',
      accent: Color(0xFFED8A3A),
      accentSoft: Color(0xFFF6B778),
      light: ThemeSurface(
        bg: Color(0xFFF1DCC4),
        card: Color(0xFFF9ECDC),
        border: Color(0xFFE7CEB2),
        divider: Color(0xFFF0DDC7),
        textPrimary: Color(0xFF3A2D21),
        textSecondary: Color(0xFF7C6A55),
        textMuted: Color(0xFFB6A385),
      ),
      dark: ThemeSurface(
        bg: Color(0xFF18120B),
        card: Color(0xFF241C12),
        border: Color(0xFF3C2F1E),
        divider: Color(0xFF2C2214),
        textPrimary: Color(0xFFF4EADD),
        textSecondary: Color(0xFFC0AC92),
        textMuted: Color(0xFF867360),
      ),
    ),
  ];

  static String _id = 'kraft';
  static String get currentId => _id;

  static AppThemeOption get current =>
      all.firstWhere((o) => o.id == _id, orElse: () => all.first);

  static ThemeSurface get light => current.light;
  static ThemeSurface get dark => current.dark;
  static Color get accent => current.accent;
  static Color get accentSoft => current.accentSoft;

  // ── Semantik + modül renkleri (temaya göre uyumlu) ───────────────────────
  // Sabit kırmızı/yeşil/amber yerine, her renk aktif aksana doğru hafifçe
  // karıştırılır; böylece içerik seçili temanın sıcaklığını alır. Hepsi orta
  // tonludur ve arayüzde SOFT kullanılır (koyu/doygun blok değil, açık tint +
  // orta tonlu metin/ikon). Statik + senkron → ColorConstant gibi context'siz.
  static Color get danger =>
      Color.lerp(const Color(0xFFD9534F), accent, 0.18)!; // gecikmiş / hata / sil
  static Color get warning =>
      Color.lerp(const Color(0xFFE0A33C), accent, 0.26)!; // uyarı / atlandı
  static Color get success =>
      Color.lerp(const Color(0xFF4FA363), accent, 0.16)!; // tamam / biten
  static Color get info => accent; // birincil / bugün / odak
  static Color get accentCool =>
      Color.lerp(const Color(0xFF6C8EC4), accent, 0.30)!; // yaklaşan / ikincil vurgu
  static Color get module => accent; // modül kimliği (Notlar/Görevler/Finans)

  /// Aktif aksanın açık modda SOFT yüzey tonu (kart/pill zemini).
  /// Koyu renkli blokların yerine kullanılır — her tema için açık/soluk kalır.
  static Color softTint(Color base, bool isDark) =>
      base.withValues(alpha: isDark ? 0.20 : 0.13);

  /// Açılışta seçili temayı belleğe yükler (ColorConstant'tan ÖNCE çağrılmalı).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_key);
      if (id != null && all.any((o) => o.id == id)) _id = id;
    } catch (_) {}
  }

  /// Temayı değiştirir ve kalıcı yazar. UI yenilemesi ThemeProvider.notify ile.
  static Future<void> set(String id) async {
    if (!all.any((o) => o.id == id)) return;
    _id = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, id);
    } catch (_) {}
  }
}
