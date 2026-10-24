import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama para birimi yönetimi.
/// - İlk açılışta cihazın ülkesine göre varsayılan belirlenir.
/// - Kullanıcı ayarlardan değiştirebilir (yerel olarak saklanır).
/// - Para birimi bir görüntüleme/etiket tercihidir: tutarlar girildikleri
///   değerde saklanır, birim değişince yalnızca sembol/biçim değişir (kur
///   dönüşümü yapılmaz).
class AppCurrency {
  static const String _kKey = 'app_currency_code_v1';

  static String code = 'TRY';
  static String symbol = '₺';
  static String localeTag = 'tr_TR';

  /// Desteklenen para birimleri: code -> [symbol, localeTag, isim]
  static const Map<String, List<String>> currencies = {
    'TRY': ['₺', 'tr_TR', 'Türk Lirası'],
    'USD': ['\$', 'en_US', 'US Dollar'],
    'EUR': ['€', 'de_DE', 'Euro'],
    'GBP': ['£', 'en_GB', 'British Pound'],
    'RUB': ['₽', 'ru_RU', 'Russian Ruble'],
    'JPY': ['¥', 'ja_JP', 'Japanese Yen'],
    'CNY': ['¥', 'zh_CN', 'Chinese Yuan'],
    'INR': ['₹', 'hi_IN', 'Indian Rupee'],
    'BRL': ['R\$', 'pt_BR', 'Brazilian Real'],
    'AED': ['د.إ', 'ar_AE', 'UAE Dirham'],
    'SAR': ['﷼', 'ar_SA', 'Saudi Riyal'],
    'CHF': ['CHF', 'de_CH', 'Swiss Franc'],
    'CAD': ['C\$', 'en_CA', 'Canadian Dollar'],
    'AUD': ['A\$', 'en_AU', 'Australian Dollar'],
  };

  /// Ülke kodu -> para birimi kodu (varsayılan belirleme için).
  static const Map<String, String> _countryToCurrency = {
    'TR': 'TRY',
    'US': 'USD',
    'GB': 'GBP',
    'RU': 'RUB',
    'JP': 'JPY',
    'CN': 'CNY',
    'IN': 'INR',
    'BR': 'BRL',
    'AE': 'AED',
    'SA': 'SAR',
    'CH': 'CHF',
    'CA': 'CAD',
    'AU': 'AUD',
    // Euro bölgesi
    'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR',
    'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR', 'IE': 'EUR', 'FI': 'EUR',
    'GR': 'EUR',
  };

  static void _apply(String c) {
    final info = currencies[c];
    if (info == null) return;
    code = c;
    symbol = info[0];
    localeTag = info[1];
  }

  /// Uygulama açılışında çağrılır: kayıtlı tercih varsa onu, yoksa cihaz
  /// ülkesine göre varsayılanı uygular.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null && currencies.containsKey(saved)) {
        _apply(saved);
        return;
      }
      // Cihaz ülkesine göre varsayılan
      final country =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      final mapped = _countryToCurrency[country?.toUpperCase()];
      _apply(mapped ?? 'TRY');
    } catch (_) {
      _apply('TRY');
    }
  }

  /// Kullanıcı seçimini uygular ve kaydeder.
  static Future<void> setCode(String c) async {
    if (!currencies.containsKey(c)) return;
    _apply(c);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, c);
    } catch (_) {}
  }

  /// Tutarı seçili para birimi sembolü ve yerel biçimiyle gösterir.
  static String format(double v, {int decimals = 2}) {
    try {
      final f = NumberFormat.currency(
        locale: localeTag,
        symbol: symbol,
        decimalDigits: decimals,
      );
      return f.format(v);
    } catch (_) {
      return '$symbol${v.toStringAsFixed(decimals)}';
    }
  }
}
