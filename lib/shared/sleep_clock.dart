/// Local calendar helpers for "tonight".
///
/// A check-in after midnight still belongs to the evening that started the
/// previous calendar day. The night rolls over at [sleepDayRolloverHour].
const int sleepDayRolloverHour = 4;

DateTime sleepDate(DateTime now) {
  final local = now.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  if (local.hour < sleepDayRolloverHour) {
    return day.subtract(const Duration(days: 1));
  }
  return day;
}

String dateKey(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final dayText = day.day.toString().padLeft(2, '0');
  return '$year-$month-$dayText';
}

DateTime? tryParseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

bool isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
}

String formatHm(int hour, int minute) {
  final h = hour.toString().padLeft(2, '0');
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}
