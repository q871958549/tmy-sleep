import 'package:flutter/foundation.dart';

import '../../core/storage/log_store.dart';
import '../../shared/sleep_clock.dart';
import '../report/report_calculator.dart';
import '../report/weekly_report.dart';
import 'models/daily_log.dart';
import 'models/sleep_check_in.dart';

const List<int> delayMinuteChoices = [15, 30, 45, 60, 90, 120];

class CheckInController extends ChangeNotifier {
  CheckInController({required LogStore store, DateTime Function()? clock}) {
    _store = store;
    _clock = clock ?? DateTime.now;
  }

  late final LogStore _store;
  late final DateTime Function() _clock;

  List<DailyLog> logs = const [];
  bool ready = false;

  DateTime get sleepNight => sleepDate(_clock());

  DailyLog? get tonight {
    final key = dateKey(sleepNight);
    for (final log in logs) {
      if (log.date == key) {
        return log;
      }
    }
    return null;
  }

  WeeklyReport get report => buildWeeklyReport(logs: logs, today: sleepNight);

  Future<void> load() async {
    logs = _store.load();
    ready = true;
    notifyListeners();
  }

  Future<void> checkIn(SleepCheckIn kind, {int? delayMinutes}) async {
    final storedDelay = switch (kind) {
      SleepCheckIn.onTime => 0,
      SleepCheckIn.delayed => delayMinutes,
      SleepCheckIn.stayedUp => null,
    };
    if (kind == SleepCheckIn.delayed &&
        (storedDelay == null || storedDelay <= 0)) {
      throw ArgumentError.value(
        delayMinutes,
        'delayMinutes',
        'A delayed check-in needs a positive delay.',
      );
    }
    final log = DailyLog(
      date: dateKey(sleepNight),
      checkIn: kind,
      delayMinutes: storedDelay,
      checkedInAt: _clock(),
    );
    logs = [...logs.where((item) => item.date != log.date), log];
    notifyListeners();
    await _store.save(logs);
  }
}
