import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens. Feature UIs should reference these instead of
/// hardcoding colors so light/dark theming and future rebrands stay
/// single-source-of-truth.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDark = Color(0xFF1B3FBF);
  static const Color secondary = Color(0xFF00C2A8);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color warning = Color(0xFFFFB020);
  static const Color success = Color(0xFF2ECC71);

  static const Color surfaceLight = Color(0xFFF7F9FC);
  static const Color surfaceDark = Color(0xFF11151C);
  static const Color cardDark = Color(0xFF1B212C);

  static const LinearGradient dashboardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6BFF), Color(0xFF00C2A8)],
  );

  static const LinearGradient junkGradient = LinearGradient(
    colors: [Color(0xFFFF5A5F), Color(0xFFFF8A65)],
  );
  static const LinearGradient duplicateGradient = LinearGradient(
    colors: [Color(0xFF8E5CF7), Color(0xFF5C7CF7)],
  );
  static const LinearGradient batteryGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF00C2A8)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
