import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:radio_fem_app/src/controllers/radio_controller.dart';
import 'package:radio_fem_app/src/models/radio_models.dart';
import 'package:radio_fem_app/src/services/azuracast_reports_service.dart';
import 'package:radio_fem_app/src/services/radio_api_service.dart';
import 'package:radio_fem_app/src/services/radio_audio_handler.dart';

void main() {
  test('ignores a quick API regression to the previous live track', () async {
    final controller = RadioController(
      apiService: _FakeRadioApiService(<NowPlayingInfo>[
        _nowPlaying(artist: 'Artist A', title: 'Song A'),
        _nowPlaying(artist: 'Artist B', title: 'Song B'),
        _nowPlaying(artist: 'Artist A', title: 'Song A'),
      ]),
      reportsService: AzuraCastReportsService(),
      playbackService: _FakePlaybackService(),
    );

    await controller.refreshNowPlaying();
    expect(controller.nowPlayingTitle, 'Song A');

    await controller.refreshNowPlaying();
    expect(controller.nowPlayingTitle, 'Song B');

    await controller.refreshNowPlaying();
    expect(controller.nowPlayingTitle, 'Song B');

    controller.dispose();
  });

  test('ignores stale player metadata after newer API metadata', () async {
    final playbackService = _FakePlaybackService();
    final controller = RadioController(
      apiService: _FakeRadioApiService(<NowPlayingInfo>[
        _nowPlaying(artist: 'Artist A', title: 'Song A'),
      ]),
      reportsService: AzuraCastReportsService(),
      playbackService: playbackService,
    );

    await controller.initialize();
    await controller.refreshNowPlaying();
    expect(controller.nowPlayingTitle, 'Song A');

    playbackService.emitMediaItem(
      const PlaybackMediaItem(
        id: 'live',
        album: 'Radio FEM',
        title: 'Song B',
        artist: 'Artist B',
        description: '',
        duration: Duration.zero,
        artworkUrl: '',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.nowPlayingTitle, 'Song B');

    playbackService.emitMediaItem(
      const PlaybackMediaItem(
        id: 'live',
        album: 'Radio FEM',
        title: 'Song A',
        artist: 'Artist A',
        description: '',
        duration: Duration.zero,
        artworkUrl: '',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.nowPlayingTitle, 'Song B');

    controller.dispose();
  });
}

NowPlayingInfo _nowPlaying({required String artist, required String title}) {
  return NowPlayingInfo(
    stationName: 'Radio FEM',
    listeners: 10,
    artist: artist,
    title: title,
    artworkUrl: '',
  );
}

class _FakeRadioApiService extends RadioApiService {
  _FakeRadioApiService(this._nowPlayingResponses);

  final List<NowPlayingInfo> _nowPlayingResponses;
  int _nowPlayingIndex = 0;

  @override
  Future<NowPlayingInfo> fetchNowPlaying() async {
    final response =
        _nowPlayingResponses[_nowPlayingIndex.clamp(
          0,
          _nowPlayingResponses.length - 1,
        )];
    _nowPlayingIndex += 1;
    return response;
  }

  @override
  Future<List<ScheduleItem>> fetchSchedule({
    DateTime? start,
    DateTime? end,
  }) async {
    return const <ScheduleItem>[];
  }

  @override
  Future<List<PodcastItem>> fetchPodcasts() async {
    return const <PodcastItem>[];
  }

  @override
  Future<List<PartnerItem>> fetchPartners() async {
    return const <PartnerItem>[];
  }
}

class _FakePlaybackService implements RadioPlaybackService {
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<PlaybackMediaItem?> _mediaController =
      StreamController<PlaybackMediaItem?>.broadcast();
  double _volume = 1.0;

  void emitMediaItem(PlaybackMediaItem item) {
    _mediaController.add(item);
  }

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackMediaItem?> get mediaItemStream => _mediaController.stream;

  @override
  double get volume => _volume;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playLive({
    required String url,
    required String stationName,
    required String artist,
    required String title,
    String artworkUrl = '',
  }) async {}

  @override
  Future<void> playPodcast({
    required String url,
    required String title,
    required String podcastTitle,
    required String description,
  }) async {}

  @override
  Future<PlaybackProgress> progress() async {
    return const PlaybackProgress(
      position: Duration.zero,
      duration: Duration.zero,
      isLive: true,
    );
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> seekRelative(Duration delta) async {}

  @override
  Future<double> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    return _volume;
  }

  @override
  Future<double> changeVolumeBy(double delta) async {
    return setVolume(_volume + delta);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> updateLiveMetadata({
    required String stationName,
    required String artist,
    required String title,
    String? artworkUrl,
    bool authoritative = true,
  }) async {}

  @override
  void dispose() {
    _statusController.close();
    _mediaController.close();
  }
}
