import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';
import 'package:tmy_sleep/features/schedule/models/day_schedule.dart';
import 'package:tmy_sleep/features/sleep/models/sleep_event.dart';
import 'package:tmy_sleep/features/sleep/models/sleep_session.dart';
import 'package:tmy_sleep/features/sleep/sleep_tracker.dart';
import 'package:tmy_sleep/features/sleep/sound_window.dart';

void main() {
  test('pcm16 windows keep snoring in band and drop a low hum', () {
    expect(
      soundWindowFromPcm16(Uint8List(0)),
      const SoundWindow(rms: 0, zcr: 0),
    );

    final loud = ByteData(4);
    loud.setInt16(0, 16384, Endian.little);
    loud.setInt16(2, -16384, Endian.little);
    final window = soundWindowFromPcm16(loud.buffer.asUint8List());
    expect(window.rms, closeTo(0.5, 0.001));
    expect(window.zcr, closeTo(0.5, 0.001));

    final snore = soundWindowFromPcm16(_tone(200));
    final hum = soundWindowFromPcm16(_tone(50));
    expect(snore.bandRatio, greaterThan(0.45));
    expect(hum.bandRatio, lessThan(0.25));
    expect(classifySound(snore), SoundGuess.snore);
    expect(classifySound(hum), SoundGuess.quiet);
    expect(
      classifySound(const SoundWindow(rms: 0.2, zcr: 0.02, bandRatio: 0.1)),
      SoundGuess.quiet,
    );
    expect(
      classifySound(const SoundWindow(rms: 0.15, zcr: 0.2, bandRatio: 0.2)),
      SoundGuess.talk,
    );
    expect(isMovement(0, 4, 0), isTrue);
    expect(isMovement(0.2, 0.1, 0), isFalse);
    expect(dbBelowFullScale(0.2), 14);
  });

  test('episodes need a repeated sound or several bumps', () {
    final tracker = SleepTracker();
    final first = DateTime(2026, 10, 9, 23, 10);
    const snore = SoundWindow(rms: 0.2, zcr: 0.02, bandRatio: 0.7);
    const louder = SoundWindow(rms: 0.3, zcr: 0.02, bandRatio: 0.7);

    tracker.onSound(first, snore);
    expect(tracker.events, isEmpty);
    tracker.onSound(first.add(const Duration(seconds: 5)), louder);
    expect(tracker.events, hasLength(1));
    expect(tracker.events.single.kind, SleepEventKind.snore);
    expect(
      tracker.events.single.endedAt,
      first.add(const Duration(seconds: 5)),
    );
    expect(tracker.events.single.detail, contains('峰值低 10 dB'));

    tracker.onSound(first.add(const Duration(seconds: 20)), snore);
    expect(tracker.events, hasLength(1));
    tracker.onSound(first.add(const Duration(seconds: 21)), snore);
    expect(tracker.events, hasLength(2));

    tracker.onMotion(first.add(const Duration(seconds: 22)), 0, 4, 0);
    tracker.onMotion(first.add(const Duration(seconds: 23)), 0, 4, 0);
    expect(tracker.events, hasLength(2));
    tracker.onMotion(first.add(const Duration(seconds: 24)), 0, 4, 0);
    expect(tracker.events, hasLength(3));
    expect(tracker.events.last.kind, SleepEventKind.motion);
    expect(tracker.events.last.detail, '2 秒');
  });

  test('a session round-trips and a missing theme stays dark', () {
    final started = DateTime(2026, 10, 9, 23);
    final session = SleepSession(
      id: 'night',
      startedAt: started,
      endedAt: started.add(const Duration(hours: 7)),
      note: '没有麦克风权限，这次只记录手机的晃动。',
      events: [
        SleepEvent(
          startedAt: started,
          endedAt: started.add(const Duration(seconds: 8)),
          kind: SleepEventKind.talk,
          intensity: 0.4,
        ),
      ],
    );
    final restored = SleepSession.tryParse(session.toJson());
    expect(restored?.id, 'night');
    expect(restored?.isOpen, isFalse);
    expect(restored?.countOf(SleepEventKind.talk), 1);
    expect(restored?.events.single.detail, contains('8 秒'));
    expect(restored?.note, session.note);
    expect(SleepSession.tryParse('nope'), isNull);

    final settings = AppSettings.fromJson({
      'weekday': DaySchedule.weekdayDefault.toJson(),
    });
    expect(settings.themeMode, AppThemeMode.dark);
    expect(
      settings.copyWith(themeMode: AppThemeMode.light).toJson()['themeMode'],
      'light',
    );
  });
}

Uint8List _tone(double hz) {
  const samples = 4096;
  const rate = 16000;
  final data = ByteData(samples * 2);
  for (var index = 0; index < samples; index++) {
    final sample = (math.sin(2 * math.pi * hz * index / rate) * 0.25 * 32767)
        .round();
    data.setInt16(index * 2, sample.clamp(-32767, 32767), Endian.little);
  }
  return data.buffer.asUint8List();
}
