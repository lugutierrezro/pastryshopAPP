import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
//  App Theme  — Premium Glassmorphism Vibe
// ============================================================
class AppTheme {
  // ---- Premium Color Palette (Pastel Pink & White) ----
  static const Color primary      = Color(0xFFF48FB1); // Pastel Pink
  static const Color primaryDark  = Color(0xFFE91E63); // Darker Pink for contrast
  static const Color primaryLight = Color(0xFFF8BBD0); // Light Pink
  
  static const Color secondary    = Color(0xFFFFCDD2); // Very light pink
  static const Color accent       = Color(0xFFFF8A80); // Accent pink
  
  static const Color background   = Color(0xFFFFFFFF); // Pure White
  static const Color surface      = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceGlass = Color(0xB3FFFFFF); // 70% opacity for glass
  
  static const Color onPrimary    = Color(0xFFFFFFFF); // White text on pink
  static const Color onBackground = Color(0xFF4A3B32); // Dark brown text (matches logo)
  static const Color textSecondary= Color(0xFF8D6E63); // Lighter brown
  
  static const Color divider      = Color(0xFFFCE4EC); // Very faint pink divider
  static const Color cream        = Color(0xFFFFF0F5); // Lavender blush
  
  static const Color success      = Color(0xFF81C784);
  static const Color warning      = Color(0xFFFFB74D);
  static const Color error        = Color(0xFFE57373);
  static const Color info         = Color(0xFF64B5F6);

  // Admin & Employee colors
  static const Color adminPrimary = Color(0xFF4A3B32); // Dark brown
  static const Color empPrimary   = Color(0xFFF48FB1); // Pastel pink

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary:    primary,
      onPrimary:  onPrimary,
      secondary:  secondary,
      onSecondary:onBackground,
      error:      error,
      onError:    onPrimary,
      surface:    surface,
      onSurface:  onBackground,
    ),
    scaffoldBackgroundColor: background,
    
    // Modern Typography
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge:  GoogleFonts.playfairDisplay(color: onBackground, fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.playfairDisplay(color: onBackground, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.playfairDisplay(color: onBackground, fontWeight: FontWeight.w700),
      headlineMedium:GoogleFonts.playfairDisplay(color: onBackground, fontWeight: FontWeight.w600, fontSize: 22),
      titleLarge:    GoogleFonts.inter(color: onBackground, fontWeight: FontWeight.w700, fontSize: 18),
      bodyLarge:     GoogleFonts.inter(color: onBackground, fontSize: 16),
      bodyMedium:    GoogleFonts.inter(color: textSecondary, fontSize: 14),
      labelLarge:    GoogleFonts.inter(color: onPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: primaryDark),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: onBackground, fontSize: 22, fontWeight: FontWeight.w800,
      ),
    ),
    
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      margin: EdgeInsets.zero,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: onPrimary,
        elevation: 6,
        shadowColor: primaryDark.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        side: const BorderSide(color: primaryDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.inter(color: textSecondary.withValues(alpha: 0.5)),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primaryDark,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: divider, width: 1),
      ),
      elevation: 0,
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondary.withValues(alpha: 0.5),
      type: BottomNavigationBarType.fixed,
      elevation: 20,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
    ),
    
    dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 24),
  );
}
