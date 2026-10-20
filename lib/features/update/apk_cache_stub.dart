import 'package:http/http.dart' as http;

import 'app_release.dart';

/// Web and other builds never download an APK. The installer opens the
/// release page instead.
Future<String> downloadReleaseApk(
  AppRelease release, {
  required http.Client httpClient,
  required void Function(double? progress) onProgress,
  required bool Function() isCancelled,
}) {
  throw UnsupportedError('APK downloads are only available on Android');
}

class UpdateCancelled implements Exception {
  const UpdateCancelled();
}
