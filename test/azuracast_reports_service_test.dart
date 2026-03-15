import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:radio_fem_app/src/services/azuracast_reports_service.dart';

void main() {
  test('fetchAudienceSummary30d aggregates listeners and top countries', () async {
    final requests = <Uri>[];
    final service = AzuraCastReportsService(
      apiKey: 'test-key',
      baseUrl: 'https://example.com/api/',
      stationId: 1,
      client: MockClient((request) async {
        requests.add(request.url);
        expect(request.headers['X-API-Key'], 'test-key');

        if (request.url.path.endsWith('/by-listening-time')) {
          return http.Response(
            '''
            {
              "all": [
                {"label": "0-1 min", "value": "12"},
                {"label": "1-5 min", "value": 8},
                {"label": "5-10 min", "value": "3"}
              ]
            }
            ''',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }

        return http.Response(
          '''
          {
            "all": [
              {"country_code": "BR", "country": "Brazil", "listeners": 20, "connected_seconds": "120.5"},
              {"country_code": "IT", "country": "Italy", "listeners": "45", "connected_seconds": "210.2"},
              {"country_code": "US", "country": "United States", "listeners": 17, "connected_seconds": "80.0"},
              {"country_code": "DE", "country": "Germany", "listeners": 5, "connected_seconds": "10.0"},
              {"country_code": "PT", "country": "Portugal", "listeners": 11, "connected_seconds": "11.0"},
              {"country_code": "FR", "country": "France", "listeners": 2, "connected_seconds": "8.0"}
            ]
          }
          ''',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final start = DateTime(2026, 2, 14);
    final end = DateTime(2026, 3, 15);
    final summary = await service.fetchAudienceSummary30d(
      start: start,
      end: end,
    );

    expect(summary.listenersUnique30d, 23);
    expect(summary.start, start);
    expect(summary.end, end);
    expect(summary.topCountries.length, 5);
    expect(summary.topCountries.first.countryCode, 'IT');
    expect(summary.topCountries.first.countryName, 'Italy');
    expect(summary.topCountries.first.listeners, 45);
    expect(summary.topCountries[1].countryCode, 'BR');
    expect(summary.topCountries.last.countryCode, 'DE');

    expect(requests, hasLength(2));
    for (final request in requests) {
      expect(request.queryParameters['start'], '2026-02-14');
      expect(request.queryParameters['end'], '2026-03-15');
    }
  });

  test('fetchAudienceSummary30d throws HTTP errors', () async {
    final service = AzuraCastReportsService(
      apiKey: 'test-key',
      baseUrl: 'https://example.com/api/',
      stationId: 1,
      client: MockClient(
        (_) async => http.Response('{"message":"forbidden"}', 403),
      ),
    );

    expect(
      () => service.fetchAudienceSummary30d(
        start: DateTime(2026, 2, 14),
        end: DateTime(2026, 3, 15),
      ),
      throwsA(
        isA<AzuraCastReportsException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });
}
