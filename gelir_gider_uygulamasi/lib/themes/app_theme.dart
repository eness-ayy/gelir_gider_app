import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ================= AÇIK TEMA =================
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Renk Şeması
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.expense,
    ),

    // Özel Finans Eklentisi
    extensions: const [FinancialColors.light],

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    ),

    // Kart Teması
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
      ),
    ),

    // Elevated Buton Teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, inherit: true),
      ),
    ),

    // Outlined Buton Teması
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, inherit: true),
      ),
    ),

    // Input / TextField Teması
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expense),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 2,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: AppColors.lightTextSecondary,
        );
      }),
    ),
  );

  // ================= KOYU TEMA =================
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Renk Şeması
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.expense,
    ),

    // Özel Finans Eklentisi
    extensions: const [FinancialColors.dark],

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
    ),

    // Kart Teması
    // Kart Teması
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
      ),
    ),

    // Elevated Buton Teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Input / TextField Teması
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252525),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expense),
      ),
    ),

    // Bottom Navigation Bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: AppColors.darkTextSecondary,
        );
      }),
    ),
  );
}

// Geriye dönük uyumluluk
// ignore: camel_case_types
typedef elevatedButtonTheme = AppTheme;
