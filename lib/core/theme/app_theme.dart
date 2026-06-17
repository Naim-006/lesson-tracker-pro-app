import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.sunsetBright,
      secondary: AppColors.sunset,
      surface: AppColors.lightBg,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightText,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _textTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      navigationBarTheme: _navBarTheme(colorScheme),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      inputDecorationTheme: _inputTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      dividerTheme: DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 0),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.sunsetBright,
      secondary: AppColors.sunset,
      surface: AppColors.darkBg,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkText,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _textTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      navigationBarTheme: _navBarTheme(colorScheme),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      inputDecorationTheme: _inputTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      dividerTheme: DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 0),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.5),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedColor, letterSpacing: 0.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedColor, letterSpacing: 0.8),
    );
  }

  static CardThemeData _cardTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return CardThemeData(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return AppBarTheme(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: isDark ? AppColors.darkText : AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  static NavigationBarThemeData _navBarTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return NavigationBarThemeData(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      indicatorColor: AppColors.sunsetBright.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sunsetBright);
        }
        return TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkMuted : AppColors.lightMuted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(size: 26, color: AppColors.sunsetBright);
        }
        return IconThemeData(size: 24, color: isDark ? AppColors.darkMuted : AppColors.lightMuted);
      }),
      height: 65,
    );
  }

  static FloatingActionButtonThemeData _fabTheme(ColorScheme colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: AppColors.sunsetBright,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: const CircleBorder(),
      smallSizeConstraints: BoxConstraints.tight(const Size(40, 40)),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkCard : Colors.grey.shade50,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.sunsetBright, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme colors) {
    return ChipThemeData(
      backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: AppColors.sunsetBright, fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
