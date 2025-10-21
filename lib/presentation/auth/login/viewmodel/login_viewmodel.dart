import 'package:flutter/material.dart';
import '../../../../core/init/locator.dart';
import '../../../../core/utils/custom_snackbar.dart';
import '../../../../models/auth/auth_models.dart';
import '../../../../service/auth/auth_service.dart';


class LoginViewModel extends ChangeNotifier {
  final IAuthService _authService = locator<IAuthService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Login with Email & Password
  Future<bool> login(
      BuildContext context,
      String email,
      String password,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: email,
        password: password,
        deviceId: 'device-unique-id', // TODO: Get from device_info package
      );

      final response = await _authService.login(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        // TODO: Save token to SharedPreferences/Secure Storage
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // await prefs.setString('auth_token', response.data!.token);
        // await prefs.setString('user_data', jsonEncode(response.data!.user.toJson()));

        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            response.message ?? 'Giriş başarılı! Hoş geldiniz 🎉',
          );
        }
        return true;
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Beklenmeyen bir hata oluştu',
        );
      }
      return false;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Google Sign-In
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) return false;

      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));

      final request = GoogleLoginRequest(
        googleId: 'google-user-id',
        email: 'user@gmail.com',
        displayName: 'Google User',
        profilePictureUrl: null,
        deviceId: 'device-unique-id',
      );

      final response = await _authService.loginWithGoogle(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'Google girişi başarılı! 🎉',
          );
        }
        return true;
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Google girişi başarısız oldu',
        );
      }
      return false;
    }
  }

  // Login with Apple
  Future<bool> loginWithApple(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Apple Sign-In
      // final credential = await SignInWithApple.getAppleIDCredential(...);

      await Future.delayed(const Duration(seconds: 1));

      final request = AppleLoginRequest(
        appleId: 'apple-user-id',
        email: 'user@privaterelay.appleid.com',
        displayName: 'Apple User',
        deviceId: 'device-unique-id',
      );

      final response = await _authService.loginWithApple(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'Apple girişi başarılı! 🎉',
          );
        }
        return true;
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Apple girişi başarısız oldu',
        );
      }
      return false;
    }
  }

  // Login as Guest
  Future<bool> loginAsGuest(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = GuestLoginRequest(
        deviceId: 'device-unique-id',
      );

      final response = await _authService.loginAsGuest(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        if (context.mounted) {
          CustomSnackBar.showInfo(
            context,
            'Misafir olarak giriş yapıldı',
          );
        }
        return true;
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Misafir girişi başarısız oldu',
        );
      }
      return false;
    }
  }
}