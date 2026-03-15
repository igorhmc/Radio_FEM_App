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

  Future<List<PartnerItem>> fetchPartners() async {
    final uri = Uri.parse(AppConfig.partnersSourceUrl);
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException(
        'HTTP ${response.statusCode} for ${AppConfig.partnersSourceUrl}',
      );
    }

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final matches = RegExp(
      r'<article class="card carousel-card">([\s\S]*?)</article>',
      caseSensitive: false,
    ).allMatches(html);

    final partners = <PartnerItem>[];
    for (final match in matches) {
      final article = match.group(1) ?? '';
      final title = _decodeHtml(
        _firstMatch(
          article,
          RegExp(r'<h3>([\s\S]*?)</h3>', caseSensitive: false),
        ),
      );
      final rawSubtitle = _decodeHtml(
        _firstMatch(
          article,
          RegExp(
            r'<span class="carousel-tag">([\s\S]*?)</span>',
            caseSensitive: false,
          ),
        ),
      );
      final rawDescription = _decodeHtml(
        _firstMatch(
          article,
          RegExp(r'<p>([\s\S]*?)</p>', caseSensitive: false),
        ),
      );
      final subtitle = _translatePartnerSubtitle(title, rawSubtitle);
      final description = _translatePartnerDescription(title, rawDescription);
      final websiteUrl = _firstMatch(
        article,
        RegExp(r'<a class="partner-link" href="([^"]+)"', caseSensitive: false),
      );
      final imagePath = _firstMatch(
        article,
        RegExp(r'<img class="partner-logo" src="([^"]+)"', caseSensitive: false),
      );

      if (title.trim().isEmpty || websiteUrl.trim().isEmpty) {
        continue;
      }

      partners.add(
        PartnerItem(
          title: title.trim(),
          subtitle: subtitle.trim().isEmpty ? 'Supporting partner' : subtitle.trim(),
          description: description.trim().isEmpty
              ? 'Independent project connected to the Radio FEM community.'
              : description.trim(),
          websiteUrl: Uri.parse(AppConfig.partnersSourceUrl)
              .resolve(websiteUrl.trim())
              .toString(),
          imageUrl: imagePath.trim().isEmpty
              ? ''
              : uri.resolve(imagePath.trim()).toString(),
        ),
      );
    }

    return partners;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final decoded = await _getDecoded(path, queryParameters: queryParameters);
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
    final decoded = await _getDecoded(path, queryParameters: queryParameters);
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

  Future<dynamic> _getDecoded(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(AppConfig.baseUrl)
        .resolve(path)
        .replace(
          queryParameters: queryParameters == null || queryParameters.isEmpty
              ? null
              : queryParameters,
        );
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RadioApiException('HTTP ${response.statusCode} for $path');
    }

    return jsonDecode(response.body);
  }
}

class RadioApiException implements Exception {
  const RadioApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _firstMatch(String input, RegExp pattern) {
  final match = pattern.firstMatch(input);
  if (match == null || match.groupCount < 1) {
    return '';
  }
  return _stripHtml(match.group(1) ?? '');
}

String _stripHtml(String value) {
  return value.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
}

String _decodeHtml(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&rsquo;', "'")
      .replaceAll('&ndash;', '-')
      .replaceAll('&mdash;', '-')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ccedil;', 'ç')
      .replaceAll('&Ccedil;', 'Ç')
      .replaceAll('&aacute;', 'á')
      .replaceAll('&Aacute;', 'Á')
      .replaceAll('&atilde;', 'ã')
      .replaceAll('&Atilde;', 'Ã')
      .replaceAll('&acirc;', 'â')
      .replaceAll('&Acirc;', 'Â')
      .replaceAll('&agrave;', 'à')
      .replaceAll('&Agrave;', 'À')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&Eacute;', 'É')
      .replaceAll('&ecirc;', 'ê')
      .replaceAll('&Ecirc;', 'Ê')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&Iacute;', 'Í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&Oacute;', 'Ó')
      .replaceAll('&otilde;', 'õ')
      .replaceAll('&Otilde;', 'Õ')
      .replaceAll('&ocirc;', 'ô')
      .replaceAll('&Ocirc;', 'Ô')
      .replaceAll('&uacute;', 'ú')
      .replaceAll('&Uacute;', 'Ú')
      .trim();
}

String _translatePartnerText(String value) {
  const translations = <String, String>{
    'Curadoria de Ivan Diaz': 'Curated by Ivan Diaz',
    'Curadoria de David Chavez': 'Curated by David Chavez',
    'Projeto dedicado ao forró em vinil, preservando memória e trazendo gravações raras de volta à vida.':
        'Project dedicated to forro on vinyl, preserving memory and bringing rare recordings back to life.',
    'Pesquisa e textos independentes sobre cultura do forró, história e suas raízes brasileiras.':
        'Independent research and writing about forro culture, its history, and its Brazilian roots.',
    'Visitar projeto': 'Open project',
  };

  return translations[value] ?? value;
}

String _translatePartnerSubtitle(String title, String value) {
  switch (title.trim()) {
    case 'Forró em Vinil':
      return 'Curated by Ivan Diaz';
    case 'É QUE MESCAPULIU':
      return 'Curated by David Chavez';
    default:
      return _translatePartnerText(value);
  }
}

String _translatePartnerDescription(String title, String value) {
  switch (title.trim()) {
    case 'Forró em Vinil':
      return 'Project dedicated to forro on vinyl, preserving memory and bringing rare recordings back to life.';
    case 'É QUE MESCAPULIU':
      return 'Independent research and writing about forro culture, its history, and its Brazilian roots.';
    default:
      return _translatePartnerText(value);
  }
}
