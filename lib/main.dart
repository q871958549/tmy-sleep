import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/tmy_sleep_app.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/log_store.dart';
import 'core/storage/settings_store.dart';
import 'features/checkin/checkin_controller.dart';
import 'features/schedule/settings_controller.dart';

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
  runApp(TmySleepApp(settings: settings, checkIns: checkIns));
}
