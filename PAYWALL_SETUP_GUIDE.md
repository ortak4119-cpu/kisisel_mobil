# 💰 RevenueCat Paywall Kurulum Rehberi

Bu rehber, RevenueCat entegrasyonlu paywall ekranının nasıl kurulup kullanılacağını açıklar.

## ✅ Yapılmış Olanlar

1. ✅ **RevenueCat Service** - `lib/service/revenue_cat/revenue_cat_service.dart`
2. ✅ **Paywall ViewModel** - `lib/presentation/paywall/viewmodel/paywall_viewmodel.dart`
3. ✅ **Paywall UI** - `lib/presentation/paywall/view/paywall_view.dart`
4. ✅ **Türkçe Çeviriler** - `assets/translations/tr-TR.json`
5. ✅ **Router Yapılandırması** - `lib/core/route/app_router.dart`
6. ✅ **Package** - `purchases_flutter: ^8.7.5` (zaten kuruluydu)

## 🚀 Kurulum Adımları

### 1. RevenueCat Dashboard Ayarları

#### A. RevenueCat Hesabı Oluşturun
1. [RevenueCat Dashboard](https://app.revenuecat.com)'a gidin
2. Yeni bir proje oluşturun
3. iOS ve Android uygulamalarını ekleyin

#### B. API Keys
1. Dashboard'da **API Keys** bölümüne gidin
2. iOS ve Android için **Public API Keys**'i kopyalayın
3. `lib/service/revenue_cat/revenue_cat_service.dart` dosyasında güncelleyin:

```dart
static const String _apiKeyIOS = 'YOUR_IOS_API_KEY'; // Buraya iOS key'i
static const String _apiKeyAndroid = 'YOUR_ANDROID_API_KEY'; // Buraya Android key'i
```

#### C. Products Oluşturma (App Store Connect / Google Play Console)

**iOS (App Store Connect):**
1. App Store Connect'e giriş yapın
2. **My Apps** → Uygulamanız → **Features** → **In-App Purchases**
3. Yeni ürünler oluşturun:
   - **Monthly Subscription**: `monthly_premium` (identifier)
   - **Annual Subscription**: `annual_premium` (1 haftalık free trial ekleyin)
   - **Lifetime Purchase**: `lifetime_premium` (Non-Consumable)

**Android (Google Play Console):**
1. Google Play Console'a giriş yapın
2. **Uygulamanız** → **Monetize** → **Products** → **Subscriptions**
3. Aynı identifier'ları kullanarak ürünler oluşturun

#### D. RevenueCat'te Products Yapılandırma
1. RevenueCat Dashboard → **Products** → **Add Product**
2. Her ürün için Store'dan oluşturduğunuz identifier'ları ekleyin
3. **Entitlements** oluşturun:
   - Entitlement identifier: `premium`
   - Products ekleyin: monthly, annual, lifetime

#### E. Offering Oluşturma
1. **Offerings** → **Create New Offering**
2. Offering identifier: `default` (veya istediğiniz bir isim)
3. Packages ekleyin:
   - **Package 1**: Monthly (`$rc_monthly`) → monthly_premium
   - **Package 2**: Annual (`$rc_annual`) → annual_premium
   - **Package 3**: Lifetime (`$rc_lifetime`) → lifetime_premium
4. Bu offering'i **Current** olarak ayarlayın

### 2. Webhook Yapılandırması (Opsiyonel)

RevenueCat'in webhook'larını backend'inize bağlamak için:

1. RevenueCat Dashboard → **Integrations** → **Webhooks**
2. Webhook URL'inizi ekleyin (örn: `https://yourapi.com/webhooks/revenuecat`)
3. Dinlemek istediğiniz event'leri seçin:
   - `INITIAL_PURCHASE`
   - `RENEWAL`
   - `CANCELLATION`
   - `EXPIRATION`

**Örnek Webhook Handler (Backend):**
```javascript
app.post('/webhooks/revenuecat', async (req, res) => {
  const event = req.body;

  const { app_user_id, product_id, event_timestamp_ms, type } = event;

  switch(type) {
    case 'INITIAL_PURCHASE':
      // Kullanıcıyı premium yap
      await updateUserToPremium(app_user_id);
      break;
    case 'RENEWAL':
      // Aboneliği yenile
      await renewSubscription(app_user_id);
      break;
    case 'CANCELLATION':
    case 'EXPIRATION':
      // Premium'u kaldır
      await removeUserFromPremium(app_user_id);
      break;
  }

  res.status(200).send('OK');
});
```

### 3. Uygulamada Kullanım

#### A. RevenueCat'i Başlatma (App Başlangıcında)

`lib/main.dart` veya ilk sayfanızda:

```dart
import 'package:your_app/service/revenue_cat/revenue_cat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RevenueCat'i başlat
  final revenueCat = RevenueCatService();
  await revenueCat.initialize();

  // Kullanıcı varsa ID'yi set et
  // await revenueCat.setUserId('user_123');

  runApp(MyApp());
}
```

#### B. Paywall Ekranını Açma

Herhangi bir yerden paywall'ı açabilirsiniz:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:your_app/core/route/app_router.gr.dart';

// Settings'te premium butonu
ElevatedButton(
  onPressed: () async {
    final result = await context.router.push(PaywallRoute());

    if (result == true) {
      // Kullanıcı premium oldu!
      print('User is now premium! 🎉');
      // UI'ı güncelleyin
    }
  },
  child: Text('Premium\'a Geç'),
)
```

#### C. Premium Durumunu Kontrol Etme

```dart
import 'package:your_app/service/revenue_cat/revenue_cat_service.dart';

final revenueCat = RevenueCatService();

// Premium mi kontrol et
bool isPremium = await revenueCat.isPremiumUser();

if (isPremium) {
  // Premium özellikleri göster
} else {
  // Free özellikleri göster
}
```

#### D. Real-time Premium Dinleme

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RevenueCatService _revenueCat = RevenueCatService();
  bool _isPremium = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _listenToPremiumChanges();
  }

  void _checkPremiumStatus() async {
    final isPremium = await _revenueCat.isPremiumUser();
    setState(() {
      _isPremium = isPremium;
    });
  }

  void _listenToPremiumChanges() {
    _subscription = _revenueCat.customerInfoStream.listen((customerInfo) {
      final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      setState(() {
        _isPremium = isPremium;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isPremium
        ? PremiumContent()
        : FreeContent(),
    );
  }
}
```

## 🎨 Paywall Özellikleri

### Mevcut Özellikler

1. ✨ **Modern UI/UX** - Gradient background, animations
2. 📦 **3 Paket Seçeneği**:
   - Aylık abonelik
   - Yıllık abonelik (1 hafta ücretsiz deneme)
   - Tek seferlik satın alım (Lifetime)
3. 💰 **Dinamik Fiyatlandırma** - RevenueCat'ten otomatik çeker
4. 🏷️ **Tasarruf Badge'leri** - "Save %30", "Free Trial"
5. 🔄 **Restore Purchases** - Önceki satın alımları geri yükleme
6. 🌍 **Multi-language** - easy_localization ile çeviriler
7. 📱 **Dark Mode** - Otomatik tema desteği

### Özelleştirme

**Özellikleri Değiştirme:**
`lib/presentation/paywall/view/paywall_view.dart` → `_buildFeaturesList` metodunda:

```dart
final features = [
  {
    'icon': Icons.sync_rounded,
    'title': 'paywall.feature1_title'.tr(),
    'subtitle': 'paywall.feature1_subtitle'.tr(),
  },
  // Yeni özellik ekle
  {
    'icon': Icons.your_icon,
    'title': 'Yeni Özellik',
    'subtitle': 'Açıklama',
  },
];
```

**Renkleri Değiştirme:**
`lib/core/utils/color_constant.dart` dosyasındaki renkleri düzenleyin.

## 🧪 Test Etme

### Sandbox Test

**iOS:**
1. Settings → App Store → Sandbox Account
2. Test kullanıcısı oluşturun (App Store Connect → Users and Access → Sandbox Testers)
3. Uygulamada satın alma yapın, sandbox hesabı ile giriş yapın

**Android:**
1. Google Play Console → Setup → License Testing
2. Test email'inizi ekleyin
3. Internal Testing track'ine yükleyin ve test edin

### Production Test

1. TestFlight (iOS) veya Internal Testing (Android) kullanın
2. Gerçek satın alma yapmadan test edin
3. RevenueCat Dashboard'dan satın alımları kontrol edin

## 📊 Analytics ve Monitoring

RevenueCat Dashboard'dan:
- 📈 **Overview**: Gelir, active subscriptions
- 👥 **Customers**: Kullanıcı detayları
- 📊 **Charts**: Revenue charts, churn rate
- 🔔 **Events**: Real-time subscription events

## ⚠️ Önemli Notlar

1. **Test Modda Çalıştırın**: Production'a geçmeden önce sandbox'ta test edin
2. **Webhook'ları Ayarlayın**: Backend ile senkronize olmak için önemli
3. **Error Handling**: Paywall'da hata yakalamayı unutmayın
4. **Privacy Policy**: Satın alma ekranında gizlilik politikası linki gerekli
5. **Store Review**: App Store/Play Store review guidelines'a uyun

## 🆘 Sorun Giderme

### Paketler yüklenmiyor
- RevenueCat API Key'lerini kontrol edin
- Offering'in "Current" olarak ayarlandığından emin olun
- Products'ların doğru identifier'larla eşleştiğini kontrol edin

### Satın alma tamamlanmıyor
- Sandbox hesabı ile giriş yaptığınızdan emin olun
- Internet bağlantısını kontrol edin
- RevenueCat Dashboard → Debug Logs'u kontrol edin

### Webhook çalışmıyor
- Webhook URL'in https olduğundan emin olun
- Backend'de endpoint'in açık olduğunu kontrol edin
- RevenueCat Dashboard → Webhooks → Delivery Logs'u kontrol edin

## 📚 Kaynaklar

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [Flutter Package Docs](https://pub.dev/packages/purchases_flutter)
- [Sample Apps](https://github.com/RevenueCat/purchases-flutter/tree/main/revenuecat_examples)

---

## 🎯 Quick Checklist

- [ ] RevenueCat hesabı oluşturuldu
- [ ] API Keys eklendi
- [ ] App Store Connect / Play Console'da products oluşturuldu
- [ ] RevenueCat'te products eklendi
- [ ] Entitlement oluşturuldu (`premium`)
- [ ] Offering oluşturuldu ve current yapıldı
- [ ] `main.dart`'ta RevenueCat initialize edildi
- [ ] Paywall test edildi
- [ ] Premium kontrolleri eklendi
- [ ] Webhook yapılandırıldı (opsiyonel)
- [ ] Production'a deploy edildi

Başarılar! 🚀
