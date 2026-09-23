import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Inter',
      fontFamilyFallback: const ['IBMPlexSansArabic'],
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.orange,
        tertiary: AppColors.lightYellow,
        error: AppColors.red,
        surface: AppColors.lightBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.lightBackground,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Inter',
      fontFamilyFallback: const ['IBMPlexSansArabic'],
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.orange,
        tertiary: AppColors.lightYellow,
        error: AppColors.red,
        surface: AppColors.darkBackground,
        onSurface: AppColors.offWhite,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.offWhite,
        displayColor: AppColors.offWhite,
        fontFamily: 'Inter',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.offWhite,
      ),
    );
  }
}
