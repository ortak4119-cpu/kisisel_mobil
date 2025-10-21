import 'dart:ui';
import 'package:flutter/painting.dart';

class ColorConstant {
  // Error renkleri
  static Color errorRed = fromHex("#FF5252");
  static Color errorLight = fromHex("#FFE5E5");
  static Color successGreen = fromHex("#4CAF50");
  static Color warningOrange = fromHex("#FFA726");

  // Ana renkler - açık mod (screenshot'taki mor/pembe tonlar)
  static Color primaryPurple = fromHex("#B794F6");      // Kartlardaki mor ton
  static Color primaryPink = fromHex("#E4B4E8");        // Pembe varyasyon
  static Color accentBlue = fromHex("#7EC8F5");         // Mavi kart tonu
  static Color accentYellow = fromHex("#FFD54F");       // Sarı aksanlar (Useful Tips)
  static Color accentOrange = fromHex("#FFB74D");       // Turuncu aksanlar
  static Color accentRed = fromHex("#FF7676");          // New & Trendy kırmızısı
  static Color accentGreen = fromHex("#81C784");        // Yeşil aksanlar

  // Arka plan renkleri - açık mod
  static Color bgColorLight = fromHex("#F5F7FA");       // Çok açık gri-beyaz ton
  static Color cardColorLight = fromHex("#FFFFFF");     // Beyaz kart arkaplanı
  static Color cardPurpleLight = fromHex("#E8DAFF");    // Mor kart arkaplanı
  static Color cardBlueLight = fromHex("#D6F0FF");      // Mavi kart arkaplanı
  static Color cardYellowLight = fromHex("#FFF9E6");    // Sarı kart arkaplanı
  static Color cardPinkLight = fromHex("#FFE8F5");      // Pembe kart arkaplanı
  static Color cardGreenLight = fromHex("#E8F5E9");     // Yeşil kart arkaplanı

  // Metin renkleri - açık mod
  static Color textPrimaryLight = fromHex("#1A1A2E");   // Koyu lacivert-siyah
  static Color textSecondaryLight = fromHex("#4A5568"); // Gri ton
  static Color textMutedLight = fromHex("#A0AEC0");     // Soluk gri
  static Color textOnPurple = fromHex("#FFFFFF");       // Mor üstünde beyaz

  // Ara renkler - açık mod
  static Color borderColorLight = fromHex("#E2E8F0");   // Açık gri kenarlık
  static Color dividerLight = fromHex("#EDF2F7");       // Çok açık ayırıcı

  // Ana renkler - koyu mod
  static Color primaryDarkModePurple = fromHex("#9C7FD6"); // Koyu mod mor
  static Color primaryDarkModeBlue = fromHex("#5BA3D6");   // Koyu mod mavi
  static Color accentDarkModeYellow = fromHex("#FFD966");  // Koyu mod sarı
  static Color accentDarkModeRed = fromHex("#FF6B6B");     // Koyu mod kırmızı

  // Arka plan renkleri - koyu mod
  static Color bgColorDark = fromHex("#121212");        // Siyah-gri arka plan
  static Color cardColorDark = fromHex("#1E1E1E");      // Koyu gri kart
  static Color cardPurpleDark = fromHex("#2A1F3D");     // Koyu mor kart
  static Color cardBlueDark = fromHex("#1A2832");       // Koyu mavi kart
  static Color cardYellowDark = fromHex("#3D3420");     // Koyu sarı kart

  // Metin renkleri - koyu mod
  static Color textPrimaryDark = fromHex("#FFFFFF");    // Beyaz yazı
  static Color textSecondaryDark = fromHex("#B0B8C4");  // Açık gri yazı
  static Color textMutedDark = fromHex("#6B7280");      // Soluk gri yazı

  // Ara renkler - koyu mod
  static Color borderColorDark = fromHex("#2D3748");    // Koyu gri kenarlık
  static Color dividerDark = fromHex("#252525");        // Koyu ayırıcı

  // Gradient renkleri (screenshot'taki gradient'ler için)
  static Color gradientPurpleStart = fromHex("#C084FC");
  static Color gradientPurpleEnd = fromHex("#E0B4F7");
  static Color gradientBlueStart = fromHex("#60A5FA");
  static Color gradientBlueEnd = fromHex("#93C5FD");
  static Color gradientPinkStart = fromHex("#F472B6");
  static Color gradientPinkEnd = fromHex("#FBB6CE");

  // İkon ve özel elementler için
  static Color iconPrimary = fromHex("#6366F1");        // İndigo ton ikonlar
  static Color iconSecondary = fromHex("#8B5CF6");      // Mor ton ikonlar
  static Color iconYellow = fromHex("#FBBF24");         // Sarı ton ikonlar

  // Genel renkler
  static Color white = fromHex("#FFFFFF");
  static Color black = fromHex("#000000");
  static Color grey = fromHex("#9CA3AF");
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