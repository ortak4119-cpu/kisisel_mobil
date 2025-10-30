import 'dart:ui';
import 'package:flutter/painting.dart';

class ColorConstant {
  // Error renkleri
  static Color errorRed = fromHex("#FF5252");
  static Color errorLight = fromHex("#FFE5E5");
  static Color successGreen = fromHex("#4CAF50");
  static Color warningOrange = fromHex("#FFA726");

  // Ana renkler - açık mod (görseldeki canlı renkler)
  static Color primaryPurple = fromHex("#B388FF");      // Kartlardaki parlak mor ton
  static Color primaryPink = fromHex("#FF80AB");        // Parlak pembe varyasyon
  static Color accentBlue = fromHex("#40C4FF");         // Parlak mavi kart tonu
  static Color accentYellow = fromHex("#FFD740");       // Parlak sarı aksanlar
  static Color accentOrange = fromHex("#FF9100");       // Parlak turuncu aksanlar
  static Color accentRed = fromHex("#FF5252");          // Parlak kırmızı
  static Color accentGreen = fromHex("#69F0AE");        // Parlak yeşil aksanlar

  // Arka plan renkleri - açık mod (görseldeki tonlar)
  static Color bgColorLight = fromHex("#E3F2FD");       // Açık mavi-beyaz ton (görseldeki gibi)
  static Color cardColorLight = fromHex("#FFFFFF");     // Beyaz kart arkaplanı
  static Color cardPurpleLight = fromHex("#EDE7F6");    // Açık mor kart arkaplanı
  static Color cardBlueLight = fromHex("#B3E5FC");      // Açık mavi kart arkaplanı
  static Color cardYellowLight = fromHex("#FFF9C4");    // Açık sarı kart arkaplanı
  static Color cardPinkLight = fromHex("#FCE4EC");      // Açık pembe kart arkaplanı
  static Color cardGreenLight = fromHex("#C8E6C9");     // Açık yeşil kart arkaplanı

  // Metin renkleri - açık mod
  static Color textPrimaryLight = fromHex("#212121");   // Koyu siyah
  static Color textSecondaryLight = fromHex("#757575"); // Gri ton
  static Color textMutedLight = fromHex("#BDBDBD");     // Soluk gri
  static Color textOnPurple = fromHex("#FFFFFF");       // Mor üstünde beyaz

  // Ara renkler - açık mod
  static Color borderColorLight = fromHex("#E0E0E0");   // Açık gri kenarlık
  static Color dividerLight = fromHex("#EEEEEE");       // Çok açık ayırıcı

  // Ana renkler - koyu mod (daha canlı versiyonlar)
  static Color primaryDarkModePurple = fromHex("#B388FF"); // Parlak koyu mod mor
  static Color primaryDarkModeBlue = fromHex("#40C4FF");   // Parlak koyu mod mavi
  static Color accentDarkModeYellow = fromHex("#FFD740");  // Parlak koyu mod sarı
  static Color accentDarkModeRed = fromHex("#FF5252");     // Parlak koyu mod kırmızı

  // Arka plan renkleri - koyu mod
  static Color bgColorDark = fromHex("#121212");        // Siyah-gri arka plan
  static Color cardColorDark = fromHex("#1E1E1E");      // Koyu gri kart
  static Color cardPurpleDark = fromHex("#311B92");     // Koyu mor kart
  static Color cardBlueDark = fromHex("#01579B");       // Koyu mavi kart
  static Color cardYellowDark = fromHex("#F57F17");     // Koyu sarı kart

  // Metin renkleri - koyu mod
  static Color textPrimaryDark = fromHex("#FFFFFF");    // Beyaz yazı
  static Color textSecondaryDark = fromHex("#B0B8C4");  // Açık gri yazı
  static Color textMutedDark = fromHex("#6B7280");      // Soluk gri yazı

  // Ara renkler - koyu mod
  static Color borderColorDark = fromHex("#424242");    // Koyu gri kenarlık
  static Color dividerDark = fromHex("#303030");        // Koyu ayırıcı

  // Gradient renkleri (görseldeki canlı gradient'ler için)
  static Color gradientPurpleStart = fromHex("#B388FF");
  static Color gradientPurpleEnd = fromHex("#EA80FC");
  static Color gradientBlueStart = fromHex("#40C4FF");
  static Color gradientBlueEnd = fromHex("#80D8FF");
  static Color gradientPinkStart = fromHex("#FF80AB");
  static Color gradientPinkEnd = fromHex("#FF4081");

  // İkon ve özel elementler için (görseldeki gibi canlı)
  static Color iconPrimary = fromHex("#7C4DFF");        // Parlak indigo ton ikonlar
  static Color iconSecondary = fromHex("#B388FF");      // Parlak mor ton ikonlar
  static Color iconYellow = fromHex("#FFD740");         // Parlak sarı ton ikonlar

  // Genel renkler
  static Color white = fromHex("#FFFFFF");
  static Color black = fromHex("#000000");
  static Color grey = fromHex("#9E9E9E");
  static Color transparent = const Color(0x00000000);

  // Overlay renkleri
  static Color overlayLight = fromHex("#FFFFFF").withOpacity(0.5);
  static Color overlayDark = fromHex("#000000").withOpacity(0.5);
  static Color scrimLight = fromHex("#000000").withOpacity(0.2);
  static Color scrimDark = fromHex("#000000").withOpacity(0.6);

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