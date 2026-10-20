import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_release.dart';

const githubRepo = 'q871958549/tmy-sleep';

abstract interface class UpdateClient {
  Future<AppRelease?> fetchLatest();
}

class GithubUpdateClient implements UpdateClient {
  GithubUpdateClient({http.Client? httpClient, this.repo = githubRepo})
    : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String repo;

  @override
  Future<AppRelease?> fetchLatest() async {
    final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final response = await _http.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'tmy-sleep',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw UpdateCheckException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    return AppRelease.tryParseGithub(decoded);
  }
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'UpdateCheckException($statusCode)';
}
