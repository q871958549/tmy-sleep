import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'apk_cache_stub.dart' show UpdateCancelled;
import 'app_release.dart';

export 'apk_cache_stub.dart' show UpdateCancelled;

/// Downloads [release] into the temp directory. A file whose length already
/// matches the GitHub asset size is reused, so a second tap after the
/// install-permission screen does not start over.
Future<String> downloadReleaseApk(
  AppRelease release, {
  required http.Client httpClient,
  required void Function(double? progress) onProgress,
  required bool Function() isCancelled,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/tmy-sleep-${release.version}.apk');
  final expected = release.apkBytes;
  if (expected != null &&
      await file.exists() &&
      await file.length() == expected) {
    onProgress(1);
    return file.path;
  }

  final request = http.Request('GET', Uri.parse(release.apkUrl!));
  request.headers['User-Agent'] = 'tmy-sleep';
  final response = await httpClient.send(request);
  if (response.statusCode != 200) {
    throw UpdateDownloadException(response.statusCode);
  }
  final total = response.contentLength ?? expected;
  final sink = file.openWrite();
  var received = 0;
  try {
    await for (final chunk in response.stream) {
      if (isCancelled()) {
        throw const UpdateCancelled();
      }
      sink.add(chunk);
      received += chunk.length;
      if (total != null && total > 0) {
        onProgress(received / total);
      } else {
        onProgress(null);
      }
    }
  } catch (error) {
    await sink.close();
    if (await file.exists()) {
      await file.delete();
    }
    rethrow;
  }
  await sink.flush();
  await sink.close();
  onProgress(1);
  return file.path;
}

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.statusCode);

  final int statusCode;
}
