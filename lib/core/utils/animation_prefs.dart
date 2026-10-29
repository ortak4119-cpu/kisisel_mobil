import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama geneli animasyon tercihi.
/// Ayarlar › Görünüm › "Animasyonları kapat" bu bayrağı değiştirir;
/// animasyonlu widget'lar (örn. Notlar esinti/overlay'leri) [enabled]'ı okur.
///
/// Varsayılan: açık (true). SharedPreferences ile kalıcı; uygulama açılışında
/// [load] çağrılır.
class AnimationPrefs {
  AnimationPrefs._();

  static const String _key = 'animations_enabled';

  /// Canlı dinlenebilir bayrak. `true` = animasyonlar açık.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Kısa yol: o anki değer.
  static bool get isOn => enabled.value;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_key) ?? true;
    } catch (_) {
      // Okuma hatası: varsayılan açık kalır.
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, value);
    } catch (_) {
      // Yazma hatası: en azından bellek içi değer güncellendi.
    }
  }
}
