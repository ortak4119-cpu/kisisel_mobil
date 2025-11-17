# 🌍 Çeviri Kullanım Kılavuzu (easy_localization)

Bu projede **easy_localization** paketi kullanarak çoklu dil desteği eklenmiştir.

## 📁 Dosya Yapısı

```
assets/translations/
├── tr-TR.json  # Türkçe çeviriler
└── en-US.json  # İngilizce çeviriler
```

## 🚀 Kullanım

### 1. Basit Çeviri Kullanımı

```dart
import 'package:easy_localization/easy_localization.dart';

// Metot 1: context ile
Text('auth.login'.tr())

// Metot 2: context olmadan
Text('auth.login').tr()

// Metot 3: context üzerinden
Text(context.tr('auth.login'))
```

### 2. Parametreli Çeviriler

JSON'da parametreli metin tanımlama:
```json
{
  "profile.stats.level": "Level {{level}}",
  "validation.passwordMinLength": "Şifre en az {{length}} karakter olmalı"
}
```

Kullanımı:
```dart
Text('profile.stats.level'.tr(namedArgs: {'level': '5'}))
Text('validation.passwordMinLength'.tr(namedArgs: {'length': '8'}))
```

### 3. Çoğul (Plural) Kullanımı

JSON'da:
```json
{
  "notifications": {
    "zero": "Bildirim yok",
    "one": "1 bildirim",
    "other": "{{count}} bildirim"
  }
}
```

Kullanımı:
```dart
Text(plural('notifications', 0))  // "Bildirim yok"
Text(plural('notifications', 1))  // "1 bildirim"
Text(plural('notifications', 5))  // "5 bildirim"
```

### 4. Dil Değiştirme

```dart
// Türkçe'ye geç
context.setLocale(Locale('tr', 'TR'))

// İngilizce'ye geç
context.setLocale(Locale('en', 'US'))

// Mevcut dili kontrol et
Locale currentLocale = context.locale
```

## 📝 Çeviri Anahtarları Yapısı

Çeviri dosyası (tr-TR.json) şu şekilde yapılandırılmıştır:

### Temel Kategoriler

```
app.*                 # Uygulama genel bilgileri
common.*              # Ortak kullanılan metinler
auth.*                # Giriş/Kayıt ekranları
navigation.*          # Navigasyon öğeleri
home.*                # Ana sayfa
tasks.*               # Görevler
habits.*              # Alışkanlıklar
profile.*             # Profil
calendar.*            # Takvim
finance.*             # Finans
notes.*               # Notlar
diary.*               # Günlük
settings.*            # Ayarlar
validation.*          # Form doğrulama mesajları
errors.*              # Hata mesajları
success.*             # Başarı mesajları
```

## 🎯 Kullanım Örnekleri

### Örnek 1: Login Ekranı

```dart
Column(
  children: [
    Text('auth.welcomeBack'.tr()),  // "Tekrar Hoş Geldiniz! 👋"
    TextField(
      decoration: InputDecoration(
        labelText: 'auth.email'.tr(),
        hintText: 'auth.emailHint'.tr(),
      ),
    ),
    ElevatedButton(
      onPressed: () {},
      child: Text('auth.login'.tr()),
    ),
  ],
)
```

### Örnek 2: Silme Onayı Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('tasks.deleteTask'.tr()),
    content: Text('tasks.deleteConfirm'.tr()),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('common.cancel'.tr()),
      ),
      TextButton(
        onPressed: () {
          // Silme işlemi
          Navigator.pop(context);
        },
        child: Text('common.delete'.tr()),
      ),
    ],
  ),
);
```

### Örnek 3: Dropdown/Select

```dart
DropdownButton<String>(
  items: [
    DropdownMenuItem(
      value: 'low',
      child: Text('tasks.priority.low'.tr()),  // "Düşük"
    ),
    DropdownMenuItem(
      value: 'medium',
      child: Text('tasks.priority.medium'.tr()),  // "Orta"
    ),
    DropdownMenuItem(
      value: 'high',
      child: Text('tasks.priority.high'.tr()),  // "Yüksek"
    ),
  ],
)
```

### Örnek 4: Snackbar/Toast Mesajları

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('success.saved'.tr()),  // "Kaydedildi"
  ),
);
```

## 🔧 Yeni Çeviri Ekleme

### 1. JSON Dosyasına Ekle

`assets/translations/tr-TR.json`:
```json
{
  "myFeature": {
    "title": "Özellik Başlığı",
    "description": "Özellik açıklaması"
  }
}
```

### 2. Kodda Kullan

```dart
Text('myFeature.title'.tr())
```

## 💡 İpuçları

1. **Tutarlı Anahtar İsimlendirme**: Kategori bazlı yapı kullanın (ör: `auth.login`, `tasks.delete`)

2. **Parametreli Metinler**: Dinamik içerik için placeholder kullanın
   ```json
   "greeting": "Merhaba {{name}}"
   ```

3. **Nested Yapı**: Alt kategoriler için nokta notasyonu kullanın
   ```json
   {
     "tasks": {
       "priority": {
         "low": "Düşük"
       }
     }
   }
   ```

4. **Ortak Metinler**: Sık kullanılan metinleri `common.*` altında toplayın

5. **Emojiler**: Türkçe metinlerde emoji kullanabilirsiniz
   ```json
   "welcome": "Hoş Geldiniz! 👋"
   ```

## 🌐 Yeni Dil Ekleme

### 1. Yeni JSON Dosyası Oluştur

`assets/translations/en-US.json` gibi yeni bir dosya oluşturun.

### 2. main.dart'ta Dili Ekle

```dart
EasyLocalization(
  supportedLocales: const [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
    Locale('de', 'DE'),  // Yeni dil
  ],
  path: 'assets/translations',
  fallbackLocale: const Locale('tr', 'TR'),
  child: MyApp(),
)
```

## 🎨 Mevcut Çeviri Yapısı

Projede şu kategoriler için çeviriler hazır:

✅ Kimlik Doğrulama (Giriş/Kayıt)
✅ Onboarding Ekranları
✅ Ana Sayfa ve Navigasyon
✅ Görevler
✅ Alışkanlıklar
✅ Profil (İstatistikler, Arkadaşlar, Başarılar)
✅ Takvim
✅ Finans
✅ Notlar ve Günlük
✅ Ayarlar (Bildirimler, Tema, Güvenlik)
✅ Form Validasyon Mesajları
✅ Hata ve Başarı Mesajları

## 📚 Daha Fazla Bilgi

Resmi dokümantasyon: [easy_localization pub.dev](https://pub.dev/packages/easy_localization)
