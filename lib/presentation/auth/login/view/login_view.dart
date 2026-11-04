import 'package:auto_route/auto_route.dart';
import 'package:base/core/route/app_router.gr.dart';
import 'package:base/core/route/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/color_constant.dart';
import '../../../../service/auth/auth_service.dart';
import '../viewmodel/login_viewmodel.dart';
import '../../widgets/auth_ui.dart';

@RoutePage()
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // "Beni hatırla" anahtarları (cihaz-yerel).
  static const _kRememberFlag = 'remember_me';
  static const _kRememberEmail = 'remember_email';
  static const _kRememberPassword = 'remember_password';
  // Parola düz metin SharedPreferences yerine şifreli keystore'da tutulur.
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Eski sürümlerden kalan düz-metin parolayı temizle (güvenlik).
      if (prefs.containsKey(_kRememberPassword)) {
        await prefs.remove(_kRememberPassword);
      }
      if (prefs.getBool(_kRememberFlag) ?? false) {
        final savedPw = await _secure.read(key: _kRememberPassword) ?? '';
        if (!mounted) return;
        setState(() {
          _rememberMe = true;
          _emailController.text = prefs.getString(_kRememberEmail) ?? '';
          _passwordController.text = savedPw;
        });
      }
    } catch (_) {}
  }

  Future<void> _persistRemembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_kRememberFlag, true);
        await prefs.setString(_kRememberEmail, _emailController.text.trim());
        await _secure.write(
            key: _kRememberPassword, value: _passwordController.text);
      } else {
        await prefs.remove(_kRememberFlag);
        await prefs.remove(_kRememberEmail);
        await _secure.delete(key: _kRememberPassword);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor:
                isDark ? ColorConstant.bgColorDark : ColorConstant.bgColorLight,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthLogo(),
                      const SizedBox(height: 22),
                      Text(
                        'auth.welcomeBack'.tr(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.loginSubtitle'.tr(),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isDark
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthToggle(
                        loginActive: true,
                        onTapRegister: () =>
                            context.router.replace(const RegisterRoute()),
                        onTapLogin: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      AuthField(
                        controller: _emailController,
                        label: 'auth.email'.tr(),
                        hint: 'auth.emailHint'.tr(),
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.emailRequired'.tr();
                          }
                          if (!value.contains('@')) {
                            return 'auth.emailInvalid'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        controller: _passwordController,
                        label: 'auth.password'.tr(),
                        hint: 'auth.passwordHintRegister'.tr(),
                        isDark: isDark,
                        obscureText: _obscurePassword,
                        onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.passwordRequired'.tr();
                          }
                          if (value.length < 6) {
                            return 'auth.passwordMinLength'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Beni hatırla — açıkken e-posta + şifre cihazda saklanır.
                          InkWell(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false),
                                      activeColor: AuthUi.teal,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'auth.rememberMe'.tr(),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? ColorConstant.textSecondaryDark
                                          : ColorConstant.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(
                                context, viewModel, isDark),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'auth.forgotPassword'.tr(),
                              style: const TextStyle(
                                color: AuthUi.teal,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                        label: 'auth.login'.tr(),
                        loading: viewModel.isLoading,
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await viewModel.login(
                                    context,
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                  if (success) {
                                    await _persistRemembered();
                                  }
                                  if (success && mounted) {
                                    AuthGate.goAfterAuth(context);
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      AuthOrDivider(isDark: isDark),
                      const SizedBox(height: 18),
                      AuthSocialButton(
                        kind: AuthSocialKind.google,
                        isDark: isDark,
                        onPressed: () async {
                          final success =
                              await viewModel.loginWithGoogle(context);
                          if (success && mounted) {
                            AuthGate.goAfterAuth(context);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      AuthSocialButton(
                        kind: AuthSocialKind.apple,
                        isDark: isDark,
                        onPressed: () async {
                          final success =
                              await viewModel.loginWithApple(context);
                          if (success && mounted) {
                            AuthGate.goAfterAuth(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForgotPasswordDialog(
      BuildContext context, LoginViewModel viewModel, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => _ForgotPasswordDialog(isDarkMode: isDarkMode),
    );
  }
}

// Forgot Password Dialog
class _ForgotPasswordDialog extends StatefulWidget {
  final bool isDarkMode;

  const _ForgotPasswordDialog({required this.isDarkMode});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = GetIt.I<IAuthService>();
    final response =
        await authService.forgotPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (response.isSuccess && mounted) {
      setState(() {
        _codeSent = true;
        _email = _emailController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.codeSent'.tr()),
          backgroundColor: ColorConstant.successGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'errors.general'.tr()),
          backgroundColor: ColorConstant.errorRed,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwordsDoNotMatch'.tr()),
          backgroundColor: ColorConstant.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = GetIt.I<IAuthService>();
    final response = await authService.resetPassword(
      _email!,
      _codeController.text.trim(),
      _passwordController.text,
      _passwordConfirmController.text,
    );

    setState(() => _isLoading = false);

    if (response.isSuccess && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwordChanged'.tr()),
          backgroundColor: ColorConstant.successGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'errors.general'.tr()),
          backgroundColor: ColorConstant.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          widget.isDarkMode ? ColorConstant.cardColorDark : ColorConstant.cardColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        _codeSent ? 'auth.resetPassword'.tr() : 'auth.forgotPassword'.tr(),
        style: TextStyle(
          color: widget.isDarkMode
              ? ColorConstant.textPrimaryDark
              : ColorConstant.textPrimaryLight,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_codeSent) ...[
                Text(
                  'auth.forgotPasswordDescription'.tr(),
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'auth.email'.tr(),
                    hintText: 'auth.emailHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.emailRequired'.tr();
                    }
                    if (!value.contains('@')) {
                      return 'auth.emailInvalid'.tr();
                    }
                    return null;
                  },
                ),
              ] else ...[
                Text(
                  'auth.resetPasswordDescription'.tr(),
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textSecondaryDark
                        : ColorConstant.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'auth.resetCode'.tr(),
                    hintText: 'auth.resetCodeHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.codeRequired'.tr();
                    }
                    if (value.length != 6) {
                      return 'auth.codeInvalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'auth.newPassword'.tr(),
                    hintText: 'auth.passwordHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (value.length < 6) {
                      return 'auth.passwordMinLength'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? ColorConstant.textPrimaryDark
                        : ColorConstant.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'auth.confirmPassword'.tr(),
                    hintText: 'auth.passwordHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (value != _passwordController.text) {
                      return 'auth.passwordsDoNotMatch'.tr();
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'common.cancel'.tr(),
            style: TextStyle(
              color: widget.isDarkMode
                  ? ColorConstant.textSecondaryDark
                  : ColorConstant.textSecondaryLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              _isLoading ? null : (_codeSent ? _resetPassword : _sendCode),
          style: ElevatedButton.styleFrom(
            backgroundColor: AuthUi.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: ColorConstant.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _codeSent ? 'auth.resetPassword'.tr() : 'auth.sendCode'.tr(),
                  style: TextStyle(
                    color: ColorConstant.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
