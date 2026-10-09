import '../../../shared/sleep_clock.dart';
import 'day_schedule.dart';

/// User schedule and local reminder preferences.
///
/// [snoozeMinutes] is either 15 or 30. There is no account, sync, or purchase
/// state — the app stays free.
class AppSettings {
  const AppSettings({
    required this.weekday,
    required this.weekend,
    required this.remindersEnabled,
    required this.snoozeMinutes,
    required this.useSeparateWeekend,
  });

  final DaySchedule weekday;
  final DaySchedule weekend;
  final bool remindersEnabled;
  final int snoozeMinutes;
  final bool useSeparateWeekend;

  static const defaults = AppSettings(
    weekday: DaySchedule.weekdayDefault,
    weekend: DaySchedule.weekendDefault,
    remindersEnabled: true,
    snoozeMinutes: 15,
    useSeparateWeekend: false,
  );

  DaySchedule scheduleFor(DateTime date) {
    if (useSeparateWeekend && isWeekend(date)) {
      return weekend;
    }
    return weekday;
  }

  String scheduleKindLabel(DateTime date) {
    if (useSeparateWeekend && isWeekend(date)) {
      return '周末';
    }
    return '工作日';
  }

  AppSettings copyWith({
    DaySchedule? weekday,
    DaySchedule? weekend,
    bool? remindersEnabled,
    int? snoozeMinutes,
    bool? useSeparateWeekend,
  }) {
    return AppSettings(
      weekday: weekday ?? this.weekday,
      weekend: weekend ?? this.weekend,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      snoozeMinutes: normalizeSnoozeMinutes(
        snoozeMinutes ?? this.snoozeMinutes,
      ),
      useSeparateWeekend: useSeparateWeekend ?? this.useSeparateWeekend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday.toJson(),
      'weekend': weekend.toJson(),
      'remindersEnabled': remindersEnabled,
      'snoozeMinutes': snoozeMinutes,
      'useSeparateWeekend': useSeparateWeekend,
    };
  }

  factory AppSettings.fromJson(Object? raw) {
    if (raw is! Map) {
      return defaults;
    }
    final json = Map<String, dynamic>.from(raw);
    return AppSettings(
      weekday: DaySchedule.tryParse(json['weekday']) ?? defaults.weekday,
      weekend: DaySchedule.tryParse(json['weekend']) ?? defaults.weekend,
      remindersEnabled: json['remindersEnabled'] is bool
          ? json['remindersEnabled'] as bool
          : defaults.remindersEnabled,
      snoozeMinutes: normalizeSnoozeMinutes(json['snoozeMinutes']),
      useSeparateWeekend: json['useSeparateWeekend'] is bool
          ? json['useSeparateWeekend'] as bool
          : defaults.useSeparateWeekend,
    );
  }

  /// Keeps the MVP choice to the two snooze lengths the notification offers.
  static int normalizeSnoozeMinutes(Object? value) {
    if (value == 30) {
      return 30;
    }
    return 15;
  }
}
