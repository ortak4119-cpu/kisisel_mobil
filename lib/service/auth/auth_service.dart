import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

import '../../models/auth/auth_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';

/// Kayıt/giriş isteklerine platform (App Store / Play Store) ve uygulama
/// sürümü bilgisini ekler. Backend bunu kullanıcının mağazasını bilmek için saklar.
String _currentPlatform() {
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'web';
}

String? _cachedAppVersion;

/// Cihaz locale'inden ülke kodu (ISO2). Örn "tr_TR" -> "TR".
/// Backend bu değeri IP tabanlı çözüme tercih eder.
String? _localeCountry() {
  try {
    final parts = Platform.localeName.split(RegExp(r'[_-]'));
    if (parts.length >= 2) {
      final region = parts[1].split('.').first;
      if (region.length == 2) return region.toUpperCase();
    }
  } catch (_) {}
  return null;
}

Future<Map<String, dynamic>> _withDeviceMeta(Map<String, dynamic> body) async {
  try {
    _cachedAppVersion ??= (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // Sürüm alınamazsa platform bilgisi yine de gönderilir.
  }
  final country = _localeCountry();
  return {
    ...body,
    'platform': _currentPlatform(),
    if (_cachedAppVersion != null) 'app_version': _cachedAppVersion,
    if (country != null) 'country': country,
  };
}


abstract class IAuthService {
  Future<ServiceResponse<AuthResponse>> login(LoginRequest request);
  Future<ServiceResponse<AuthResponse>> register(RegisterRequest request);
  Future<ServiceResponse<AuthResponse>> loginWithGoogle(GoogleLoginRequest request);
  Future<ServiceResponse<AuthResponse>> loginWithApple(AppleLoginRequest request);
  Future<ServiceResponse<AuthResponse>> loginAsGuest(GuestLoginRequest request);
  Future<ServiceResponse<User>> getCurrentUser();
  Future<ServiceResponse<void>> logout();
  Future<ServiceResponse<void>> logoutAllDevices();
  Future<ServiceResponse<Map<String, dynamic>>> forgotPassword(String email);
  Future<ServiceResponse<void>> resetPassword(String email, String code, String password, String passwordConfirmation);
}

class AuthService implements IAuthService {
  @override
  Future<ServiceResponse<AuthResponse>> login(LoginRequest request) async {
    final response = await BaseApiService.post<AuthResponse>(
      '/auth/login',
      body: await _withDeviceMeta(request.toJson()),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    // Token'ı kaydet
    if (response.isSuccess && response.data != null) {
      BaseApiService.setAuthToken(response.data!.token);
    }

    return response;
  }

  @override
  Future<ServiceResponse<AuthResponse>> register(RegisterRequest request) async {
    final response = await BaseApiService.post<AuthResponse>(
      '/auth/register',
      body: await _withDeviceMeta(request.toJson()),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    // Token'ı kaydet
    if (response.isSuccess && response.data != null) {
      BaseApiService.setAuthToken(response.data!.token);
    }

    return response;
  }

  @override
  Future<ServiceResponse<AuthResponse>> loginWithGoogle(
      GoogleLoginRequest request,
      ) async {
    final response = await BaseApiService.post<AuthResponse>(
      '/auth/login/google',
      body: await _withDeviceMeta(request.toJson()),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    // Token'ı kaydet
    if (response.isSuccess && response.data != null) {
      BaseApiService.setAuthToken(response.data!.token);
    }

    return response;
  }

  @override
  Future<ServiceResponse<AuthResponse>> loginWithApple(
      AppleLoginRequest request,
      ) async {
    final response = await BaseApiService.post<AuthResponse>(
      '/auth/login/apple',
      body: await _withDeviceMeta(request.toJson()),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    // Token'ı kaydet
    if (response.isSuccess && response.data != null) {
      BaseApiService.setAuthToken(response.data!.token);
    }

    return response;
  }

  @override
  Future<ServiceResponse<AuthResponse>> loginAsGuest(
      GuestLoginRequest request,
      ) async {
    final response = await BaseApiService.post<AuthResponse>(
      '/auth/login/guest',
      body: await _withDeviceMeta(request.toJson()),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    // Token'ı kaydet
    if (response.isSuccess && response.data != null) {
      BaseApiService.setAuthToken(response.data!.token);
    }

    return response;
  }

  @override
  Future<ServiceResponse<User>> getCurrentUser() async {
    final response = await BaseApiService.get<User>(
      '/auth/me',
      requiresAuth: true,
      fromJson: (json) {
        final userData = json['user'] as Map<String, dynamic>;
        return User.fromJson(userData);
      },
    );

    return response;
  }

  @override
  Future<ServiceResponse<void>> logout() async {
    final response = await BaseApiService.post<void>(
      '/auth/logout',
      requiresAuth: true,
    );

    // Token'ı temizle
    if (response.isSuccess) {
      BaseApiService.clearAuthToken();
    }

    return response;
  }

  @override
  Future<ServiceResponse<void>> logoutAllDevices() async {
    final response = await BaseApiService.post<void>(
      '/auth/logout-all',
      requiresAuth: true,
    );

    // Token'ı temizle
    if (response.isSuccess) {
      BaseApiService.clearAuthToken();
    }

    return response;
  }

  @override
  Future<ServiceResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    final response = await BaseApiService.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      body: {'email': email},
      requiresAuth: false,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    return response;
  }

  @override
  Future<ServiceResponse<void>> resetPassword(
    String email,
    String code,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await BaseApiService.post<void>(
      '/auth/reset-password',
      body: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      requiresAuth: false,
    );

    return response;
  }
}