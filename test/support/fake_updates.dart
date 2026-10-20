import 'package:tmy_sleep/features/update/app_release.dart';
import 'package:tmy_sleep/features/update/update_client.dart';
import 'package:tmy_sleep/features/update/update_installer.dart';

class FakeUpdateClient implements UpdateClient {
  FakeUpdateClient([this.next]);

  AppRelease? next;
  Object? error;
  int calls = 0;

  @override
  Future<AppRelease?> fetchLatest() async {
    calls += 1;
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return next;
  }
}

class ScriptedUpdateClient implements UpdateClient {
  ScriptedUpdateClient(this.steps);

  final List<Object?> steps;
  var index = 0;

  @override
  Future<AppRelease?> fetchLatest() async {
    final step = steps[index];
    index += 1;
    if (step is Exception) {
      throw step;
    }
    return step as AppRelease?;
  }
}

class FakeUpdateInstaller implements UpdateInstaller {
  InstallOutcome outcome = InstallOutcome.openedBrowser;
  int installs = 0;

  @override
  Future<InstallOutcome> install(
    AppRelease release, {
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
  }) async {
    installs += 1;
    onProgress(1);
    return outcome;
  }

  @override
  Future<void> openInstallPermissionSettings() async {}
}

AppRelease sampleRelease({
  String version = '1.1.0',
  String? apkUrl = 'https://example.com/tmy-sleep.apk',
  String notes = '',
}) {
  return AppRelease(
    version: version,
    tag: 'v$version',
    notes: notes,
    pageUrl: 'https://github.com/q871958549/tmy-sleep/releases/tag/v$version',
    apkUrl: apkUrl,
    apkBytes: apkUrl == null ? null : 128,
  );
}
