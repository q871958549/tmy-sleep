import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS system dark colors. The sleep screen stays dark on every platform.
abstract final class IosColors {
  static const background = Color(0xFF000000);
  static const grouped = Color(0xFF1C1C1E);
  static const elevated = Color(0xFF2C2C2E);
  static const thumb = Color(0xFF636366);
  static const separator = Color(0xFF38383A);
  static const label = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF8E8E93);
  static const tertiary = Color(0xFF636366);
  static const accent = Color(0xFF0A84FF);
  static const green = Color(0xFF30D158);
}

abstract final class IosType {
  static const largeTime = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w300,
    height: 1,
    letterSpacing: -1.2,
    color: IosColors.label,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const section = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: IosColors.secondary,
    height: 1.25,
  );

  static const row = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: IosColors.label,
    height: 1.2,
  );

  static const value = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: IosColors.accent,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: IosColors.secondary,
    height: 1.35,
  );

  static const metric = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: IosColors.label,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

CupertinoThemeData buildCupertinoTheme() {
  const text = TextStyle(
    fontSize: 17,
    color: IosColors.label,
    letterSpacing: -0.2,
  );
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: IosColors.accent,
    scaffoldBackgroundColor: IosColors.background,
    barBackgroundColor: IosColors.background,
    textTheme: CupertinoTextThemeData(
      textStyle: text,
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: IosColors.label,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: IosColors.label,
      ),
      pickerTextStyle: TextStyle(fontSize: 21, color: IosColors.label),
      actionTextStyle: TextStyle(fontSize: 17, color: IosColors.accent),
    ),
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: IosColors.accent,
    onPrimary: IosColors.label,
    secondary: IosColors.accent,
    surface: IosColors.grouped,
    onSurface: IosColors.label,
    onSurfaceVariant: IosColors.secondary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: IosColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x14FFFFFF),
    textTheme: const TextTheme(
      bodyLarge: IosType.row,
      bodyMedium: IosType.row,
      bodySmall: IosType.footnote,
      titleLarge: IosType.metric,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: IosColors.elevated,
      contentTextStyle: IosType.row,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
