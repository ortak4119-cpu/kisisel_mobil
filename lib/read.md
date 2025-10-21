Flutter MVVM Projesi
Proje Mimarisi
Temel Yapı

Mimari Pattern: MVVM (Model-View-ViewModel)
State Management: Provider
Navigasyon: Auto Route
Çeviri: Easy Localization
Dependency Injection: GetIt
HTTP İstekleri: http package
Tema Yönetimi: ThemeProvider (Custom)

📁 Klasör Yapısı
lib/
├── core/
│   ├── routes/
│   │   └── app_router.dart
│   ├── utils/
│   │   ├── color_constant.dart
│   │   ├── date_formatter.dart
│   │   ├── image_constant.dart
│   │   ├── local_storage_keys.dart
│   │   ├── math_utils.dart
│   │   │── theme_provider.dart
│   │   └── custom_snackbar.dart
│   └── app_export.dart
├── models/
├── presentation/
│   └── [sayfa_adi]/
│       ├── view/
│       │   └── [sayfa_adi]_view.dart
│       └── viewmodel/
│           └── [sayfa_adi]_viewmodel.dart
├── service/
│   ├── local/
│   │   └── local_storage_service.dart
│   └── response/
│       └── service_response.dart
├── widgets/
├── locator.dart
└── main.dart



📦 Kullanılan Paketler
Core Dependencies

cupertino_icons: ^1.0.8
cached_network_image: ^3.4.1
shared_preferences: ^2.5.3
auto_route: ^10.0.1
firebase_core: ^3.13.0
provider: ^6.1.5
easy_localization: ^3.0.7+1
firebase_auth: ^5.5.3
cloud_firestore: ^5.6.7
flutter_svg: ^2.1.0
in_app_review: ^2.0.10
package_info_plus: ^8.3.0
firebase_messaging: ^15.2.5
url_launcher: ^6.3.1
share_plus: ^11.0.0
purchases_flutter: ^8.7.5
firebase_analytics: ^11.4.5
get_it: ^8.0.3
http: ^1.3.0






🎨 Kodlama Standartları
View Katmanı
dart@RoutePage()
class ProfileView extends StatelessWidget {
const ProfileView({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider(
create: (_) => ProfileViewModel(),
child: Consumer<ProfileViewModel>(
builder: (context, viewmodel, _) {
return Scaffold(
// UI implementasyonu
);
}
),
);
}
}
ViewModel Katmanı


dartclass ProfileViewModel extends ChangeNotifier {
final IProfileService _profileService = locator.get<IProfileService>();

// State değişkenleri
bool _isLoading = false;
Profile? _profile;

// Getters
bool get isLoading => _isLoading;
Profile? get profile => _profile;

// Constructor
ProfileViewModel() {
_initialization();
}

// Methods
Future<void> _initialization() async {
// Initialization logic
}

// Setters with notification
set setIsLoading(bool value) {
_isLoading = value;
notifyListeners();
}
}
Service Katmanı
dartabstract class IProfileService {
Future<ServiceResponse> getProfile({required String accessToken});
Future<ServiceResponse> updateProfile({
required String accessToken,
required Map<String, dynamic> data
});
}

class ProfileService extends IProfileService {
@override
Future<ServiceResponse> getProfile({required String accessToken}) async {
try {
final apiUrl = Uri.parse("${Constants.devBaseUrl}/api/mobile/profile");

      final response = await http.get(
        apiUrl,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "x-api-key": Constants.xApiKey,
          "Authorization": "Bearer $accessToken",
        },
      );
      
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        Profile profile = Profile.fromJson(jsonBody);
        return ServiceResponse(
          statusCode: response.statusCode,
          body: profile
        );
      } else {
        return ServiceResponse(
          statusCode: response.statusCode,
          body: 'Bir hata oluştu'
        );
      }
    } catch (e) {
      return ServiceResponse(
        statusCode: 0,
        body: 'Bir hata oluştu: ${e.toString()}'
      );
    }
}
}
🛠️ Yardımcı Sistemler
1. Responsif Tasarım (math_utils.dart)

getHorizontalSize(): Yatay ölçülendirme (375px baz)
getVerticalSize(): Dikey ölçülendirme (768px baz)
getFontSize(): Font boyutu hesaplama
getSize(): Minimum boyut
getPadding(): Responsif padding
getMargin(): Responsif margin

2. Tema Sistemi

ColorConstant: Merkezi renk yönetimi
ThemeProvider: Dinamik tema değişimi
Light/Dark mod desteği
Logoya uyumlu renk paleti

3. Tarih Formatlaması (date_formatter.dart)

timerFormatter(): Süre formatı (MM)
dateFormatterYearMonthDay(): Tarih formatı (YYYY-MM-DD)
daysUntil(): Kalan gün hesaplama
formatTimeAgo(): Geçen zaman formatı (1dk önce, 2s önce)


🧭 Navigation Kullanımı
dart// Route navigation
AutoRouter.of(context).push(const ProfileRoute());

// With parameters
AutoRouter.of(context).push(ProfileDetailRoute(id: 123));

// Replace current route
AutoRouter.of(context).replace(const HomeRoute());

// Pop
AutoRouter.of(context).pop();
🧩 Widget Standartları

CustomButton: Özel buton komponenti
CustomHintTextField: Text input komponenti
CustomSnackbar: Bildirim gösterimi
CustomProgressIndicator: Yükleme göstergesi
VerticalSpace/HorizontalSpace: Boşluk yönetimi

✅ Best Practices

Her View bir StatelessWidget olmalı
Business logic ViewModel'de tutulmalı
Service katmanında interface kullanılmalı
Tüm API çağrıları try-catch ile sarmalanmalı
Loading state'leri UI'da gösterilmeli
Error handling CustomSnackbar ile yapılmalı
TextEditingController'lar dispose edilmeli
FocusNode'lar yönetilmeli
Responsive tasarım her zaman kullanılmalı
Tema değişiklikleri ThemeProvider üzerinden yapılmalı

🔒 Firebase Anonymous Auth Sistemi

Onboarding sonrası opsiyonel bilgi toplama
Anonymous authentication ile sessiz giriş
Firestore'da kullanıcı profili oluşturma
İleride gerçek hesaba upgrade imkanı



💳 Ödeme Sistemi

RevenueCat entegrasyonu
Abonelik yönetimi
In-app purchase desteği

🌍 Localization

Easy Localization ile çoklu dil desteği
JSON tabanlı çeviri dosyaları
Dinamik dil değişimi

📊 Analytics

Firebase Analytics entegrasyonu
Event tracking
User properties

🔄 State Management Patterns
dart// State update pattern
set setProfile(Profile value) {
_profile = value;
notifyListeners();
}

// Multiple state updates
void updateMultipleStates() {
_isLoading = true;
_error = null;
notifyListeners();
}