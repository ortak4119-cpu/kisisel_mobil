import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/color_constant.dart';

/// Giriş / kayıt ekranlarında paylaşılan tasarım parçaları.
class AuthUi {
  static const Color teal = Color(0xFF15788C);
  static const Color tealDark = Color(0xFF3AA6B8);

  static Color fieldBg(bool d) =>
      d ? ColorConstant.cardColorDark : Colors.white;
  static Color fieldBorder(bool d) =>
      d ? ColorConstant.borderColorDark : const Color(0xFFE4D9C2);
  static Color trackBg(bool d) =>
      d ? ColorConstant.cardColorDark : const Color(0xFFD9CBAD);
  static Color textPrimary(bool d) =>
      d ? ColorConstant.textPrimaryDark : ColorConstant.textPrimaryLight;
  static Color textSecondary(bool d) =>
      d ? ColorConstant.textSecondaryDark : ColorConstant.textSecondaryLight;
  static Color textMuted(bool d) =>
      d ? ColorConstant.textMutedDark : ColorConstant.textMutedLight;
}

/// Sol üstteki küçük logo karesi.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AuthUi.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logos/1024.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// Giriş yap / Kayıt ol segment anahtarı.
class AuthToggle extends StatelessWidget {
  final bool loginActive;
  final VoidCallback onTapLogin;
  final VoidCallback onTapRegister;
  final bool isDark;

  const AuthToggle({
    super.key,
    required this.loginActive,
    required this.onTapLogin,
    required this.onTapRegister,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AuthUi.trackBg(isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _seg('auth.login'.tr(), loginActive, onTapLogin),
          _seg('auth.register'.tr(), !loginActive, onTapRegister),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF4A4A46) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active
                  ? AuthUi.textPrimary(isDark)
                  : AuthUi.textMuted(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiketli metin alanı. [onToggleObscure] verilirse şifre alanı gibi
/// davranır ve sağda Göster/Gizle metni gösterir.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AuthUi.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: AuthUi.textPrimary(isDark), fontSize: 16),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AuthUi.textMuted(isDark)),
            filled: true,
            fillColor: AuthUi.fieldBg(isDark),
            suffixIcon: onToggleObscure == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: onToggleObscure,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        obscureText
                            ? 'auth.show'.tr()
                            : 'auth.hide'.tr(),
                        style: const TextStyle(
                          color: AuthUi.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AuthUi.fieldBorder(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AuthUi.fieldBorder(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuthUi.teal, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorConstant.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorConstant.errorRed, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Teal dolgulu ana aksiyon butonu.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthUi.teal,
          disabledBackgroundColor: AuthUi.teal.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.4))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// "veya" ayırıcısı.
class AuthOrDivider extends StatelessWidget {
  final bool isDark;
  const AuthOrDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final line = AuthUi.fieldBorder(isDark);
    return Row(
      children: [
        Expanded(child: Divider(color: line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('common.or'.tr(),
              style: TextStyle(color: AuthUi.textMuted(isDark), fontSize: 13)),
        ),
        Expanded(child: Divider(color: line, thickness: 1)),
      ],
    );
  }
}

enum AuthSocialKind { google, apple }

/// Google / Apple butonu (tam genişlik — alt alta kullanılır).
class AuthSocialButton extends StatelessWidget {
  final AuthSocialKind kind;
  final bool isDark;
  final VoidCallback onPressed;

  const AuthSocialButton({
    super.key,
    required this.kind,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = kind == AuthSocialKind.google;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AuthUi.fieldBg(isDark),
          side: BorderSide(color: AuthUi.fieldBorder(isDark), width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isGoogle ? _googleMark() : _appleMark(isDark),
            const SizedBox(width: 12),
            Text(
              isGoogle ? 'Google' : 'Apple',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AuthUi.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleMark() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFC4CC), width: 1.4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }

  Widget _appleMark(bool isDark) {
    return Icon(Icons.apple, size: 24, color: AuthUi.textPrimary(isDark));
  }
}
