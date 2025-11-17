import 'package:auto_route/auto_route.dart';
import 'package:base/core/route/app_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/color_constant.dart';
import '../viewmodel/login_viewmodel.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? ColorConstant.bgColorDark
                : ColorConstant.bgColorLight,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      // Logo ve App Name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstant.primaryPurple
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.asset(
                                  'assets/logos/1024.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'app.name'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'app.tagline'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Welcome Back
                      Text(
                        'auth.welcomeBack'.tr(),
                        style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.signInInstruction'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'auth.email'.tr(),
                        hint: 'auth.emailHint'.tr(),
                        icon: Icons.email_outlined,
                        isDarkMode: isDarkMode,
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

                      const SizedBox(height: 20),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'auth.password'.tr(),
                        hint: 'auth.passwordHint'.tr(),
                        icon: Icons.lock_outline_rounded,
                        isDarkMode: isDarkMode,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDarkMode
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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

                      const SizedBox(height: 12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Forgot password
                          },
                          child: Text(
                            'auth.forgotPassword'.tr(),
                            style: TextStyle(
                              color: ColorConstant.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await viewModel.login(
                                context,
                                _emailController.text.trim(),
                                _passwordController.text,
                              );

                              if (success && mounted) {
                                context.router.push(HomeRoute());
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? ColorConstant.primaryDarkModePurple
                                : ColorConstant.primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: viewModel.isLoading
                              ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: ColorConstant.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            'auth.login'.tr(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'common.or'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textMutedDark
                                    : ColorConstant.textMutedLight,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDarkMode
                                  ? ColorConstant.borderColorDark
                                  : ColorConstant.borderColorLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Login Buttons
                      _buildSocialButton(
                        label: 'auth.continueWithGoogle'.tr(),
                        icon: Icons.g_mobiledata_rounded,
                        isDarkMode: isDarkMode,
                        onPressed: () => viewModel.loginWithGoogle(context),
                      ),

                      const SizedBox(height: 12),

                      _buildSocialButton(
                        label: 'auth.continueWithApple'.tr(),
                        icon: Icons.apple_rounded,
                        isDarkMode: isDarkMode,
                        onPressed: () => viewModel.loginWithApple(context),
                      ),

                      const SizedBox(height: 24),

                      // Guest Login
                      Center(
                        child: TextButton(
                          onPressed: () => viewModel.loginAsGuest(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'auth.continueAsGuest'.tr(),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? ColorConstant.textSecondaryDark
                                      : ColorConstant.textSecondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign Up
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.noAccount'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.router.push(RegisterRoute());
                              },
                              child: Text(
                                'auth.register'.tr(),
                                style: TextStyle(
                                  color: ColorConstant.primaryPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            color: isDarkMode
                ? ColorConstant.textPrimaryDark
                : ColorConstant.textPrimaryLight,
            fontSize: 16,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode
                  ? ColorConstant.textMutedDark
                  : ColorConstant.textMutedLight,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? ColorConstant.cardColorDark
                    : ColorConstant.cardPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDarkMode
                    ? ColorConstant.primaryDarkModePurple
                    : ColorConstant.primaryPurple,
              ),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDarkMode
                ? ColorConstant.cardColorDark
                : ColorConstant.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: isDarkMode
                    ? ColorConstant.borderColorDark
                    : ColorConstant.borderColorLight,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: isDarkMode
                    ? ColorConstant.primaryDarkModePurple
                    : ColorConstant.primaryPurple,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: ColorConstant.errorRed,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: ColorConstant.errorRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDarkMode
                ? ColorConstant.borderColorDark
                : ColorConstant.borderColorLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDarkMode
                  ? ColorConstant.textPrimaryDark
                  : ColorConstant.textPrimaryLight,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? ColorConstant.textPrimaryDark
                    : ColorConstant.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}