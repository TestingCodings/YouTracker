import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../src/design_tokens.dart';

class AppTheme {
  static const _primaryColor = Color(0xFFFF0000);
  static const _secondaryColor = Color(0xFF282828);
  static const _accentColor = Color(0xFF065FD4);

  // Seed color for Material 3 color scheme generation (indigo/teal fallback)
  static const _seedColor = Color(0xFF3F51B5); // Indigo

  /// Creates a custom text theme using Inter font from Google Fonts.
  /// Falls back to default Material typography if unavailable.
  static TextTheme _createTextTheme(Color textColor) {
    try {
      return GoogleFonts.interTextTheme().copyWith(
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.25,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.15,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.25,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.1,
        ),
      );
    } catch (_) {
      // Fallback to default Material typography if google_fonts fails
      return Typography.material2021().black.apply(
            bodyColor: textColor,
            displayColor: textColor,
          );
    }
  }

  /// Light theme configuration with Material 3 enhancements.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: Colors.white,
      error: Colors.red.shade700,
    );

    final textTheme = _createTextTheme(_secondaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _secondaryColor,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _secondaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          elevation: Elevations.medium,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          side: const BorderSide(color: _primaryColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xs,
        ),
        minVerticalPadding: Spacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      // Page transitions theme for consistent navigation animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Dark theme configuration with Material 3 enhancements.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      primary: _primaryColor,
      secondary: Colors.grey.shade300,
      tertiary: _accentColor,
      surface: const Color(0xFF121212),
      error: Colors.red.shade400,
    );

    final textTheme = _createTextTheme(Colors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF212121),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          elevation: Elevations.medium,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          side: const BorderSide(color: _primaryColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xs,
        ),
        minVerticalPadding: Spacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF212121),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
      ),
      // Page transitions theme for consistent navigation animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
