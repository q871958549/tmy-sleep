import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmy_sleep/app/tmy_sleep_app.dart';
import 'package:tmy_sleep/core/storage/log_store.dart';
import 'package:tmy_sleep/core/storage/settings_store.dart';
import 'package:tmy_sleep/features/checkin/checkin_controller.dart';
import 'package:tmy_sleep/features/checkin/models/sleep_check_in.dart';
import 'package:tmy_sleep/features/schedule/models/app_settings.dart';
import 'package:tmy_sleep/features/schedule/settings_controller.dart';
import 'package:tmy_sleep/features/sleep/sleep_controller.dart';
import 'package:tmy_sleep/features/sleep/sleep_store.dart';
import 'package:tmy_sleep/features/update/update_client.dart';
import 'package:tmy_sleep/features/update/update_coordinator.dart';

import 'support/fake_scheduler.dart';
import 'support/fake_sleep.dart';
import 'support/fake_updates.dart';

Future<void> _openUpdateCheck(WidgetTester tester) async {
  final row = find.text('检查更新');
  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(row, 400, scrollable: scrollable);
  await tester.drag(scrollable, const Offset(0, -160));
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CheckInController> pumpHome(
    WidgetTester tester, {
    UpdateClient? client,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(
      store: SettingsStore(prefs),
      scheduler: FakeScheduler(),
    );
    final checkIns = CheckInController(
      store: LogStore(prefs),
      clock: () => DateTime(2026, 10, 9, 21),
    );
    final updates = UpdateCoordinator(
      client: client ?? FakeUpdateClient(),
      installer: FakeUpdateInstaller(),
      prefs: prefs,
      currentVersion: '1.0.0',
      clock: () => DateTime(2026, 10, 9, 21),
    );
    final sleep = SleepSessionController(
      store: SleepStore(prefs),
      monitor: FakeSleepMonitor(),
      clock: () => DateTime(2026, 10, 9, 21, 30),
    );
    sleep.load();
    await settings.load();
    await checkIns.load();
    await tester.pumpWidget(
      TmySleepApp(
        settings: settings,
        checkIns: checkIns,
        updates: updates,
        sleep: sleep,
      ),
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
    final bedtime = tester.widget<Text>(find.text('23:00'));
    expect(bedtime.style?.decoration, TextDecoration.none);
    expect(bedtime.style?.inherit, isFalse);

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

  testWidgets('a newer release prompts once and stays on the home screen', (
    tester,
  ) async {
    final client = FakeUpdateClient(sampleRelease(notes: '修了提醒时间'));

    await pumpHome(tester, client: client);

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('修了提醒时间'), findsOneWidget);
    expect(client.calls, 1);

    await tester.tap(find.text('以后再说'));
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsNothing);
    expect(find.text('可更新到 1.1.0'), findsOneWidget);

    await pumpHome(tester, client: client);

    expect(find.text('发现新版本'), findsNothing);
    expect(find.text('可更新到 1.1.0'), findsOneWidget);
    expect(client.calls, 1);
  });

  testWidgets('manual check reports the current version or a failure', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('作息设置'));
    await tester.pumpAndSettle();
    await _openUpdateCheck(tester);

    expect(find.text('已是最新版本'), findsOneWidget);
    await tester.tap(find.text('好'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await pumpHome(
      tester,
      client: FakeUpdateClient()..error = const UpdateCheckException(500),
    );
    await tester.tap(find.byTooltip('作息设置'));
    await tester.pumpAndSettle();
    await _openUpdateCheck(tester);

    expect(find.text('暂时无法检查'), findsOneWidget);
  });

  testWidgets('sleep now records snore, talk, and motion for tonight', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('立即入睡'), findsOneWidget);
    expect(find.text('今晚的记录'), findsNothing);

    await tester.tap(find.byKey(const Key('sleep-now')));
    await tester.pumpAndSettle();

    expect(find.text('我醒了'), findsOneWidget);
    expect(find.text('21:30'), findsOneWidget);
    expect(find.text('亮度'), findsOneWidget);
    expect(find.textContaining('21:30  鼾声'), findsOneWidget);
    expect(find.textContaining('21:30  梦话'), findsOneWidget);
    expect(find.textContaining('21:30  异动'), findsOneWidget);
    expect(find.textContaining('峰值低 14 dB'), findsOneWidget);

    await tester.tap(find.text('我醒了'));
    await tester.pumpAndSettle();

    expect(find.text('今晚的记录'), findsOneWidget);
    expect(find.textContaining('峰值低 14 dB'), findsOneWidget);
    expect(find.text('立即入睡'), findsOneWidget);
  });

  testWidgets('light theme is saved from settings', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('作息设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('浅色'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(SettingsStore(prefs).load().themeMode, AppThemeMode.light);
  });
}
