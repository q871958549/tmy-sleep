import 'sleep_event.dart';

class SleepSession {
  const SleepSession({
    required this.id,
    required this.startedAt,
    required this.events,
    this.endedAt,
    this.note,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<SleepEvent> events;
  final String? note;

  bool get isOpen => endedAt == null;

  int countOf(SleepEventKind kind) {
    var total = 0;
    for (final event in events) {
      if (event.kind == kind) {
        total += 1;
      }
    }
    return total;
  }

  SleepSession copyWith({
    DateTime? endedAt,
    bool clearEnded = false,
    List<SleepEvent>? events,
    String? note,
  }) {
    return SleepSession(
      id: id,
      startedAt: startedAt,
      endedAt: clearEnded ? null : endedAt ?? this.endedAt,
      events: events ?? this.events,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'note': note,
      'events': [for (final event in events) event.toJson()],
    };
  }

  static SleepSession? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    final started = DateTime.tryParse('${json['startedAt']}');
    if (id is! String || id.isEmpty || started == null) {
      return null;
    }
    final endedRaw = json['endedAt'];
    final ended = endedRaw is String ? DateTime.tryParse(endedRaw) : null;
    final note = json['note'];
    final events = <SleepEvent>[];
    final rawEvents = json['events'];
    if (rawEvents is List) {
      for (final item in rawEvents) {
        final event = SleepEvent.tryParse(item);
        if (event != null) {
          events.add(event);
        }
      }
    }
    return SleepSession(
      id: id,
      startedAt: started,
      endedAt: ended,
      note: note is String && note.isNotEmpty ? note : null,
      events: events,
    );
  }
}
