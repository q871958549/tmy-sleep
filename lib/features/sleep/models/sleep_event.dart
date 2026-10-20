import 'dart:math' as math;

import '../../../shared/sleep_clock.dart';

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

  String get clockLabel => formatHm(startedAt.hour, startedAt.minute);

  /// Duration, and for sounds how far the peak sits below digital full scale.
  String get detail {
    final length = _formatLength(duration);
    if (kind == SleepEventKind.motion) {
      return length;
    }
    return '$length · 峰值低 ${_dbBelowFullScale(intensity)} dB';
  }

  String get line => '$clockLabel  ${kind.label}  $detail';

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

int _dbBelowFullScale(double rms) {
  final safe = rms.clamp(0.0001, 1.0);
  return (-20 * math.log(safe) / math.ln10).round();
}

String _formatLength(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 1) {
    return '约 1 秒';
  }
  if (seconds < 60) {
    return '$seconds 秒';
  }
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (rest == 0) {
    return '$minutes 分钟';
  }
  return '$minutes 分 $rest 秒';
}
