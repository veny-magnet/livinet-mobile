import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary     = Color(0xFF41AD49);
  static const secondary   = Color(0xFFFCBF0F); 
  static const text        = Color(0xFF484C4F); 
  static const background  = Color(0xFFF8F9FA); 
  static const warning     = Color(0xFFF59E0B);
  static const success     = Color(0xFF10B981);
}

class Gaps {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class Corners {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white, 
      secondary: AppColors.secondary,
      onSecondary: AppColors.text,
      surface: AppColors.background,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _openSansTextTheme(scheme),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.md),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
        ),
      ),
    );
  }

  static TextTheme _openSansTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.openSansTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600, color: scheme.onSurface),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurface),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600, color: scheme.onSurface),
    );
  }
}
