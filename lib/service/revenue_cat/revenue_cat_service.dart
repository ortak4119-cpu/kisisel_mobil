import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // RevenueCat API Keys - Bunları kendi anahtarlarınızla değiştirin
  static const String _apiKeyIOS = 'appl_AqSfLLdHoJylyNSYFEutttWrDgn';
  static const String _apiKeyAndroid = 'YOUR_ANDROID_API_KEY';

  bool _isInitialized = false;

  /// RevenueCat'i başlat
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      debugPrint('RevenueCat already initialized');
      return;
    }

    try {
      final configuration = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.iOS ? _apiKeyIOS : _apiKeyAndroid,
      );

      if (userId != null) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);

      // Log seviyesini ayarla (development için)
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('❌ RevenueCat initialization error: $e');
      rethrow;
    }
  }

  /// Kullanıcı kimliğini ayarla
  Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('✅ User logged in to RevenueCat: $userId');
    } catch (e) {
      debugPrint('❌ Error logging in user: $e');
      rethrow;
    }
  }

  /// Kullanıcı çıkışı
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      debugPrint('✅ User logged out from RevenueCat');
    } catch (e) {
      debugPrint('❌ Error logging out user: $e');
      rethrow;
    }
  }

  /// Mevcut paketleri al (offerings)
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        debugPrint('✅ Available packages: ${offerings.current!.availablePackages.length}');
        return offerings;
      } else {
        debugPrint('⚠️ No offerings available');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching offerings: $e');
      return null;
    }
  }

  /// Satın alma işlemi
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      debugPrint('🛒 Attempting to purchase: ${package.identifier}');
      final customerInfo = await Purchases.purchasePackage(package);
      debugPrint('✅ Purchase successful!');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('⚠️ User cancelled the purchase');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        debugPrint('❌ User is not allowed to purchase');
      } else {
        debugPrint('❌ Purchase error: ${e.message}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Unexpected purchase error: $e');
      return null;
    }
  }

  /// Abonelikleri restore et
  Future<CustomerInfo?> restorePurchases() async {
    try {
      debugPrint('🔄 Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('✅ Purchases restored successfully');
      return customerInfo;
    } catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
      return null;
    }
  }

  /// Kullanıcının premium durumunu kontrol et
  Future<bool> isPremiumUser() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      // Entitlement kontrolü - RevenueCat dashboard'da "premium" identifier'ı ile bir entitlement oluşturmalısınız
      final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;

      debugPrint('👤 Premium status: $isPremium');
      return isPremium;
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Müşteri bilgilerini al
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo;
    } catch (e) {
      debugPrint('❌ Error getting customer info: $e');
      return null;
    }
  }

  /// Abonelik durumunu dinle
  /// Not: Listener eklemek için addCustomerInfoUpdateListener kullanın
  void addCustomerInfoUpdateListener(Function(CustomerInfo) listener) {
    try {
      Purchases.addCustomerInfoUpdateListener(listener);
      debugPrint('✅ Customer info listener added');
    } catch (e) {
      debugPrint('❌ Error adding listener: $e');
    }
  }

  /// Listener'ı kaldır
  void removeCustomerInfoUpdateListener(Function(CustomerInfo) listener) {
    try {
      Purchases.removeCustomerInfoUpdateListener(listener);
      debugPrint('✅ Customer info listener removed');
    } catch (e) {
      debugPrint('❌ Error removing listener: $e');
    }
  }

  /// Attribution data ayarla (opsiyonel - analytics için)
  Future<void> setAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
      debugPrint('✅ Attributes set successfully');
    } catch (e) {
      debugPrint('❌ Error setting attributes: $e');
    }
  }

  /// Email ayarla
  Future<void> setEmail(String email) async {
    try {
      await Purchases.setEmail(email);
      debugPrint('✅ Email set successfully');
    } catch (e) {
      debugPrint('❌ Error setting email: $e');
    }
  }

  /// Display name ayarla
  Future<void> setDisplayName(String displayName) async {
    try {
      await Purchases.setDisplayName(displayName);
      debugPrint('✅ Display name set successfully');
    } catch (e) {
      debugPrint('❌ Error setting display name: $e');
    }
  }

  /// Package type'a göre süre string'i döndür
  String getPackageDuration(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return 'Aylık';
      case PackageType.annual:
        return 'Yıllık';
      case PackageType.lifetime:
        return 'Sınırsız';
      case PackageType.weekly:
        return 'Haftalık';
      case PackageType.sixMonth:
        return '6 Aylık';
      case PackageType.threeMonth:
        return '3 Aylık';
      case PackageType.twoMonth:
        return '2 Aylık';
      default:
        return 'Özel';
    }
  }

  /// Paket bilgilerini formatla
  Map<String, dynamic> formatPackageInfo(Package package) {
    final product = package.storeProduct;

    return {
      'identifier': package.identifier,
      'packageType': package.packageType,
      'title': product.title,
      'description': product.description,
      'price': product.priceString,
      'priceAmount': product.price,
      'currencyCode': product.currencyCode,
      'introPrice': product.introductoryPrice?.priceString,
      'hasTrial': product.introductoryPrice != null,
      'trialDuration': product.introductoryPrice?.period,
      'duration': getPackageDuration(package.packageType),
    };
  }
}
