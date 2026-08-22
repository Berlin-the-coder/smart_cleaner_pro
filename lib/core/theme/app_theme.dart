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

  /// Shared radius token — used across the new component themes below
  /// so inputs, dialogs, chips, and buttons all feel like one
  /// consistent design language instead of a mix of default corner
  /// values.
  static const double radius = 16;

  /// A refined type scale layered on top of GoogleFonts.inter —
  /// tighter letter-spacing on large headings (a common "premium app"
  /// typographic trick), slightly heavier weights for titles, and a
  /// comfortable line-height on body text for readability. Built as a
  /// TextTheme so it flows through every Text widget in the app
  /// automatically via Theme.of(context).textTheme — no per-screen
  /// changes required.
  static TextTheme _typeScale(TextTheme base, Color bodyColor) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.12,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.18,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Component themes shared by both light and dark — each one takes
  /// the resolved [scheme] so every input/dialog/chip/switch already
  /// matches whichever brightness is active, without duplicating this
  /// logic between light() and dark().
  static ThemeData _applySharedComponentThemes(
    ThemeData base,
    ColorScheme scheme,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.035);

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AppColors.danger, width: 1.4),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),

      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.white : Colors.black87,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide.none,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Colors.white70 : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.16);
        }),
        trackOutlineColor:
            const WidgetStatePropertyAll(Colors.transparent),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? Colors.black87 : Colors.white,
          fontSize: 12,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: fieldFill,
        circularTrackColor: fieldFill,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
        modalElevation: 0,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
    );
    final themed = base.copyWith(
      textTheme: _typeScale(
        GoogleFonts.interTextTheme(base.textTheme),
        Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
    return _applySharedComponentThemes(themed, themed.colorScheme);
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
    final themed = base.copyWith(
      textTheme: _typeScale(
        GoogleFonts.interTextTheme(base.textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
    return _applySharedComponentThemes(themed, themed.colorScheme);
  }
}
