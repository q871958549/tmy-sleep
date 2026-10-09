import 'sleep_check_in.dart';

/// One night's check-in. [date] is the sleep-night key (`yyyy-MM-dd`).
///
/// [delayMinutes] is 0 for [SleepCheckIn.onTime], a positive number for
/// [SleepCheckIn.delayed], and null for [SleepCheckIn.stayedUp].
class DailyLog {
  const DailyLog({
    required this.date,
    required this.checkIn,
    required this.delayMinutes,
    required this.checkedInAt,
  });

  final String date;
  final SleepCheckIn checkIn;
  final int? delayMinutes;
  final DateTime checkedInAt;

  String get summary => switch (checkIn) {
    SleepCheckIn.onTime => '已记录：准时入睡',
    SleepCheckIn.delayed => '已记录：推迟了 $delayMinutes 分钟',
    SleepCheckIn.stayedUp => '已记录：熬夜了',
  };

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'checkIn': checkIn.name,
      'delayMinutes': delayMinutes,
      'checkedInAt': checkedInAt.toIso8601String(),
    };
  }

  static DailyLog? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final date = json['date'];
    final checkIn = SleepCheckIn.tryParse(json['checkIn']);
    final checkedInAt = DateTime.tryParse('${json['checkedInAt']}');
    if (date is! String || date.isEmpty || checkIn == null) {
      return null;
    }
    if (checkedInAt == null) {
      return null;
    }
    final delay = json['delayMinutes'];
    int? delayMinutes;
    if (delay is int) {
      delayMinutes = delay;
    }
    if (checkIn == SleepCheckIn.onTime) {
      delayMinutes = 0;
    } else if (checkIn == SleepCheckIn.delayed) {
      if (delayMinutes == null || delayMinutes <= 0) {
        return null;
      }
    } else {
      delayMinutes = null;
    }
    return DailyLog(
      date: date,
      checkIn: checkIn,
      delayMinutes: delayMinutes,
      checkedInAt: checkedInAt,
    );
  }
}
