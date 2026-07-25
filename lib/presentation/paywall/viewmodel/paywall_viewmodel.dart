import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../service/revenue_cat/revenue_cat_service.dart';
import '../../../service/profile/profile_service.dart';
import '../../../core/init/locator.dart';

class PaywallViewModel extends ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final IProfileService _profileService = locator.get<IProfileService>();

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;

  Offerings? _offerings;
  Package? _monthlyPackage;
  Package? _annualPackage;
  Package? _lifetimePackage;

  int _selectedPackageIndex = 1; // Default: Annual (index 1)

  // Getters
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;

  Offerings? get offerings => _offerings;
  Package? get monthlyPackage => _monthlyPackage;
  Package? get annualPackage => _annualPackage;
  Package? get lifetimePackage => _lifetimePackage;

  int get selectedPackageIndex => _selectedPackageIndex;

  Package? get selectedPackage {
    switch (_selectedPackageIndex) {
      case 0:
        return _monthlyPackage;
      case 1:
        return _annualPackage;
      case 2:
        return _lifetimePackage;
      default:
        return null;
    }
  }

  /// ViewModel'i başlat ve paketleri yükle
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // RevenueCat'i başlat
      await _revenueCatService.initialize();

      // Paketleri al
      await loadOfferings();
    } catch (e) {
      _errorMessage = '${'paywall.errors.initFailed'.tr()}: $e';
      debugPrint('❌ PaywallViewModel initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Offerings'leri yükle
  Future<void> loadOfferings() async {
    try {
      _offerings = await _revenueCatService.getOfferings();

      if (_offerings?.current != null) {
        final packages = _offerings!.current!.availablePackages;

        // Paketleri type'a göre ayır
        _monthlyPackage = packages.firstWhere(
          (package) => package.packageType == PackageType.monthly,
          orElse: () => packages.firstWhere(
            (package) => package.identifier.toLowerCase().contains('monthly'),
            orElse: () => packages.first,
          ),
        );

        _annualPackage = packages.firstWhere(
          (package) => package.packageType == PackageType.annual,
          orElse: () => packages.firstWhere(
            (package) => package.identifier.toLowerCase().contains('annual') ||
                package.identifier.toLowerCase().contains('yearly'),
            orElse: () => packages.length > 1 ? packages[1] : packages.first,
          ),
        );

        _lifetimePackage = packages.firstWhere(
          (package) => package.packageType == PackageType.lifetime,
          orElse: () => packages.firstWhere(
            (package) => package.identifier.toLowerCase().contains('lifetime') ||
                package.identifier.toLowerCase().contains('permanent'),
            orElse: () => packages.length > 2 ? packages[2] : packages.first,
          ),
        );

        debugPrint('✅ Packages loaded successfully');
        debugPrint('Monthly: ${_monthlyPackage?.storeProduct.priceString}');
        debugPrint('Annual: ${_annualPackage?.storeProduct.priceString}');
        debugPrint('Lifetime: ${_lifetimePackage?.storeProduct.priceString}');
      } else {
        _errorMessage = 'paywall.errors.noPackages'.tr();
        debugPrint('⚠️ No current offering available');
      }
    } catch (e) {
      _errorMessage = '${'paywall.errors.loadFailed'.tr()}: $e';
      debugPrint('❌ Error loading offerings: $e');
    }

    notifyListeners();
  }

  /// Paket seçimini değiştir
  void selectPackage(int index) {
    _selectedPackageIndex = index;
    notifyListeners();
  }

  /// Satın alma işlemi
  Future<bool> purchaseSelectedPackage() async {
    if (selectedPackage == null) {
      _errorMessage = 'paywall.errors.selectPackage'.tr();
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerInfo = await _revenueCatService.purchasePackage(selectedPackage!);

      if (customerInfo != null) {
        debugPrint('✅ Purchase successful!');

        // Backend'den kullanıcı durumunu kontrol et
        // RevenueCat webhook backend'i güncelleyecek, biz de backend'den güncel durumu alalım
        final isPremium = await _checkPremiumFromBackend();

        if (isPremium) {
          debugPrint('🎉 User is now premium!');
          return true;
        }
      }

      return false;
    } catch (e) {
      _errorMessage = '${'paywall.purchaseFailed'.tr()}: $e';
      debugPrint('❌ Purchase error: $e');
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Backend'den premium durumunu kontrol et
  Future<bool> _checkPremiumFromBackend() async {
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess && response.data != null) {
        final user = response.data!;
        final subscriptionStatus = user.subscriptionStatus;
        final subscriptionType = user.subscriptionType;

        // Aktif subscription kontrolü
        if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
          if (subscriptionType != null && subscriptionType != 'free') {
            debugPrint('✅ User is premium from backend: $subscriptionType ($subscriptionStatus)');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking premium from backend: $e');
    }
    return false;
  }

  /// Satın alımları restore et
  Future<bool> restorePurchases() async {
    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerInfo = await _revenueCatService.restorePurchases();

      if (customerInfo != null) {
        // Sadece backend'den kontrol et
        final backendPremium = await _checkPremiumFromBackend();
        if (backendPremium) {
          debugPrint('✅ Purchases restored - User is premium (from backend)');
          return true;
        } else {
          _errorMessage = 'paywall.errors.noActiveSubscription'.tr();
          debugPrint('⚠️ No active subscription found');
          return false;
        }
      }

      _errorMessage = 'paywall.errors.restoreFailed'.tr();
      return false;
    } catch (e) {
      _errorMessage = '${'paywall.errors.restoreError'.tr()}: $e';
      debugPrint('❌ Restore error: $e');
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Tasarruf yüzdesini hesapla (yıllık vs aylık)
  String getSavingsPercentage() {
    if (_monthlyPackage == null || _annualPackage == null) return '0';

    final monthlyPrice = _monthlyPackage!.storeProduct.price;
    final annualPrice = _annualPackage!.storeProduct.price;

    final monthlyYearlyCost = monthlyPrice * 12;
    final savings = ((monthlyYearlyCost - annualPrice) / monthlyYearlyCost * 100).round();

    return savings.toString();
  }

  /// Aylık fiyat karşılaştırması (yıllık pakette)
  String getMonthlyPriceForAnnual() {
    if (_annualPackage == null) return '';

    final annualPrice = _annualPackage!.storeProduct.price;
    final monthlyEquivalent = annualPrice / 12;
    final currencySymbol = _getCurrencySymbol(_annualPackage!.storeProduct.currencyCode);

    return '$currencySymbol${monthlyEquivalent.toStringAsFixed(2)}';
  }

  /// Para birimi sembolünü al
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }

  /// Trial süresi var mı kontrol et
  bool hasTrialPeriod(Package? package) {
    if (package == null) return false;
    return package.storeProduct.introductoryPrice != null;
  }

  /// Trial süresini string olarak al
  String getTrialDurationText(Package? package) {
    if (package == null || !hasTrialPeriod(package)) return '';

    final periodString = package.storeProduct.introductoryPrice!.period;

    // ISO8601 duration format parsing (e.g., "P7D", "P1W", "P1M", "P1Y")
    if (periodString.isEmpty) return '';

    // Remove 'P' prefix
    final period = periodString.substring(1);

    if (period.endsWith('D')) {
      final days = int.tryParse(period.replaceAll('D', '')) ?? 0;
      return '$days ${'paywall.duration.days'.tr()}';
    } else if (period.endsWith('W')) {
      final weeks = int.tryParse(period.replaceAll('W', '')) ?? 0;
      return '$weeks hafta';
    } else if (period.endsWith('M')) {
      final months = int.tryParse(period.replaceAll('M', '')) ?? 0;
      return '$months ay';
    } else if (period.endsWith('Y')) {
      final years = int.tryParse(period.replaceAll('Y', '')) ?? 0;
      return '$years ${'paywall.duration.years'.tr()}';
    }

    return '';
  }

  /// Trial disclosure metnini al (Apple gereksinimleri için)
  String getTrialDisclosure(Package? package) {
    if (package == null || !hasTrialPeriod(package)) return '';

    final duration = getTrialDurationText(package);
    final price = package.storeProduct.priceString;

    return 'paywall.trial_disclosure'.tr(namedArgs: {
      'duration': duration,
      'price': price,
    });
  }
}
