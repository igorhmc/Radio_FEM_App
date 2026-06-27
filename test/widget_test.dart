import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:radio_fem_app/src/controllers/radio_controller.dart';
import 'package:radio_fem_app/src/models/radio_models.dart';
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

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    expect(find.text('Android app'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('shows a rolling PROG-only schedule timeline', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final controller = RadioController(
      apiService: RadioApiService(),
      reportsService: AzuraCastReportsService(),
      playbackService: _FakePlaybackService(),
    );
    controller.schedule = <ScheduleItem>[
      ScheduleItem(
        id: 1,
        rawTitle: 'PROG_Past_Show',
        title: 'Past Show',
        description: 'Past program',
        startAt: now.subtract(const Duration(hours: 3)),
        endAt: now.subtract(const Duration(hours: 2)),
        isNow: false,
      ),
      ScheduleItem(
        id: 2,
        rawTitle: 'PROG_Upcoming_Show',
        title: 'Upcoming Show',
        description: 'Upcoming program',
        startAt: now.add(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 3)),
        isNow: false,
      ),
      ScheduleItem(
        id: 3,
        rawTitle: 'BASE_MANHA',
        title: 'Base Manha',
        description: 'Base playlist',
        startAt: now.add(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 2)),
        isNow: false,
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.textContaining('curated radio programs'), findsOneWidget);
    expect(find.text('ON THE RADIO NOW'), findsOneWidget);
    expect(find.textContaining('NOW •'), findsOneWidget);
    expect(find.text('Past Show'), findsOneWidget);
    expect(find.text('Upcoming Show'), findsOneWidget);
    expect(find.text('Base Manha'), findsNothing);
  });

  testWidgets('auto-scrolls schedule timeline to the present marker', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final controller = RadioController(
      apiService: RadioApiService(),
      reportsService: AzuraCastReportsService(),
      playbackService: _FakePlaybackService(),
    );
    controller.schedule = <ScheduleItem>[
      for (var index = 0; index < 28; index++)
        ScheduleItem(
          id: index,
          rawTitle: 'PROG_Past_Show_$index',
          title: 'Past Show $index',
          description: 'Past program',
          startAt: now.subtract(Duration(hours: 60 - index * 2)),
          endAt: now.subtract(Duration(hours: 59 - index * 2)),
          isNow: false,
        ),
      ScheduleItem(
        id: 100,
        rawTitle: 'PROG_Upcoming_Target',
        title: 'Upcoming Target',
        description: 'Nearest upcoming program',
        startAt: now.add(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 3)),
        isNow: false,
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    final presentMarkerTop = tester.getTopLeft(find.textContaining('NOW •')).dy;
    expect(presentMarkerTop, greaterThanOrEqualTo(0));
    expect(presentMarkerTop, lessThan(520));

    final upcomingTop = tester.getTopLeft(find.text('Upcoming Target')).dy;
    expect(upcomingTop, greaterThan(0));
  });

  testWidgets('keeps current broadcast card fixed while scrolling schedule', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final controller = RadioController(
      apiService: RadioApiService(),
      reportsService: AzuraCastReportsService(),
      playbackService: _FakePlaybackService(),
    );
    controller.schedule = <ScheduleItem>[
      for (var index = 0; index < 24; index++)
        ScheduleItem(
          id: index,
          rawTitle: 'PROG_Past_Show_$index',
          title: 'Past Program $index',
          description: 'Past program',
          startAt: now.subtract(Duration(hours: 48 - index)),
          endAt: now.subtract(Duration(hours: 47 - index)),
          isNow: false,
        ),
      ScheduleItem(
        id: 100,
        rawTitle: 'PROG_Current_Show',
        title: 'Current Program',
        description: 'Program on air',
        startAt: now.subtract(const Duration(minutes: 10)),
        endAt: now.add(const Duration(minutes: 50)),
        isNow: true,
      ),
      for (var index = 0; index < 12; index++)
        ScheduleItem(
          id: 200 + index,
          rawTitle: 'PROG_Upcoming_Show_$index',
          title: 'Upcoming Program $index',
          description: 'Upcoming program',
          startAt: now.add(Duration(hours: index + 2)),
          endAt: now.add(Duration(hours: index + 3)),
          isNow: false,
        ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    final fixedCardFinder = find.text('ON THE RADIO NOW');
    final initialTop = tester.getTopLeft(fixedCardFinder).dy;

    await tester.drag(find.textContaining('NOW •'), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(fixedCardFinder, findsOneWidget);
    expect(tester.getTopLeft(fixedCardFinder).dy, initialTop);
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
