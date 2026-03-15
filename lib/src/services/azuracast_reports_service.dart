import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/azuracast_reports_models.dart';

class AzuraCastReportsService {
  AzuraCastReportsService({
    required this.apiKey,
    this.baseUrl = AppConfig.apiBaseUrl,
    this.stationId = AppConfig.analyticsStationId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final int stationId;
  final http.Client _client;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<AudienceSummary30d> fetchAudienceSummary30d({
    DateTime? start,
    DateTime? end,
  }) async {
    if (!isConfigured) {
      throw const AzuraCastReportsException('Analytics API key is not configured.');
    }

    final range = _resolveRange(start: start, end: end);
    final queryParameters = <String, String>{
      'start': _formatDate(range.start),
      'end': _formatDate(range.end),
    };

    final listeningTimeJson = await _getJson(
      'station/$stationId/reports/overview/by-listening-time',
      queryParameters: queryParameters,
    );
    final countryJson = await _getJson(
      'station/$stationId/reports/overview/by-country',
      queryParameters: queryParameters,
    );

    final listeningTimeRows = _extractList(listeningTimeJson['all'])
        .map(ListeningTimeValue.fromJson)
        .toList(growable: false);
    final countryRows = _extractList(countryJson['all'])
        .map(TopCountryAudience.fromJson)
        .toList()
      ..sort((left, right) => right.listeners.compareTo(left.listeners));

    return AudienceSummary30d(
      listenersUnique30d: listeningTimeRows.fold<int>(
        0,
        (sum, item) => sum + item.value,
      ),
      topCountries: countryRows.take(5).toList(growable: false),
      start: range.start,
      end: range.end,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(baseUrl).resolve(path).replace(
      queryParameters: queryParameters,
    );
    final response = await _client.get(
      uri,
      headers: <String, String>{'X-API-Key': apiKey.trim()},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AzuraCastReportsException(
        'HTTP ${response.statusCode} for $path',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AzuraCastReportsException('Unexpected JSON shape from reports API.');
  }
}

class AzuraCastReportsException implements Exception {
  const AzuraCastReportsException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => message;
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

_DateRange _resolveRange({DateTime? start, DateTime? end}) {
  final normalizedStart = start == null ? null : DateTime(start.year, start.month, start.day);
  final normalizedEnd = end == null ? null : DateTime(end.year, end.month, end.day);

  if (normalizedStart != null && normalizedEnd != null) {
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const AzuraCastReportsException('The end date must be on or after the start date.');
    }
    return _DateRange(start: normalizedStart, end: normalizedEnd);
  }

  if (normalizedStart != null) {
    return _DateRange(
      start: normalizedStart,
      end: normalizedStart.add(const Duration(days: 29)),
    );
  }

  if (normalizedEnd != null) {
    return _DateRange(
      start: normalizedEnd.subtract(const Duration(days: 29)),
      end: normalizedEnd,
    );
  }

  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return _DateRange(
    start: normalizedToday.subtract(const Duration(days: 29)),
    end: normalizedToday,
  );
}

String _formatDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

List<Map<String, dynamic>> _extractList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.map((key, data) => MapEntry(key.toString(), data)))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
