import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/radio_models.dart';

class RadioApiService {
  RadioApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<NowPlayingInfo> fetchNowPlaying() async {
    final json = await _getJson('api/nowplaying/${AppConfig.stationShortcode}');
    return NowPlayingInfo.fromJson(json);
  }

  Future<List<ScheduleItem>> fetchSchedule({
    DateTime? start,
    DateTime? end,
  }) async {
    final query = <String, String>{};
    final formatter = DateFormat('yyyy-MM-dd');
    if (start != null) {
      query['start'] = formatter.format(start);
    }
    if (end != null) {
      query['end'] = formatter.format(end);
    }

    final json = await _getJsonList(
      'api/station/${AppConfig.stationShortcode}/schedule',
      queryParameters: query,
    );

    return json
        .map(ScheduleItem.fromJson)
        .where((item) => item.rawTitlePrefix.startsWith('PROG'))
        .toList();
  }

  Future<List<PodcastItem>> fetchPodcasts() async {
    final json = await _getJsonList(
      'api/station/${AppConfig.stationShortcode}/public/podcasts',
    );
    return json.map(PodcastItem.fromJson).toList();
  }

  Future<List<PodcastEpisode>> fetchPodcastEpisodes(String podcastId) async {
    final json = await _getJsonList(
      'api/station/${AppConfig.stationShortcode}/public/podcast/$podcastId/episodes',
    );
    return json.map(PodcastEpisode.fromJson).toList();
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(AppConfig.baseUrl)
        .resolve(path)
        .replace(
          queryParameters: queryParameters == null || queryParameters.isEmpty
              ? null
              : queryParameters,
        );
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException('HTTP ${response.statusCode} for $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const RadioApiException('Unexpected JSON shape.');
  }

  Future<List<Map<String, dynamic>>> _getJsonList(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(AppConfig.baseUrl)
        .resolve(path)
        .replace(
          queryParameters: queryParameters == null || queryParameters.isEmpty
              ? null
              : queryParameters,
        );
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException('HTTP ${response.statusCode} for $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const RadioApiException('Unexpected JSON shape.');
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }
}

class RadioApiException implements Exception {
  const RadioApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
