import '../../shared/sleep_clock.dart';
import '../checkin/models/daily_log.dart';
import '../checkin/models/sleep_check_in.dart';
import 'weekly_report.dart';

const int reportWindowDays = 7;

WeeklyReport buildWeeklyReport({
  required List<DailyLog> logs,
  required DateTime today,
}) {
  final night = DateTime(today.year, today.month, today.day);
  final start = night.subtract(const Duration(days: reportWindowDays - 1));
  final byDate = <String, DailyLog>{};
  for (final log in logs) {
    final parsed = tryParseDateKey(log.date);
    if (parsed == null) {
      continue;
    }
    byDate[dateKey(parsed)] = log;
  }

  final window = <DailyLog>[];
  for (var offset = 0; offset < reportWindowDays; offset++) {
    final day = start.add(Duration(days: offset));
    final log = byDate[dateKey(day)];
    if (log != null) {
      window.add(log);
    }
  }

  final onTimeDays = window
      .where((log) => log.checkIn == SleepCheckIn.onTime)
      .length;
  final stayedUpDays = window
      .where((log) => log.checkIn == SleepCheckIn.stayedUp)
      .length;
  final delaySamples = window
      .where((log) => log.checkIn != SleepCheckIn.stayedUp)
      .map((log) => log.delayMinutes ?? 0)
      .toList();

  return WeeklyReport(
    loggedDays: window.length,
    onTimeDays: onTimeDays,
    onTimeRate: window.isEmpty ? null : onTimeDays / window.length,
    averageDelayMinutes: delaySamples.isEmpty
        ? null
        : delaySamples.reduce((a, b) => a + b) / delaySamples.length,
    streak: _streak(byDate, night),
    stayedUpDays: stayedUpDays,
  );
}

int _streak(Map<String, DailyLog> byDate, DateTime today) {
  var cursor = today;
  final todayLog = byDate[dateKey(cursor)];
  if (todayLog == null) {
    cursor = cursor.subtract(const Duration(days: 1));
  } else if (todayLog.checkIn != SleepCheckIn.onTime) {
    return 0;
  }

  var streak = 0;
  while (streak < 3660) {
    final log = byDate[dateKey(cursor)];
    if (log == null || log.checkIn != SleepCheckIn.onTime) {
      break;
    }
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
