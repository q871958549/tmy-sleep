/// How tonight compared with the target bedtime.
enum SleepCheckIn {
  onTime,
  delayed,
  stayedUp;

  static SleepCheckIn? tryParse(Object? raw) {
    if (raw is! String) {
      return null;
    }
    for (final value in SleepCheckIn.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  String get label => switch (this) {
    SleepCheckIn.onTime => '准时入睡',
    SleepCheckIn.delayed => '推迟了',
    SleepCheckIn.stayedUp => '熬夜了',
  };
}
