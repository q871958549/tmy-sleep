import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmy_sleep/core/storage/log_store.dart';
import 'package:tmy_sleep/core/storage/settings_store.dart';
import 'package:tmy_sleep/features/checkin/checkin_controller.dart';
import 'package:tmy_sleep/features/checkin/models/sleep_check_in.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';
import 'package:tmy_sleep/features/schedule/settings_controller.dart';

import 'support/fake_scheduler.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('settings survive a fresh preferences read', () async {
    final first = await SharedPreferences.getInstance();
    await SettingsStore(first).save(
      AppSettings.defaults.copyWith(
        snoozeMinutes: 30,
        useSeparateWeekend: true,
        remindersEnabled: false,
      ),
    );
    final raw = first.getString(SettingsStore.storageKey);
    SharedPreferences.setMockInitialValues({SettingsStore.storageKey: raw!});
    final second = await SharedPreferences.getInstance();

    final loaded = SettingsStore(second).load();
    expect(loaded.snoozeMinutes, 30);
    expect(loaded.useSeparateWeekend, isTrue);
    expect(loaded.remindersEnabled, isFalse);
  });

  test('check-in overwrites the same night and reloads', () async {
    final prefs = await SharedPreferences.getInstance();
    final clock = DateTime(2026, 10, 9, 23, 40);
    final controller = CheckInController(
      store: LogStore(prefs),
      clock: () => clock,
    );
    await controller.load();
    await controller.checkIn(SleepCheckIn.onTime);
    await controller.checkIn(SleepCheckIn.delayed, delayMinutes: 45);

    final raw = prefs.getString(LogStore.storageKey);
    SharedPreferences.setMockInitialValues({LogStore.storageKey: raw!});
    final reloaded = CheckInController(
      store: LogStore(await SharedPreferences.getInstance()),
      clock: () => clock,
    );
    await reloaded.load();

    expect(reloaded.logs, hasLength(1));
    expect(reloaded.tonight?.checkIn, SleepCheckIn.delayed);
    expect(reloaded.tonight?.delayMinutes, 45);
    expect(reloaded.report.onTimeRate, 0);
    expect(reloaded.report.averageDelayMinutes, 45);
  });

  test('saving settings asks the scheduler to refresh reminders', () async {
    final prefs = await SharedPreferences.getInstance();
    final scheduler = FakeScheduler();
    final controller = SettingsController(
      store: SettingsStore(prefs),
      scheduler: scheduler,
    );
    await controller.load();
    await controller.setSnoozeMinutes(30);

    expect(scheduler.scheduled.last.snoozeMinutes, 30);
    expect(SettingsStore(prefs).load().snoozeMinutes, 30);
  });
}
