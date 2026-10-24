/// Uygulamanın o anki dil kodu (easy_localization seçimine göre).
/// API isteklerinde `Accept-Language` başlığı olarak gönderilir; böylece
/// backend mesajları kullanıcının seçtiği dile göre döner.
/// [MyApp.build] içinde `context.locale` değiştikçe güncellenir.
class AppLocale {
  static String code = 'en';
}
