import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HardSyncColors {
  // Surfaces & Backgrounds
  static const Color cream = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E4DA);
  static const Color borderSubtle = Color(0xFFF1EDE4);

  // Illustration-led brand palette
  static const Color ink = Color(0xFF17182B);
  static const Color inkMuted = Color(0xFF565B76);
  static const Color violet = Color(0xFF7C5CE7);
  static const Color violetDark = Color(0xFF6547CF);
  static const Color lilacMist = Color(0xFFF1EDFF);
  static const Color lilacBorder = Color(0xFFE2D8FF);
  static const Color apricot = Color(0xFFFF8A43);
  static const Color apricotMist = Color(0xFFFFF0E3);
  static const Color olive = Color(0xFF65704F);
  static const Color oliveMist = Color(0xFFEDF2E7);
  static const Color coral = Color(0xFFF06F61);
  static const Color coralMist = Color(0xFFFFEAE6);
  static const Color sun = Color(0xFFF5B735);
  static const Color sunMist = Color(0xFFFFF4D8);

  // Primary aliases. Keep older screens on the same illustration-led palette.
  static const Color primary = violet;
  static const Color primaryHover = violetDark;
  static const Color primarySubtle = lilacMist;

  // Accent (Warm Terracotta / Coral)
  static const Color accent = apricot;
  static const Color accentHover = Color(0xFFF5742D);
  static const Color accentSubtle = apricotMist;

  // Typography & Neutrals
  static const Color dark = ink;
  static const Color muted = inkMuted;
  static const Color lightMuted = Color(0xFF8B8DA3);

  // Gamification & Badges
  static const Color streakBg = Color(0xFFF8F1E2);
  static const Color streakText = Color(0xFFA26217);
  static const Color streakBorder = Color(0xFFECD9BD);

  // Status & Telemetry
  static const Color crimson = Color(0xFFD32F2F);
  static const Color crimsonSubtle = Color(0xFFFFEBEE);
  static const Color green = Color(0xFF2E7D32);
  static const Color greenSubtle = Color(0xFFE8F5E9);
  static const Color amber = Color(0xFFF57C00);
  static const Color amberSubtle = Color(0xFFFFF3E0);
}

class HardSyncTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: HardSyncColors.cream,
      colorScheme: const ColorScheme.light(
        primary: HardSyncColors.violet,
        onPrimary: Colors.white,
        secondary: HardSyncColors.accent,
        onSecondary: Colors.white,
        surface: HardSyncColors.surface,
        onSurface: HardSyncColors.ink,
        error: HardSyncColors.crimson,
        outline: HardSyncColors.border,
      ),
      textTheme: TextTheme(
        // Editorial Serif Headings
        displayLarge: GoogleFonts.newsreader(
          fontSize: 38,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.newsreader(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.newsreader(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.newsreader(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: HardSyncColors.dark,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.newsreader(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: HardSyncColors.dark,
          height: 1.35,
        ),

        // Modern Geometric Sans Body & UI
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
          letterSpacing: -0.2,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: HardSyncColors.dark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: HardSyncColors.dark,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: HardSyncColors.muted,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: HardSyncColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: HardSyncColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HardSyncColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // Full pill
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HardSyncColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HardSyncColors.surface,
        selectedColor: HardSyncColors.violet,
        side: const BorderSide(color: HardSyncColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: HardSyncColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HardSyncColors.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          side: const BorderSide(color: HardSyncColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HardSyncColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: HardSyncColors.dark),
        titleTextStyle: GoogleFonts.newsreader(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: HardSyncColors.dark,
        ),
      ),
    );
  }
}
