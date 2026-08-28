import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF3B2FCC);
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color accent = Color(0xFFFFA940);
  static const Color background = Color(0xFFF4F5FB);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1A1B2E);
  static const Color textMuted = Color(0xFF8A8FA8);
  static const Color income = Color(0xFF1FA971);
  static const Color expense = Color(0xFFE5484D);
  static const Color divider = Color(0xFFEDEEF5);

  static const List<List<Color>> cardGradients = <List<Color>>[
    <Color>[Color(0xFF3B2FCC), Color(0xFF6C5CE7)],
    <Color>[Color(0xFFF7971E), Color(0xFFFFC46B)],
    <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    <Color>[Color(0xFFEB3349), Color(0xFFF45C43)],
    <Color>[Color(0xFF232526), Color(0xFF515A63)],
  ];

  static List<Color> gradientFor(int index) =>
      cardGradients[index % cardGradients.length];
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.expense,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.text,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.expense),
      ),

      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),

    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    
  );
}
