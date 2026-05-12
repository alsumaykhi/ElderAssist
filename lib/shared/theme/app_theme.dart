import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design tokens and Material 3 theme for ElderAssist.
///
/// Colors and type roles follow `ElderAssist_brand_kit/README.txt` (Bond):
/// sage primary, coral accent, cream canvas, ink text; Fraunces + Inter.
///
/// Built around the needs of elderly users:
///  - Generous touch targets (≥56dp)
///  - High-contrast text on warm surfaces
///  - Large, readable typography
class AppTheme {
  AppTheme._();

  // --- Brand colors (ElderAssist_brand_kit · Direction B) -----------------
  static const Color brandPrimary = Color(0xFF3F7D5C); // Sage
  static const Color brandPrimaryDark = Color(0xFF2C5942); // Sage dark
  static const Color brandPrimarySoft = Color(0xFFE8F2EC); // Light sage tint
  static const Color brandAccent = Color(0xFFE87B5A); // Coral (heart)

  // --- Semantic colors -----------------------------------------------------
  static const Color success = Color(0xFF2E7D32);
  static const Color successSoft = Color(0xFFE6F4EA);
  static const Color warning = Color(0xFFB26A00);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color info = Color(0xFF1565C0);
  static const Color infoSoft = Color(0xFFE3F0FB);

  // --- Surface & text ------------------------------------------------------
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5EFE8);
  static const Color background = Color(0xFFFBF7F0); // Cream
  static const Color textPrimary = Color(0xFF1A2B22); // Ink
  static const Color textSecondary = Color(0xFF5F6B62);
  static const Color textTertiary = Color(0xFF7A867C);
  static const Color border = Color(0xFFE2E6E2);

  // --- Spacing scale -------------------------------------------------------
  static const double space2 = 4;
  static const double space3 = 8;
  static const double space4 = 12;
  static const double space5 = 16;
  static const double space6 = 20;
  static const double space7 = 24;
  static const double space8 = 32;
  static const double space9 = 40;

  // --- Radius scale --------------------------------------------------------
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static TextTheme _lightTextTheme() {
    const onSurface = textPrimary;
    const seed = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: onSurface,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        color: textSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.1,
      ),
    );
    final inter = GoogleFonts.interTextTheme(seed);
    return inter.copyWith(
      displayLarge: GoogleFonts.fraunces(textStyle: inter.displayLarge),
      headlineLarge: GoogleFonts.fraunces(textStyle: inter.headlineLarge),
      headlineMedium: GoogleFonts.fraunces(textStyle: inter.headlineMedium),
      titleLarge: GoogleFonts.fraunces(textStyle: inter.titleLarge),
      titleMedium: GoogleFonts.fraunces(textStyle: inter.titleMedium),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
      primary: brandPrimary,
      onPrimary: Colors.white,
      secondary: brandAccent,
      onSecondary: Colors.white,
      tertiary: brandPrimaryDark,
      surface: surface,
      onSurface: textPrimary,
      error: danger,
    );

    final textTheme = _lightTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 26),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brandPrimary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          foregroundColor: brandPrimary,
          side: const BorderSide(color: brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 17,
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          fontSize: 17,
          color: textTertiary,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 15,
          color: brandPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandPrimarySoft,
        labelStyle: const TextStyle(
          fontSize: 15,
          color: brandPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 17,
          color: textPrimary,
          height: 1.4,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
