import 'package:tmy_sleep/core/notifications/bedtime_scheduler.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';

class FakeScheduler implements BedtimeScheduler {
  FakeScheduler({
    this.access = const ReminderAccess(
      notificationsGranted: true,
      exactAlarmsGranted: true,
    ),
  });

  ReminderAccess access;
  final List<AppSettings> scheduled = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderAccess> readAccess() async => access;

  @override
  Future<ReminderAccess> requestAccess({bool exactAlarms = false}) async {
    return access;
  }

  @override
  Future<ScheduleResult> reschedule(AppSettings settings) async {
    scheduled.add(settings);
    if (!settings.remindersEnabled) {
      return const ScheduleResult.disabled();
    }
    return ScheduleResult(usedExact: access.exactAlarmsGranted);
  }
}
