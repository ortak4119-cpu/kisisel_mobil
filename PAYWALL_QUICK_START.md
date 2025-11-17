# 🚀 Paywall - Hızlı Başlangıç

## ✅ Yapılanlar

Tüm paywall sistemi hazır! Aşağıdaki dosyalar oluşturuldu:

```
📦 Yeni Dosyalar:
├── lib/service/revenue_cat/revenue_cat_service.dart       ✨ RevenueCat servisi
├── lib/presentation/paywall/
│   ├── view/paywall_view.dart                             ✨ Modern paywall UI
│   └── viewmodel/paywall_viewmodel.dart                   ✨ Business logic
├── assets/translations/tr-TR.json                          ✨ Çeviriler eklendi
├── PAYWALL_SETUP_GUIDE.md                                  📚 Detaylı kurulum rehberi
└── PAYWALL_QUICK_START.md                                  ⚡ Bu dosya
```

## 🎯 Hızlı Adımlar (5 Dakika)

### 1. RevenueCat API Keys Ekle

`lib/core/constant/constants.dart` dosyasını aç ve güncelleyin:

```dart
class Constants {
  // RevenueCat keys
  static const String revenueCatApiKeyIOS = 'appl_xxxxxxxxxxxxxxxxxxxxx';     // ← Buraya iOS key
  static const String revenueCatApiKeyAndroid = 'goog_xxxxxxxxxxxxxxxxxxxxx'; // ← Buraya Android key
}
```

**API Key'leri nereden alacaksınız?**
1. [RevenueCat Dashboard](https://app.revenuecat.com) → Login
2. Project Settings → API Keys
3. Public App-Specific API Keys'i kopyalayın

### 2. RevenueCat Dashboard Ayarları

#### A. Products Oluştur
1. **App Store Connect** (iOS):
   - Identifier: `monthly_premium`, `annual_premium`, `lifetime_premium`
   - Annual'a 1 hafta free trial ekle

2. **Google Play Console** (Android):
   - Aynı identifier'ları kullan

#### B. RevenueCat'te Products Ekle
```
Dashboard → Products → Add Product
├── monthly_premium  (Auto-Renewing Subscription)
├── annual_premium   (Auto-Renewing Subscription)
└── lifetime_premium (Non-Consumable)
```

#### C. Entitlement Oluştur
```
Dashboard → Entitlements → Create
Name: premium
Products: monthly_premium, annual_premium, lifetime_premium
```

#### D. Offering Oluştur
```
Dashboard → Offerings → Create
Identifier: default
Packages:
  - Monthly ($rc_monthly)   → monthly_premium
  - Annual ($rc_annual)     → annual_premium
  - Lifetime ($rc_lifetime) → lifetime_premium

Set as Current: ✓
```

### 3. Paywall'ı Kullan

Herhangi bir yerden paywall açın:

```dart
import 'package:auto_route/auto_route.dart';

// Örnek: Settings'te Premium butonu
ElevatedButton(
  onPressed: () async {
    final isPremium = await context.router.push(PaywallRoute());

    if (isPremium == true) {
      print('🎉 Kullanıcı Premium oldu!');
      // UI'ı güncelleyin
    }
  },
  child: Text('Premium\'a Geç'),
)
```

### 4. Premium Kontrolü

```dart
import 'package:base/service/revenue_cat/revenue_cat_service.dart';

final revenueCat = RevenueCatService();
bool isPremium = await revenueCat.isPremiumUser();

if (isPremium) {
  // Premium özellikler
} else {
  // Free özellikler
}
```

## 🎨 Paywall Özellikleri

✨ **Hazır Özellikler:**
- 3 paket seçeneği (Aylık, Yıllık, Lifetime)
- Yıllık pakette 1 hafta ücretsiz deneme badge'i
- Tasarruf yüzdesi gösterimi
- Dinamik fiyatlandırma (RevenueCat'ten otomatik)
- Restore purchases (geri yükleme)
- Dark mode desteği
- Türkçe çeviriler
- Modern animasyonlar

## 📱 Test Etme

### Sandbox Test (Geliştirme)
```bash
# iOS
Settings → App Store → Sandbox Account → Test kullanıcısı ile giriş

# Android
Google Play Console → License Testing → Email ekle
```

### Production Test
```bash
# iOS: TestFlight
# Android: Internal Testing
```

## 🔥 Webhook (Backend Entegrasyonu)

Webhook URL'inizi RevenueCat'e ekleyin:

```
Dashboard → Integrations → Webhooks
URL: https://yourapi.com/webhooks/revenuecat

Events:
✓ INITIAL_PURCHASE
✓ RENEWAL
✓ CANCELLATION
✓ EXPIRATION
```

**Backend Örneği:**
```javascript
app.post('/webhooks/revenuecat', async (req, res) => {
  const { app_user_id, type } = req.body;

  switch(type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
      await makeUserPremium(app_user_id);
      break;
    case 'CANCELLATION':
    case 'EXPIRATION':
      await removeUserPremium(app_user_id);
      break;
  }

  res.status(200).send('OK');
});
```

## ⚡ Hızlı Checklist

- [ ] RevenueCat hesabı oluşturuldu
- [ ] API Keys `constants.dart`'a eklendi
- [ ] App Store / Play Console'da products oluşturuldu
- [ ] RevenueCat'te products eklendi
- [ ] Entitlement oluşturuldu (`premium`)
- [ ] Offering oluşturuldu ve current yapıldı
- [ ] Uygulamayı test ettim
- [ ] Premium kontrolleri ekledim
- [ ] Webhook ayarlandı (opsiyonel)

## 🆘 Sorun mu var?

Detaylı troubleshooting için:
👉 **PAYWALL_SETUP_GUIDE.md** dosyasına bakın

## 📚 Kaynaklar

- [RevenueCat Docs](https://docs.revenuecat.com)
- [Flutter Package](https://pub.dev/packages/purchases_flutter)
- [Sample Apps](https://github.com/RevenueCat/purchases-flutter)

---

**Hazırsınız!** 🎉 Paywall ekranınız kullanıma hazır!
