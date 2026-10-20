import 'dart:async';

import 'package:tmy_sleep/features/sleep/sleep_monitor.dart';
import 'package:tmy_sleep/features/sleep/sound_window.dart';

/// Emits confirmed snore, talk, and restless-motion episodes when [start] runs.
class FakeSleepMonitor implements SleepMonitor {
  final _samples = StreamController<SleepSample>.broadcast();

  @override
  Stream<SleepSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    const snore = SoundWindow(rms: 0.2, zcr: 0.02, bandRatio: 0.7);
    const talk = SoundWindow(rms: 0.15, zcr: 0.2, bandRatio: 0.3);
    _samples.add(SoundSample(snore));
    _samples.add(SoundSample(snore));
    _samples.add(SoundSample(talk));
    _samples.add(SoundSample(talk));
    _samples.add(MotionSample(0, 4, 0));
    _samples.add(MotionSample(0, 4, 0));
    _samples.add(MotionSample(0, 4, 0));
  }

  @override
  Future<void> stop() async {}
}
