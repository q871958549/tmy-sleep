import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/schedule/models/app_settings.dart';

class SettingsStore {
  SettingsStore(this._prefs);

  static const storageKey = 'app_settings';

  final SharedPreferences _prefs;

  AppSettings load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.defaults;
    }
    try {
      return AppSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return AppSettings.defaults;
    }
  }

  Future<void> save(AppSettings settings) {
    return _prefs.setString(storageKey, jsonEncode(settings.toJson()));
  }
}
