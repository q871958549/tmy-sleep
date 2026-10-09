import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/checkin/models/daily_log.dart';

class LogStore {
  LogStore(this._prefs);

  static const storageKey = 'daily_logs';

  final SharedPreferences _prefs;

  List<DailyLog> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final logs = <DailyLog>[];
      for (final item in decoded) {
        final log = DailyLog.tryParse(item);
        if (log != null) {
          logs.add(log);
        }
      }
      logs.sort((a, b) => a.date.compareTo(b.date));
      return logs;
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<DailyLog> logs) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final encoded = jsonEncode(sorted.map((log) => log.toJson()).toList());
    return _prefs.setString(storageKey, encoded);
  }
}
