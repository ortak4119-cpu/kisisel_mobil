import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/init/locator.dart';
import '../../../../core/utils/custom_snackbar.dart';
import '../../../../core/utils/helper_methods.dart';
import '../../../../models/auth/auth_models.dart';
import '../../../../service/auth/auth_service.dart';
import '../../../../service/firebase/fcm_service.dart';


class RegisterViewModel extends ChangeNotifier {
  final IAuthService _authService = locator<IAuthService>();
  final FCMService _fcmService = locator<FCMService>();

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

        // Send FCM token to backend after successful registration
        await _fcmService.sendTokenToBackendAfterLogin();

        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'auth.success.registerSuccess'.tr(),
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
          'errors.general'.tr(),
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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Google ile giriş yap
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı iptal etti
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Google'dan bilgileri al
      final request = GoogleLoginRequest(
        googleId: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
        profilePictureUrl: googleUser.photoUrl,
        deviceId: await getDeviceId(),
      );

      // Backend'de login ve register aynı endpoint (otomatik kullanıcı oluşturur)
      final response = await _authService.loginWithGoogle(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        // Send FCM token to backend after successful registration
        await _fcmService.sendTokenToBackendAfterLogin();

        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'auth.success.googleRegisterSuccess'.tr(),
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
          'Google ile kayıt başarısız: ${e.toString()}',
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
      // Apple ile giriş yap
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Apple'dan bilgileri al
      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      final request = AppleLoginRequest(
        appleId: credential.userIdentifier??"credentialnotfound",
        email: credential.email, // İlk girişte gelir, sonra null olabilir
        displayName: displayName,
        deviceId: await getDeviceId(),
      );

      // Backend'de login ve register aynı endpoint (otomatik kullanıcı oluşturur)
      final response = await _authService.loginWithApple(request);

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess && response.data != null) {
        // Send FCM token to backend after successful registration
        await _fcmService.sendTokenToBackendAfterLogin();

        if (context.mounted) {
          CustomSnackBar.showSuccess(
            context,
            'auth.success.appleRegisterSuccess'.tr(),
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
          'Apple ile kayıt başarısız: ${e.toString()}',
        );
      }
      return false;
    }
  }
}
