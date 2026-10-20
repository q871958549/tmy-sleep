import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmy_sleep/features/update/app_release.dart';
import 'package:tmy_sleep/features/update/update_client.dart';
import 'package:tmy_sleep/features/update/update_coordinator.dart';
import 'package:tmy_sleep/features/update/version_name.dart';
import 'package:tmy_sleep/shared/sleep_clock.dart';

import 'support/fake_updates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('versions', () {
    test('compares numeric names and ignores a build suffix', () {
      expect(isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(isNewerVersion('1.2.0', '1.10.0'), isFalse);
      expect(isNewerVersion('v1.0.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0+9', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0-beta', '0.9.0'), isFalse);
      expect(isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(VersionName.tryParse('v1.2.3-rc.1'), isNull);
    });
  });

  group('github release', () {
    test('reads the first apk and skips pre-releases', () {
      final release = AppRelease.tryParseGithub({
        'tag_name': 'v1.2.0',
        'html_url':
            'https://github.com/q871958549/tmy-sleep/releases/tag/v1.2.0',
        'body': ' 说明 ',
        'assets': [
          {
            'name': 'notes.txt',
            'browser_download_url': 'https://example.com/notes.txt',
            'size': 4,
          },
          {
            'name': 'tmy-sleep-v1.2.0.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 42,
          },
        ],
      });

      expect(release?.version, '1.2.0');
      expect(release?.notes, '说明');
      expect(release?.apkUrl, 'https://example.com/app.apk');
      expect(release?.apkBytes, 42);
      expect(
        AppRelease.tryParseGithub({
          'tag_name': 'v1.2.0-beta',
          'html_url': 'https://example.com',
        }),
        isNull,
      );
    });

    test('round-trips the release stored on device', () {
      final release = sampleRelease(notes: '修了提醒');
      final stored = AppRelease.tryParseStored(
        jsonDecode(jsonEncode(release.toJson())),
      );
      expect(stored?.version, release.version);
      expect(stored?.apkUrl, release.apkUrl);
      expect(stored?.notes, '修了提醒');
    });

    test('maps GitHub status codes', () async {
      final missing = GithubUpdateClient(
        httpClient: _StubClient((request) async {
          expect(
            request.url.path,
            '/repos/q871958549/tmy-sleep/releases/latest',
          );
          expect(request.headers['User-Agent'], 'tmy-sleep');
          return http.Response('{}', 404);
        }),
      );
      expect(await missing.fetchLatest(), isNull);

      final broken = GithubUpdateClient(
        httpClient: _StubClient((_) async => http.Response('no', 500)),
      );
      expect(broken.fetchLatest(), throwsA(isA<UpdateCheckException>()));

      final found = GithubUpdateClient(
        httpClient: _StubClient(
          (_) async => http.Response(
            jsonEncode({
              'tag_name': 'v2.0.0',
              'html_url':
                  'https://github.com/q871958549/tmy-sleep/releases/tag/v2.0.0',
              'body': '',
              'assets': const <Object>[],
            }),
            200,
          ),
        ),
      );
      expect((await found.fetchLatest())?.version, '2.0.0');
      expect((await found.fetchLatest())?.apkUrl, isNull);
    });
  });

  group('daily check', () {
    test('prompts once per sleep day and again after 04:00', () async {
      final prefs = await SharedPreferences.getInstance();
      final client = FakeUpdateClient(sampleRelease());
      var now = DateTime(2026, 10, 10, 3, 30);
      final updates = UpdateCoordinator(
        client: client,
        installer: FakeUpdateInstaller(),
        prefs: prefs,
        currentVersion: '1.0.0',
        clock: () => now,
      );

      expect((await updates.autoCheck())?.version, '1.1.0');
      expect(await updates.autoCheck(), isNull);
      expect(client.calls, 1);
      expect(
        prefs.getString(UpdateCoordinator.checkedDayKey),
        dateKey(sleepDate(DateTime(2026, 10, 10, 3, 30))),
      );

      now = DateTime(2026, 10, 10, 4);
      expect((await updates.autoCheck())?.version, '1.1.0');
      expect(client.calls, 2);
    });

    test('a failed check does not consume the day', () async {
      final prefs = await SharedPreferences.getInstance();
      final client = FakeUpdateClient(sampleRelease())
        ..error = const UpdateCheckException(503);
      final updates = UpdateCoordinator(
        client: client,
        installer: FakeUpdateInstaller(),
        prefs: prefs,
        currentVersion: '1.0.0',
        clock: () => DateTime(2026, 10, 9, 21),
      );

      expect(await updates.autoCheck(), isNull);
      expect(prefs.getString(UpdateCoordinator.checkedDayKey), isNull);

      client.error = null;
      expect((await updates.autoCheck())?.version, '1.1.0');
    });

    test('an older or equal release is not an update', () async {
      final prefs = await SharedPreferences.getInstance();
      final client = FakeUpdateClient(sampleRelease(version: '0.9.0'));
      final updates = UpdateCoordinator(
        client: client,
        installer: FakeUpdateInstaller(),
        prefs: prefs,
        currentVersion: '1.0.0',
        clock: () => DateTime(2026, 10, 9, 21),
      );

      expect(await updates.autoCheck(), isNull);
      expect(updates.available, isNull);
      expect(prefs.getString(UpdateCoordinator.availableKey), isNull);

      client.next = sampleRelease(version: '1.0.0');
      final manual = await updates.manualCheck();
      expect(manual.kind, ManualCheckKind.upToDate);
    });

    test(
      'remembers an update for the home banner without prompting again',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime(2026, 10, 9, 21);
        await prefs.setString(
          UpdateCoordinator.checkedDayKey,
          dateKey(sleepDate(now)),
        );
        await prefs.setString(
          UpdateCoordinator.availableKey,
          jsonEncode(sampleRelease().toJson()),
        );
        final client = FakeUpdateClient(sampleRelease(version: '9.0.0'));
        final updates = UpdateCoordinator(
          client: client,
          installer: FakeUpdateInstaller(),
          prefs: prefs,
          currentVersion: '1.0.0',
          clock: () => now,
        );

        expect(updates.available?.version, '1.1.0');
        expect(await updates.autoCheck(), isNull);
        expect(client.calls, 0);
      },
    );

    test('manual check reports failure and keeps a known update', () async {
      final prefs = await SharedPreferences.getInstance();
      final client = FakeUpdateClient(sampleRelease())
        ..error = const UpdateCheckException(500);
      final updates = UpdateCoordinator(
        client: client,
        installer: FakeUpdateInstaller(),
        prefs: prefs,
        currentVersion: '1.0.0',
        clock: () => DateTime(2026, 10, 9, 21),
      );
      updates.available = sampleRelease();

      final result = await updates.manualCheck();
      expect(result.kind, ManualCheckKind.failed);
      expect(updates.available?.version, '1.1.0');
      expect(updates.checking, isFalse);
    });
  });
}

class _StubClient extends http.BaseClient {
  _StubClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  @override
  void close() {}
}
