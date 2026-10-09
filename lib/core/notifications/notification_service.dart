import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/schedule/models/app_settings.dart';
import 'bedtime_scheduler.dart';

const int bedtimeNotificationIdBase = 4100;
const int bedtimeNotificationCount = 7;
const int snoozeNotificationId = 4200;
const String snoozeActionId = 'snooze';
const String bedtimeCategoryId = 'bedtime';
const String _channelId = 'bedtime_reminder';

/// Foreground taps land here. Snooze uses a background action, so this mainly
/// covers a body tap while the app is open.
void onNotificationResponse(NotificationResponse response) {
  if (response.actionId != snoozeActionId) {
    return;
  }
  unawaited(_scheduleSnooze(response.payload));
}

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  if (response.actionId != snoozeActionId) {
    return;
  }
  unawaited(_scheduleSnooze(response.payload));
}

Future<void> _scheduleSnooze(String? payload) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final service = NotificationService();
    await service.initialize();
    await service.scheduleSnooze(parseSnoozeMinutes(payload));
  } catch (error, stackTrace) {
    debugPrint('snooze failed: $error\n$stackTrace');
  }
}

int parseSnoozeMinutes(String? payload) {
  final raw = payload?.split(':').last;
  final value = int.tryParse(raw ?? '');
  if (value == null || value <= 0 || value > 180) {
    return 15;
  }
  return value;
}

String bedtimePayload(int snoozeMinutes) => 'bedtime:$snoozeMinutes';

class NotificationService implements BedtimeScheduler {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _callbacksRegistered = false;
  bool _timeZoneReady = false;

  AndroidFlutterLocalNotificationsPlugin? get _android {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  @override
  Future<void> initialize() async {
    await _configureTimeZone();
    if (_callbacksRegistered) {
      return;
    }
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          bedtimeCategoryId,
          actions: [DarwinNotificationAction.plain(snoozeActionId, '稍后提醒')],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@drawable/ic_stat_moon'),
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    _callbacksRegistered = true;
  }

  Future<void> scheduleSnooze(int minutes) async {
    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _zonedSchedule(
      id: snoozeNotificationId,
      title: '该睡觉了',
      body: '稍后提醒：再过 $minutes 分钟就休息吧。',
      when: when,
      snoozeMinutes: minutes,
      preferExact: true,
    );
  }

  @override
  Future<ScheduleResult> reschedule(AppSettings settings) async {
    try {
      await _cancelBedtimeAlarms();
      if (!settings.remindersEnabled) {
        await _plugin.cancel(id: snoozeNotificationId);
        return const ScheduleResult.disabled();
      }
      final access = await readAccess();
      final scheduled = await _scheduleUpcoming(settings, access);
      if (scheduled == 0) {
        return const ScheduleResult(usedExact: false, note: '没有排上未来的睡前提醒。');
      }
      if (access.exactAlarmsGranted) {
        return const ScheduleResult(usedExact: true);
      }
      return const ScheduleResult(
        usedExact: false,
        note: '未授予精确闹钟权限，提醒可能被系统推迟。请在系统设置里允许「闹钟和提醒」。',
      );
    } catch (error, stackTrace) {
      debugPrint('reschedule failed: $error\n$stackTrace');
      return ScheduleResult(usedExact: false, note: '睡前提醒暂时没有排上：$error');
    }
  }

  @override
  Future<ReminderAccess> readAccess() async {
    if (kIsWeb) {
      return ReminderAccess.unknown;
    }
    try {
      final notifications = await Permission.notification.status;
      final exact = await Permission.scheduleExactAlarm.status;
      final canExact = await _android?.canScheduleExactNotifications();
      return ReminderAccess(
        notificationsGranted:
            notifications.isGranted || notifications.isLimited,
        exactAlarmsGranted: canExact ?? exact.isGranted,
      );
    } catch (error, stackTrace) {
      debugPrint('readAccess failed: $error\n$stackTrace');
      return ReminderAccess.unknown;
    }
  }

  @override
  Future<ReminderAccess> requestAccess({bool exactAlarms = false}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _android?.requestNotificationsPermission();
        if (exactAlarms) {
          await _android?.requestExactAlarmsPermission();
        }
      } else {
        await Permission.notification.request();
      }
    } catch (error, stackTrace) {
      debugPrint('requestAccess failed: $error\n$stackTrace');
    }
    return readAccess();
  }

  Future<int> _scheduleUpcoming(
    AppSettings settings,
    ReminderAccess access,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;
    for (
      var dayOffset = 0;
      dayOffset < 10 && scheduled < bedtimeNotificationCount;
      dayOffset++
    ) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      final schedule = settings.scheduleFor(day);
      final when = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        schedule.bedtimeHour,
        schedule.bedtimeMinute,
      );
      if (!when.isAfter(now)) {
        continue;
      }
      final placed = await _zonedSchedule(
        id: bedtimeNotificationIdBase + scheduled,
        title: '该睡觉了',
        body: '目标入睡 ${schedule.bedtimeLabel}，打开 tmy-sleep 打卡。',
        when: when,
        snoozeMinutes: settings.snoozeMinutes,
        preferExact: access.exactAlarmsGranted,
      );
      if (placed) {
        scheduled += 1;
      }
    }
    return scheduled;
  }

  Future<bool> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required int snoozeMinutes,
    required bool preferExact,
  }) async {
    final details = _details(snoozeMinutes);
    final payload = bedtimePayload(snoozeMinutes);
    final modes = preferExact
        ? const [
            AndroidScheduleMode.exactAllowWhileIdle,
            AndroidScheduleMode.inexactAllowWhileIdle,
          ]
        : const [AndroidScheduleMode.inexactAllowWhileIdle];
    Object? lastError;
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: mode,
          payload: payload,
        );
        return true;
      } catch (error, stackTrace) {
        lastError = error;
        debugPrint('zonedSchedule ($mode) failed: $error\n$stackTrace');
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return false;
  }

  NotificationDetails _details(int snoozeMinutes) {
    final actionLabel = '$snoozeMinutes 分钟后提醒';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        '睡前提醒',
        channelDescription: '到了目标入睡时间时提醒你',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: [
          AndroidNotificationAction(
            snoozeActionId,
            actionLabel,
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: bedtimeCategoryId,
      ),
      macOS: const DarwinNotificationDetails(
        categoryIdentifier: bedtimeCategoryId,
      ),
    );
  }

  Future<void> _cancelBedtimeAlarms() async {
    for (var index = 0; index < bedtimeNotificationCount; index++) {
      await _plugin.cancel(id: bedtimeNotificationIdBase + index);
    }
  }

  Future<void> _configureTimeZone() async {
    if (_timeZoneReady) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error, stackTrace) {
      debugPrint('timezone lookup failed: $error\n$stackTrace');
      tz.setLocalLocation(_locationForOffset(DateTime.now().timeZoneOffset));
    }
    _timeZoneReady = true;
  }

  tz.Location _locationForOffset(Duration offset) {
    final hours = offset.inHours;
    if (offset.inMinutes != hours * 60) {
      return tz.UTC;
    }
    final sign = hours >= 0 ? '-' : '+';
    final name = 'Etc/GMT$sign${hours.abs()}';
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.UTC;
    }
  }
}
