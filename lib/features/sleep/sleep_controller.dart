import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/sleep_clock.dart';
import 'models/sleep_event.dart';
import 'models/sleep_session.dart';
import 'sleep_monitor.dart';
import 'sleep_store.dart';
import 'sleep_tracker.dart';

class SleepSessionController extends ChangeNotifier {
  SleepSessionController({
    required SleepStore store,
    required SleepMonitor monitor,
    DateTime Function()? clock,
  }) {
    _store = store;
    _monitor = monitor;
    _clock = clock ?? DateTime.now;
  }

  late final SleepStore _store;
  late final SleepMonitor _monitor;
  late final DateTime Function() _clock;

  List<SleepSession> sessions = [];
  SleepSession? active;
  String? note;
  bool listening = false;

  StreamSubscription<SleepSample>? _subscription;
  SleepTracker _tracker = SleepTracker();
  Future<void> _writes = Future<void>.value();

  void load() {
    sessions = _store.load();
    for (final session in sessions) {
      if (session.isOpen) {
        active = session;
      }
    }
  }

  /// The latest session that belongs to this sleep night.
  SleepSession? sessionFor(DateTime night) {
    final key = dateKey(night);
    SleepSession? match;
    for (final session in sessions) {
      if (dateKey(sleepDate(session.startedAt)) == key) {
        match = session;
      }
    }
    return match;
  }

  Future<void> begin() async {
    if (listening) {
      return;
    }
    final now = _clock();
    final night = dateKey(sleepDate(now));
    SleepSession? existing;
    for (final session in sessions) {
      if (dateKey(sleepDate(session.startedAt)) == night) {
        existing = session;
      }
    }
    if (existing == null) {
      existing = SleepSession(
        id: now.toIso8601String(),
        startedAt: now,
        events: const [],
      );
      sessions = [...sessions, existing];
    } else {
      existing = existing.copyWith(clearEnded: true);
      _replace(existing);
    }
    active = existing;
    note = null;
    _tracker = SleepTracker(existing: existing.events);
    listening = true;
    notifyListeners();
    _subscription = _monitor.samples.listen(_onSample);
    try {
      await _monitor.start();
    } catch (error, stackTrace) {
      debugPrint('sleep monitor failed: $error\n$stackTrace');
      if (!listening) {
        return;
      }
      note = '这台设备暂时不能记录声音和晃动。';
      notifyListeners();
    }
    if (!listening || active == null) {
      return;
    }
    _replace(active!);
    await _persist();
  }

  Future<void> end() async {
    final current = active;
    if (current == null) {
      unawaited(_stopListening());
      return;
    }
    final closed = current.copyWith(
      endedAt: _clock(),
      events: List.unmodifiable(_tracker.events),
      note: note,
    );
    active = null;
    listening = false;
    _replace(closed);
    notifyListeners();
    final release = _stopListening();
    await _persist();
    unawaited(release);
  }

  void _onSample(SleepSample sample) {
    if (!listening || active == null) {
      return;
    }
    final at = _clock();
    var changed = false;
    switch (sample) {
      case SoundSample(:final window):
        changed = _tracker.onSound(at, window);
      case MotionSample(:final x, :final y, :final z):
        changed = _tracker.onMotion(at, x, y, z);
      case MonitorNote(:final message):
        note = message;
        changed = true;
    }
    if (!changed || active == null) {
      if (sample is MonitorNote) {
        notifyListeners();
      }
      return;
    }
    final events = List<SleepEvent>.unmodifiable(_tracker.events);
    if (events.length > 200) {
      _tracker.events.removeRange(0, events.length - 200);
    }
    final next = active!.copyWith(
      events: List.unmodifiable(_tracker.events),
      note: note,
    );
    active = next;
    _replace(next);
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _stopListening() async {
    listening = false;
    final subscription = _subscription;
    _subscription = null;
    try {
      await subscription?.cancel();
    } catch (error, stackTrace) {
      debugPrint('sleep monitor cancel failed: $error\n$stackTrace');
    }
    try {
      await _monitor.stop();
    } catch (error, stackTrace) {
      debugPrint('sleep monitor stop failed: $error\n$stackTrace');
    }
  }

  void _replace(SleepSession session) {
    sessions = [
      for (final item in sessions)
        if (item.id == session.id) session else item,
    ];
    if (sessions.length > 30) {
      sessions = sessions.sublist(sessions.length - 30);
    }
  }

  Future<void> _persist() {
    final snapshot = List<SleepSession>.from(sessions);
    _writes = _writes
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('sleep save failed: $error\n$stackTrace');
        })
        .then((_) => _store.save(snapshot));
    return _writes;
  }

  @override
  void dispose() {
    unawaited(_stopListening());
    super.dispose();
  }
}
