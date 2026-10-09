import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmy_sleep/app/tmy_sleep_app.dart';
import 'package:tmy_sleep/core/storage/log_store.dart';
import 'package:tmy_sleep/core/storage/settings_store.dart';
import 'package:tmy_sleep/features/checkin/checkin_controller.dart';
import 'package:tmy_sleep/features/checkin/models/sleep_check_in.dart';
import 'package:tmy_sleep/features/schedule/settings_controller.dart';

import 'support/fake_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CheckInController> pumpHome(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(
      store: SettingsStore(prefs),
      scheduler: FakeScheduler(),
    );
    final checkIns = CheckInController(
      store: LogStore(prefs),
      clock: () => DateTime(2026, 10, 9, 21),
    );
    await settings.load();
    await checkIns.load();
    await tester.pumpWidget(
      TmySleepApp(settings: settings, checkIns: checkIns),
    );
    await tester.pumpAndSettle();
    return checkIns;
  }

  testWidgets('home shows tonight target and records an on-time check-in', (
    tester,
  ) async {
    final checkIns = await pumpHome(tester);

    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('起床 次日 07:00'), findsOneWidget);
    expect(find.text('工作日'), findsOneWidget);

    await tester.tap(find.text('准时入睡'));
    await tester.pumpAndSettle();

    expect(find.text('已记录：准时入睡'), findsOneWidget);
    expect(checkIns.tonight?.checkIn, SleepCheckIn.onTime);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1 天'), findsOneWidget);
  });

  testWidgets('delayed check-in asks for minutes', (tester) async {
    final checkIns = await pumpHome(tester);

    await tester.tap(find.text('推迟了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 分钟'));
    await tester.pumpAndSettle();

    expect(find.text('已记录：推迟了 30 分钟'), findsOneWidget);
    expect(checkIns.tonight?.delayMinutes, 30);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('weekend schedule toggle persists on the settings screen', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('作息设置'));
    await tester.pumpAndSettle();
    expect(find.text('周末入睡'), findsNothing);

    await tester.tap(find.byKey(const Key('weekend-switch')));
    await tester.pumpAndSettle();

    expect(find.text('周末入睡'), findsOneWidget);
    expect(find.text('23:30'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(SettingsStore(prefs).load().useSeparateWeekend, isTrue);
  });
}
