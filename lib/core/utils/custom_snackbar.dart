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
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 4),
      icon: icon,
    );
  }

  /// Warning notification with orange background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 3),
      icon: icon,
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
