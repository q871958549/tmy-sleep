import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'apk_cache.dart';
import 'app_release.dart';

enum InstallOutcome {
  openedInstaller,
  openedBrowser,
  needPermission,
  failed,
  cancelled,
}

abstract interface class UpdateInstaller {
  Future<InstallOutcome> install(
    AppRelease release, {
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
  });

  Future<void> openInstallPermissionSettings();
}

class PlatformUpdateInstaller implements UpdateInstaller {
  PlatformUpdateInstaller({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const channelName = 'com.tmysleep/updates';
  static const _channel = MethodChannel(channelName);

  final http.Client _http;

  @override
  Future<InstallOutcome> install(
    AppRelease release, {
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
  }) async {
    final apkUrl = release.apkUrl;
    if (kIsWeb ||
        apkUrl == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return _openPage(release);
    }
    try {
      final path = await downloadReleaseApk(
        release,
        httpClient: _http,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      if (isCancelled()) {
        return InstallOutcome.cancelled;
      }
      final allowed = await _channel.invokeMethod<bool>('canInstallPackages');
      if (allowed == false) {
        return InstallOutcome.needPermission;
      }
      await _channel.invokeMethod<void>('installApk', {'path': path});
      return InstallOutcome.openedInstaller;
    } on UpdateCancelled {
      return InstallOutcome.cancelled;
    } catch (error, stackTrace) {
      debugPrint('install failed: $error\n$stackTrace');
      return InstallOutcome.failed;
    }
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await _channel.invokeMethod<void>('openInstallSettings');
  }

  Future<InstallOutcome> _openPage(AppRelease release) async {
    final target = release.apkUrl ?? release.pageUrl;
    final opened = await launchUrl(
      Uri.parse(target),
      mode: LaunchMode.externalApplication,
    );
    return opened ? InstallOutcome.openedBrowser : InstallOutcome.failed;
  }
}
