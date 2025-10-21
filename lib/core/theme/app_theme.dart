import 'package:flutter/material.dart';
import '../utils/color_constant.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: ColorConstant.primaryPurple,
      secondary: ColorConstant.accentBlue,
      tertiary: ColorConstant.accentYellow,
      surface: ColorConstant.cardColorLight,
      background: ColorConstant.bgColorLight,
      error: ColorConstant.errorRed,
      onPrimary: ColorConstant.white,
      onSecondary: ColorConstant.white,
      onSurface: ColorConstant.textPrimaryLight,
      onBackground: ColorConstant.textPrimaryLight,
    ),
    scaffoldBackgroundColor: ColorConstant.bgColorLight,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorConstant.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: ColorConstant.cardColorLight,
      elevation: 0,
      shadowColor: ColorConstant.primaryPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: ColorConstant.textSecondaryLight,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: ColorConstant.textMutedLight,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: ColorConstant.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: ColorConstant.textSecondaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstant.primaryPurple,
        foregroundColor: ColorConstant.white,
        elevation: 0,
        shadowColor: ColorConstant.primaryPurple.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorConstant.accentBlue,
        foregroundColor: ColorConstant.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstant.primaryPurple,
        side: BorderSide(color: ColorConstant.primaryPurple, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorConstant.primaryPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorConstant.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.borderColorLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.borderColorLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.primaryPurple, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.errorRed, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      hintStyle: TextStyle(
        color: ColorConstant.textMutedLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ColorConstant.cardYellowLight,
      labelStyle: TextStyle(
        color: ColorConstant.textPrimaryLight,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorConstant.primaryPurple,
      foregroundColor: ColorConstant.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      iconSize: 32,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorConstant.white,
      selectedItemColor: ColorConstant.primaryPurple,
      unselectedItemColor: ColorConstant.textMutedLight,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      showUnselectedLabels: true,
    ),
    dividerTheme: DividerThemeData(
      color: ColorConstant.dividerLight,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: ColorConstant.iconPrimary,
      size: 24,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: ColorConstant.primaryPurple,
      linearTrackColor: ColorConstant.borderColorLight,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColorConstant.textPrimaryLight,
      contentTextStyle: TextStyle(
        color: ColorConstant.white,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: ColorConstant.primaryDarkModePurple,
      secondary: ColorConstant.primaryDarkModeBlue,
      tertiary: ColorConstant.accentDarkModeYellow,
      surface: ColorConstant.cardColorDark,
      background: ColorConstant.bgColorDark,
      error: ColorConstant.errorRed,
      onPrimary: ColorConstant.white,
      onSecondary: ColorConstant.white,
      onSurface: ColorConstant.textPrimaryDark,
      onBackground: ColorConstant.textPrimaryDark,
    ),
    scaffoldBackgroundColor: ColorConstant.bgColorDark,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorConstant.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: ColorConstant.cardColorDark,
      elevation: 0,
      shadowColor: ColorConstant.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: ColorConstant.textSecondaryDark,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: ColorConstant.textMutedDark,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: ColorConstant.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: ColorConstant.textSecondaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstant.primaryDarkModePurple,
        foregroundColor: ColorConstant.white,
        elevation: 0,
        shadowColor: ColorConstant.primaryDarkModePurple.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorConstant.primaryDarkModeBlue,
        foregroundColor: ColorConstant.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstant.primaryDarkModePurple,
        side: BorderSide(color: ColorConstant.primaryDarkModePurple, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorConstant.primaryDarkModePurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorConstant.cardColorDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.borderColorDark, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.borderColorDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.primaryDarkModePurple, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: ColorConstant.errorRed, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      hintStyle: TextStyle(
        color: ColorConstant.textMutedDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ColorConstant.cardYellowDark,
      labelStyle: TextStyle(
        color: ColorConstant.accentDarkModeYellow,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorConstant.primaryDarkModePurple,
      foregroundColor: ColorConstant.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      iconSize: 32,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorConstant.cardColorDark,
      selectedItemColor: ColorConstant.primaryDarkModePurple,
      unselectedItemColor: ColorConstant.textMutedDark,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      showUnselectedLabels: true,
    ),
    dividerTheme: DividerThemeData(
      color: ColorConstant.dividerDark,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: ColorConstant.iconSecondary,
      size: 24,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: ColorConstant.primaryDarkModePurple,
      linearTrackColor: ColorConstant.borderColorDark,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColorConstant.cardColorDark,
      contentTextStyle: TextStyle(
        color: ColorConstant.textPrimaryDark,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}