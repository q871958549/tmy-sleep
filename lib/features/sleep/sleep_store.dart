import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/sleep_session.dart';

class SleepStore {
  SleepStore(this._prefs);

  static const storageKey = 'sleep_sessions';

  final SharedPreferences _prefs;

  List<SleepSession> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return [for (final item in decoded) ?SleepSession.tryParse(item)];
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<SleepSession> sessions) {
    return _prefs.setString(
      storageKey,
      jsonEncode([for (final session in sessions) session.toJson()]),
    );
  }
}
