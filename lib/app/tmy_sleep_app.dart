import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/checkin/checkin_controller.dart';
import '../features/schedule/settings_controller.dart';
import 'router.dart';
import 'theme.dart';

class TmySleepApp extends StatefulWidget {
  const TmySleepApp({
    required this.settings,
    required this.checkIns,
    super.key,
  });

  final SettingsController settings;
  final CheckInController checkIns;

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
      ],
      child: MaterialApp.router(
        title: 'tmy-sleep',
        theme: buildTheme(),
        routerConfig: _router,
      ),
    );
  }
}
