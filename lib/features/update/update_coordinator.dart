import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/sleep_clock.dart';
import 'app_release.dart';
import 'update_client.dart';
import 'update_installer.dart';
import 'version_name.dart';

enum ManualCheckKind { upToDate, update, failed }

class ManualCheck {
  const ManualCheck._(this.kind, this.release);

  const ManualCheck.upToDate() : this._(ManualCheckKind.upToDate, null);

  const ManualCheck.update(AppRelease release)
    : this._(ManualCheckKind.update, release);

  const ManualCheck.failed() : this._(ManualCheckKind.failed, null);

  final ManualCheckKind kind;
  final AppRelease? release;
}

/// Checks GitHub Releases. The automatic check runs once per sleep day,
/// and a sleep day starts at 04:00.
class UpdateCoordinator extends ChangeNotifier {
  UpdateCoordinator({
    required UpdateClient client,
    required UpdateInstaller installer,
    required SharedPreferences prefs,
    required this.currentVersion,
    DateTime Function()? clock,
  }) {
    _client = client;
    _installer = installer;
    _prefs = prefs;
    _clock = clock ?? DateTime.now;
    _restore();
  }

  static const checkedDayKey = 'update_auto_check_day';
  static const availableKey = 'update_available';

  late final UpdateClient _client;
  late final UpdateInstaller _installer;
  late final SharedPreferences _prefs;
  late final DateTime Function() _clock;

  final String currentVersion;

  UpdateInstaller get installer => _installer;

  AppRelease? available;
  bool checking = false;
  Future<ManualCheck>? _inFlight;

  /// Returns a release when this is the day's first successful check and a
  /// newer stable version exists. Network failures stay quiet and retry next
  /// time the app opens.
  Future<AppRelease?> autoCheck() async {
    final day = dateKey(sleepDate(_clock()));
    if (_prefs.getString(checkedDayKey) == day) {
      return null;
    }
    try {
      final latest = await _client.fetchLatest();
      await _prefs.setString(checkedDayKey, day);
      return await _remember(latest);
    } catch (error, stackTrace) {
      debugPrint('auto update check failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<ManualCheck> manualCheck() {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final run = _runManual();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) {
        _inFlight = null;
      }
    });
  }

  Future<ManualCheck> _runManual() async {
    checking = true;
    notifyListeners();
    try {
      final latest = await _client.fetchLatest();
      final newer = await _remember(latest);
      if (newer != null) {
        return ManualCheck.update(newer);
      }
      return const ManualCheck.upToDate();
    } catch (error, stackTrace) {
      debugPrint('manual update check failed: $error\n$stackTrace');
      return const ManualCheck.failed();
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  void _restore() {
    final raw = _prefs.getString(availableKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final release = AppRelease.tryParseStored(jsonDecode(raw));
      if (release != null && isNewerVersion(release.version, currentVersion)) {
        available = release;
        return;
      }
    } catch (error, stackTrace) {
      debugPrint('stored update ignored: $error\n$stackTrace');
    }
    _prefs.remove(availableKey);
  }

  Future<AppRelease?> _remember(AppRelease? latest) async {
    if (latest != null && isNewerVersion(latest.version, currentVersion)) {
      available = latest;
      await _prefs.setString(availableKey, jsonEncode(latest.toJson()));
      notifyListeners();
      return latest;
    }
    available = null;
    await _prefs.remove(availableKey);
    notifyListeners();
    return null;
  }
}
