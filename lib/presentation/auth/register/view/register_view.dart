import 'package:auto_route/auto_route.dart';
import 'package:base/core/route/app_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/color_constant.dart';
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
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
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
                      const SizedBox(height: 40),

                      // Logo ve App Name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstant.primaryPurple
                                        .withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.asset(
                                  'assets/logos/1024.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'app.name'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                color: isDarkMode
                                    ? ColorConstant.textPrimaryDark
                                    : ColorConstant.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Header
                      Text(
                        'auth.createAccount'.tr(),
                        style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isDarkMode
                              ? ColorConstant.textPrimaryDark
                              : ColorConstant.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.createAccountSubtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDarkMode
                              ? ColorConstant.textSecondaryDark
                              : ColorConstant.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Username Field
                      _buildTextField(
                        controller: _usernameController,
                        label: 'auth.username'.tr(),
                        hint: 'auth.usernameHint'.tr(),
                        icon: Icons.person_outline_rounded,
                        isDarkMode: isDarkMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.usernameRequired'.tr();
                          }
                          if (value.length < 3) {
                            return 'auth.usernameMinLength'.tr();
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

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
                        hint: 'auth.passwordHintRegister'.tr(),
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
                          if (value.length < 8) {
                            return 'auth.passwordMinLengthRegister'.tr();
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'auth.passwordConfirm'.tr(),
                        hint: 'auth.passwordConfirmHint'.tr(),
                        icon: Icons.lock_outline_rounded,
                        isDarkMode: isDarkMode,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDarkMode
                                ? ColorConstant.textMutedDark
                                : ColorConstant.textMutedLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.passwordConfirmRequired'.tr();
                          }
                          if (value != _passwordController.text) {
                            return 'auth.passwordMismatch'.tr();
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Terms Checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: _agreeToTerms
                                      ? (isDarkMode
                                      ? ColorConstant.primaryDarkModePurple
                                      : ColorConstant.primaryPurple)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _agreeToTerms
                                        ? (isDarkMode
                                        ? ColorConstant.primaryDarkModePurple
                                        : ColorConstant.primaryPurple)
                                        : (isDarkMode
                                        ? ColorConstant.borderColorDark
                                        : ColorConstant.borderColorLight),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _agreeToTerms
                                    ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: ColorConstant.white,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: isDarkMode
                                          ? ColorConstant.textSecondaryDark
                                          : ColorConstant.textSecondaryLight,
                                    ),
                                    children: [
                                      TextSpan(text: 'auth.agreeToTerms'.tr()),
                                      TextSpan(
                                        text: 'auth.termsOfService'.tr(),
                                        style: TextStyle(
                                          color: ColorConstant.primaryPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: 'auth.and'.tr()),
                                      TextSpan(
                                        text: 'auth.privacyPolicy'.tr(),
                                        style: TextStyle(
                                          color: ColorConstant.primaryPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading || !_agreeToTerms
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await viewModel.register(
                                context,
                                email: _emailController.text.trim(),
                                username: _usernameController.text.trim(),
                                password: _passwordController.text,
                                passwordConfirmation:
                                _confirmPasswordController.text,
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
                            disabledBackgroundColor: isDarkMode
                                ? ColorConstant.borderColorDark
                                : ColorConstant.borderColorLight,
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
                            'auth.register'.tr(),
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
                        label: 'auth.registerWithGoogle'.tr(),
                        icon: Icons.g_mobiledata_rounded,
                        isDarkMode: isDarkMode,
                        onPressed: () async {
                          final success = await viewModel.registerWithGoogle(context);
                          if (success && mounted) {
                            context.router.push(HomeRoute());
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildSocialButton(
                        label: 'auth.registerWithApple'.tr(),
                        icon: Icons.apple_rounded,
                        isDarkMode: isDarkMode,
                        onPressed: () async {
                          final success = await viewModel.registerWithApple(context);
                          if (success && mounted) {
                            context.router.push(HomeRoute());
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // Sign In
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.haveAccount'.tr(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? ColorConstant.textSecondaryDark
                                    : ColorConstant.textSecondaryLight,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.router.push(LoginRoute());
                              },
                              child: Text(
                                'auth.login'.tr(),
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