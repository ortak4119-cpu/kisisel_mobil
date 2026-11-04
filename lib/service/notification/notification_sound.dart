import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir bildirim sesi seçeneği. Android'de her ses AYRI kanala bağlanır
/// (kanal sesi oluşturulduktan sonra değiştirilemez), iOS'ta ses bildirim
/// başına verilir. [asset] uygulama içi önizleme (audioplayers) içindir.
class NotifSound {
  final String id; // kalıcı anahtar + backend değeri
  final String nameKey; // i18n: settings.<nameKey>
  final String channelId; // Android kanal kimliği (push payload da bunu gönderir)
  final String? raw; // android res/raw adı (uzantısız); null = sistem varsayılanı
  final String? iosFile; // iOS bundle dosyası; null = 'default'
  final String? asset; // assets/sounds/... önizleme; null = önizleme yok
  final bool playSound;

  const NotifSound({
    required this.id,
    required this.nameKey,
    required this.channelId,
    this.raw,
    this.iosFile,
    this.asset,
    this.playSound = true,
  });

  /// Seçilebilir sesler. 'default' = sistem sesi, 'silent' = sessiz.
  static const List<NotifSound> all = [
    NotifSound(
        id: 'chime',
        nameKey: 'snd_chime',
        channelId: 'snd_chime',
        raw: 'notif_chime',
        iosFile: 'notif_chime.wav',
        asset: 'sounds/notif_chime.wav'),
    NotifSound(
        id: 'marimba',
        nameKey: 'snd_marimba',
        channelId: 'snd_marimba',
        raw: 'notif_marimba',
        iosFile: 'notif_marimba.wav',
        asset: 'sounds/notif_marimba.wav'),
    NotifSound(
        id: 'bell',
        nameKey: 'snd_bell',
        channelId: 'snd_bell',
        raw: 'notif_bell',
        iosFile: 'notif_bell.wav',
        asset: 'sounds/notif_bell.wav'),
    NotifSound(
        id: 'soft',
        nameKey: 'snd_soft',
        channelId: 'snd_soft',
        raw: 'notif_soft',
        iosFile: 'notif_soft.wav',
        asset: 'sounds/notif_soft.wav'),
    NotifSound(
        id: 'pop',
        nameKey: 'snd_pop',
        channelId: 'snd_pop',
        raw: 'notif_pop',
        iosFile: 'notif_pop.wav',
        asset: 'sounds/notif_pop.wav'),
    NotifSound(
        id: 'default',
        nameKey: 'snd_default',
        channelId: 'high_importance_channel'),
    NotifSound(
        id: 'silent',
        nameKey: 'snd_silent',
        channelId: 'snd_silent',
        playSound: false),
  ];

  static NotifSound byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

/// Seçili bildirim sesi tercihi (cihazda kalıcı). Backend'e de gönderilir ki
/// arka plandaki push'larda doğru kanal/ses kullanılsın.
class NotifSoundPrefs {
  static const String _key = 'notif_sound_id';
  static String _id = 'chime';

  /// Seçim değişince UI'ı (Ayarlar tile alt yazısı) yenilemek için.
  static final ValueNotifier<String> idListenable = ValueNotifier<String>(_id);

  static String get currentId => _id;
  static NotifSound get current => NotifSound.byId(_id);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_key);
      if (id != null && NotifSound.all.any((s) => s.id == id)) {
        _id = id;
        idListenable.value = id;
      }
    } catch (_) {}
  }

  static Future<void> set(String id) async {
    if (!NotifSound.all.any((s) => s.id == id)) return;
    _id = id;
    idListenable.value = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, id);
    } catch (_) {}
  }
}
