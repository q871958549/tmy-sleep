/// A stable GitHub release the app can offer to install.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.tag,
    required this.notes,
    required this.pageUrl,
    this.apkUrl,
    this.apkBytes,
  });

  final String version;
  final String tag;
  final String notes;
  final String pageUrl;
  final String? apkUrl;
  final int? apkBytes;

  static AppRelease? tryParseGithub(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final tag = json['tag_name'];
    final page = json['html_url'];
    if (tag is! String || page is! String || page.isEmpty) {
      return null;
    }
    final version = _versionFromTag(tag);
    if (version == null) {
      return null;
    }
    final notes = json['body'];
    String? apkUrl;
    int? apkBytes;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) {
          continue;
        }
        final name = asset['name'];
        final url = asset['browser_download_url'];
        if (name is! String || url is! String) {
          continue;
        }
        if (!name.toLowerCase().endsWith('.apk')) {
          continue;
        }
        apkUrl = url;
        final size = asset['size'];
        if (size is int && size > 0) {
          apkBytes = size;
        }
        break;
      }
    }
    return AppRelease(
      version: version,
      tag: tag,
      notes: notes is String ? notes.trim() : '',
      pageUrl: page,
      apkUrl: apkUrl,
      apkBytes: apkBytes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'tag': tag,
      'notes': notes,
      'pageUrl': pageUrl,
      'apkUrl': apkUrl,
      'apkBytes': apkBytes,
    };
  }

  /// Release remembered on device so the home banner survives a restart.
  static AppRelease? tryParseStored(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final version = json['version'];
    final tag = json['tag'];
    final page = json['pageUrl'];
    if (version is! String ||
        tag is! String ||
        page is! String ||
        version.isEmpty ||
        page.isEmpty) {
      return null;
    }
    final notes = json['notes'];
    final apkUrl = json['apkUrl'];
    final apkBytes = json['apkBytes'];
    return AppRelease(
      version: version,
      tag: tag,
      notes: notes is String ? notes : '',
      pageUrl: page,
      apkUrl: apkUrl is String && apkUrl.isNotEmpty ? apkUrl : null,
      apkBytes: apkBytes is int && apkBytes > 0 ? apkBytes : null,
    );
  }

  static String? _versionFromTag(String tag) {
    var text = tag.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    if (text.isEmpty || text.contains('-')) {
      return null;
    }
    return text;
  }
}
