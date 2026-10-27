import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'color_constant.dart';

class CustomSnackBar {
  /// Shows a customizable SnackBar with automatic theming
  ///
  /// [context] is required for accessing the theme
  /// [message] is the text to display
  /// [type] determines the background color (success, error, info, warning)
  /// [icon] optional icon to display
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    bool overlay = false,
  }) {
    // Determine if dark mode is active
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Select background color and icon based on type and theme
    Color backgroundColor;
    Color textColor;
    IconData defaultIcon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = isDarkMode
            ? ColorConstant.successGreen.withValues(alpha: 0.9)
            : ColorConstant.successGreen;
        textColor = ColorConstant.white;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = isDarkMode
            ? ColorConstant.errorRed.withValues(alpha: 0.9)
            : ColorConstant.errorRed;
        textColor = ColorConstant.white;
        defaultIcon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = isDarkMode
            ? ColorConstant.warningOrange.withValues(alpha: 0.9)
            : ColorConstant.warningOrange;
        textColor = ColorConstant.white;
        defaultIcon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = isDarkMode
            ? ColorConstant.primaryDarkModePurple
            : ColorConstant.primaryPurple;
        textColor = ColorConstant.white;
        defaultIcon = Icons.info_rounded;
        break;
    }

    // Modal bottom sheet açıkken normal SnackBar sheet'in ARKASINDA kalır ve
    // görünmez. overlay=true ise mesajı kök Overlay'e (tüm rotaların üstüne)
    // ekranın üstünde bir toast olarak gösterir; validasyon uyarıları için.
    if (overlay) {
      _showOverlayToast(
        context,
        message: message.tr(),
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon ?? defaultIcon,
        duration: duration,
      );
      return;
    }

    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? defaultIcon,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.tr(), // Use easy_localization for translation
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: duration,
        elevation: 4,
      ),
    );
  }

  /// Kök Overlay'e üstten giren, otomatik kaybolan toast (modal sheet'lerin
  /// üstünde de görünür).
  static void _showOverlayToast(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      // Overlay yoksa normal SnackBar'a düş.
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      } catch (_) {}
      return;
    }
    final topPad = MediaQuery.of(context).padding.top;
    late OverlayEntry entry;
    final notifier = ValueNotifier<double>(0.0);
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topPad + 12,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: notifier.value),
            duration: const Duration(milliseconds: 220),
            builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - v) * -16),
                child: child,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: textColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(message,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(entry);
    // giriş animasyonu
    notifier.value = 1.0;
    entry.markNeedsBuild();
    // çıkış + kaldırma
    Future.delayed(duration, () {
      notifier.value = 0.0;
      entry.markNeedsBuild();
      Future.delayed(const Duration(milliseconds: 240), () {
        entry.remove();
        notifier.dispose();
      });
    });
  }

  /// Success notification with green background
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 3),
      icon: icon,
    );
  }

  /// Error notification with red background
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
    bool overlay = false,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 4),
      icon: icon,
      overlay: overlay,
    );
  }

  /// Warning notification with orange background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
    bool overlay = false,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 3),
      icon: icon,
      overlay: overlay,
    );
  }

  /// Info notification with purple background
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 3),
      icon: icon,
    );
  }

  /// Backwards-compatible method to quickly update existing SnackBar calls
  /// Automatically determines the appropriate theme and styling
  static void showDefault(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
}

// Enum to define different types of SnackBars
enum SnackBarType {
  success,
  error,
  warning,
  info,
}
