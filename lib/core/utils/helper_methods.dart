import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihaz için benzersiz ID döndürür (SharedPreferences'ta saklanır)
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'device_unique_id';
  String? id = prefs.getString(key);
  if (id == null || id.isEmpty) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts * 1000 + (ts % 997)).toRadixString(16);
    id = 'dev-$rand';
    await prefs.setString(key, id);
  }
  return id;
}

/// Dil koduna göre para birimi döndürür
String getCurrencyFromLocale(Locale locale) {
  final Map<String, String> localeToCurrency = {
    'tr': 'TRY', // Türk Lirası
    'en': 'USD', // ABD Doları
    'zh': 'CNY', // Çin Yuanı
    'hi': 'INR', // Hint Rupisi
    'es': 'EUR', // Euro
    'ar': 'SAR', // Suudi Riyali
    'fr': 'EUR', // Euro
    'ru': 'RUB', // Rus Rublesi
    'pt': 'EUR', // Euro
    'de': 'EUR', // Euro
    'ja': 'JPY', // Japon Yeni
  };

  return localeToCurrency[locale.languageCode] ?? 'TRY';
}

