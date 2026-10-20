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
  static const _dimmest = 0.12;
  static const _bedside = 0.22;
  static const _glance = 0.7;

  final _brightness = ScreenBrightness();
  var _level = _bedside;
  Timer? _glanceTimer;

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
    await _apply(_level);
  }

  Future<void> _apply(double level) async {
    try {
      await _brightness.setApplicationScreenBrightness(
        level.clamp(_dimmest, 1),
      );
    } catch (error, stackTrace) {
      debugPrint('brightness failed: $error\n$stackTrace');
    }
  }

  void _glanceAtClock() {
    _glanceTimer?.cancel();
    unawaited(_apply(_glance));
    _glanceTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) {
        return;
      }
      unawaited(_apply(_level));
    });
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
    _glanceTimer?.cancel();
    unawaited(_releaseHardware());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SleepPalette.dark;
    final noteStyle = IosType.footnote(colors)
        .copyWith(color: const Color(0xFFD1D1D6));
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
                    Text(
                      '正在记录',
                      style: IosType.section(colors)
                          .copyWith(color: const Color(0xFFD1D1D6)),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _glanceAtClock,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        active == null
                            ? '准备中'
                            : formatHm(
                                active.startedAt.hour,
                                active.startedAt.minute,
                              ),
                        style: IosType.largeTime(colors),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('点时间可以暂时调亮。请保持这个画面打开，不要锁屏。', style: noteStyle),
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
                      Text(session.note!, style: noteStyle),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('亮度', style: noteStyle),
                        Expanded(
                          child: CupertinoSlider(
                            value: _level,
                            min: _dimmest,
                            max: 1,
                            activeColor: colors.accent,
                            onChanged: (value) {
                              _glanceTimer?.cancel();
                              setState(() => _level = value);
                              unawaited(_apply(value));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: events.isEmpty
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '要连续大约两秒才记。鼾声还要落在偏低的频段里，单次晃动先不记。峰值是相对手机满幅的响度，不是房间里的分贝计。不保存录音，也不上传。',
                                style: noteStyle,
                              ),
                            )
                          : ListView.separated(
                              itemCount: events.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: colors.separator),
                              itemBuilder: (context, index) {
                                final event = events[events.length - 1 - index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    event.line,
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
