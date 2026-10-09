import '../../../shared/sleep_clock.dart';

/// Bedtime and wake time for one kind of day (weekday or weekend).
class DaySchedule {
  const DaySchedule({
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.wakeHour,
    required this.wakeMinute,
  });

  final int bedtimeHour;
  final int bedtimeMinute;
  final int wakeHour;
  final int wakeMinute;

  static const weekdayDefault = DaySchedule(
    bedtimeHour: 23,
    bedtimeMinute: 0,
    wakeHour: 7,
    wakeMinute: 0,
  );

  static const weekendDefault = DaySchedule(
    bedtimeHour: 23,
    bedtimeMinute: 30,
    wakeHour: 8,
    wakeMinute: 0,
  );

  bool get wakeIsNextDay {
    final bedtime = bedtimeHour * 60 + bedtimeMinute;
    final wake = wakeHour * 60 + wakeMinute;
    return wake <= bedtime;
  }

  String get bedtimeLabel => formatHm(bedtimeHour, bedtimeMinute);

  String get wakeLabel {
    final hm = formatHm(wakeHour, wakeMinute);
    return wakeIsNextDay ? '次日 $hm' : hm;
  }

  DaySchedule copyWith({
    int? bedtimeHour,
    int? bedtimeMinute,
    int? wakeHour,
    int? wakeMinute,
  }) {
    return DaySchedule(
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      wakeHour: wakeHour ?? this.wakeHour,
      wakeMinute: wakeMinute ?? this.wakeMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bedtimeHour': bedtimeHour,
      'bedtimeMinute': bedtimeMinute,
      'wakeHour': wakeHour,
      'wakeMinute': wakeMinute,
    };
  }

  static DaySchedule? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final bedtimeHour = _hour(json['bedtimeHour']);
    final bedtimeMinute = _minute(json['bedtimeMinute']);
    final wakeHour = _hour(json['wakeHour']);
    final wakeMinute = _minute(json['wakeMinute']);
    if (bedtimeHour == null ||
        bedtimeMinute == null ||
        wakeHour == null ||
        wakeMinute == null) {
      return null;
    }
    return DaySchedule(
      bedtimeHour: bedtimeHour,
      bedtimeMinute: bedtimeMinute,
      wakeHour: wakeHour,
      wakeMinute: wakeMinute,
    );
  }

  static int? _hour(Object? value) {
    if (value is! int || value < 0 || value > 23) {
      return null;
    }
    return value;
  }

  static int? _minute(Object? value) {
    if (value is! int || value < 0 || value > 59) {
      return null;
    }
    return value;
  }
}
