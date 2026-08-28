import 'package:flutter/material.dart';

abstract final class CampusTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B4AE8),
      brightness: Brightness.light,
    );
    return _buildTheme(scheme);
  }

  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: Color(0xFF28A9FF),
      onPrimary: Color(0xFF001B2D),
      primaryContainer: Color(0xFF073A5D),
      onPrimaryContainer: Color(0xFFBDE5FF),
      secondary: Color(0xFF00D5D5),
      onSecondary: Color(0xFF002021),
      secondaryContainer: Color(0xFF06494A),
      onSecondaryContainer: Color(0xFF9AF4F2),
      surface: Color(0xFF151827),
      onSurface: Color(0xFFE8EAF4),
      surfaceContainerLowest: Color(0xFF0E101B),
      surfaceContainerLow: Color(0xFF1B1F31),
      surfaceContainer: Color(0xFF202538),
      surfaceContainerHigh: Color(0xFF292E43),
      surfaceContainerHighest: Color(0xFF333950),
      outline: Color(0xFF8992AA),
      outlineVariant: Color(0xFF3B435B),
      error: Color(0xFFFF6B7A),
      onError: Color(0xFF3F0010),
    );
    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withAlpha(80)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(150),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }
}
