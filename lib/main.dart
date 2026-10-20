import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/tmy_sleep_app.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/log_store.dart';
import 'core/storage/settings_store.dart';
import 'features/checkin/checkin_controller.dart';
import 'features/schedule/settings_controller.dart';
import 'features/sleep/sleep_controller.dart';
import 'features/sleep/sleep_monitor.dart';
import 'features/sleep/sleep_store.dart';
import 'features/update/update_client.dart';
import 'features/update/update_coordinator.dart';
import 'features/update/update_installer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  try {
    await notifications.initialize();
  } catch (error, stackTrace) {
    debugPrint('notification init failed: $error\n$stackTrace');
  }
  final settings = SettingsController(
    store: SettingsStore(prefs),
    scheduler: notifications,
  );
  final checkIns = CheckInController(store: LogStore(prefs));
  await Future.wait([settings.load(), checkIns.load()]);
  final updates = UpdateCoordinator(
    client: GithubUpdateClient(),
    installer: PlatformUpdateInstaller(),
    prefs: prefs,
    currentVersion: await _currentVersion(),
  );
  final sleep = SleepSessionController(
    store: SleepStore(prefs),
    monitor: PlatformSleepMonitor(),
  );
  sleep.load();
  runApp(
    TmySleepApp(
      settings: settings,
      checkIns: checkIns,
      updates: updates,
      sleep: sleep,
    ),
  );
}

Future<String> _currentVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) {
      return info.version;
    }
  } catch (error, stackTrace) {
    debugPrint('package info failed: $error\n$stackTrace');
  }
  return '0.0.0';
}
