import 'dart:async';

import 'package:tmy_sleep/features/sleep/sleep_monitor.dart';
import 'package:tmy_sleep/features/sleep/sound_window.dart';

/// Emits one snore, one talk, and one movement when [start] runs.
class FakeSleepMonitor implements SleepMonitor {
  final _samples = StreamController<SleepSample>.broadcast();

  @override
  Stream<SleepSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    _samples.add(SoundSample(const SoundWindow(rms: 0.2, zcr: 0.02)));
    _samples.add(SoundSample(const SoundWindow(rms: 0.15, zcr: 0.2)));
    _samples.add(MotionSample(0, 4, 0));
  }

  @override
  Future<void> stop() async {}
}
