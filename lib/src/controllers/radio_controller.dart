import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/radio_models.dart';
import '../services/radio_api_service.dart';

class RadioController extends ChangeNotifier {
  RadioController({
    required RadioApiService apiService,
    required AudioHandler audioHandler,
  }) : _apiService = apiService,
       _audioHandler = audioHandler;

  final RadioApiService _apiService;
  final AudioHandler _audioHandler;

  final Map<String, List<PodcastEpisode>> _episodesCache =
      <String, List<PodcastEpisode>>{};

  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _pollTimer;
  Timer? _progressTimer;

  bool _initialized = false;
  int _schedulePollCount = 0;
  DateTime? _loadedScheduleStart;
  DateTime? _loadedScheduleEnd;

  String stationName = AppConfig.stationName;
  String nowPlayingArtist = 'Loading artist...';
  String nowPlayingTitle = 'Loading track...';
  int listeners = 0;
  bool isPlaying = false;
  bool isBuffering = false;
  bool isLiveStreamMode = true;
  bool isLoading = true;
  bool isScheduleLoading = false;
  bool isPodcastsLoading = false;
  bool isEpisodesLoading = false;
  String playbackSourceLabel = 'Live';
  String currentPodcastEpisodeTitle = '';
  String currentPodcastEpisodeDescription = '';
  String selectedPodcastTitle = '';
  String? selectedPodcastId;
  String? apiErrorMessage;
  String? playerErrorMessage;
  String? scheduleErrorMessage;
  String? podcastsErrorMessage;
  String? episodesErrorMessage;
  String lastUpdated = '';
  Duration podcastPosition = Duration.zero;
  Duration podcastDuration = Duration.zero;
  List<ScheduleItem> schedule = const <ScheduleItem>[];
  List<PodcastItem> podcasts = const <PodcastItem>[];
  List<PodcastEpisode> podcastEpisodes = const <PodcastEpisode>[];

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _playbackSubscription = _audioHandler.playbackState.listen((state) {
      isPlaying = state.playing;
      isBuffering =
          state.processingState == AudioProcessingState.loading ||
          state.processingState == AudioProcessingState.buffering;
      notifyListeners();
    });

    _mediaItemSubscription = _audioHandler.mediaItem.listen((item) {
      if (item == null) {
        return;
      }
      if (isLiveStreamMode) {
        if ((item.artist?.trim().isNotEmpty ?? false)) {
          nowPlayingArtist = item.artist!.trim();
        }
        if (item.title.trim().isNotEmpty) {
          nowPlayingTitle = item.title.trim();
        }
        notifyListeners();
      }
    });

    await Future.wait<void>(<Future<void>>[
      refreshNowPlaying(),
      refreshSchedule(),
      refreshPodcasts(),
    ]);

    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refreshNowPlaying());
      _schedulePollCount += 1;
      if (_schedulePollCount >= 4) {
        _schedulePollCount = 0;
        unawaited(refreshSchedule());
      }
    });

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshPlaybackProgress());
    });
  }

  Future<void> togglePlayPause() async {
    playerErrorMessage = null;
    if (isPlaying) {
      await _audioHandler.pause();
      return;
    }

    if (isLiveStreamMode) {
      await startLivePlayback();
      return;
    }

    await _audioHandler.play();
  }

  Future<void> startLivePlayback() async {
    playerErrorMessage = null;
    try {
      await _audioHandler.customAction('playLive', <String, dynamic>{
        'url': AppConfig.streamUrl,
        'stationName': stationName,
        'artist': nowPlayingArtist,
        'title': nowPlayingTitle,
      });
      isLiveStreamMode = true;
      playbackSourceLabel = 'Live';
      currentPodcastEpisodeTitle = '';
      currentPodcastEpisodeDescription = '';
      podcastPosition = Duration.zero;
      podcastDuration = Duration.zero;
      notifyListeners();
    } catch (_) {
      playerErrorMessage = 'Could not start the live stream.';
      notifyListeners();
    }
  }

  Future<void> returnToLive() async {
    await startLivePlayback();
    await refreshNowPlaying();
  }

  Future<void> playPodcastEpisode(PodcastEpisode episode) async {
    if (episode.playUrl.isEmpty) {
      playerErrorMessage = 'Episode has no playback URL.';
      notifyListeners();
      return;
    }

    playerErrorMessage = null;
    try {
      await _audioHandler.customAction('playPodcast', <String, dynamic>{
        'url': episode.playUrl,
        'title': episode.title,
        'podcastTitle': selectedPodcastTitle.isEmpty
            ? AppConfig.stationName
            : selectedPodcastTitle,
        'description': episode.description,
      });
      isLiveStreamMode = false;
      playbackSourceLabel = 'Podcast';
      currentPodcastEpisodeTitle = episode.title;
      currentPodcastEpisodeDescription = episode.description;
      nowPlayingArtist = selectedPodcastTitle.isEmpty
          ? AppConfig.stationName
          : selectedPodcastTitle;
      nowPlayingTitle = episode.title;
      podcastPosition = Duration.zero;
      podcastDuration = Duration.zero;
      notifyListeners();
    } catch (_) {
      playerErrorMessage = 'Could not play this episode.';
      notifyListeners();
    }
  }

  Future<void> seekPodcastTo(Duration position) async {
    if (isLiveStreamMode) {
      return;
    }
    final maxDuration = podcastDuration;
    final clamped = maxDuration > Duration.zero && position > maxDuration
        ? maxDuration
        : position;
    await _audioHandler.seek(clamped < Duration.zero ? Duration.zero : clamped);
    await _refreshPlaybackProgress();
  }

  Future<void> skipPodcastBy(Duration delta) async {
    if (isLiveStreamMode) {
      return;
    }
    await _audioHandler.customAction('seekRelative', <String, dynamic>{
      'deltaMs': delta.inMilliseconds,
    });
    await _refreshPlaybackProgress();
  }

  Future<void> refreshNowPlaying() async {
    final showLoading = lastUpdated.isEmpty;
    isLoading = showLoading;
    apiErrorMessage = null;
    notifyListeners();

    try {
      final payload = await _apiService.fetchNowPlaying();
      stationName = payload.stationName;
      listeners = payload.listeners;
      lastUpdated = DateFormat('dd/MM HH:mm').format(DateTime.now());
      isLoading = false;
      apiErrorMessage = null;

      if (isLiveStreamMode) {
        nowPlayingArtist = payload.artist;
        nowPlayingTitle = payload.title;
        await _audioHandler
            .customAction('updateLiveMetadata', <String, dynamic>{
              'stationName': payload.stationName,
              'artist': payload.artist,
              'title': payload.title,
            });
      }

      notifyListeners();
    } catch (_) {
      isLoading = false;
      apiErrorMessage = 'Could not update live status.';
      notifyListeners();
    }
  }

  Future<void> refreshSchedule({
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    isScheduleLoading = true;
    scheduleErrorMessage = null;
    notifyListeners();

    final window = _scheduleFetchWindow(
      targetRangeStart: rangeStart,
      targetRangeEnd: rangeEnd,
    );

    try {
      final payload = await _apiService.fetchSchedule(
        start: window.start,
        end: window.end,
      );
      final merged =
          (rangeStart != null && rangeEnd != null && schedule.isNotEmpty)
          ? _mergeSchedule(schedule, payload)
          : payload;
      schedule = merged..sort((a, b) => a.startAt.compareTo(b.startAt));
      isScheduleLoading = false;
      scheduleErrorMessage = null;
      _loadedScheduleStart = _loadedScheduleStart == null
          ? window.start
          : (_loadedScheduleStart!.isBefore(window.start)
                ? _loadedScheduleStart
                : window.start);
      _loadedScheduleEnd = _loadedScheduleEnd == null
          ? window.end
          : (_loadedScheduleEnd!.isAfter(window.end)
                ? _loadedScheduleEnd
                : window.end);
      notifyListeners();
    } catch (_) {
      isScheduleLoading = false;
      scheduleErrorMessage = 'Could not load schedule.';
      notifyListeners();
    }
  }

  Future<void> ensureScheduleRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final loadedStart = _loadedScheduleStart;
    final loadedEnd = _loadedScheduleEnd;
    if (loadedStart != null &&
        loadedEnd != null &&
        !rangeStart.isBefore(loadedStart) &&
        !rangeEnd.isAfter(loadedEnd)) {
      return;
    }

    await refreshSchedule(rangeStart: rangeStart, rangeEnd: rangeEnd);
  }

  Future<void> refreshPodcasts() async {
    isPodcastsLoading = true;
    podcastsErrorMessage = null;
    notifyListeners();

    try {
      podcasts = await _apiService.fetchPodcasts();
      isPodcastsLoading = false;
      podcastsErrorMessage = null;
      notifyListeners();
    } catch (_) {
      isPodcastsLoading = false;
      podcastsErrorMessage = 'Could not load podcasts.';
      notifyListeners();
    }
  }

  Future<void> openPodcast(String podcastId) async {
    final selected = podcasts.where((item) => item.id == podcastId).firstOrNull;
    if (selected == null) {
      return;
    }

    selectedPodcastId = selected.id;
    selectedPodcastTitle = selected.title;
    podcastEpisodes = const <PodcastEpisode>[];
    episodesErrorMessage = null;
    notifyListeners();

    final cached = _episodesCache[podcastId];
    if (cached != null) {
      podcastEpisodes = cached;
      notifyListeners();
      return;
    }

    isEpisodesLoading = true;
    notifyListeners();

    try {
      final episodes = await _apiService.fetchPodcastEpisodes(podcastId);
      _episodesCache[podcastId] = episodes;
      if (selectedPodcastId == podcastId) {
        podcastEpisodes = episodes;
        isEpisodesLoading = false;
        episodesErrorMessage = null;
        notifyListeners();
      }
    } catch (_) {
      if (selectedPodcastId == podcastId) {
        isEpisodesLoading = false;
        episodesErrorMessage = 'Could not load episodes for this podcast.';
        notifyListeners();
      }
    }
  }

  void closePodcast() {
    selectedPodcastId = null;
    selectedPodcastTitle = '';
    podcastEpisodes = const <PodcastEpisode>[];
    isEpisodesLoading = false;
    episodesErrorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshPlaybackProgress() async {
    if (isLiveStreamMode) {
      if (podcastPosition != Duration.zero ||
          podcastDuration != Duration.zero) {
        podcastPosition = Duration.zero;
        podcastDuration = Duration.zero;
        notifyListeners();
      }
      return;
    }

    final result = await _audioHandler.customAction('progress');
    if (result is! Map) {
      return;
    }

    final positionMs = result['positionMs'];
    final durationMs = result['durationMs'];
    final nextPosition = Duration(
      milliseconds: positionMs is int ? positionMs : 0,
    );
    final nextDuration = Duration(
      milliseconds: durationMs is int ? durationMs : 0,
    );
    if (nextPosition != podcastPosition || nextDuration != podcastDuration) {
      podcastPosition = nextPosition;
      podcastDuration = nextDuration;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _pollTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }
}

class _ScheduleFetchWindow {
  const _ScheduleFetchWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

_ScheduleFetchWindow _scheduleFetchWindow({
  DateTime? targetRangeStart,
  DateTime? targetRangeEnd,
}) {
  if (targetRangeStart != null && targetRangeEnd != null) {
    final start = DateTime(
      targetRangeStart.year,
      targetRangeStart.month,
      targetRangeStart.day,
    ).subtract(const Duration(days: 1));
    final end = DateTime(
      targetRangeEnd.year,
      targetRangeEnd.month,
      targetRangeEnd.day,
      23,
      59,
      59,
    ).add(const Duration(days: 1));
    return _ScheduleFetchWindow(start: start, end: end);
  }

  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month + 3, 0, 23, 59, 59);
  return _ScheduleFetchWindow(start: start, end: end);
}

List<ScheduleItem> _mergeSchedule(
  List<ScheduleItem> existing,
  List<ScheduleItem> incoming,
) {
  final items = <String, ScheduleItem>{
    for (final item in existing) item.key: item,
    for (final item in incoming) item.key: item,
  };
  return items.values.toList();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
