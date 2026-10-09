import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const background = Color(0xFF0E1420);
  const surface = Color(0xFF1A2233);
  const primary = Color(0xFF9BB0FF);
  const secondary = Color(0xFFF0C27A);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: primary,
        onPrimary: const Color(0xFF101423),
        secondary: secondary,
        onSecondary: const Color(0xFF2A2112),
        surface: surface,
        onSurface: const Color(0xFFF6F3EC),
        onSurfaceVariant: const Color(0xFFC8C2B4),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Color(0xFFF6F3EC),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF101423);
          }
          return const Color(0xFFF6F3EC);
        }),
      ),
    ),
  );
}
