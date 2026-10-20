import 'models/sleep_event.dart';
import 'sound_window.dart';

/// Merges microphone and motion samples into short episodes.
///
/// A sound has to repeat for [confirmWindows] windows before it is kept.
/// One bump of the phone is ignored; [motionHitsNeeded] bumps inside
/// [motionWindow] become one restless episode.
class SleepTracker {
  SleepTracker({List<SleepEvent>? existing}) {
    if (existing != null) {
      events.addAll(existing);
    }
  }

  static const mergeGap = Duration(seconds: 8);
  static const confirmWindows = 2;
  static const motionHitsNeeded = 3;
  static const motionWindow = Duration(seconds: 10);

  final events = <SleepEvent>[];

  SoundGuess? _arming;
  var _armingCount = 0;
  DateTime? _armingStarted;
  DateTime? _lastSoundAt;
  final _motionTimes = <DateTime>[];

  /// Returns true when the visible list changed.
  bool onSound(DateTime at, SoundWindow window) {
    final guess = classifySound(window);
    if (guess == SoundGuess.quiet) {
      _clearArming();
      return false;
    }
    final stalled =
        _lastSoundAt != null && at.difference(_lastSoundAt!) > mergeGap;
    if (_arming != guess || stalled) {
      _arming = guess;
      _armingCount = 1;
      _armingStarted = at;
      _lastSoundAt = at;
      return false;
    }
    _lastSoundAt = at;
    _armingCount += 1;
    if (_armingCount < confirmWindows) {
      return false;
    }
    return _note(
      _armingStarted ?? at,
      at,
      guess == SoundGuess.snore ? SleepEventKind.snore : SleepEventKind.talk,
      window.rms,
    );
  }

  /// Returns true when the visible list changed.
  bool onMotion(DateTime at, double x, double y, double z) {
    if (!isMovement(x, y, z)) {
      return false;
    }
    _motionTimes.add(at);
    final cutoff = at.subtract(motionWindow);
    _motionTimes.removeWhere((time) => time.isBefore(cutoff));
    if (_motionTimes.length < motionHitsNeeded) {
      return false;
    }
    return _note(_motionTimes.first, at, SleepEventKind.motion, 0.7);
  }

  void _clearArming() {
    _arming = null;
    _armingCount = 0;
    _armingStarted = null;
    _lastSoundAt = null;
  }

  bool _note(
    DateTime start,
    DateTime end,
    SleepEventKind kind,
    double intensity,
  ) {
    final finished = end.isBefore(start) ? start : end;
    if (events.isNotEmpty) {
      final last = events.last;
      final gap = start.difference(last.endedAt);
      if (last.kind == kind && !gap.isNegative && gap <= mergeGap) {
        events[events.length - 1] = last.extendTo(finished, intensity);
        return true;
      }
    }
    events.add(
      SleepEvent(
        startedAt: start,
        endedAt: finished,
        kind: kind,
        intensity: intensity.clamp(0, 1),
      ),
    );
    return true;
  }
}
