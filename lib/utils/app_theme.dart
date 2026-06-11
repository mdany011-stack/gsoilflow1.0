import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const primary     = Color(0xFF0D1F3C);
  static const accent      = Color(0xFFFA8C12);
  static const accentDark  = Color(0xFFCC6E00);
  static const success     = Color(0xFF21B35E);
  static const danger      = Color(0xFFE53935);
  static const bg          = Color(0xFF0B0E16);
  static const card        = Color(0xFF131B28);
  static const card2       = Color(0xFF1A2335);
  static const textPrimary = Color(0xFFF0F2F5);
  static const textMuted   = Color(0xFF6B7A99);
  static const border      = Color(0xFF243050);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: success,
      surface: card,
      error: danger,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
