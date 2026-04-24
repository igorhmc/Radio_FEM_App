import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:radio_fem_app/src/controllers/radio_controller.dart';
import 'package:radio_fem_app/src/services/azuracast_reports_service.dart';
import 'package:radio_fem_app/src/services/radio_api_service.dart';
import 'package:radio_fem_app/src/services/radio_audio_handler.dart';
import 'package:radio_fem_app/src/ui/home_shell.dart';

void main() {
  testWidgets('shows core navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RadioController(
          apiService: RadioApiService(),
          reportsService: AzuraCastReportsService(),
          playbackService: _FakePlaybackService(),
        ),
        child: const MaterialApp(home: HomeShell()),
      ),
    );

    expect(find.text('Live'), findsWidgets);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Podcasts'), findsOneWidget);
    expect(find.text('Partners'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
  });
}

class _FakePlaybackService extends RadioPlaybackService {
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<PlaybackMediaItem?> _mediaController =
      StreamController<PlaybackMediaItem?>.broadcast();
  double _volume = 1.0;

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
  }) async {}

  @override
  void dispose() {
    _statusController.close();
    _mediaController.close();
  }
}
