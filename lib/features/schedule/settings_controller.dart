import 'package:flutter/foundation.dart';

import '../../core/notifications/bedtime_scheduler.dart';
import '../../core/storage/settings_store.dart';
import 'models/app_settings.dart';
import 'models/day_schedule.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsStore store,
    required BedtimeScheduler scheduler,
  }) {
    _store = store;
    _scheduler = scheduler;
  }

  late final SettingsStore _store;
  late final BedtimeScheduler _scheduler;

  AppSettings settings = AppSettings.defaults;
  ReminderAccess access = ReminderAccess.unknown;
  ScheduleResult scheduleResult = const ScheduleResult.disabled();
  bool ready = false;

  Future<void> load() async {
    settings = _store.load();
    ready = true;
    notifyListeners();
    access = settings.remindersEnabled
        ? await _scheduler.requestAccess()
        : await _scheduler.readAccess();
    notifyListeners();
    await _applySchedule();
  }

  Future<void> refreshAccess() async {
    access = await _scheduler.readAccess();
    notifyListeners();
    if (settings.remindersEnabled) {
      await _applySchedule();
    }
  }

  Future<void> setWeekday(DaySchedule schedule) {
    return update(settings.copyWith(weekday: schedule));
  }

  Future<void> setWeekend(DaySchedule schedule) {
    return update(settings.copyWith(weekend: schedule));
  }

  Future<void> setUseSeparateWeekend(bool value) {
    return update(settings.copyWith(useSeparateWeekend: value));
  }

  Future<void> setRemindersEnabled(bool value) async {
    if (value) {
      access = await _scheduler.requestAccess(exactAlarms: true);
    }
    await update(settings.copyWith(remindersEnabled: value));
  }

  Future<void> setSnoozeMinutes(int minutes) {
    return update(settings.copyWith(snoozeMinutes: minutes));
  }

  Future<void> requestReminderAccess() async {
    access = await _scheduler.requestAccess(exactAlarms: true);
    notifyListeners();
    await _applySchedule();
  }

  Future<void> update(AppSettings next) async {
    settings = next;
    notifyListeners();
    await _store.save(settings);
    await _applySchedule();
  }

  Future<void> _applySchedule() async {
    scheduleResult = await _scheduler.reschedule(settings);
    notifyListeners();
  }
}
