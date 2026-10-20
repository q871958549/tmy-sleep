import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/checkin/checkin_controller.dart';
import '../features/schedule/models/app_settings.dart';
import '../features/schedule/settings_controller.dart';
import '../features/sleep/sleep_controller.dart';
import '../features/update/update_coordinator.dart';
import 'router.dart';
import 'theme.dart';

class TmySleepApp extends StatefulWidget {
  const TmySleepApp({
    required this.settings,
    required this.checkIns,
    required this.updates,
    required this.sleep,
    super.key,
  });

  final SettingsController settings;
  final CheckInController checkIns;
  final UpdateCoordinator updates;
  final SleepSessionController sleep;

  @override
  State<TmySleepApp> createState() => _TmySleepAppState();
}

class _TmySleepAppState extends State<TmySleepApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider.value(value: widget.checkIns),
        ChangeNotifierProvider.value(value: widget.updates),
        ChangeNotifierProvider.value(value: widget.sleep),
      ],
      child: _ThemedApp(router: _router),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<SettingsController>().settings.themeMode;
    return MaterialApp.router(
      title: 'tmy-sleep',
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      theme: buildTheme(SleepPalette.light, Brightness.light),
      darkTheme: buildTheme(SleepPalette.dark, Brightness.dark),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final palette = brightness == Brightness.dark
            ? SleepPalette.dark
            : SleepPalette.light;
        final style = IosType.row(palette);
        return Material(
          type: MaterialType.transparency,
          child: CupertinoTheme(
            data: buildCupertinoTheme(palette, brightness),
            child: DefaultTextStyle(
              style: style,
              child: IconTheme(
                data: IconThemeData(color: palette.label),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
