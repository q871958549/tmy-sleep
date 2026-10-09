import 'package:flutter_test/flutter_test.dart';
import 'package:tmy_sleep/features/checkin/models/daily_log.dart';
import 'package:tmy_sleep/features/checkin/models/sleep_check_in.dart';
import 'package:tmy_sleep/features/report/report_calculator.dart';
import 'package:tmy_sleep/shared/sleep_clock.dart';

void main() {
  DailyLog log(String date, SleepCheckIn kind, {int? delay}) {
    return DailyLog(
      date: date,
      checkIn: kind,
      delayMinutes: switch (kind) {
        SleepCheckIn.onTime => 0,
        SleepCheckIn.delayed => delay,
        SleepCheckIn.stayedUp => null,
      },
      checkedInAt: DateTime.parse('${date}T23:00:00'),
    );
  }

  test('empty week has no rate and a zero streak', () {
    final report = buildWeeklyReport(
      logs: const [],
      today: DateTime(2026, 10, 9),
    );
    expect(report.loggedDays, 0);
    expect(report.onTimeRate, isNull);
    expect(report.averageDelayMinutes, isNull);
    expect(report.streak, 0);
  });

  test('rate and average delay cover the last 7 nights', () {
    final report = buildWeeklyReport(
      logs: [
        log('2026-10-03', SleepCheckIn.onTime),
        log('2026-10-04', SleepCheckIn.delayed, delay: 30),
        log('2026-10-05', SleepCheckIn.stayedUp),
        log('2026-10-09', SleepCheckIn.onTime),
        log('2026-09-01', SleepCheckIn.delayed, delay: 120),
      ],
      today: DateTime(2026, 10, 9),
    );

    expect(report.loggedDays, 4);
    expect(report.onTimeDays, 2);
    expect(report.onTimeRate, 0.5);
    expect(report.stayedUpDays, 1);
    expect(report.averageDelayMinutes, 10);
  });

  test('missing tonight does not break an on-time streak', () {
    final report = buildWeeklyReport(
      logs: [
        log('2026-10-07', SleepCheckIn.onTime),
        log('2026-10-08', SleepCheckIn.onTime),
      ],
      today: DateTime(2026, 10, 9),
    );
    expect(report.streak, 2);
  });

  test('a late night or a gap ends the streak', () {
    final late = buildWeeklyReport(
      logs: [
        log('2026-10-08', SleepCheckIn.onTime),
        log('2026-10-09', SleepCheckIn.delayed, delay: 20),
      ],
      today: DateTime(2026, 10, 9),
    );
    expect(late.streak, 0);

    final gap = buildWeeklyReport(
      logs: [
        log('2026-10-06', SleepCheckIn.onTime),
        log('2026-10-08', SleepCheckIn.onTime),
      ],
      today: DateTime(2026, 10, 8),
    );
    expect(gap.streak, 1);
  });

  test('sleep night rolls over at 04:00', () {
    expect(dateKey(sleepDate(DateTime(2026, 10, 9, 3, 30))), '2026-10-08');
    expect(dateKey(sleepDate(DateTime(2026, 10, 9, 4))), '2026-10-09');
    expect(isWeekend(DateTime(2026, 10, 10)), isTrue);
    expect(isWeekend(DateTime(2026, 10, 9)), isFalse);
  });
}
