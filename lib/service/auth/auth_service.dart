import '../../models/auth/auth_models.dart';
import '../base/base_api_service.dart';
import '../response/service_response.dart';


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
      body: request.toJson(),
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
      body: request.toJson(),
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
      body: request.toJson(),
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
      body: request.toJson(),
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
      body: request.toJson(),
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