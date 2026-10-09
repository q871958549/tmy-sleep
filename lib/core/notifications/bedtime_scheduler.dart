import '../../features/schedule/models/app_settings.dart';

/// Whether the OS will show bedtime reminders, and how precise they can be.
class ReminderAccess {
  const ReminderAccess({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;

  static const unknown = ReminderAccess(
    notificationsGranted: false,
    exactAlarmsGranted: false,
  );
}

class ScheduleResult {
  const ScheduleResult({required this.usedExact, this.note});

  /// No reminders were scheduled because the user turned them off.
  const ScheduleResult.disabled() : usedExact = false, note = null;

  final bool usedExact;
  final String? note;
}

/// Schedules the local bedtime reminder. Tests use a fake.
abstract interface class BedtimeScheduler {
  Future<void> initialize();

  Future<ScheduleResult> reschedule(AppSettings settings);

  Future<ReminderAccess> readAccess();

  /// Asks for notification permission. When [exactAlarms] is true, also opens
  /// the system screen for exact alarms. That screen is easy to get stuck in,
  /// so startup does not pass true.
  Future<ReminderAccess> requestAccess({bool exactAlarms = false});
}
