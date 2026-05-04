import 'package:flutter_test/flutter_test.dart';
import 'package:radio_fem_app/src/models/radio_models.dart';

void main() {
  test('NowPlayingInfo parses song artwork URL', () {
    final info = NowPlayingInfo.fromJson(<String, dynamic>{
      'station': <String, dynamic>{'name': 'RadioFEM'},
      'listeners': <String, dynamic>{'current': 7},
      'now_playing': <String, dynamic>{
        'song': <String, dynamic>{
          'artist': 'Trio Potigua',
          'title': 'Vamos Balancar',
          'art': 'https://example.com/cover.jpg',
        },
      },
    });

    expect(info.stationName, 'Radio FEM');
    expect(info.listeners, 7);
    expect(info.artist, 'Trio Potigua');
    expect(info.title, 'Vamos Balancar');
    expect(info.artworkUrl, 'https://example.com/cover.jpg');
  });
}
