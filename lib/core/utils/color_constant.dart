import 'package:flutter/painting.dart';
import '../theme/app_palette.dart';

class ColorConstant {
  // Error renkleri
  static Color errorRed = fromHex("#FF5252");
  static Color errorLight = fromHex("#FFE5E5");
  static Color successGreen = fromHex("#4CAF50");
  static Color warningOrange = fromHex("#FFA726");

  // Ana renkler - açık mod (görseldeki canlı renkler)
  static Color primaryPurple = fromHex("#B388FF"); // Kartlardaki parlak mor ton
  static Color primaryPink = fromHex("#FF80AB"); // Parlak pembe varyasyon
  static Color accentBlue = fromHex("#40C4FF"); // Parlak mavi kart tonu
  static Color get accentYellow => AppPalette.accentSoft; // Parlak sarı aksanlar
  static Color get accentOrange => AppPalette.accent; // Parlak turuncu aksanlar
  // Aksan tint'li açık zemin üstünde okunur koyu aksan (metin/ikon için).
  static Color get accentInk =>
      Color.alphaBlend(const Color(0x59000000), AppPalette.accent); // ~%35 koyu
  static Color accentRed = fromHex("#FF5252"); // Parlak kırmızı
  static Color accentGreen = fromHex("#69F0AE"); // Parlak yeşil aksanlar

  // Arka plan renkleri - açık mod (referans swatch: sıcak tan/bej)
  static Color get bgColorLight => AppPalette.light.bg; // Sıcak tan/bej zemin (referans görseldeki ton)
  static Color get cardColorLight => AppPalette.light.card; // Belirgin sıcak krem kart (tan zeminin açık tonu)
  static Color cardPurpleLight = fromHex("#EDE7F6"); // Açık mor kart arkaplanı
  static Color cardBlueLight = fromHex("#B3E5FC"); // Açık mavi kart arkaplanı
  static Color cardYellowLight = fromHex("#FFF9C4"); // Açık sarı kart arkaplanı
  static Color cardPinkLight = fromHex("#FCE4EC"); // Açık pembe kart arkaplanı
  static Color cardGreenLight = fromHex("#C8E6C9"); // Açık yeşil kart arkaplanı

  // Metin renkleri - açık mod (Notlar sıcak kahve mürekkep tonları)
  static Color get textPrimaryLight => AppPalette.light.textPrimary; // Koyu sıcak kahve
  static Color get textSecondaryLight => AppPalette.light.textSecondary; // Sıcak gri-kahve
  static Color get textMutedLight => AppPalette.light.textMuted; // Soluk sıcak bej-gri
  static Color textOnPurple = fromHex("#FFFFFF"); // Mor üstünde beyaz

  // Ara renkler - açık mod (bej zeminle uyumlu sıcak kenarlıklar)
  static Color get borderColorLight => AppPalette.light.border; // Sıcak açık kenarlık
  static Color get dividerLight => AppPalette.light.divider; // Sıcak açık ayırıcı

  // Ana renkler - koyu mod (daha canlı versiyonlar)
  static Color primaryDarkModePurple =
      fromHex("#B388FF"); // Parlak koyu mod mor
  static Color primaryDarkModeBlue = fromHex("#40C4FF"); // Parlak koyu mod mavi
  static Color accentDarkModeYellow =
      fromHex("#FFD740"); // Parlak koyu mod sarı
  static Color accentDarkModeRed =
      fromHex("#FF5252"); // Parlak koyu mod kırmızı

  // Arka plan renkleri - koyu mod
  static Color get bgColorDark => AppPalette.dark.bg; // Siyah-gri arka plan
  static Color get cardColorDark => AppPalette.dark.card; // Koyu gri kart
  static Color cardPurpleDark = fromHex("#311B92"); // Koyu mor kart
  static Color cardBlueDark = fromHex("#01579B"); // Koyu mavi kart
  static Color cardYellowDark = fromHex("#F57F17"); // Koyu sarı kart

  // Metin renkleri - koyu mod
  static Color get textPrimaryDark => AppPalette.dark.textPrimary; // Beyaz yazı
  static Color get textSecondaryDark => AppPalette.dark.textSecondary; // Açık gri yazı
  static Color get textMutedDark => AppPalette.dark.textMuted; // Soluk gri yazı

  // Ara renkler - koyu mod
  static Color get borderColorDark => AppPalette.dark.border; // Koyu gri kenarlık
  static Color get dividerDark => AppPalette.dark.divider; // Koyu ayırıcı

  // Gradient renkleri (görseldeki canlı gradient'ler için)
  static Color gradientPurpleStart = fromHex("#B388FF");
  static Color gradientPurpleEnd = fromHex("#EA80FC");
  static Color gradientBlueStart = fromHex("#40C4FF");
  static Color gradientBlueEnd = fromHex("#80D8FF");
  static Color gradientPinkStart = fromHex("#FF80AB");
  static Color gradientPinkEnd = fromHex("#FF4081");

  // İkon ve özel elementler için (görseldeki gibi canlı)
  static Color iconPrimary = fromHex("#7C4DFF"); // Parlak indigo ton ikonlar
  static Color iconSecondary = fromHex("#B388FF"); // Parlak mor ton ikonlar
  static Color iconYellow = fromHex("#FFD740"); // Parlak sarı ton ikonlar

  // Genel renkler
  static Color white = fromHex("#FFFFFF");
  static Color black = fromHex("#000000");
  static Color grey = fromHex("#9E9E9E");
  static Color transparent = const Color(0x00000000);

  // Overlay renkleri
  static Color overlayLight = fromHex("#FFFFFF").withValues(alpha: 0.5);
  static Color overlayDark = fromHex("#000000").withValues(alpha: 0.5);
  static Color scrimLight = fromHex("#000000").withValues(alpha: 0.2);
  static Color scrimDark = fromHex("#000000").withValues(alpha: 0.6);

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Gradient oluşturucu helper metodlar
  static LinearGradient purpleGradient = LinearGradient(
    colors: [gradientPurpleStart, gradientPurpleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient blueGradient = LinearGradient(
    colors: [gradientBlueStart, gradientBlueEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pinkGradient = LinearGradient(
    colors: [gradientPinkStart, gradientPinkEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
