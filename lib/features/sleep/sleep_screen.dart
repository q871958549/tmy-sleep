import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme.dart';
import '../../shared/sleep_clock.dart';
import 'models/sleep_event.dart';
import 'sleep_controller.dart';

/// Bedside page. It stays dark even when the rest of the app is light.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final _brightness = ScreenBrightness();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_open());
    });
  }

  Future<void> _open() async {
    unawaited(_holdAwake());
    if (!mounted) {
      return;
    }
    await context.read<SleepSessionController>().begin();
  }

  Future<void> _holdAwake() async {
    try {
      await WakelockPlus.enable();
    } catch (error, stackTrace) {
      debugPrint('wakelock failed: $error\n$stackTrace');
    }
    try {
      await _brightness.setApplicationScreenBrightness(0.02);
    } catch (error, stackTrace) {
      debugPrint('brightness failed: $error\n$stackTrace');
    }
  }

  Future<void> _finish() async {
    await context.read<SleepSessionController>().end();
    unawaited(_releaseHardware());
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _releaseHardware() async {
    try {
      await _brightness.resetApplicationScreenBrightness();
    } catch (error, stackTrace) {
      debugPrint('brightness reset failed: $error\n$stackTrace');
    }
    try {
      await WakelockPlus.disable();
    } catch (error, stackTrace) {
      debugPrint('wakelock disable failed: $error\n$stackTrace');
    }
  }

  @override
  void dispose() {
    unawaited(_releaseHardware());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SleepPalette.dark;
    final session = context.watch<SleepSessionController>();
    final active = session.active;
    final events = active?.events ?? const [];
    return Theme(
      data: buildTheme(colors, Brightness.dark),
      child: CupertinoTheme(
        data: buildCupertinoTheme(colors, Brightness.dark),
        child: PopScope(
          canPop: false,
          child: CupertinoPageScaffold(
            backgroundColor: colors.background,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('正在记录', style: IosType.section(colors)),
                    const SizedBox(height: 8),
                    Text(
                      active == null
                          ? '准备中'
                          : formatHm(
                              active.startedAt.hour,
                              active.startedAt.minute,
                            ),
                      style: IosType.largeTime(colors),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '从这时开始。请保持这个画面打开，不要锁屏。',
                      style: IosType.footnote(colors),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _Count(
                          colors: colors,
                          label: '鼾声',
                          value:
                              '${active?.countOf(SleepEventKind.snore) ?? 0}',
                        ),
                        _Count(
                          colors: colors,
                          label: '梦话',
                          value: '${active?.countOf(SleepEventKind.talk) ?? 0}',
                        ),
                        _Count(
                          colors: colors,
                          label: '异动',
                          value:
                              '${active?.countOf(SleepEventKind.motion) ?? 0}',
                        ),
                      ],
                    ),
                    if (session.note != null) ...[
                      const SizedBox(height: 16),
                      Text(session.note!, style: IosType.footnote(colors)),
                    ],
                    const SizedBox(height: 20),
                    Expanded(
                      child: events.isEmpty
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '安静的时候不会记。低沉的声音记为鼾声，更像说话的声音记为梦话，手机明显晃动记为异动。不保存录音，也不上传。',
                                style: IosType.footnote(colors),
                              ),
                            )
                          : ListView.separated(
                              itemCount: events.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: colors.separator),
                              itemBuilder: (context, index) {
                                final event = events[events.length - 1 - index];
                                final clock = formatHm(
                                  event.startedAt.hour,
                                  event.startedAt.minute,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    '$clock  ${event.kind.label}',
                                    style: IosType.row(colors),
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: colors.grouped,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onPressed: _finish,
                        child: Text(
                          '我醒了',
                          style: IosType.row(colors)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.colors,
    required this.label,
    required this.value,
  });

  final SleepPalette colors;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: IosType.metric(colors)),
          const SizedBox(height: 4),
          Text(label, style: IosType.section(colors)),
        ],
      ),
    );
  }
}
