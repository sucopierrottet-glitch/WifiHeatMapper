import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundObsidian = Color(0xFF0B0F19);
  static const Color surfaceSlate = Color(0xFF161F30);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentAmber = Color(0xFFFFD600);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFF28354A);

  static void configureOfflineFonts() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static ThemeData get darkTheme {
    configureOfflineFonts();
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: backgroundObsidian,
      primaryColor: accentGreen,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentCyan,
        tertiary: accentAmber,
        surface: surfaceSlate,
        error: accentRed,
        onPrimary: Color(0xFF04140B),
        onSecondary: Color(0xFF031824),
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundObsidian,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceSlate,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceSlate,
        indicatorColor: accentGreen.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? accentGreen : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? accentGreen : textSecondary,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: const Color(0xFF04140B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentGreen,
        inactiveTrackColor: borderColor,
        thumbColor: accentGreen,
        overlayColor: accentGreen.withValues(alpha: 0.2),
      ),
      dividerColor: borderColor,
    );
  }
}
