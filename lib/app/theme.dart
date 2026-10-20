import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS grouped colors for one brightness.
///
/// Text styles set [TextDecoration.none] and do not inherit. Without that,
/// text under [CupertinoPageScaffold] picks up Material's fallback style:
/// a yellow double underline.
class SleepPalette {
  const SleepPalette({
    required this.background,
    required this.grouped,
    required this.elevated,
    required this.thumb,
    required this.separator,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.accent,
    required this.onAccent,
    required this.green,
  });

  final Color background;
  final Color grouped;
  final Color elevated;
  final Color thumb;
  final Color separator;
  final Color label;
  final Color secondary;
  final Color tertiary;
  final Color accent;
  final Color onAccent;
  final Color green;

  static const dark = SleepPalette(
    background: Color(0xFF000000),
    grouped: Color(0xFF1C1C1E),
    elevated: Color(0xFF2C2C2E),
    thumb: Color(0xFF636366),
    separator: Color(0xFF38383A),
    label: Color(0xFFFFFFFF),
    secondary: Color(0xFF8E8E93),
    tertiary: Color(0xFF636366),
    accent: Color(0xFF0A84FF),
    onAccent: Color(0xFFFFFFFF),
    green: Color(0xFF30D158),
  );

  static const light = SleepPalette(
    background: Color(0xFFF2F2F7),
    grouped: Color(0xFFFFFFFF),
    elevated: Color(0xFFE5E5EA),
    thumb: Color(0xFFFFFFFF),
    separator: Color(0xFFC6C6C8),
    label: Color(0xFF000000),
    secondary: Color(0xFF6C6C70),
    tertiary: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    onAccent: Color(0xFFFFFFFF),
    green: Color(0xFF34C759),
  );

  static SleepPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

abstract final class IosType {
  static const _features = [FontFeature.tabularFigures()];

  static TextStyle largeTime(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 64,
      fontWeight: FontWeight.w300,
      height: 1,
      letterSpacing: -1.2,
      color: colors.label,
      fontFeatures: _features,
    );
  }

  static TextStyle section(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: colors.secondary,
      height: 1.25,
    );
  }

  static TextStyle row(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: colors.label,
      height: 1.2,
    );
  }

  static TextStyle value(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: colors.accent,
      height: 1.2,
      fontFeatures: _features,
    );
  }

  static TextStyle footnote(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: colors.secondary,
      height: 1.35,
    );
  }

  static TextStyle metric(SleepPalette colors) {
    return TextStyle(
      inherit: false,
      decoration: TextDecoration.none,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: colors.label,
      height: 1.15,
      fontFeatures: _features,
    );
  }
}

CupertinoThemeData buildCupertinoTheme(
  SleepPalette colors,
  Brightness brightness,
) {
  final text = TextStyle(
    inherit: false,
    decoration: TextDecoration.none,
    fontSize: 17,
    color: colors.label,
    letterSpacing: -0.2,
  );
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: colors.accent,
    scaffoldBackgroundColor: colors.background,
    barBackgroundColor: colors.background,
    textTheme: CupertinoTextThemeData(
      textStyle: text,
      navTitleTextStyle: TextStyle(
        inherit: false,
        decoration: TextDecoration.none,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colors.label,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        decoration: TextDecoration.none,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: colors.label,
      ),
      pickerTextStyle: TextStyle(
        inherit: false,
        decoration: TextDecoration.none,
        fontSize: 21,
        color: colors.label,
      ),
      actionTextStyle: TextStyle(
        inherit: false,
        decoration: TextDecoration.none,
        fontSize: 17,
        color: colors.accent,
      ),
    ),
  );
}

ThemeData buildTheme(SleepPalette colors, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    surface: colors.grouped,
    onSurface: colors.label,
    onSurfaceVariant: colors.secondary,
    error: const Color(0xFFFF453A),
    onError: colors.onAccent,
  );
  final row = IosType.row(colors);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: brightness == Brightness.dark
        ? const Color(0x14FFFFFF)
        : const Color(0x14000000),
    textTheme: TextTheme(
      bodyLarge: row,
      bodyMedium: row,
      bodySmall: IosType.footnote(colors),
      titleLarge: IosType.metric(colors),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.elevated,
      contentTextStyle: row,
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
