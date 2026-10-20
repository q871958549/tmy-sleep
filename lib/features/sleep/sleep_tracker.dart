import 'models/sleep_event.dart';
import 'sound_window.dart';

/// Merges raw microphone and motion samples into a short list of events.
class SleepTracker {
  SleepTracker({List<SleepEvent>? existing}) {
    if (existing != null) {
      events.addAll(existing);
    }
  }

  static const mergeGap = Duration(seconds: 8);

  final events = <SleepEvent>[];

  /// Returns true when the visible list changed.
  bool onSound(DateTime at, SoundWindow window) {
    switch (classifySound(window)) {
      case SoundGuess.quiet:
        return false;
      case SoundGuess.snore:
        return _note(at, SleepEventKind.snore, window.rms);
      case SoundGuess.talk:
        return _note(at, SleepEventKind.talk, window.rms);
    }
  }

  /// Returns true when the visible list changed.
  bool onMotion(DateTime at, double x, double y, double z) {
    if (!isMovement(x, y, z)) {
      return false;
    }
    return _note(at, SleepEventKind.motion, 0.7);
  }

  bool _note(DateTime at, SleepEventKind kind, double intensity) {
    if (events.isNotEmpty) {
      final last = events.last;
      final gap = at.difference(last.endedAt);
      if (last.kind == kind && !gap.isNegative && gap <= mergeGap) {
        events[events.length - 1] = last.extendTo(at, intensity);
        return true;
      }
    }
    events.add(
      SleepEvent(
        startedAt: at,
        endedAt: at,
        kind: kind,
        intensity: intensity.clamp(0, 1),
      ),
    );
    return true;
  }
}
