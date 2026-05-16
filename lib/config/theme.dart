// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      surface: AppColors.mainLightBackgroundColor,
      surfaceContainer: AppColors.mainLightBackgroundColor2,
      primary: AppColors.mainLightContainerBgColor,
      onPrimary: AppColors.lightProductCardColor,
      onSecondary: AppColors.lightSubCategoryCardColor,
      secondary: AppColors.lightSecondary,
      tertiary: AppColors.lightTertiary,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      onSecondaryContainer: Colors.grey[700],
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.lightTertiary),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.primaryColor.withValues(alpha:0.3),
      selectionHandleColor: AppColors.primaryColor,
      cursorColor: AppColors.primaryColor,
    ),
    fontFamily: AppConstants.fontFamily,
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.grey.shade900,
      onPrimary: AppColors.darkProductCardColor,
      onSecondary: AppColors.darkSubCategoryCardColor,
      secondary: AppColors.darkExtraCardColor,
      // surface: const Color(0xFF0D1117),
      surface: const Color(0xFF1E1E1E),
      surfaceContainer: const Color(0xFF2C2C2C),
      tertiary: AppColors.darkTertiary,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      onSecondaryContainer: Colors.white54,
    ),
    fontFamily: AppConstants.fontFamily,
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.darkTertiary),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.primaryColor.withValues(alpha:0.3),
      selectionHandleColor: AppColors.primaryColor,
      cursorColor: AppColors.primaryColor,
    ),
  );
}
