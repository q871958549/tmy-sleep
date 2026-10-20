enum SleepEventKind { snore, talk, motion }

extension SleepEventKindLabel on SleepEventKind {
  String get label {
    switch (this) {
      case SleepEventKind.snore:
        return '鼾声';
      case SleepEventKind.talk:
        return '梦话';
      case SleepEventKind.motion:
        return '异动';
    }
  }
}

/// One noted moment. Nearby moments of the same kind are merged.
class SleepEvent {
  const SleepEvent({
    required this.startedAt,
    required this.endedAt,
    required this.kind,
    required this.intensity,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final SleepEventKind kind;
  final double intensity;

  Duration get duration => endedAt.difference(startedAt);

  SleepEvent extendTo(DateTime at, double nextIntensity) {
    final end = at.isAfter(endedAt) ? at : endedAt;
    return SleepEvent(
      startedAt: startedAt,
      endedAt: end,
      kind: kind,
      intensity: nextIntensity > intensity ? nextIntensity : intensity,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'kind': kind.name,
      'intensity': intensity,
    };
  }

  static SleepEvent? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final started = DateTime.tryParse('${json['startedAt']}');
    final ended = DateTime.tryParse('${json['endedAt']}');
    final kindName = json['kind'];
    final intensity = json['intensity'];
    if (started == null || ended == null || kindName is! String) {
      return null;
    }
    SleepEventKind? kind;
    for (final value in SleepEventKind.values) {
      if (value.name == kindName) {
        kind = value;
      }
    }
    if (kind == null) {
      return null;
    }
    return SleepEvent(
      startedAt: started,
      endedAt: ended.isBefore(started) ? started : ended,
      kind: kind,
      intensity: intensity is num ? intensity.toDouble().clamp(0, 1) : 0,
    );
  }
}
