import 'package:flutter/material.dart';
import '../../../../core/init/locator.dart';
import '../../../../core/utils/custom_snackbar.dart';
import '../../../../models/auth/auth_models.dart';
import '../../../../service/auth/auth_service.dart';


class RegisterViewModel extends ChangeNotifier {
  final IAuthService _authService = locator<IAuthService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Register with Email & Password
  Future<bool> register(
      BuildContext context, {
        required String email,
        required String username,
        required String password,
        required String passwordConfirmation,
        String? displayName,
      }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = RegisterRequest(
        email: email,
        username: username,
        password: password,
        passwordConfirmation: passwordConfirmation,
        displayName: displayName,
        preferredLanguage: 'tr',
      );

      final response = await _authService.register(request);

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
            'Kayıt başarılı! LifeSync\'e hoş geldiniz 🎉',
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

  // Register with Google
  Future<bool> registerWithGoogle(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Google Sign-In
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) return false;

      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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
            'Google ile kayıt başarılı! 🎉',
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
          'Google ile kayıt başarısız oldu',
        );
      }
      return false;
    }
  }

  // Register with Apple
  Future<bool> registerWithApple(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Apple Sign-In
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );

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
            'Apple ile kayıt başarılı! 🎉',
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
          'Apple ile kayıt başarısız oldu',
        );
      }
      return false;
    }
  }
}