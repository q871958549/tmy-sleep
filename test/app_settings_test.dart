import 'package:flutter_test/flutter_test.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';
import 'package:tmy_sleep/features/schedule/models/day_schedule.dart';

void main() {
  test('weekend schedule is optional', () {
    const separate = AppSettings(
      weekday: DaySchedule.weekdayDefault,
      weekend: DaySchedule.weekendDefault,
      remindersEnabled: true,
      snoozeMinutes: 15,
      useSeparateWeekend: true,
    );
    final saturday = DateTime(2026, 10, 10);
    final friday = DateTime(2026, 10, 9);

    expect(separate.scheduleFor(saturday).bedtimeMinute, 30);
    expect(separate.scheduleFor(friday).bedtimeHour, 23);
    expect(separate.scheduleFor(friday).bedtimeMinute, 0);

    final shared = separate.copyWith(useSeparateWeekend: false);
    expect(shared.scheduleFor(saturday).bedtimeMinute, 0);
    expect(shared.scheduleKindLabel(saturday), '工作日');
    expect(separate.scheduleKindLabel(saturday), '周末');
  });

  test('json keeps only 15 or 30 minute snooze', () {
    final restored = AppSettings.fromJson({
      'weekday': DaySchedule.weekdayDefault.toJson(),
      'weekend': {
        'bedtimeHour': 1,
        'bedtimeMinute': 15,
        'wakeHour': 9,
        'wakeMinute': 0,
      },
      'remindersEnabled': false,
      'snoozeMinutes': 30,
      'useSeparateWeekend': true,
    });
    expect(restored.snoozeMinutes, 30);
    expect(restored.remindersEnabled, isFalse);
    expect(restored.weekend.bedtimeHour, 1);
    expect(restored.weekend.wakeIsNextDay, isFalse);

    final broken = AppSettings.fromJson({
      'snoozeMinutes': 45,
      'weekday': {'bedtimeHour': 99},
    });
    expect(broken.snoozeMinutes, 15);
    expect(broken.weekday.bedtimeHour, DaySchedule.weekdayDefault.bedtimeHour);
    expect(AppSettings.fromJson('nope').remindersEnabled, isTrue);
  });

  test('wake after midnight is labeled as the next day', () {
    expect(DaySchedule.weekdayDefault.wakeLabel, '次日 07:00');
    expect(DaySchedule.weekdayDefault.bedtimeLabel, '23:00');
  });
}
