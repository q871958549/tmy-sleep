/// Numeric `major.minor.patch` names from pubspec or a GitHub tag.
class VersionName implements Comparable<VersionName> {
  const VersionName(this.parts);

  final List<int> parts;

  /// Accepts `1.2.3`, `v1.2.3`, and an optional `+build`.
  /// Pre-release tags such as `v1.2.3-beta` are ignored.
  static VersionName? tryParse(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    if (text.contains('-')) {
      return null;
    }
    final plus = text.indexOf('+');
    if (plus >= 0) {
      text = text.substring(0, plus);
    }
    final pieces = text.split('.');
    if (pieces.isEmpty || pieces.length > 4) {
      return null;
    }
    final numbers = <int>[];
    for (final piece in pieces) {
      final value = int.tryParse(piece);
      if (value == null || value < 0) {
        return null;
      }
      numbers.add(value);
    }
    return VersionName(numbers);
  }

  @override
  int compareTo(VersionName other) {
    final length = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var index = 0; index < length; index++) {
      final left = index < parts.length ? parts[index] : 0;
      final right = index < other.parts.length ? other.parts[index] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }
}

/// True when [remote] is a newer stable version than [current].
bool isNewerVersion(String remote, String current) {
  final next = VersionName.tryParse(remote);
  final installed = VersionName.tryParse(current);
  if (next == null || installed == null) {
    return false;
  }
  return next.compareTo(installed) > 0;
}
