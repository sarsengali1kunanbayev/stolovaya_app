import 'package:flutter/material.dart';

// ─── Цветовая палитра ───────────────────────────────────────────────────────
class AppColors {
  // Фоны
  static const bgDeep = Color(0xFF080B14);
  static const bgCard = Color(0xFF0F1420);
  static const bgElevated = Color(0xFF151B2E);
  static const bgOverlay = Color(0xFF1A2236);

  // Неон-акценты
  static const neonCyan = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFF7C4DFF);
  static const neonGreen = Color(0xFF00E676);
  static const neonOrange = Color(0xFFFF6D00);
  static const neonRed = Color(0xFFFF1744);

  // Текст
  static const textPrimary = Color(0xFFE8EAF6);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted = Color(0xFF4A5568);

  // Границы
  static const borderSubtle = Color(0xFF1E2A42);
  static const borderGlow = Color(0xFF00E5FF26);
}

// ─── Градиенты ──────────────────────────────────────────────────────────────
class AppGradients {
  static const cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1420), Color(0xFF1A2236)],
  );

  static const neonHeader = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
  );

  static const greenShift = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
  );

  static const redShift = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
  );

  static const bgRadial = RadialGradient(
    center: Alignment(-0.6, -0.8),
    radius: 1.2,
    colors: [Color(0xFF0D1829), Color(0xFF080B14)],
  );
}

// ─── Тени и свечения ────────────────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> neonCyan = [
    BoxShadow(
        color: AppColors.neonCyan.withOpacity(0.3),
        blurRadius: 20,
        spreadRadius: -4),
    BoxShadow(
        color: AppColors.neonCyan.withOpacity(0.1),
        blurRadius: 60,
        spreadRadius: 0),
  ];

  static List<BoxShadow> neonGreen = [
    BoxShadow(
        color: AppColors.neonGreen.withOpacity(0.4),
        blurRadius: 20,
        spreadRadius: -4),
  ];

  static List<BoxShadow> neonRed = [
    BoxShadow(
        color: AppColors.neonRed.withOpacity(0.4),
        blurRadius: 20,
        spreadRadius: -4),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 16,
        offset: const Offset(0, 4)),
    BoxShadow(
        color: AppColors.neonCyan.withOpacity(0.04),
        blurRadius: 1,
        offset: Offset.zero),
  ];
}

// ─── ThemeData ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonCyan,
          secondary: AppColors.neonPurple,
          surface: AppColors.bgCard,
          error: AppColors.neonRed,
        ),
        fontFamily: 'SF Pro Display', // fallback to system
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -1),
          titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18),
          titleMedium: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          labelSmall: TextStyle(
              color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIconColor: AppColors.textSecondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            foregroundColor: AppColors.bgDeep,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.neonCyan,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        dividerTheme:
            const DividerThemeData(color: AppColors.borderSubtle, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.bgElevated,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.bgElevated,
          selectedColor: AppColors.neonCyan.withOpacity(0.2),
          labelStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          secondaryLabelStyle: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.borderSubtle),
          selectedShadowColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
