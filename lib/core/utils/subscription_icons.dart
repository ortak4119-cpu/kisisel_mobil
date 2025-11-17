import 'package:flutter/material.dart';
import 'color_constant.dart';

class SubscriptionIcons {
  // Popüler servislerin logo URL ve renk mapping'i
  static final Map<String, SubscriptionIconData> _platforms = {
    // Streaming
    'netflix': SubscriptionIconData(
      icon: Icons.play_circle_filled,
      color: const Color(0xFFE50914),
      gradient: [const Color(0xFFE50914), const Color(0xFFB20710)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/netflix.svg',
    ),
    'youtube': SubscriptionIconData(
      icon: Icons.play_circle_outline,
      color: const Color(0xFFFF0000),
      gradient: [const Color(0xFFFF0000), const Color(0xFFCC0000)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/youtube.svg',
    ),
    'youtube premium': SubscriptionIconData(
      icon: Icons.play_circle_outline,
      color: const Color(0xFFFF0000),
      gradient: [const Color(0xFFFF0000), const Color(0xFFCC0000)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/youtube.svg',
    ),
    'spotify': SubscriptionIconData(
      icon: Icons.music_note_rounded,
      color: const Color(0xFF1DB954),
      gradient: [const Color(0xFF1DB954), const Color(0xFF1AA34A)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/spotify.svg',
    ),
    'apple music': SubscriptionIconData(
      icon: Icons.music_note,
      color: const Color(0xFFFA243C),
      gradient: [const Color(0xFFFA243C), const Color(0xFFE91E36)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/applemusic.svg',
    ),
    'disney+': SubscriptionIconData(
      icon: Icons.star_rounded,
      color: const Color(0xFF0063E5),
      gradient: [const Color(0xFF0063E5), const Color(0xFF0054C6)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/disneyplus.svg',
    ),
    'disney plus': SubscriptionIconData(
      icon: Icons.star_rounded,
      color: const Color(0xFF0063E5),
      gradient: [const Color(0xFF0063E5), const Color(0xFF0054C6)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/disneyplus.svg',
    ),
    'amazon prime': SubscriptionIconData(
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFF00A8E1),
      gradient: [const Color(0xFF00A8E1), const Color(0xFF0095CC)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/amazon.svg',
    ),
    'prime video': SubscriptionIconData(
      icon: Icons.play_arrow_rounded,
      color: const Color(0xFF00A8E1),
      gradient: [const Color(0xFF00A8E1), const Color(0xFF0095CC)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/primevideo.svg',
    ),
    'hbo': SubscriptionIconData(
      icon: Icons.tv_rounded,
      color: const Color(0xFF000000),
      gradient: [const Color(0xFF000000), const Color(0xFF1A1A1A)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/hbo.svg',
    ),
    'hbo max': SubscriptionIconData(
      icon: Icons.tv_rounded,
      color: const Color(0xFF000000),
      gradient: [const Color(0xFF000000), const Color(0xFF1A1A1A)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/hbomax.svg',
    ),
    'twitch': SubscriptionIconData(
      icon: Icons.videocam_rounded,
      color: const Color(0xFF9146FF),
      gradient: [const Color(0xFF9146FF), const Color(0xFF772CE8)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/twitch.svg',
    ),

    // Gaming
    'xbox game pass': SubscriptionIconData(
      icon: Icons.sports_esports_rounded,
      color: const Color(0xFF107C10),
      gradient: [const Color(0xFF107C10), const Color(0xFF0E6A0E)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/xbox.svg',
    ),
    'playstation plus': SubscriptionIconData(
      icon: Icons.sports_esports,
      color: const Color(0xFF003087),
      gradient: [const Color(0xFF003087), const Color(0xFF002A73)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/playstation.svg',
    ),
    'nintendo switch online': SubscriptionIconData(
      icon: Icons.sports_esports_outlined,
      color: const Color(0xFFE60012),
      gradient: [const Color(0xFFE60012), const Color(0xFFCC0010)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/nintendoswitch.svg',
    ),

    // Cloud Storage
    'google drive': SubscriptionIconData(
      icon: Icons.cloud_rounded,
      color: const Color(0xFF4285F4),
      gradient: [const Color(0xFF4285F4), const Color(0xFF3367D6)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/googledrive.svg',
    ),
    'google one': SubscriptionIconData(
      icon: Icons.cloud_circle_rounded,
      color: const Color(0xFF4285F4),
      gradient: [const Color(0xFF4285F4), const Color(0xFF3367D6)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/google.svg',
    ),
    'dropbox': SubscriptionIconData(
      icon: Icons.cloud_upload_rounded,
      color: const Color(0xFF0061FF),
      gradient: [const Color(0xFF0061FF), const Color(0xFF0052D9)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/dropbox.svg',
    ),
    'icloud': SubscriptionIconData(
      icon: Icons.cloud_outlined,
      color: const Color(0xFF3693F3),
      gradient: [const Color(0xFF3693F3), const Color(0xFF2B7DD8)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/icloud.svg',
    ),
    'onedrive': SubscriptionIconData(
      icon: Icons.cloud_done_rounded,
      color: const Color(0xFF0078D4),
      gradient: [const Color(0xFF0078D4), const Color(0xFF0063B1)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/microsoftonedrive.svg',
    ),

    // Productivity
    'microsoft 365': SubscriptionIconData(
      icon: Icons.work_outline_rounded,
      color: const Color(0xFFD83B01),
      gradient: [const Color(0xFFD83B01), const Color(0xFFBF3501)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/microsoft.svg',
    ),
    'office 365': SubscriptionIconData(
      icon: Icons.work_outline_rounded,
      color: const Color(0xFFD83B01),
      gradient: [const Color(0xFFD83B01), const Color(0xFFBF3501)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/microsoftoffice.svg',
    ),
    'adobe': SubscriptionIconData(
      icon: Icons.design_services_rounded,
      color: const Color(0xFFFF0000),
      gradient: [const Color(0xFFFF0000), const Color(0xFFCC0000)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/adobe.svg',
    ),
    'adobe creative cloud': SubscriptionIconData(
      icon: Icons.design_services_rounded,
      color: const Color(0xFFFF0000),
      gradient: [const Color(0xFFFF0000), const Color(0xFFCC0000)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/adobecreativecloud.svg',
    ),
    'notion': SubscriptionIconData(
      icon: Icons.note_alt_rounded,
      color: const Color(0xFF000000),
      gradient: [const Color(0xFF000000), const Color(0xFF1A1A1A)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/notion.svg',
    ),
    'evernote': SubscriptionIconData(
      icon: Icons.notes_rounded,
      color: const Color(0xFF00A82D),
      gradient: [const Color(0xFF00A82D), const Color(0xFF009127)],
      logoUrl: 'https://cdn.jsdelivr.net/npm/simple-icons@v9/icons/evernote.svg',
    ),

    // Music (Turkish)
    'fizy': SubscriptionIconData(
      icon: Icons.music_note_rounded,
      color: const Color(0xFFFF6B00),
      gradient: [const Color(0xFFFF6B00), const Color(0xFFE65F00)],
    ),
    'muud': SubscriptionIconData(
      icon: Icons.music_note,
      color: const Color(0xFF9B59B6),
      gradient: [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
    ),

    // Turkish Platforms
    'turkcell tv+': SubscriptionIconData(
      icon: Icons.tv,
      color: const Color(0xFFFFCC00),
      gradient: [const Color(0xFFFFCC00), const Color(0xFFE6B800)],
    ),
    'blu tv': SubscriptionIconData(
      icon: Icons.play_circle_filled,
      color: const Color(0xFF0078D4),
      gradient: [const Color(0xFF0078D4), const Color(0xFF0063B1)],
    ),
    'gain': SubscriptionIconData(
      icon: Icons.movie_rounded,
      color: const Color(0xFFE74C3C),
      gradient: [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
    ),
    'bein connect': SubscriptionIconData(
      icon: Icons.sports_soccer_rounded,
      color: const Color(0xFFE30613),
      gradient: [const Color(0xFFE30613), const Color(0xFFC40511)],
    ),
  };

  // Platform adına göre ikon al
  static SubscriptionIconData? getIcon(String? name) {
    if (name == null || name.isEmpty) return null;

    final normalizedName = name.toLowerCase().trim();

    // Tam eşleşme kontrolü
    if (_platforms.containsKey(normalizedName)) {
      return _platforms[normalizedName];
    }

    // Kısmi eşleşme kontrolü (örn: "youtube premium" için "youtube")
    for (var key in _platforms.keys) {
      if (normalizedName.contains(key) || key.contains(normalizedName)) {
        return _platforms[key];
      }
    }

    return null;
  }

  // Varsayılan ikon
  static SubscriptionIconData getDefaultIcon() {
    return SubscriptionIconData(
      icon: Icons.subscriptions_rounded,
      color: ColorConstant.primaryPurple,
      gradient: [ColorConstant.primaryPurple, ColorConstant.accentBlue],
    );
  }

  // Tüm platformların listesi (autocomplete için)
  static List<String> getAllPlatformNames() {
    return _platforms.keys.map((key) => _capitalize(key)).toList()..sort();
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class SubscriptionIconData {
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String? logoUrl;

  SubscriptionIconData({
    required this.icon,
    required this.color,
    required this.gradient,
    this.logoUrl,
  });
}
