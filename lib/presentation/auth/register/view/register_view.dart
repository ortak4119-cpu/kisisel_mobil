import 'package:auto_route/auto_route.dart';
import 'package:base/core/route/app_router.gr.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/color_constant.dart';
import '../../widgets/auth_ui.dart';
import '../viewmodel/register_viewmodel.dart';

@RoutePage()
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
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
                        'auth.createAccount'.tr(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AuthUi.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.registerSubtitle'.tr(),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AuthUi.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthToggle(
                        loginActive: false,
                        onTapLogin: () =>
                            context.router.replace(const LoginRoute()),
                        onTapRegister: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      AuthField(
                        controller: _usernameController,
                        label: 'auth.name'.tr(),
                        hint: 'auth.nameHint'.tr(),
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'auth.usernameRequired'.tr();
                          }
                          if (value.trim().length < 3) {
                            return 'auth.usernameMinLength'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                          if (value.length < 8) {
                            return 'auth.passwordMinLengthRegister'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      AuthPrimaryButton(
                        label: 'auth.createAccountBtn'.tr(),
                        loading: viewModel.isLoading,
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await viewModel.register(
                                    context,
                                    email: _emailController.text.trim(),
                                    username: _usernameController.text.trim(),
                                    password: _passwordController.text,
                                    passwordConfirmation:
                                        _passwordController.text,
                                  );
                                  if (success && mounted) {
                                    context.router.replace(const HomeRoute());
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
                              await viewModel.registerWithGoogle(context);
                          if (success && mounted) {
                            context.router.replace(const HomeRoute());
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      AuthSocialButton(
                        kind: AuthSocialKind.apple,
                        isDark: isDark,
                        onPressed: () async {
                          final success =
                              await viewModel.registerWithApple(context);
                          if (success && mounted) {
                            context.router.replace(const HomeRoute());
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _termsText(isDark),
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

  Widget _termsText(bool isDark) {
    final base = TextStyle(
      fontSize: 12.5,
      height: 1.5,
      color: AuthUi.textMuted(isDark),
    );
    const link = TextStyle(
      fontSize: 12.5,
      height: 1.5,
      fontWeight: FontWeight.w700,
      color: AuthUi.teal,
    );
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'auth.registerTermsPrefix'.tr(), style: base),
            TextSpan(
              text: 'auth.termsOfService'.tr(),
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://goodlifesync.com/terms'),
            ),
            TextSpan(text: 'auth.and'.tr(), style: base),
            TextSpan(
              text: 'auth.privacyPolicy'.tr(),
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://goodlifesync.com/privacy'),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
