import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';
import 'package:tmy_sleep/features/schedule/models/day_schedule.dart';
import 'package:tmy_sleep/features/sleep/models/sleep_event.dart';
import 'package:tmy_sleep/features/sleep/models/sleep_session.dart';
import 'package:tmy_sleep/features/sleep/sleep_tracker.dart';
import 'package:tmy_sleep/features/sleep/sound_window.dart';

void main() {
  test('pcm16 windows split quiet, snore, and talk', () {
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

    expect(
      classifySound(const SoundWindow(rms: 0.01, zcr: 0.01)),
      SoundGuess.quiet,
    );
    expect(
      classifySound(const SoundWindow(rms: 0.2, zcr: 0.02)),
      SoundGuess.snore,
    );
    expect(
      classifySound(const SoundWindow(rms: 0.15, zcr: 0.2)),
      SoundGuess.talk,
    );
    expect(isMovement(0, 4, 0), isTrue);
    expect(isMovement(0.2, 0.1, 0), isFalse);
  });

  test('the same kind within eight seconds becomes one event', () {
    final tracker = SleepTracker();
    final first = DateTime(2026, 10, 9, 23, 10);
    tracker.onSound(first, const SoundWindow(rms: 0.2, zcr: 0.02));
    tracker.onSound(
      first.add(const Duration(seconds: 5)),
      const SoundWindow(rms: 0.3, zcr: 0.02),
    );
    expect(tracker.events, hasLength(1));
    expect(tracker.events.single.kind, SleepEventKind.snore);
    expect(
      tracker.events.single.endedAt,
      first.add(const Duration(seconds: 5)),
    );

    tracker.onSound(
      first.add(const Duration(seconds: 20)),
      const SoundWindow(rms: 0.2, zcr: 0.02),
    );
    tracker.onMotion(first.add(const Duration(seconds: 21)), 0, 4, 0);
    expect(tracker.events, hasLength(3));
    expect(tracker.events.last.kind, SleepEventKind.motion);
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
