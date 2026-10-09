/// Summary of the last 7 sleep nights, plus an ongoing on-time streak.
class WeeklyReport {
  const WeeklyReport({
    required this.loggedDays,
    required this.onTimeDays,
    required this.onTimeRate,
    required this.averageDelayMinutes,
    required this.streak,
    required this.stayedUpDays,
  });

  final int loggedDays;
  final int onTimeDays;

  /// Null when [loggedDays] is 0.
  final double? onTimeRate;

  /// Mean delay of on-time (0) and delayed nights. Stayed-up nights are left
  /// out because they have no delay. Null when none of those nights exist.
  final double? averageDelayMinutes;

  /// Consecutive on-time nights ending at the latest relevant night.
  /// Today's missing check-in does not break the streak.
  final int streak;

  final int stayedUpDays;

  static const empty = WeeklyReport(
    loggedDays: 0,
    onTimeDays: 0,
    onTimeRate: null,
    averageDelayMinutes: null,
    streak: 0,
    stayedUpDays: 0,
  );
}
